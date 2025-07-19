import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/school_assignment_service.dart';
import '../../../../data/models/school.dart';
import '../../common/esc_dismissible_dialog.dart';

// Simple Cubit for managing schools list state
class SchoolsListCubit extends Cubit<SchoolsListState> {
  final SchoolAssignmentService _schoolService;

  SchoolsListCubit(this._schoolService) : super(SchoolsListInitial());

  Future<void> loadSchools(String supervisorId) async {
    emit(SchoolsListLoading());
    
    try {
      final schools = await _schoolService.getSchoolsForSupervisor(supervisorId);
      final hasLargeDataset = schools.length > 1000;
      
      if (hasLargeDataset) {
        print('🏫 DEBUG: Large dataset detected in dialog: ${schools.length} schools');
      }
      
      emit(SchoolsListLoaded(
        schools: schools,
        filteredSchools: schools,
        totalSchools: schools.length,
        hasLargeDataset: hasLargeDataset,
      ));
    } catch (e) {
      emit(SchoolsListError(e.toString()));
    }
  }

  void filterSchools(String query) {
    if (state is SchoolsListLoaded) {
      final currentState = state as SchoolsListLoaded;
      final filteredSchools = currentState.schools.where((school) {
        final nameMatch = school.name.toLowerCase().contains(query.toLowerCase());
        final addressMatch = school.address?.toLowerCase().contains(query.toLowerCase()) ?? false;
        return nameMatch || addressMatch;
      }).toList();
      
      emit(currentState.copyWith(filteredSchools: filteredSchools));
    }
  }
}

// States
abstract class SchoolsListState {}

class SchoolsListInitial extends SchoolsListState {}

class SchoolsListLoading extends SchoolsListState {}

class SchoolsListLoaded extends SchoolsListState {
  final List<School> schools;
  final List<School> filteredSchools;
  final int totalSchools;
  final bool hasLargeDataset;

  SchoolsListLoaded({
    required this.schools,
    required this.filteredSchools,
    required this.totalSchools,
    required this.hasLargeDataset,
  });

  SchoolsListLoaded copyWith({
    List<School>? schools,
    List<School>? filteredSchools,
    int? totalSchools,
    bool? hasLargeDataset,
  }) {
    return SchoolsListLoaded(
      schools: schools ?? this.schools,
      filteredSchools: filteredSchools ?? this.filteredSchools,
      totalSchools: totalSchools ?? this.totalSchools,
      hasLargeDataset: hasLargeDataset ?? this.hasLargeDataset,
    );
  }
}

class SchoolsListError extends SchoolsListState {
  final String message;
  SchoolsListError(this.message);
}

class SchoolsListDialog extends StatefulWidget {
  final String supervisorId;
  final String supervisorName;

  const SchoolsListDialog({
    super.key,
    required this.supervisorId,
    required this.supervisorName,
  });

  @override
  State<SchoolsListDialog> createState() => _SchoolsListDialogState();
}

class _SchoolsListDialogState extends State<SchoolsListDialog> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    context.read<SchoolsListCubit>().filterSchools(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => SchoolsListCubit(SchoolAssignmentService(Supabase.instance.client)),
      child: BlocBuilder<SchoolsListCubit, SchoolsListState>(
        builder: (context, state) {
          // Trigger initial load if we're in initial state
          if (state is SchoolsListInitial) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<SchoolsListCubit>().loadSchools(widget.supervisorId);
            });
          }
          
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: 600,
              constraints: const BoxConstraints(maxHeight: 700),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(context, isDark),
                  Flexible(
                    child: _buildContent(context, isDark, state),
                  ),
                  _buildActionButtons(context, isDark),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark, SchoolsListState state) {
    if (state is SchoolsListLoading) {
      return _buildLoadingState();
    } else if (state is SchoolsListError) {
      return _buildErrorState(isDark, state.message);
    } else if (state is SchoolsListLoaded) {
      return Column(
        children: [
          _buildSearchBar(isDark, state.hasLargeDataset),
          Expanded(child: _buildSchoolsList(isDark, state.filteredSchools)),
        ],
      );
    }
    return const SizedBox.shrink(); // Fallback for initial state
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return BlocBuilder<SchoolsListCubit, SchoolsListState>(
      builder: (context, state) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'المدارس المُعيّنة',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'للمشرف: ${widget.supervisorName}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (state is SchoolsListLoaded) ...[
                Text(
                  '${state.filteredSchools.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (state.hasLargeDataset) ...[
                  const SizedBox(height: 4),
                  Text(
                    'من أصل ${state.totalSchools} مدرسة',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(64),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
            ),
            SizedBox(height: 16),
            Text(
              'جاري تحميل المدارس...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ في تحميل المدارس',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.read<SchoolsListCubit>().loadSchools(widget.supervisorId),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark, bool hasLargeDataset) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: TextField(
            controller: _searchController,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              hintText: 'البحث في المدارس...',
              hintStyle: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              prefixIcon: Icon(
                Icons.search,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark ? const Color(0xFF374151) : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF8B5CF6),
                  width: 2,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1E293B),
              fontSize: 14,
            ),
          ),
        ),
        if (hasLargeDataset) ...[
          BlocBuilder<SchoolsListCubit, SchoolsListState>(
            builder: (context, state) {
              if (state is SchoolsListLoaded) {
                return Container(
                  margin: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.orange[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'هذا المشرف لديه ${state.totalSchools} مدرسة. يتم عرض أول 1000 مدرسة فقط. استخدم البحث للعثور على مدرسة محددة.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSchoolsList(bool isDark, List<School> filteredSchools) {
    if (filteredSchools.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'لا توجد نتائج بحث',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'لم يتم العثور على مدارس تطابق "${_searchController.text}"',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (filteredSchools.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.school_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'لا توجد مدارس مُعيّنة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'لم يتم تعيين أي مدارس لهذا المشرف بعد',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: filteredSchools.length,
      itemBuilder: (context, index) {
        final school = filteredSchools[index];
        return _buildSchoolCard(school, isDark);
      },
    );
  }

  Widget _buildSchoolCard(School school, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.school,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  school.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                if (school.address != null && school.address!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    school.address!,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF374151) : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'إغلاق',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
