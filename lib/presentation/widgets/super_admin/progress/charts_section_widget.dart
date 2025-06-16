import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../logic/blocs/super_admin/super_admin_state.dart';

class ChartsSectionWidget extends StatelessWidget {
  final SuperAdminLoaded state;

  const ChartsSectionWidget({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isExtraWide = constraints.maxWidth > 1600;
        final isWide = constraints.maxWidth > 1200;
        final isMedium = constraints.maxWidth > 800;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
         
            
            // Report Types Container
            _buildReportTypesContainer(context, isExtraWide, isWide, isMedium),
            const SizedBox(height: 24),
            
            // Report Sources Container
            _buildReportSourcesContainer(context, isExtraWide, isWide, isMedium),
            const SizedBox(height: 24),
            
            // Performance and Admin Distribution Container
            _buildPerformanceAdminContainer(context, isExtraWide, isWide, isMedium),
            const SizedBox(height: 24),
            
            // Maintenance Container
            _buildMaintenanceContainer(context),
          ],
        );
      },
    );
  }



  Widget _buildReportTypesContainer(BuildContext context, bool isExtraWide, bool isWide, bool isMedium) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.category_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تحليل أنواع البلاغات',
                      style: AppFonts.sectionTitle(isDark: isDark).copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'توزيع ومعدلات إنجاز البلاغات حسب النوع',
                      style: AppFonts.bodyText(isDark: isDark).copyWith(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Charts Grid
          if (isWide) ...[
            // Wide screens: side by side
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildReportTypesChart(context)),
                const SizedBox(width: 20),
                Expanded(child: _buildReportTypesCompletionChart(context)),
              ],
            ),
          ] else ...[
            // Medium and small screens: stacked
            _buildReportTypesChart(context),
            const SizedBox(height: 20),
            _buildReportTypesCompletionChart(context),
          ],
        ],
      ),
    );
  }

  Widget _buildReportSourcesContainer(BuildContext context, bool isExtraWide, bool isWide, bool isMedium) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.source_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تحليل مصادر البلاغات',
                      style: AppFonts.sectionTitle(isDark: isDark).copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'توزيع ومعدلات إنجاز البلاغات حسب المصدر',
                      style: AppFonts.bodyText(isDark: isDark).copyWith(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Charts Grid
          if (isWide) ...[
            // Wide screens: side by side
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildReportSourcesChart(context)),
                const SizedBox(width: 20),
                Expanded(child: _buildReportSourcesCompletionChart(context)),
              ],
            ),
          ] else ...[
            // Medium and small screens: stacked
            _buildReportSourcesChart(context),
            const SizedBox(height: 20),
            _buildReportSourcesCompletionChart(context),
          ],
        ],
      ),
    );
  }



  Widget _buildPerformanceAdminContainer(BuildContext context, bool isExtraWide, bool isWide, bool isMedium) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تحليل الأداء وتوزيع المسؤولين',
                      style: AppFonts.sectionTitle(isDark: isDark).copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'نظرة شاملة على الأداء العام وتوزيع المهام',
                      style: AppFonts.bodyText(isDark: isDark).copyWith(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Charts Grid
          if (isWide) ...[
            // Wide screens: side by side
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildPerformanceChart(context)),
                const SizedBox(width: 20),
                Expanded(child: _buildAdminReportsDistributionChart(context)),
              ],
            ),
          ] else ...[
            // Medium and small screens: stacked
            _buildPerformanceChart(context),
            const SizedBox(height: 20),
            _buildAdminReportsDistributionChart(context),
          ],
        ],
      ),
    );
  }

  Widget _buildMaintenanceContainer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.build_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تحليل الصيانة',
                      style: AppFonts.sectionTitle(isDark: isDark).copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'حالة وتوزيع أعمال الصيانة',
                      style: AppFonts.bodyText(isDark: isDark).copyWith(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildMaintenanceStatusChart(context)),
                    const SizedBox(width: 20),
                    Expanded(child: _buildAdminMaintenanceDistributionChart(context)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildMaintenanceStatusChart(context),
                    const SizedBox(height: 20),
                    _buildAdminMaintenanceDistributionChart(context),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final analytics = _calculateAnalytics(state);
    final pieData = _calculatePieChartData(analytics);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.speed_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تحليل الأداء العام',
                      style: AppFonts.sectionTitle(isDark: isDark).copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'نظرة شاملة على حالة النظام',
                      style: AppFonts.bodyText(isDark: isDark).copyWith(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 200,
                  child: analytics['totalReports'] > 0
                      ? PieChart(
                          PieChartData(
                            sections: pieData,
                            centerSpaceRadius: 50,
                            sectionsSpace: 2,
                            startDegreeOffset: -90,
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.speed_outlined,
                                size: 48,
                                color: isDark ? Colors.white30 : Colors.black26,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'لا توجد بيانات',
                                style:
                                    AppFonts.bodyText(isDark: isDark).copyWith(
                                  color:
                                      isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem('مكتملة', const Color(0xFF10B981), isDark),
                    const SizedBox(height: 8),
                    _buildLegendItem('قيد التنفيذ', const Color(0xFFF59E0B), isDark),
                    const SizedBox(height: 8),
                    _buildLegendItem('معلقة', const Color(0xFFEF4444), isDark),
                   
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '${analytics['totalReports']}',
                      style: AppFonts.cardTitle(isDark: isDark).copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF667EEA),
                      ),
                    ),
                    Text(
                      'إجمالي البلاغات',
                      style: AppFonts.bodyText(isDark: isDark).copyWith(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
                Column(
                  children: [
                    Text(
                      '${(analytics['completionRate'] * 100).toInt()}%',
                      style: AppFonts.cardTitle(isDark: isDark).copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    Text(
                      'معدل الإنجاز',
                      style: AppFonts.bodyText(isDark: isDark).copyWith(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTypesCompletionChart(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.task_alt_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'معدل الإنجاز حسب النوع',
                style: AppFonts.sectionTitle(isDark: isDark).copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200, // Match the pie chart height
            child: _buildCompletionRatesByType(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildReportSourcesCompletionChart(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.source_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'معدل الإنجاز حسب المصدر',
                style: AppFonts.sectionTitle(isDark: isDark).copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200, // Match the pie chart height
            child: _buildCompletionRatesBySource(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionRatesByType(bool isDark) {
    final completionRates = state.reportTypesCompletionRates;
    
    if (completionRates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt_outlined,
              size: 48,
              color: isDark ? Colors.white30 : Colors.black26,
            ),
            const SizedBox(height: 12),
            Text(
              'لا توجد بيانات',
              style: AppFonts.bodyText(isDark: isDark).copyWith(
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    final validEntries = completionRates.entries
        .where((entry) => entry.value['total'] > 0)
        .toList();

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in validEntries)
            _buildCompletionRateMetric(entry.key, entry.value, isDark),
        ],
      ),
    );
  }

  Widget _buildCompletionRateMetric(
      String type, Map<String, dynamic> typeData, bool isDark) {
    final rate = typeData['rate'] as double;
    final total = typeData['total'] as int;
    final completed = typeData['completed'] as int;
    final percentage = (rate * 100).toInt();
    final color = _getHealthColor(rate);

    // Translate type to Arabic
    String arabicType;
    switch (type) {
      case 'Civil':
        arabicType = 'مدني';
        break;
      case 'Plumbing':
        arabicType = 'سباكة';
        break;
      case 'Electricity':
        arabicType = 'كهرباء';
        break;
      case 'AC':
        arabicType = 'تكييف';
        break;
      case 'Fire':
        arabicType = 'حريق';
        break;
      default:
        arabicType = type;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
                arabicType,
              style: AppFonts.bodyText(isDark: isDark).copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
              Row(
                children: [
                  Text(
                    '$completed/$total',
                    style: AppFonts.bodyText(isDark: isDark).copyWith(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(width: 8),
            Text(
              '$percentage%',
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
                  ),
                ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
              widthFactor: rate,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildCompletionRatesBySource(bool isDark) {
    final completionRates = state.reportSourcesCompletionRates;
    
    if (completionRates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.source_outlined,
              size: 48,
              color: isDark ? Colors.white30 : Colors.black26,
            ),
            const SizedBox(height: 12),
            Text(
              'لا توجد بيانات',
              style: AppFonts.bodyText(isDark: isDark).copyWith(
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    final validEntries = completionRates.entries
        .where((entry) => entry.value['total'] > 0)
        .toList();

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in validEntries)
            _buildSourceCompletionRateMetric(entry.key, entry.value, isDark),
        ],
      ),
    );
  }

  Widget _buildSourceCompletionRateMetric(
      String source, Map<String, dynamic> sourceData, bool isDark) {
    final rate = sourceData['rate'] as double;
    final total = sourceData['total'] as int;
    final completed = sourceData['completed'] as int;
    final percentage = (rate * 100).toInt();
    final color = _getHealthColor(rate);

    // Translate source to Arabic
    String arabicSource;
    switch (source) {
      case 'unifier':
        arabicSource = 'يونيفاير';
        break;
      case 'check_list':
        arabicSource = 'تشيك ليست';
        break;
      case 'consultant':
        arabicSource = 'استشاري';
        break;
      default:
        arabicSource = source;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                arabicSource,
                style: AppFonts.bodyText(isDark: isDark).copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  Text(
                    '$completed/$total',
                    style: AppFonts.bodyText(isDark: isDark).copyWith(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
        Container(
            height: 8,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: rate,
              child: Container(
          decoration: BoxDecoration(
            color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTypesChart(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typesData = _calculateReportTypesData();
    final pieData = _calculateTypesPieChartData(typesData);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.category_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'أنواع البلاغات',
                      style: AppFonts.sectionTitle(isDark: isDark).copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'توزيع البلاغات حسب النوع',
                      style: AppFonts.bodyText(isDark: isDark).copyWith(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 200,
                  child: typesData['totalReports'] > 0
                      ? PieChart(
                          PieChartData(
                            sections: pieData,
                            centerSpaceRadius: 50,
                            sectionsSpace: 2,
                            startDegreeOffset: -90,
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.category_outlined,
                                size: 48,
                                color: isDark ? Colors.white30 : Colors.black26,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'لا توجد بيانات',
                                style:
                                    AppFonts.bodyText(isDark: isDark).copyWith(
                                  color:
                                      isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem('كهرباء', const Color(0xFFF59E0B), isDark),
                    const SizedBox(height: 8),
                    _buildLegendItem('سباكة', const Color(0xFF3B82F6), isDark),
                    const SizedBox(height: 8),
                    _buildLegendItem('تكييف', const Color(0xFF10B981), isDark),
                    const SizedBox(height: 8),
                    _buildLegendItem('مدني', const Color(0xFFEF4444), isDark),
                    const SizedBox(height: 8),
                    _buildLegendItem('حريق', const Color(0xFF8B5CF6), isDark),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '${typesData['totalReports']}',
                      style: AppFonts.cardTitle(isDark: isDark).copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF667EEA),
                      ),
                    ),
                    Text(
                      'إجمالي البلاغات',
                      style: AppFonts.bodyText(isDark: isDark).copyWith(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
                Column(
                  children: [
                    Text(
                      '${typesData['mostCommonType']['name']}',
                      style: AppFonts.cardTitle(isDark: isDark).copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF667EEA),
                      ),
                    ),
                    Text(
                      'النوع الأكثر شيوعاً',
                      style: AppFonts.bodyText(isDark: isDark).copyWith(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateReportTypesData() {
    final reportTypes = state.reportTypesStats;
    
    int totalReports = 0;
    String mostCommonTypeName = 'غير محدد';
    int mostCommonTypeCount = 0;

    // Calculate totals and find most common type
    for (final entry in reportTypes.entries) {
      final count = entry.value;
      totalReports += count;
      
      if (count > mostCommonTypeCount) {
        mostCommonTypeCount = count;
        // Translate to Arabic
        switch (entry.key) {
          case 'Civil':
            mostCommonTypeName = 'مدني';
            break;
          case 'Plumbing':
            mostCommonTypeName = 'سباكة';
            break;
          case 'Electricity':
            mostCommonTypeName = 'كهرباء';
            break;
          case 'AC':
            mostCommonTypeName = 'تكييف';
            break;
          case 'Fire':
            mostCommonTypeName = 'حريق';
            break;
          default:
            mostCommonTypeName = 'غير محدد';
        }
      }
    }

    return {
      'totalReports': totalReports,
      'reportTypes': reportTypes,
      'mostCommonType': {
        'name': mostCommonTypeName,
        'count': mostCommonTypeCount,
      },
    };
  }

  List<PieChartSectionData> _calculateTypesPieChartData(
      Map<String, dynamic> typesData) {
    final reportTypes = typesData['reportTypes'] as Map<String, int>;
    final totalReports = typesData['totalReports'] as int;

    if (totalReports == 0) {
      return [];
    }

    // Colors for each type
    final colors = {
      'Electricity': const Color(0xFFF59E0B), // Orange
      'Plumbing': const Color(0xFF3B82F6),    // Blue
      'AC': const Color(0xFF10B981),          // Green
      'Civil': const Color(0xFFEF4444),       // Red
      'Fire': const Color(0xFF8B5CF6),        // Purple
    };

    List<PieChartSectionData> sections = [];

    for (final entry in reportTypes.entries) {
      final type = entry.key;
      final count = entry.value;
      
      if (count > 0) {
        sections.add(
          PieChartSectionData(
            color: colors[type] ?? const Color(0xFF9CA3AF),
            value: count.toDouble(),
            title: count > 0 ? '$count' : '',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        );
      }
    }

    return sections;
  }

  Color _getHealthColor(double value) {
    if (value >= 0.8) return const Color(0xFF4ECDC4);
    if (value >= 0.6) return const Color(0xFF96CEB4);
    if (value >= 0.4) return const Color(0xFFFECEA8);
    return const Color(0xFFFF6B6B);
  }

  Map<String, dynamic> _calculateAnalytics(SuperAdminLoaded state) {
    int totalReports = 0;
    int completedReports = 0;
    int lateReports = 0;

    for (final stats in state.adminStats.values) {
      totalReports += (stats['reports'] as int? ?? 0);
      completedReports += (stats['completed_reports'] as int? ?? 0);
      lateReports += (stats['late_reports'] as int? ?? 0);
    }

    final completionRate =
        totalReports > 0 ? completedReports / totalReports : 0.0;

    return {
      'totalReports': totalReports,
      'completedReports': completedReports,
      'lateReports': lateReports,
      'completionRate': completionRate,
    };
  }

  List<PieChartSectionData> _calculatePieChartData(
      Map<String, dynamic> analytics) {
    final totalReports = analytics['totalReports'] as int;
    final completedReports = analytics['completedReports'] as int;
    final lateReports = analytics['lateReports'] as int;
    final inProgressReports = totalReports - completedReports - lateReports;

    return [
      PieChartSectionData(
        color: const Color(0xFF4ECDC4),
        value: completedReports.toDouble(),
        title: completedReports > 0 ? '$completedReports' : '',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: const Color(0xFF667EEA),
        value: inProgressReports.toDouble(),
        title: inProgressReports > 0 ? '$inProgressReports' : '',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: const Color(0xFFFF6B6B),
        value: lateReports.toDouble(),
        title: lateReports > 0 ? '$lateReports' : '',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    ];
  }

  Widget _buildLegendItem(String label, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppFonts.bodyText(isDark: isDark).copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color:
                isDark ? Colors.white70 : Colors.black.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildReportSourcesChart(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sourcesData = _calculateReportSourcesData();
    final pieData = _calculateSourcesPieChartData(sourcesData);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.source_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مصادر البلاغات',
                      style: AppFonts.sectionTitle(isDark: isDark).copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'توزيع البلاغات حسب المصدر',
                      style: AppFonts.bodyText(isDark: isDark).copyWith(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 200,
                  child: sourcesData['totalReports'] > 0
                      ? PieChart(
                          PieChartData(
                            sections: pieData,
                            centerSpaceRadius: 50,
                            sectionsSpace: 2,
                            startDegreeOffset: -90,
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.source_outlined,
                                size: 48,
                                color: isDark ? Colors.white30 : Colors.black26,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'لا توجد بيانات',
                                style:
                                    AppFonts.bodyText(isDark: isDark).copyWith(
                                  color:
                                      isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem('يونيفاير', const Color(0xFF8B5CF6), isDark),
                    const SizedBox(height: 8),
                    _buildLegendItem('تشيك ليست', const Color(0xFF06B6D4), isDark),
                    const SizedBox(height: 8),
                    _buildLegendItem('استشاري', const Color(0xFFEF4444), isDark),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '${sourcesData['totalReports']}',
                      style: AppFonts.cardTitle(isDark: isDark).copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF8B5CF6),
                      ),
                    ),
                    Text(
                      'إجمالي البلاغات',
                      style: AppFonts.bodyText(isDark: isDark).copyWith(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
                Column(
                  children: [
                    Text(
                      '${sourcesData['mostCommonSource']['name']}',
                      style: AppFonts.cardTitle(isDark: isDark).copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF8B5CF6),
                      ),
                    ),
                    Text(
                      'المصدر الأكثر شيوعاً',
                      style: AppFonts.bodyText(isDark: isDark).copyWith(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateReportSourcesData() {
    final reportSources = state.reportSourcesStats;
    
    int totalReports = 0;
    String mostCommonSourceName = 'غير محدد';
    int mostCommonSourceCount = 0;

    // Calculate totals and find most common source
    for (final entry in reportSources.entries) {
      final count = entry.value;
      totalReports += count;
      
      if (count > mostCommonSourceCount) {
        mostCommonSourceCount = count;
        // Translate to Arabic
        switch (entry.key) {
          case 'unifier':
            mostCommonSourceName = 'يونيفاير';
            break;
          case 'check_list':
            mostCommonSourceName = 'تشيك ليست';
            break;
          case 'consultant':
            mostCommonSourceName = 'استشاري';
            break;
          default:
            mostCommonSourceName = 'غير محدد';
        }
      }
    }

    return {
      'totalReports': totalReports,
      'reportSources': reportSources,
      'mostCommonSource': {
        'name': mostCommonSourceName,
        'count': mostCommonSourceCount,
      },
    };
  }

  List<PieChartSectionData> _calculateSourcesPieChartData(
      Map<String, dynamic> sourcesData) {
    final reportSources = sourcesData['reportSources'] as Map<String, int>;
    final totalReports = sourcesData['totalReports'] as int;

    if (totalReports == 0) {
      return [];
    }

    // Colors for each source
    final colors = {
      'unifier': const Color(0xFF8B5CF6), // Purple for unifier
      'check_list': const Color(0xFF06B6D4), // Cyan for check_list
      'consultant': const Color(0xFFEF4444), // Red for consultant
    };

    List<PieChartSectionData> sections = [];

    for (final entry in reportSources.entries) {
      final source = entry.key;
      final count = entry.value;
      
      if (count > 0) {
        sections.add(
          PieChartSectionData(
            color: colors[source] ?? const Color(0xFF9CA3AF),
            value: count.toDouble(),
            title: count > 0 ? '$count' : '',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        );
      }
    }

    return sections;
  }

  Widget _buildMaintenanceStatusChart(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maintenanceData = _calculateMaintenanceStatusData();
    final pieData = _calculateMaintenancePieChartData(maintenanceData);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.engineering_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'حالة الصيانات',
                      style: AppFonts.sectionTitle(isDark: isDark).copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'توزيع الصيانات حسب الحالة',
                      style: AppFonts.bodyText(isDark: isDark).copyWith(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 200,
                  child: maintenanceData['totalReports'] > 0
                      ? PieChart(
                          PieChartData(
                            sections: pieData,
                            centerSpaceRadius: 50,
                            sectionsSpace: 2,
                            startDegreeOffset: -90,
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.engineering_outlined,
                                size: 48,
                                color: isDark ? Colors.white30 : Colors.black26,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'لا توجد بيانات',
                                style:
                                    AppFonts.bodyText(isDark: isDark).copyWith(
                                  color:
                                      isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    _buildLegendItem('قيد التنفيذ', const Color(0xFF3B82F6), isDark),
                    const SizedBox(height: 8),
                    _buildLegendItem('مكتمل', const Color(0xFF10B981), isDark),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '${maintenanceData['totalReports']}',
                      style: AppFonts.cardTitle(isDark: isDark).copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                    Text(
                      'إجمالي بلاغات الصيانة',
                      style: AppFonts.bodyText(isDark: isDark).copyWith(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
                Column(
                  children: [
                    Text(
                      '${maintenanceData['mostCommonStatus']['name']}',
                      style: AppFonts.cardTitle(isDark: isDark).copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                    Text(
                      'الحالة الأكثر شيوعاً',
                      style: AppFonts.bodyText(isDark: isDark).copyWith(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateMaintenanceStatusData() {
    final maintenanceStatus = state.maintenanceStatusStats;
    
    int totalReports = 0;
    String mostCommonStatusName = 'غير محدد';
    int mostCommonStatusCount = 0;

    // Calculate totals and find most common status
    for (final entry in maintenanceStatus.entries) {
      final count = entry.value;
      totalReports += count;
      
      if (count > mostCommonStatusCount) {
        mostCommonStatusCount = count;
        // Translate to Arabic
        switch (entry.key) {
          case 'pending':
            mostCommonStatusName = 'قيد التنفيذ';
            break;
          
            
          case 'completed':
            mostCommonStatusName = 'مكتمل';
            break;
          default:
            mostCommonStatusName = 'غير محدد';
        }
      }
    }

    return {
      'totalReports': totalReports,
      'maintenanceStatus': maintenanceStatus,
      'mostCommonStatus': {
        'name': mostCommonStatusName,
        'count': mostCommonStatusCount,
      },
    };
  }

  List<PieChartSectionData> _calculateMaintenancePieChartData(
      Map<String, dynamic> maintenanceData) {
    final maintenanceStatus = maintenanceData['maintenanceStatus'] as Map<String, int>;
    final totalReports = maintenanceData['totalReports'] as int;

    if (totalReports == 0) {
      return [];
    }

    // Colors for each status
    final colors = {
      'pending': const Color(0xFF6B7280),    // Gray
      'in_progress': const Color(0xFF3B82F6), // Blue
      'completed': const Color(0xFF10B981),   // Green
    };

    List<PieChartSectionData> sections = [];

    for (final entry in maintenanceStatus.entries) {
      final status = entry.key;
      final count = entry.value;
      
      if (count > 0) {
        sections.add(
          PieChartSectionData(
            color: colors[status] ?? const Color(0xFF9CA3AF),
            value: count.toDouble(),
            title: count > 0 ? '$count' : '',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        );
      }
    }

    return sections;
  }

  Widget _buildAdminReportsDistributionChart(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final adminData = _calculateAdminReportsData();
    final pieData = _calculateAdminReportsPieChartData(adminData);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF047857)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'توزيع البلاغات على المسؤولين',
                      style: AppFonts.sectionTitle(isDark: isDark).copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'عدد البلاغات المخصصة لكل مدير',
                      style: AppFonts.bodyText(isDark: isDark).copyWith(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 200,
                  child: adminData['totalReports'] > 0
                      ? PieChart(
                          PieChartData(
                            sections: pieData,
                            centerSpaceRadius: 50,
                            sectionsSpace: 2,
                            startDegreeOffset: -90,
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.admin_panel_settings_outlined,
                                size: 48,
                                color: isDark ? Colors.white30 : Colors.black26,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'لا توجد بيانات',
                                style:
                                    AppFonts.bodyText(isDark: isDark).copyWith(
                                  color:
                                      isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: _buildAdminLegend(adminData['adminReportsDistribution'], isDark),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '${adminData['totalReports']}',
                      style: AppFonts.cardTitle(isDark: isDark).copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF059669),
                      ),
                    ),
                    Text(
                      'إجمالي البلاغات',
                      style: AppFonts.bodyText(isDark: isDark).copyWith(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
                Column(
                  children: [
                    Text(
                      '${adminData['topAdmin']['name']}',
                      style: AppFonts.cardTitle(isDark: isDark).copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF059669),
                      ),
                    ),
                    Text(
                      'أكثر المسؤولين بلاغات',
                      style: AppFonts.bodyText(isDark: isDark).copyWith(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateAdminReportsData() {
    final adminReports = state.adminReportsDistribution;
    
    int totalReports = 0;
    String topAdminName = 'غير محدد';
    int topAdminReports = 0;

    // Calculate totals and find top admin
    for (final entry in adminReports.entries) {
      final count = entry.value;
      totalReports += count;
      
      if (count > topAdminReports) {
        topAdminReports = count;
        topAdminName = entry.key;
      }
    }

    return {
      'totalReports': totalReports,
      'adminReportsDistribution': adminReports,
      'topAdmin': {
        'name': topAdminName,
        'count': topAdminReports,
      },
    };
  }

  List<PieChartSectionData> _calculateAdminReportsPieChartData(
      Map<String, dynamic> adminData) {
    final adminReports = adminData['adminReportsDistribution'] as Map<String, int>;
    final totalReports = adminData['totalReports'] as int;

    if (totalReports == 0) {
      return [];
    }

    // Colors for each admin - using a predefined set of colors
    final colorList = [
      const Color(0xFF059669), // Green
      const Color(0xFF3B82F6), // Blue
      const Color(0xFFEF4444), // Red
      const Color(0xFFF59E0B), // Orange
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF84CC16), // Lime
      const Color(0xFFEC4899), // Pink
    ];

    List<PieChartSectionData> sections = [];
    int colorIndex = 0;

    for (final entry in adminReports.entries) {
      final count = entry.value;
      
      if (count > 0) {
        sections.add(
          PieChartSectionData(
            color: colorList[colorIndex % colorList.length],
            value: count.toDouble(),
            title: count > 0 ? '$count' : '',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        );
        colorIndex++;
      }
    }

    return sections;
  }

  Widget _buildAdminLegend(Map<String, int> adminReportsDistribution, bool isDark) {
    final colorList = [
      const Color(0xFF059669), // Green
      const Color(0xFF3B82F6), // Blue
      const Color(0xFFEF4444), // Red
      const Color(0xFFF59E0B), // Orange
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF84CC16), // Lime
      const Color(0xFFEC4899), // Pink
    ];

    int colorIndex = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in adminReportsDistribution.entries)
          if (entry.value > 0)
            _buildLegendItem(
              entry.key, 
              colorList[colorIndex++ % colorList.length], 
              isDark
            ),
      ],
    );
  }

  Widget _buildAdminMaintenanceDistributionChart(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final adminData = _calculateAdminMaintenanceData();
    final pieData = _calculateAdminMaintenancePieChartData(adminData);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF047857)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'توزيع الصيانة على المسؤولين',
                      style: AppFonts.sectionTitle(isDark: isDark).copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'عدد الصيانة المخصصة لكل مدير',
                      style: AppFonts.bodyText(isDark: isDark).copyWith(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 200,
                  child: adminData['totalReports'] > 0
                      ? PieChart(
                          PieChartData(
                            sections: pieData,
                            centerSpaceRadius: 50,
                            sectionsSpace: 2,
                            startDegreeOffset: -90,
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.admin_panel_settings_outlined,
                                size: 48,
                                color: isDark ? Colors.white30 : Colors.black26,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'لا توجد بيانات',
                                style:
                                    AppFonts.bodyText(isDark: isDark).copyWith(
                                  color:
                                      isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: _buildAdminMaintenanceLegend(adminData['adminMaintenanceDistribution'], isDark),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '${adminData['totalReports']}',
                      style: AppFonts.cardTitle(isDark: isDark).copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF059669),
                      ),
                    ),
                    Text(
                      'إجمالي الصيانة',
                      style: AppFonts.bodyText(isDark: isDark).copyWith(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
                Column(
                  children: [
                    Text(
                      '${adminData['topAdmin']['name']}',
                      style: AppFonts.cardTitle(isDark: isDark).copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF059669),
                      ),
                    ),
                    Text(
                      'أكثر المسؤولين صيانة',
                      style: AppFonts.bodyText(isDark: isDark).copyWith(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateAdminMaintenanceData() {
    final adminMaintenance = state.adminMaintenanceDistribution;
    
    int totalReports = 0;
    String topAdminName = 'غير محدد';
    int topAdminReports = 0;

    // Calculate totals and find top admin
    for (final entry in adminMaintenance.entries) {
      final count = entry.value;
      totalReports += count;
      
      if (count > topAdminReports) {
        topAdminReports = count;
        topAdminName = entry.key;
      }
    }

    return {
      'totalReports': totalReports,
      'adminMaintenanceDistribution': adminMaintenance,
      'topAdmin': {
        'name': topAdminName,
        'count': topAdminReports,
      },
    };
  }

  List<PieChartSectionData> _calculateAdminMaintenancePieChartData(
      Map<String, dynamic> adminData) {
    final adminMaintenance = adminData['adminMaintenanceDistribution'] as Map<String, int>;
    final totalReports = adminData['totalReports'] as int;

    if (totalReports == 0) {
      return [];
    }

    // Colors for each admin - using a predefined set of colors
    final colorList = [
      const Color(0xFF059669), // Green
      const Color(0xFF3B82F6), // Blue
      const Color(0xFFEF4444), // Red
      const Color(0xFFF59E0B), // Orange
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF84CC16), // Lime
      const Color(0xFFEC4899), // Pink
    ];

    List<PieChartSectionData> sections = [];
    int colorIndex = 0;

    for (final entry in adminMaintenance.entries) {
      final count = entry.value;
      
      if (count > 0) {
        sections.add(
          PieChartSectionData(
            color: colorList[colorIndex % colorList.length],
            value: count.toDouble(),
            title: count > 0 ? '$count' : '',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        );
        colorIndex++;
      }
    }

    return sections;
  }

  Widget _buildAdminMaintenanceLegend(Map<String, int> adminMaintenanceDistribution, bool isDark) {
    final colorList = [
      const Color(0xFF059669), // Green
      const Color(0xFF3B82F6), // Blue
      const Color(0xFFEF4444), // Red
      const Color(0xFFF59E0B), // Orange
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF84CC16), // Lime
      const Color(0xFFEC4899), // Pink
    ];

    int colorIndex = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in adminMaintenanceDistribution.entries)
          if (entry.value > 0)
            _buildLegendItem(
              entry.key, 
              colorList[colorIndex++ % colorList.length], 
              isDark
            ),
      ],
    );
  }
}
