import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/admin_service.dart';
import '../../../data/models/supervisor.dart';

// State class for the supervisor dropdown
class SupervisorDropdownState extends Equatable {
  final List<Supervisor> supervisors;
  final List<Supervisor> filteredSupervisors;
  final bool isLoading;
  final bool isDropdownOpen;
  final String? errorMessage;
  final String? selectedSupervisorId;

  const SupervisorDropdownState({
    this.supervisors = const [],
    this.filteredSupervisors = const [],
    this.isLoading = true,
    this.isDropdownOpen = false,
    this.errorMessage,
    this.selectedSupervisorId,
  });

  SupervisorDropdownState copyWith({
    List<Supervisor>? supervisors,
    List<Supervisor>? filteredSupervisors,
    bool? isLoading,
    bool? isDropdownOpen,
    String? errorMessage,
    String? selectedSupervisorId,
  }) {
    return SupervisorDropdownState(
      supervisors: supervisors ?? this.supervisors,
      filteredSupervisors: filteredSupervisors ?? this.filteredSupervisors,
      isLoading: isLoading ?? this.isLoading,
      isDropdownOpen: isDropdownOpen ?? this.isDropdownOpen,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedSupervisorId: selectedSupervisorId ?? this.selectedSupervisorId,
    );
  }

  @override
  List<Object?> get props => [
        supervisors,
        filteredSupervisors,
        isLoading,
        isDropdownOpen,
        errorMessage,
        selectedSupervisorId,
      ];
}

// Cubit for managing supervisor dropdown state
class SupervisorDropdownCubit extends Cubit<SupervisorDropdownState> {
  final AdminService _adminService;

  SupervisorDropdownCubit(this._adminService)
      : super(const SupervisorDropdownState()) {
    _loadSupervisors();
  }

  Future<void> _loadSupervisors() async {
    try {
      if (isClosed) return;
      emit(state.copyWith(isLoading: true, errorMessage: null));
      
      print('👥 Loading supervisors for current admin');
      
      final supervisors = await _adminService.getCurrentAdminSupervisors();
      print('👥 Loaded ${supervisors.length} supervisors: ${supervisors.map((s) => s.username).toList()}');
      
      if (isClosed) return;
      emit(state.copyWith(
        supervisors: supervisors,
        filteredSupervisors: supervisors,
        isLoading: false,
      ));
    } catch (e) {
      print('👥 Error loading supervisors: $e');
      if (isClosed) return;
      emit(state.copyWith(
        errorMessage: 'فشل في تحميل المشرفين: $e',
        isLoading: false,
      ));
    }
  }

  void filterSupervisors(String query) {
    if (isClosed) return;
    final filteredQuery = query.toLowerCase().trim();
    List<Supervisor> filtered;
    
         if (filteredQuery.isEmpty) {
       filtered = state.supervisors;
     } else {
       filtered = state.supervisors.where((supervisor) {
         final usernameMatch = supervisor.username.toLowerCase().contains(filteredQuery);
         final workIdMatch = supervisor.workId.toLowerCase().contains(filteredQuery);
         return usernameMatch || workIdMatch;
       }).toList();
     }
    if (isClosed) return;
    emit(state.copyWith(filteredSupervisors: filtered));
  }

  void openDropdown() {
    if (isClosed) return;
    if (state.filteredSupervisors.isNotEmpty) {
      print('👥 Opening supervisor dropdown');
      emit(state.copyWith(isDropdownOpen: true));
    }
  }

  void closeDropdown() {
    if (isClosed) return;
    print('👥 Closing supervisor dropdown');
    emit(state.copyWith(isDropdownOpen: false));
  }

  void selectSupervisor(Supervisor supervisor) {
    if (isClosed) return;
    print('👥 Supervisor selected: ${supervisor.username}');
    emit(state.copyWith(
      selectedSupervisorId: supervisor.id,
      isDropdownOpen: false,
    ));
  }

  void setSelectedSupervisorId(String? supervisorId) {
    if (isClosed) return;
    emit(state.copyWith(selectedSupervisorId: supervisorId));
  }
}

class SearchableSupervisorDropdown extends StatefulWidget {
  final String? selectedSupervisorId;
  final Function(String supervisorId) onSupervisorSelected;
  final String? hintText;
  final String? errorText;
  final bool enabled;

  const SearchableSupervisorDropdown({
    super.key,
    this.selectedSupervisorId,
    required this.onSupervisorSelected,
    this.hintText,
    this.errorText,
    this.enabled = true,
  });

  @override
  State<SearchableSupervisorDropdown> createState() => _SearchableSupervisorDropdownState();
}

class _SearchableSupervisorDropdownState extends State<SearchableSupervisorDropdown> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late SupervisorDropdownCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = SupervisorDropdownCubit(
      AdminService(Supabase.instance.client),
    );
    _searchController.addListener(_filterSupervisors);
    _focusNode.addListener(_onFocusChange);

    // Set initial value if provided
    if (widget.selectedSupervisorId != null) {
      _cubit.setSelectedSupervisorId(widget.selectedSupervisorId);
             // Find the supervisor name for display
       final supervisor = _cubit.state.supervisors.firstWhere(
         (s) => s.id == widget.selectedSupervisorId,
         orElse: () => Supervisor(
           id: '', 
           username: '', 
           email: '',
           phone: '',
           createdAt: DateTime.now(),
           iqamaId: '',
           plateNumbers: '',
           plateEnglishLetters: '',
           plateArabicLetters: '',
           workId: '',
         ),
       );
      if (supervisor.id.isNotEmpty) {
        _searchController.text = supervisor.username;
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _cubit.close();
    super.dispose();
  }

  void _filterSupervisors() {
    _cubit.filterSupervisors(_searchController.text);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && _cubit.state.filteredSupervisors.isNotEmpty) {
      print('👥 Focus gained - opening supervisor dropdown');
      _cubit.openDropdown();
    } else if (!_focusNode.hasFocus) {
      // Add a delay before closing to allow for option selection
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && !_focusNode.hasFocus) {
          print('👥 Focus lost - closing supervisor dropdown');
          _cubit.closeDropdown();
        }
      });
    }
  }

  void _selectSupervisor(Supervisor supervisor) {
    print('👥 Supervisor selected: ${supervisor.username}');
    _searchController.text = supervisor.username;
    _cubit.selectSupervisor(supervisor);
    // Delay unfocus to prevent immediate dropdown closure
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _focusNode.unfocus();
      }
    });
    print('👥 Calling onSupervisorSelected with: ${supervisor.id}');
    widget.onSupervisorSelected(supervisor.id);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    print('👥 Building SearchableSupervisorDropdown - dropdown open: ${_cubit.state.isDropdownOpen}, supervisors: ${_cubit.state.filteredSupervisors.length}');

    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<SupervisorDropdownCubit, SupervisorDropdownState>(
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
                        : isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Search Input
                    TextFormField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      enabled: widget.enabled,
                      decoration: InputDecoration(
                        labelText: widget.hintText ?? 'ابحث واختر المشرف...',
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                        prefixIcon: const Icon(
                          Icons.person_search_rounded,
                          color: Color(0xFF3B82F6),
                          size: 16,
                        ),
                        suffixIcon: state.isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: Padding(
                                  padding: EdgeInsets.all(8),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                                  ),
                                ),
                              )
                            : state.isDropdownOpen
                                ? IconButton(
                                    icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 16),
                                    onPressed: () => _cubit.closeDropdown(),
                                    color: const Color(0xFF64748B),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                                    onPressed: () => _cubit.openDropdown(),
                                    color: const Color(0xFF64748B),
                                  ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        errorText: widget.errorText,
                        errorStyle: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    
                    // Dropdown Options
                    if (state.isDropdownOpen && state.filteredSupervisors.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          border: Border(
                            top: BorderSide(
                              color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                        ),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: state.filteredSupervisors.length,
                          itemBuilder: (context, index) {
                            final supervisor = state.filteredSupervisors[index];
                            return ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFF3B82F6).withOpacity(0.1),
                                child: Text(
                                  supervisor.username.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF3B82F6),
                                  ),
                                ),
                              ),
                              title: Text(
                                supervisor.username,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                                                             subtitle: Text(
                                 supervisor.workId,
                                 style: TextStyle(
                                   fontSize: 11,
                                   color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                 ),
                               ),
                              onTap: () => _selectSupervisor(supervisor),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              
              // Error Message
              if (state.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    state.errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
} 