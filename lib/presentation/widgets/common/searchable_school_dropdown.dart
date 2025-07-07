import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/school_assignment_service.dart';
import '../../../data/models/school.dart';

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
  State<SearchableSchoolDropdown> createState() =>
      _SearchableSchoolDropdownState();
}

class _SearchableSchoolDropdownState extends State<SearchableSchoolDropdown> {
  final SchoolAssignmentService _schoolService =
      SchoolAssignmentService(Supabase.instance.client);
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<School> _schools = [];
  List<School> _filteredSchools = [];
  bool _isLoading = true;
  bool _isDropdownOpen = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSchools();
    _searchController.addListener(_filterSchools);
    _focusNode.addListener(_onFocusChange);

    // Set initial value if provided
    if (widget.selectedSchoolName != null) {
      print('🏫 Setting initial value: ${widget.selectedSchoolName}');
      _searchController.text = widget.selectedSchoolName!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SearchableSchoolDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update controller text if the selected school changed externally
    if (widget.selectedSchoolName != oldWidget.selectedSchoolName) {
      print(
          '🏫 External value changed: ${oldWidget.selectedSchoolName} -> ${widget.selectedSchoolName}');
      // Only update if the text is different to prevent cursor issues
      if (_searchController.text != (widget.selectedSchoolName ?? '')) {
        print(
            '🏫 Updating controller text to: ${widget.selectedSchoolName ?? ''}');
        _searchController.text = widget.selectedSchoolName ?? '';
      }
    }

    // Reload schools if supervisor changed
    if (widget.supervisorId != oldWidget.supervisorId) {
      _loadSchools();
    }
  }

  Future<void> _loadSchools() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('🏫 Loading schools for supervisor: ${widget.supervisorId}');
      final schools =
          await _schoolService.getSchoolsForSupervisor(widget.supervisorId);
      print(
          '🏫 Loaded ${schools.length} schools: ${schools.map((s) => s.name).toList()}');
      setState(() {
        _schools = schools;
        _filteredSchools = schools;
        _isLoading = false;
      });
    } catch (e) {
      print('🏫 Error loading schools: $e');
      setState(() {
        _errorMessage = 'فشل في تحميل المدارس: $e';
        _isLoading = false;
      });
    }
  }

  void _filterSchools() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredSchools = _schools;
      } else {
        _filteredSchools = _schools.where((school) {
          final nameMatch = school.name.toLowerCase().contains(query);
          final addressMatch =
              school.address?.toLowerCase().contains(query) ?? false;
          return nameMatch || addressMatch;
        }).toList();
      }
    });
  }

  void _onFocusChange() {
    // Only close the dropdown if focus is lost AND user isn't interacting with dropdown
    if (_focusNode.hasFocus && _filteredSchools.isNotEmpty) {
      print('🏫 Focus gained - opening dropdown');
      setState(() {
        _isDropdownOpen = true;
      });
    } else if (!_focusNode.hasFocus) {
      // Add a small delay before closing to allow for option selection
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !_focusNode.hasFocus) {
          print('🏫 Focus lost - closing dropdown');
          setState(() {
            _isDropdownOpen = false;
          });
        }
      });
    }
  }

  void _selectSchool(School school) {
    print('🏫 School selected: ${school.name}');
    _searchController.text = school.name;
    _focusNode.unfocus();
    setState(() {
      _isDropdownOpen = false;
    });
    print('🏫 Calling onSchoolSelected with: ${school.name}');
    widget.onSchoolSelected(school.name);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  suffixIcon: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : Icon(
                          _isDropdownOpen
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
                  print(
                      '🏫 TextFormField tapped. Dropdown open: $_isDropdownOpen, Schools: ${_filteredSchools.length}');
                  if (!_isDropdownOpen && _filteredSchools.isNotEmpty) {
                    print('🏫 Opening dropdown');
                    setState(() {
                      _isDropdownOpen = true;
                    });
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
        if (_errorMessage != null) ...[
          const SizedBox(height: 4),
          Text(
            _errorMessage!,
            style: const TextStyle(
              color: Color(0xFFEF4444),
              fontSize: 12,
            ),
          ),
        ],

        // Dropdown list
        if (_isDropdownOpen && _filteredSchools.isNotEmpty) ...[
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
                itemCount: _filteredSchools.length,
                itemBuilder: (context, index) {
                  final school = _filteredSchools[index];
                  return _buildSchoolOption(school, isDark);
                },
              ),
            ),
          ),
        ],

        // Empty state when no schools match search
        if (_isDropdownOpen &&
            _filteredSchools.isEmpty &&
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
        if (_schools.isEmpty && !_isLoading && _errorMessage == null) ...[
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
  }

  Widget _buildSchoolOption(School school, bool isDark) {
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
