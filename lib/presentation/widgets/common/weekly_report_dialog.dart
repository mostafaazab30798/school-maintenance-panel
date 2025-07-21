import 'package:flutter/material.dart';
import '../../../core/services/weekly_report_service.dart';
import '../../../core/services/admin_service.dart';

class WeeklyReportDialog extends StatefulWidget {
  final AdminService? adminService;
  
  const WeeklyReportDialog({
    super.key,
    this.adminService,
  });

  @override
  State<WeeklyReportDialog> createState() => _WeeklyReportDialogState();
}

class _WeeklyReportDialogState extends State<WeeklyReportDialog> {
  late int selectedYear;
  late int selectedMonth;
  List<Map<String, dynamic>> availableWeeks = [];
  Map<String, dynamic>? selectedWeek;
  Map<String, dynamic>? selectedMonthData;
  bool isGenerating = false;
  bool isMonthlyReport = false; // Toggle between weekly and monthly reports

  final WeeklyReportService _reportService = WeeklyReportService();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedYear = now.year;
    selectedMonth = now.month;
    _updateAvailableWeeks();
    _updateMonthData();
  }

  void _updateAvailableWeeks() {
    availableWeeks = WeeklyReportService.getWeeksInMonth(selectedYear, selectedMonth);
    selectedWeek = null;
    setState(() {});
  }

  void _updateMonthData() {
    selectedMonthData = WeeklyReportService.getMonthData(selectedYear, selectedMonth);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 800),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, isDark),
            const SizedBox(height: 24),
            _buildReportTypeToggle(isDark),
            const SizedBox(height: 20),
            _buildMonthYearSelector(isDark),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isMonthlyReport)
                      _buildMonthSelector(isDark)
                    else
                      _buildWeekSelector(isDark),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildActionButtons(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.assessment_outlined,
            color: Color(0xFF3B82F6),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMonthlyReport ? 'تقرير شهري' : 'تقرير أسبوعي',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              Text(
                isMonthlyReport 
                    ? 'اختر الشهر لإنشاء تقرير مفصل'
                    : 'اختر الأسبوع لإنشاء تقرير مفصل',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.close,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildReportTypeToggle(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نوع التقرير',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isMonthlyReport = false;
                      selectedWeek = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: !isMonthlyReport
                          ? const Color(0xFF3B82F6)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'تقرير أسبوعي',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: !isMonthlyReport
                            ? Colors.white
                            : (isDark ? Colors.grey[400] : Colors.grey[600]),
                        fontWeight: !isMonthlyReport ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isMonthlyReport = true;
                      selectedWeek = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isMonthlyReport
                          ? const Color(0xFF3B82F6)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'تقرير شهري',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isMonthlyReport
                            ? Colors.white
                            : (isDark ? Colors.grey[400] : Colors.grey[600]),
                        fontWeight: isMonthlyReport ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthYearSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اختر الشهر والسنة',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Month selector
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF374151) : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedMonth,
                    isExpanded: true,
                    dropdownColor: isDark ? const Color(0xFF374151) : Colors.white,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF374151),
                    ),
                    items: List.generate(12, (index) {
                      final month = index + 1;
                      return DropdownMenuItem(
                        value: month,
                        child: Text(_getMonthName(month)),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        selectedMonth = value;
                        _updateAvailableWeeks();
                        _updateMonthData();
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Year selector
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF374151) : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedYear,
                    isExpanded: true,
                    dropdownColor: isDark ? const Color(0xFF374151) : Colors.white,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF374151),
                    ),
                    items: List.generate(5, (index) {
                      final year = DateTime.now().year - 2 + index;
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        selectedYear = value;
                        _updateAvailableWeeks();
                        _updateMonthData();
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeekSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اختر الأسبوع',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 12),
        if (availableWeeks.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF374151) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
              ),
            ),
            child: Text(
              'لا توجد أسابيع متاحة للشهر المحدد',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          )
        else
          Column(
            children: availableWeeks.map((week) {
              final isSelected = selectedWeek == week;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      selectedWeek = week;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF3B82F6).withOpacity(0.1)
                          : (isDark ? const Color(0xFF374151) : const Color(0xFFF9FAFB)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF3B82F6)
                            : (isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB)),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF3B82F6)
                                : (isDark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            week['weekNumber'].toString(),
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            week['label'],
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF3B82F6)
                                  : (isDark ? Colors.white : const Color(0xFF374151)),
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF3B82F6),
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildMonthSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الشهر المحدد',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF3B82F6),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.calendar_month,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  selectedMonthData?['label'] ?? '${_getMonthName(selectedMonth)} $selectedYear',
                  style: TextStyle(
                    color: const Color(0xFF3B82F6),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              const Icon(
                Icons.check_circle,
                color: Color(0xFF3B82F6),
                size: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: isGenerating ? null : () => Navigator.of(context).pop(),
          child: Text(
            'إلغاء',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: ((isMonthlyReport ? selectedMonthData != null : selectedWeek != null) && !isGenerating) ? _generateReport : null,
          icon: isGenerating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download_outlined),
          label: Text(isGenerating ? 'جاري الإنشاء...' : 'تحميل التقرير'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const monthNames = [
      'يناير', 'فبراير', 'مارس', 'أبريل',
      'مايو', 'يونيو', 'يوليو', 'أغسطس',
      'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return monthNames[month - 1];
  }

  Future<void> _generateReport() async {
    if (isMonthlyReport) {
      if (selectedMonthData == null) return;
    } else {
      if (selectedWeek == null) return;
    }

    setState(() {
      isGenerating = true;
    });

    try {
      if (isMonthlyReport) {
        final startDate = selectedMonthData!['startDate'] as DateTime;
        final endDate = selectedMonthData!['endDate'] as DateTime;
        final monthLabel = selectedMonthData!['label'] as String;

        await _reportService.generateAndDownloadMonthlyReport(
          startDate: startDate,
          endDate: endDate,
          monthLabel: monthLabel,
          adminService: widget.adminService,
        );
      } else {
        final startDate = selectedWeek!['startDate'] as DateTime;
        final endDate = selectedWeek!['endDate'] as DateTime;
        final weekLabel = selectedWeek!['label'] as String;

        await _reportService.generateAndDownloadWeeklyReport(
          startDate: startDate,
          endDate: endDate,
          weekLabel: weekLabel,
          adminService: widget.adminService,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isMonthlyReport ? 'تم تحميل التقرير الشهري بنجاح' : 'تم تحميل التقرير الأسبوعي بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إنشاء التقرير: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isGenerating = false;
        });
      }
    }
  }
} 