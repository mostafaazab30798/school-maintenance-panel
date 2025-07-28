import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/fci_assessment.dart';
import '../widgets/common/shared_app_bar.dart';
import 'package:flutter/foundation.dart'; // Added for kDebugMode

class FciAssessmentDetailsScreen extends StatefulWidget {
  final FciAssessment assessment;

  const FciAssessmentDetailsScreen({
    super.key,
    required this.assessment,
  });

  @override
  State<FciAssessmentDetailsScreen> createState() => _FciAssessmentDetailsScreenState();
}

class _FciAssessmentDetailsScreenState extends State<FciAssessmentDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Debug: Log assessment details to help identify issues
    if (kDebugMode) {
      print('🔍 FciAssessmentDetailsScreen: Initializing with assessment');
      widget.assessment.debugPrint();
    }
    
    // Validate assessment data
    if (!widget.assessment.isValid) {
      print('⚠️ Warning: Invalid FCI assessment data');
      // You could show an error dialog here if needed
    }
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    BuildingState buildingState;
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    try {
      buildingState = widget.assessment.calculateBuildingState();
    } catch (e) {
      print('❌ Error calculating building state: $e');
      // Return a simple error screen
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: SharedAppBar(
            title: 'خطأ في التقييم',
          ),
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                SizedBox(height: 16),
                Text(
                  'حدث خطأ في تحميل بيانات التقييم',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 8),
                Text(
                  'يرجى المحاولة مرة أخرى',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: SharedAppBar(
          title: widget.assessment.schoolName,
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, buildingState, isDark),
                const SizedBox(height: 16),
                _buildOverallScore(context, buildingState, isDark),
                const SizedBox(height: 16),
                _buildStatusGrid(context, buildingState, isDark),
                const SizedBox(height: 16),
                _buildCategoriesList(context, buildingState, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, BuildingState buildingState, bool isDark) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.assessment_outlined,
                  color: buildingState.overallConditionColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'تقييم حالة المبنى',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                _buildStatusChip(widget.assessment.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(widget.assessment.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'المشرف: ${widget.assessment.supervisorName.isNotEmpty ? widget.assessment.supervisorName : 'غير محدد'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final isSubmitted = status == 'submitted';
    final color = isSubmitted ? Colors.green : const Color(0xFF26A69A);
    final text = isSubmitted ? 'مقدم' : 'مسودة';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildOverallScore(BuildContext context, BuildingState buildingState, bool isDark) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'الحالة العامة',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: buildingState.overallConditionColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    buildingState.overallCondition,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildScoreItem(
                    'النسبة المئوية',
                    '${buildingState.overallPercentage.toStringAsFixed(1)}%',
                    buildingState.overallConditionColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildScoreItem(
                    'إجمالي العناصر',
                    buildingState.totalItems.toString(),
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusGrid(BuildContext context, BuildingState buildingState, bool isDark) {
    final statusItems = [
      ('جيد', buildingState.goodItems, Colors.green),
      ('مناسب', buildingState.acceptableItems, const Color(0xFF26A69A)),
      ('ضعيف', buildingState.poorItems, Colors.deepOrange),
      ('حرج', buildingState.criticalItems, Colors.red),
      ('تالف/غير موجود', buildingState.damagedItems, const Color(0xFF7F0000)),
    ];

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'توزيع حالة العناصر',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: statusItems.map((item) => _buildStatusChipItem(
                item.$1,
                item.$2,
                item.$3,
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChipItem(String status, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList(BuildContext context, BuildingState buildingState, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تفاصيل الفئات',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...FCICategories.categoryWeights.entries.map((entry) {
          String categoryKey = entry.key;
          double categoryWeight = entry.value;
          
          if (!widget.assessment.categoryAssessments.containsKey(categoryKey)) {
            return const SizedBox.shrink();
          }
          
          CategoryScore? categoryScore = buildingState.categoryScores[categoryKey];
          if (categoryScore == null) return const SizedBox.shrink();
          
          return _buildCategoryCard(
            context,
            categoryKey,
            categoryWeight,
            categoryScore,
            buildingState,
            isDark,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String categoryKey,
    double categoryWeight,
    CategoryScore categoryScore,
    BuildingState buildingState,
    bool isDark,
  ) {
    String categoryName = FCICategories.categoryNames[categoryKey] ?? categoryKey;
    String condition = buildingState.getCategoryCondition(categoryKey);
    Color conditionColor = buildingState.getCategoryConditionColor(categoryKey);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(
          _getCategoryIcon(categoryKey),
          color: conditionColor,
          size: 20,
        ),
        title: Text(
          categoryName,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              '${categoryScore.percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                color: conditionColor,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: conditionColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                condition,
                style: TextStyle(
                  color: conditionColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: categoryScore.itemScores.entries.map((entry) {
                String itemKey = entry.key;
                ItemScore itemScore = entry.value;
                String itemName = FCICategories.allCategories[categoryKey]?[itemKey] ?? itemKey;
                
                return _buildItemRow(
                  context,
                  itemName,
                  itemScore.status,
                  itemScore.percentage,
                  itemScore.weight,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(
    BuildContext context,
    String itemName,
    String status,
    double percentage,
    double weight,
  ) {
    Color statusColor = FCICategories.statusColors[status] ?? Colors.grey;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(status),
            color: statusColor,
            size: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              itemName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'جيد':
        return Icons.check_circle;
      case 'مناسب':
        return Icons.thumb_up;
      case 'ضعيف':
        return Icons.warning;
      case 'حرج':
        return Icons.error;
      case 'تالف':
      case 'غير موجود':
        return Icons.block;
      default:
        return Icons.help;
    }
  }

  IconData _getCategoryIcon(String categoryKey) {
    switch (categoryKey) {
      case 'foundations':
        return Icons.foundation;
      case 'structural':
        return Icons.architecture;
      case 'walls':
        return Icons.wallpaper;
      case 'tiles_floors':
        return Icons.grid_on;
      case 'woodwork':
        return Icons.door_front_door;
      case 'aluminum':
        return Icons.view_in_ar;
      case 'ironwork':
        return Icons.hardware;
      case 'plastering':
        return Icons.texture;
      case 'paintings':
        return Icons.palette;
      case 'insulation':
        return Icons.thermostat;
      case 'site_floors':
        return Icons.landscape;
      case 'suspended_ceilings':
        return Icons.lightbulb;
      case 'shades':
        return Icons.umbrella;
      case 'fire_fighting':
        return Icons.local_fire_department;
      case 'plumbing':
        return Icons.plumbing;
      case 'hvac':
        return Icons.ac_unit;
      case 'electrical':
        return Icons.electrical_services;
      case 'low_voltage':
        return Icons.sensors;
      case 'elevators':
        return Icons.elevator;
      default:
        return Icons.category;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 