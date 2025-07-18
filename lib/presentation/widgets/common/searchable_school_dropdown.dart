import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/school_assignment_service.dart';
import '../../../data/models/school.dart';

// State class for the dropdown
class SchoolDropdownState extends Equatable {
  final List<School> schools;
  final List<School> filteredSchools;
  final bool isLoading;
  final bool isDropdownOpen;
  final String? errorMessage;
  final String? selectedSchoolName;

  const SchoolDropdownState({
    this.schools = const [],
    this.filteredSchools = const [],
    this.isLoading = true,
    this.isDropdownOpen = false,
    this.errorMessage,
    this.selectedSchoolName,
  });

  SchoolDropdownState copyWith({
    List<School>? schools,
    List<School>? filteredSchools,
    bool? isLoading,
    bool? isDropdownOpen,
    String? errorMessage,
    String? selectedSchoolName,
  }) {
    return SchoolDropdownState(
      schools: schools ?? this.schools,
      filteredSchools: filteredSchools ?? this.filteredSchools,
      isLoading: isLoading ?? this.isLoading,
      isDropdownOpen: isDropdownOpen ?? this.isDropdownOpen,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedSchoolName: selectedSchoolName ?? this.selectedSchoolName,
    );
  }

  @override
  List<Object?> get props => [
        schools,
        filteredSchools,
        isLoading,
        isDropdownOpen,
        errorMessage,
        selectedSchoolName,
      ];
}

// Cubit for managing dropdown state
class SchoolDropdownCubit extends Cubit<SchoolDropdownState> {
  final SchoolAssignmentService _schoolService;
  final String supervisorId;

  SchoolDropdownCubit(this._schoolService, this.supervisorId)
      : super(const SchoolDropdownState()) {
    _loadSchools();
  }

  Future<void> _loadSchools() async {
    try {
      emit(state.copyWith(isLoading: true, errorMessage: null));
      print('🏫 Loading schools for supervisor: $supervisorId');
      
      final schools = await _schoolService.getSchoolsForSupervisor(supervisorId);
      print('🏫 Loaded ${schools.length} schools: ${schools.map((s) => s.name).toList()}');
      
      emit(state.copyWith(
        schools: schools,
        filteredSchools: schools,
        isLoading: false,
      ));
    } catch (e) {
      print('🏫 Error loading schools: $e');
      emit(state.copyWith(
        errorMessage: 'فشل في تحميل المدارس: $e',
        isLoading: false,
      ));
    }
  }

  void filterSchools(String query) {
    final filteredQuery = query.toLowerCase().trim();
    List<School> filtered;
    
    if (filteredQuery.isEmpty) {
      filtered = state.schools;
    } else {
      filtered = state.schools.where((school) {
        final nameMatch = school.name.toLowerCase().contains(filteredQuery);
        final addressMatch = school.address?.toLowerCase().contains(filteredQuery) ?? false;
        return nameMatch || addressMatch;
      }).toList();
    }
    
    emit(state.copyWith(filteredSchools: filtered));
  }

  void openDropdown() {
    if (state.filteredSchools.isNotEmpty) {
      print('🏫 Opening dropdown');
      emit(state.copyWith(isDropdownOpen: true));
    }
  }

  void closeDropdown() {
    print('🏫 Closing dropdown');
    emit(state.copyWith(isDropdownOpen: false));
  }

  void selectSchool(School school) {
    print('🏫 School selected: ${school.name}');
    emit(state.copyWith(
      selectedSchoolName: school.name,
      isDropdownOpen: false,
    ));
  }

  void setSelectedSchoolName(String? schoolName) {
    emit(state.copyWith(selectedSchoolName: schoolName));
  }
}

class SearchableSchoolDropdown extends StatefulWidget {
  final String supervisorId;
  final String? selectedSchoolName;
  final Function(String schoolName) onSchoolSelected;
  final String? hintText;
  final String? errorText;
  final bool enabled;

  const SearchableSchoolDropdown({
    super.key,
    required this.supervisorId,
    this.selectedSchoolName,
    required this.onSchoolSelected,
    this.hintText,
    this.errorText,
    this.enabled = true,
  });

  @override
  State<SearchableSchoolDropdown> createState() => _SearchableSchoolDropdownState();
}

class _SearchableSchoolDropdownState extends State<SearchableSchoolDropdown> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late SchoolDropdownCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = SchoolDropdownCubit(
      SchoolAssignmentService(Supabase.instance.client),
      widget.supervisorId,
    );
    _searchController.addListener(_filterSchools);
    _focusNode.addListener(_onFocusChange);

    // Set initial value if provided
    if (widget.selectedSchoolName != null) {
      print('🏫 Setting initial value: ${widget.selectedSchoolName}');
      _searchController.text = widget.selectedSchoolName!;
      _cubit.setSelectedSchoolName(widget.selectedSchoolName);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  void didUpdateWidget(SearchableSchoolDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update controller text if the selected school changed externally
    if (widget.selectedSchoolName != oldWidget.selectedSchoolName) {
      print('🏫 External value changed: ${oldWidget.selectedSchoolName} -> ${widget.selectedSchoolName}');
      if (_searchController.text != (widget.selectedSchoolName ?? '')) {
        print('🏫 Updating controller text to: ${widget.selectedSchoolName ?? ''}');
        _searchController.text = widget.selectedSchoolName ?? '';
        _cubit.setSelectedSchoolName(widget.selectedSchoolName);
      }
    }

    // Reload schools if supervisor changed
    if (widget.supervisorId != oldWidget.supervisorId) {
      _cubit.close();
      _cubit = SchoolDropdownCubit(
        SchoolAssignmentService(Supabase.instance.client),
        widget.supervisorId,
      );
    }
  }

  void _filterSchools() {
    _cubit.filterSchools(_searchController.text);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && _cubit.state.filteredSchools.isNotEmpty) {
      print('🏫 Focus gained - opening dropdown');
      _cubit.openDropdown();
    } else if (!_focusNode.hasFocus) {
      // Add a delay before closing to allow for option selection
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && !_focusNode.hasFocus) {
          print('🏫 Focus lost - closing dropdown');
          _cubit.closeDropdown();
        }
      });
    }
  }

  void _selectSchool(School school) {
    print('🏫 School selected: ${school.name}');
    _searchController.text = school.name;
    _cubit.selectSchool(school);
    // Delay unfocus to prevent immediate dropdown closure
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _focusNode.unfocus();
      }
    });
    print('🏫 Calling onSchoolSelected with: ${school.name}');
    widget.onSchoolSelected(school.name);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    print('🏫 Building SearchableSchoolDropdown - dropdown open: ${_cubit.state.isDropdownOpen}, schools: ${_cubit.state.filteredSchools.length}');

    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<SchoolDropdownCubit, SchoolDropdownState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  border: Border.all(
                    color: widget.errorText != null
                        ? const Color(0xFFEF4444)
                        : isDark
                            ? const Color(0xFF475569)
                            : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    TextFormField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      enabled: widget.enabled,
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(
                        hintText: widget.hintText ?? 'ابحث واختر المدرسة...',
                        hintStyle: TextStyle(
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                        prefixIcon: Icon(
                          Icons.school_rounded,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          size: 16,
                        ),
                        suffixIcon: state.isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : Icon(
                                state.isDropdownOpen
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        fontSize: 14,
                      ),
                      onTap: () {
                        print('🏫 TextFormField tapped. Dropdown open: ${state.isDropdownOpen}, Schools: ${state.filteredSchools.length}');
                        if (!state.isDropdownOpen && state.filteredSchools.isNotEmpty) {
                          print('🏫 Opening dropdown');
                          _cubit.openDropdown();
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Error message
              if (widget.errorText != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.errorText!,
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              // Loading error message
              if (state.errorMessage != null) ...[
                const SizedBox(height: 4),
                Text(
                  state.errorMessage!,
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 12,
                  ),
                ),
              ],

              // Dropdown list
              if (state.isDropdownOpen && state.filteredSchools.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    border: Border.all(
                      color:
                          isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: state.filteredSchools.length,
                      itemBuilder: (context, index) {
                        final school = state.filteredSchools[index];
                        return _buildSchoolOption(school, isDark);
                      },
                    ),
                  ),
                ),
              ],

              // Empty state when no schools match search
              if (state.isDropdownOpen &&
                  state.filteredSchools.isEmpty &&
                  _searchController.text.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    border: Border.all(
                      color:
                          isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_off,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'لا توجد مدارس تطابق البحث',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Empty state when supervisor has no schools
              if (state.schools.isEmpty && !state.isLoading && state.errorMessage == null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    border: Border.all(
                      color:
                          isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.school_outlined,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'لا توجد مدارس مُعيّنة لهذا المشرف',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSchoolOption(School school, bool isDark) {
    print('🏫 Building school option: ${school.name}');
    return InkWell(
      onTap: () {
        print('🏫 School option tapped: ${school.name}');
        _selectSchool(school);
      },
      splashColor: const Color(0xFF3B82F6).withOpacity(0.1),
      highlightColor: const Color(0xFF3B82F6).withOpacity(0.05),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.school,
                color: Color(0xFF3B82F6),
                size: 12,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    school.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  if (school.address != null && school.address!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      school.address!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
