/// Searchable Excel Schools Dropdown Widget
/// 
/// This widget provides a searchable dropdown for selecting schools from Excel data.
/// It's specifically designed for the Excel report submission system where schools
/// are loaded from Excel files rather than the database.
/// 
/// Features:
/// - Real-time search filtering
/// - Keyboard navigation support
/// - Arabic text direction support
/// - Dark/light theme support
/// - Error state handling
/// - Empty state handling
/// 
/// Usage:
/// ```dart
/// SearchableExcelSchoolDropdown(
///   schools: state.excelReportsBySchool.keys.toList()..sort(),
///   selectedSchoolName: state.selectedExcelSchoolName,
///   hintText: 'ابحث واختر المدرسة من ملف الإكسل...',
///   onSchoolSelected: (schoolName) {
///     context.read<Cubit>().updateSelectedExcelSchoolName(schoolName);
///   },
/// )
/// ```

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// State class for the Excel schools dropdown
class ExcelSchoolDropdownState extends Equatable {
  final List<String> schools;
  final List<String> filteredSchools;
  final bool isDropdownOpen;
  final String? selectedSchoolName;

  const ExcelSchoolDropdownState({
    this.schools = const [],
    this.filteredSchools = const [],
    this.isDropdownOpen = false,
    this.selectedSchoolName,
  });

  ExcelSchoolDropdownState copyWith({
    List<String>? schools,
    List<String>? filteredSchools,
    bool? isDropdownOpen,
    String? selectedSchoolName,
  }) {
    return ExcelSchoolDropdownState(
      schools: schools ?? this.schools,
      filteredSchools: filteredSchools ?? this.filteredSchools,
      isDropdownOpen: isDropdownOpen ?? this.isDropdownOpen,
      selectedSchoolName: selectedSchoolName ?? this.selectedSchoolName,
    );
  }

  @override
  List<Object?> get props => [
        schools,
        filteredSchools,
        isDropdownOpen,
        selectedSchoolName,
      ];
}

// Cubit for managing Excel schools dropdown state
class ExcelSchoolDropdownCubit extends Cubit<ExcelSchoolDropdownState> {
  ExcelSchoolDropdownCubit(List<String> schools)
      : super(ExcelSchoolDropdownState(schools: schools, filteredSchools: schools));

  void filterSchools(String query) {
    if (isClosed) return;
    final filteredQuery = query.toLowerCase().trim();
    List<String> filtered;
    
    if (filteredQuery.isEmpty) {
      filtered = state.schools;
    } else {
      filtered = state.schools.where((schoolName) {
        return schoolName.toLowerCase().contains(filteredQuery);
      }).toList();
    }
    if (isClosed) return;
    emit(state.copyWith(filteredSchools: filtered));
  }

  void openDropdown() {
    if (isClosed) return;
    if (state.filteredSchools.isNotEmpty) {
      print('🏫 Excel: Opening dropdown');
      emit(state.copyWith(isDropdownOpen: true));
    }
  }

  void closeDropdown() {
    if (isClosed) return;
    print('🏫 Excel: Closing dropdown');
    emit(state.copyWith(isDropdownOpen: false));
  }

  void selectSchool(String schoolName) {
    if (isClosed) return;
    print('🏫 Excel: School selected: $schoolName');
    emit(state.copyWith(
      selectedSchoolName: schoolName,
      isDropdownOpen: false,
    ));
  }

  void setSelectedSchoolName(String? schoolName) {
    if (isClosed) return;
    emit(state.copyWith(selectedSchoolName: schoolName));
  }

  void updateSchools(List<String> schools) {
    if (isClosed) return;
    emit(state.copyWith(
      schools: schools,
      filteredSchools: schools,
    ));
  }
}

class SearchableExcelSchoolDropdown extends StatefulWidget {
  final List<String> schools;
  final String? selectedSchoolName;
  final Function(String schoolName) onSchoolSelected;
  final String? hintText;
  final String? errorText;
  final bool enabled;

  const SearchableExcelSchoolDropdown({
    super.key,
    required this.schools,
    this.selectedSchoolName,
    required this.onSchoolSelected,
    this.hintText,
    this.errorText,
    this.enabled = true,
  });

  @override
  State<SearchableExcelSchoolDropdown> createState() => _SearchableExcelSchoolDropdownState();
}

class _SearchableExcelSchoolDropdownState extends State<SearchableExcelSchoolDropdown> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late ExcelSchoolDropdownCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = ExcelSchoolDropdownCubit(widget.schools);
    _searchController.addListener(_filterSchools);
    _focusNode.addListener(_onFocusChange);

    // Set initial value if provided
    if (widget.selectedSchoolName != null) {
      print('🏫 Excel: Setting initial value: ${widget.selectedSchoolName}');
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
  void didUpdateWidget(SearchableExcelSchoolDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update schools list if it changed
    if (widget.schools != oldWidget.schools) {
      _cubit.updateSchools(widget.schools);
    }

    // Update controller text if the selected school changed externally
    if (widget.selectedSchoolName != oldWidget.selectedSchoolName) {
      print('🏫 Excel: External value changed: ${oldWidget.selectedSchoolName} -> ${widget.selectedSchoolName}');
      if (_searchController.text != (widget.selectedSchoolName ?? '')) {
        print('🏫 Excel: Updating controller text to: ${widget.selectedSchoolName ?? ''}');
        _searchController.text = widget.selectedSchoolName ?? '';
        _cubit.setSelectedSchoolName(widget.selectedSchoolName);
      }
    }
  }

  void _filterSchools() {
    _cubit.filterSchools(_searchController.text);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && _cubit.state.filteredSchools.isNotEmpty) {
      print('🏫 Excel: Focus gained - opening dropdown');
      _cubit.openDropdown();
    } else if (!_focusNode.hasFocus) {
      // Add a delay before closing to allow for option selection
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && !_focusNode.hasFocus) {
          print('🏫 Excel: Focus lost - closing dropdown');
          _cubit.closeDropdown();
        }
      });
    }
  }

  void _selectSchool(String schoolName) {
    print('🏫 Excel: School selected: $schoolName');
    _searchController.text = schoolName;
    _cubit.selectSchool(schoolName);
    // Delay unfocus to prevent immediate dropdown closure
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _focusNode.unfocus();
      }
    });
    print('🏫 Excel: Calling onSchoolSelected with: $schoolName');
    widget.onSchoolSelected(schoolName);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    print('🏫 Excel: Building SearchableExcelSchoolDropdown - dropdown open: ${_cubit.state.isDropdownOpen}, schools: ${_cubit.state.filteredSchools.length}');

    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<ExcelSchoolDropdownCubit, ExcelSchoolDropdownState>(
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
                        hintText: widget.hintText ?? 'ابحث واختر المدرسة من ملف الإكسل...',
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
                        suffixIcon: Icon(
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
                        print('🏫 Excel: TextFormField tapped. Dropdown open: ${state.isDropdownOpen}, Schools: ${state.filteredSchools.length}');
                        if (!state.isDropdownOpen && state.filteredSchools.isNotEmpty) {
                          print('🏫 Excel: Opening dropdown');
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
                        final schoolName = state.filteredSchools[index];
                        return _buildSchoolOption(schoolName, isDark);
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

              // Empty state when no schools available
              if (state.schools.isEmpty) ...[
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
                        Icons.file_present_outlined,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'لا توجد مدارس في ملف الإكسل',
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

  Widget _buildSchoolOption(String schoolName, bool isDark) {
    print('🏫 Excel: Building school option: $schoolName');
    return InkWell(
      onTap: () {
        print('🏫 Excel: School option tapped: $schoolName');
        _selectSchool(schoolName);
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
                Icons.file_present,
                color: Color(0xFF3B82F6),
                size: 12,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                schoolName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 