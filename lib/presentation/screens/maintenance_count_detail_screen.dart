import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/maintenance_count_repository.dart';
import '../../data/models/maintenance_count.dart';
import '../widgets/common/shared_app_bar.dart';
import '../widgets/common/error_widget.dart';
import 'maintenance_count_category_screen.dart';

class MaintenanceCountDetailScreen extends StatefulWidget {
  final String schoolId;
  final String schoolName;

  const MaintenanceCountDetailScreen({
    super.key,
    required this.schoolId,
    required this.schoolName,
  });

  @override
  State<MaintenanceCountDetailScreen> createState() =>
      _MaintenanceCountDetailScreenState();
}

class _MaintenanceCountDetailScreenState
    extends State<MaintenanceCountDetailScreen> with TickerProviderStateMixin {
  final MaintenanceCountRepository _repository =
      MaintenanceCountRepository(Supabase.instance.client);
  List<MaintenanceCount> _maintenanceCounts = [];
  bool _isLoading = true;
  String? _error;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _loadMaintenanceCounts();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadMaintenanceCounts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final counts = await _repository.getMaintenanceCounts(
        schoolId: widget.schoolId,
      );
      setState(() {
        _maintenanceCounts = counts;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        appBar: SharedAppBar(
          title: 'تفاصيل حصر ${widget.schoolName}',
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return Center(
        child: AppErrorWidget(
          message: _error!,
          onRetry: _loadMaintenanceCounts,
        ),
      );
    }

    if (_maintenanceCounts.isEmpty) {
      return _buildEmptyState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _loadMaintenanceCounts,
        color: const Color(0xFF3B82F6),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: CustomScrollView(
          slivers: [
            // Maintenance Records List
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final count = _maintenanceCounts[index];
                    return _buildMaintenanceCountCard(count, index);
                  },
                  childCount: _maintenanceCounts.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'جارٍ تحميل بيانات الحصر...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF3B82F6).withOpacity(0.1),
                    const Color(0xFF1D4ED8).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.inventory_2_rounded,
                size: 80,
                color: Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'لا توجد بيانات حصر',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد بيانات حصر صيانة لهذه المدرسة حتى الآن',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceCountCard(MaintenanceCount count, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor(count.status);

    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutBack,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.08),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStatusIndicator(count.status, statusColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'حصر رقم ${count.id.substring(0, 8)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: isDark
                                ? Colors.grey[400]
                                : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatDate(count.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.grey[400]
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getStatusText(count.status),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Category Grid
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildCategoryGrid(count),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String status, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Icon(
        _getStatusIcon(status),
        color: color,
        size: 20,
      ),
    );
  }

  Widget _buildCategoryGrid(MaintenanceCount count) {
    final categories = [
      {
        'title': 'أمن وسلامة',
        'icon': Icons.security_rounded,
        'color': const Color(0xFFEF4444),
        'category': 'safety',
        'itemCount': _getSafetyItemsCount(count),
      },
      {
        'title': 'ميكانيكا',
        'icon': Icons.precision_manufacturing_rounded,
        'color': const Color(0xFF10B981),
        'category': 'mechanical',
        'itemCount': _getMechanicalItemsCount(count),
      },
      {
        'title': 'كهرباء',
        'icon': Icons.electrical_services_rounded,
        'color': const Color(0xFFF59E0B),
        'category': 'electrical',
        'itemCount': _getElectricalItemsCount(count),
      },
      {
        'title': 'مدني',
        'icon': Icons.business_rounded,
        'color': const Color(0xFF8B5CF6),
        'category': 'civil',
        'itemCount': _getCivilItemsCount(count),
      },
    ];

    return SizedBox(
      height: 70,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: categories.asMap().entries.map((entry) {
          final index = entry.key;
          final category = entry.value;
          return Expanded(
            flex: 1,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: _buildCategoryCard(category, count, index),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryCard(
      Map<String, dynamic> category, MaintenanceCount count, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = category['color'] as Color;

    return AnimatedContainer(
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutBack,
      height: 70,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    MaintenanceCountCategoryScreen(
                  count: count,
                  category: category['category'],
                  categoryTitle: category['title'],
                  categoryIcon: category['icon'],
                  categoryColor: color,
                  schoolName: widget.schoolName,
                ),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    category['icon'],
                    color: color,
                    size: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    category['title'],
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${category['itemCount']}',
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget _buildSafetySecurityCategory(MaintenanceCount count) {
  //   final isDark = Theme.of(context).brightness == Brightness.dark;
  //   final safetyColor = const Color(0xFFEF4444);

  //   // Extract safety-related data
  //   final safetyItems = _getSafetyItems(count);
  //   final safetyAnswers = _getSafetyAnswers(count);
  //   final safetyPhotos = _getSafetyPhotos(count);
  //   final safetyNotes = _getSafetyNotes(count);

  //   return SingleChildScrollView(
  //     padding: const EdgeInsets.all(16),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         _buildCategoryHeader(
  //             'أمن وسلامة', Icons.security_rounded, safetyColor),
  //         const SizedBox(height: 20),
  //         if (safetyItems.isNotEmpty) ...[
  //           _buildModernDataSection('المعدات والأجهزة', Icons.inventory_rounded,
  //               safetyColor, safetyItems),
  //           const SizedBox(height: 16),
  //         ],
  //         if (safetyAnswers.isNotEmpty) ...[
  //           _buildModernConditionSection('حالة الأنظمة',
  //               Icons.health_and_safety_rounded, safetyColor, safetyAnswers),
  //           const SizedBox(height: 16),
  //         ],
  //         if (safetyPhotos.isNotEmpty) ...[
  //           _buildModernPhotosSection('صور الأمن والسلامة',
  //               Icons.photo_camera_rounded, safetyColor, safetyPhotos),
  //           const SizedBox(height: 16),
  //         ],
  //         if (safetyNotes.isNotEmpty) ...[
  //           _buildModernNotesSection('ملاحظات الأمن والسلامة',
  //               Icons.note_alt_rounded, safetyColor, safetyNotes),
  //         ],
  //         if (safetyItems.isEmpty &&
  //             safetyAnswers.isEmpty &&
  //             safetyPhotos.isEmpty &&
  //             safetyNotes.isEmpty)
  //           _buildEmptyCategory(
  //               'أمن وسلامة', Icons.security_rounded, safetyColor),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildMechanicalCategory(MaintenanceCount count) {
  //   final mechanicalColor = const Color(0xFF10B981);

  //   // Extract mechanical-related data
  //   final mechanicalItems = _getMechanicalItems(count);
  //   final mechanicalAnswers = _getMechanicalAnswers(count);
  //   final mechanicalPhotos = _getMechanicalPhotos(count);
  //   final mechanicalNotes = _getMechanicalNotes(count);

  //   return SingleChildScrollView(
  //     padding: const EdgeInsets.all(16),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         _buildCategoryHeader('ميكانيكا',
  //             Icons.precision_manufacturing_rounded, mechanicalColor),
  //         const SizedBox(height: 20),
  //         if (mechanicalItems.isNotEmpty) ...[
  //           _buildModernDataSection('المضخات والمعدات',
  //               Icons.water_damage_rounded, mechanicalColor, mechanicalItems),
  //           const SizedBox(height: 16),
  //         ],
  //         if (mechanicalAnswers.isNotEmpty) ...[
  //           _buildModernConditionSection('حالة المعدات الميكانيكية',
  //               Icons.settings_rounded, mechanicalColor, mechanicalAnswers),
  //           const SizedBox(height: 16),
  //         ],
  //         if (mechanicalPhotos.isNotEmpty) ...[
  //           _buildModernPhotosSection('صور الميكانيكا',
  //               Icons.photo_camera_rounded, mechanicalColor, mechanicalPhotos),
  //           const SizedBox(height: 16),
  //         ],
  //         if (mechanicalNotes.isNotEmpty) ...[
  //           _buildModernNotesSection('ملاحظات الميكانيكا',
  //               Icons.note_alt_rounded, mechanicalColor, mechanicalNotes),
  //         ],
  //         if (mechanicalItems.isEmpty &&
  //             mechanicalAnswers.isEmpty &&
  //             mechanicalPhotos.isEmpty &&
  //             mechanicalNotes.isEmpty)
  //           _buildEmptyCategory('ميكانيكا',
  //               Icons.precision_manufacturing_rounded, mechanicalColor),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildElectricalCategory(MaintenanceCount count) {
  //   final electricalColor = const Color(0xFFF59E0B);

  //   // Extract electrical-related data
  //   final electricalItems = _getElectricalItems(count);
  //   final electricalAnswers = _getElectricalAnswers(count);
  //   final electricalPhotos = _getElectricalPhotos(count);
  //   final electricalNotes = _getElectricalNotes(count);

  //   return SingleChildScrollView(
  //     padding: const EdgeInsets.all(16),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         _buildCategoryHeader(
  //             'كهرباء', Icons.electrical_services_rounded, electricalColor),
  //         const SizedBox(height: 20),
  //         if (electricalItems.isNotEmpty) ...[
  //           _buildModernDataSection(
  //               'الأنظمة الكهربائية',
  //               Icons.electrical_services_rounded,
  //               electricalColor,
  //               electricalItems),
  //           const SizedBox(height: 16),
  //         ],
  //         if (electricalAnswers.isNotEmpty) ...[
  //           _buildModernConditionSection('حالة الأنظمة الكهربائية',
  //               Icons.power_rounded, electricalColor, electricalAnswers),
  //           const SizedBox(height: 16),
  //         ],
  //         if (electricalPhotos.isNotEmpty) ...[
  //           _buildModernPhotosSection('صور الكهرباء',
  //               Icons.photo_camera_rounded, electricalColor, electricalPhotos),
  //           const SizedBox(height: 16),
  //         ],
  //         if (electricalNotes.isNotEmpty) ...[
  //           _buildModernNotesSection('ملاحظات الكهرباء', Icons.note_alt_rounded,
  //               electricalColor, electricalNotes),
  //         ],
  //         if (electricalItems.isEmpty &&
  //             electricalAnswers.isEmpty &&
  //             electricalPhotos.isEmpty &&
  //             electricalNotes.isEmpty)
  //           _buildEmptyCategory(
  //               'كهرباء', Icons.electrical_services_rounded, electricalColor),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildCivilCategory(MaintenanceCount count) {
  //   final civilColor = const Color(0xFF8B5CF6);

  //   // Extract civil-related data
  //   final civilItems = _getCivilItems(count);
  //   final civilAnswers = _getCivilAnswers(count);
  //   final civilPhotos = _getCivilPhotos(count);
  //   final civilNotes = _getCivilNotes(count);

  //   return SingleChildScrollView(
  //     padding: const EdgeInsets.all(16),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         _buildCategoryHeader('مدني', Icons.business_rounded, civilColor),
  //         const SizedBox(height: 20),
  //         if (civilItems.isNotEmpty) ...[
  //           _buildModernDataSection('البنية التحتية', Icons.foundation_rounded,
  //               civilColor, civilItems),
  //           const SizedBox(height: 16),
  //         ],
  //         if (civilAnswers.isNotEmpty) ...[
  //           _buildModernConditionSection('حالة البناء', Icons.apartment_rounded,
  //               civilColor, civilAnswers),
  //           const SizedBox(height: 16),
  //         ],
  //         if (civilPhotos.isNotEmpty) ...[
  //           _buildModernPhotosSection('صور المدني', Icons.photo_camera_rounded,
  //               civilColor, civilPhotos),
  //           const SizedBox(height: 16),
  //         ],
  //         if (civilNotes.isNotEmpty) ...[
  //           _buildModernNotesSection('ملاحظات المدني', Icons.note_alt_rounded,
  //               civilColor, civilNotes),
  //         ],
  //         if (civilItems.isEmpty &&
  //             civilAnswers.isEmpty &&
  //             civilPhotos.isEmpty &&
  //             civilNotes.isEmpty)
  //           _buildEmptyCategory('مدني', Icons.business_rounded, civilColor),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildSurveyAnswers(Map<String, String> surveyAnswers) {
  //   final isDark = Theme.of(context).brightness == Brightness.dark;

  //   return Column(
  //     children: surveyAnswers.entries.map((entry) {
  //       final color = _getConditionColor(entry.value);
  //       return AnimatedContainer(
  //         duration: const Duration(milliseconds: 300),
  //         margin: const EdgeInsets.only(bottom: 12),
  //         padding: const EdgeInsets.all(16),
  //         decoration: BoxDecoration(
  //           gradient: LinearGradient(
  //             colors: [
  //               color.withOpacity(0.08),
  //               color.withOpacity(0.03),
  //             ],
  //             begin: Alignment.centerLeft,
  //             end: Alignment.centerRight,
  //           ),
  //           borderRadius: BorderRadius.circular(12),
  //           border: Border.all(color: color.withOpacity(0.3), width: 1),
  //           boxShadow: [
  //             BoxShadow(
  //               color: color.withOpacity(0.1),
  //               blurRadius: 8,
  //               spreadRadius: 0,
  //               offset: const Offset(0, 2),
  //             ),
  //           ],
  //         ),
  //         child: Row(
  //           children: [
  //             Container(
  //               padding: const EdgeInsets.all(6),
  //               decoration: BoxDecoration(
  //                 color: color.withOpacity(0.15),
  //                 borderRadius: BorderRadius.circular(8),
  //               ),
  //               child: Icon(
  //                 _getConditionIcon(entry.value),
  //                 color: color,
  //                 size: 16,
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               child: Text(
  //                 _translateItemName(entry.key),
  //                 style: TextStyle(
  //                   fontSize: 14,
  //                   fontWeight: FontWeight.w600,
  //                   color: isDark ? Colors.grey[300] : const Color(0xFF475569),
  //                 ),
  //               ),
  //             ),
  //             Container(
  //               padding:
  //                   const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  //               decoration: BoxDecoration(
  //                 color: color,
  //                 borderRadius: BorderRadius.circular(16),
  //                 boxShadow: [
  //                   BoxShadow(
  //                     color: color.withOpacity(0.3),
  //                     blurRadius: 4,
  //                     spreadRadius: 0,
  //                     offset: const Offset(0, 2),
  //                   ),
  //                 ],
  //               ),
  //               child: Text(
  //                 entry.value,
  //                 style: const TextStyle(
  //                   fontSize: 12,
  //                   fontWeight: FontWeight.w700,
  //                   color: Colors.white,
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       );
  //     }).toList(),
  //   );
  // }

  // Widget _buildYesNoAnswers(Map<String, bool> yesNoAnswers) {
  //   final isDark = Theme.of(context).brightness == Brightness.dark;

  //   return Column(
  //     children: yesNoAnswers.entries.map((entry) {
  //       final color =
  //           entry.value ? const Color(0xFFEF4444) : const Color(0xFF10B981);
  //       final icon =
  //           entry.value ? Icons.warning_rounded : Icons.check_circle_rounded;
  //       final text = entry.value ? 'نعم' : 'لا';

  //       return AnimatedContainer(
  //         duration: const Duration(milliseconds: 300),
  //         margin: const EdgeInsets.only(bottom: 12),
  //         padding: const EdgeInsets.all(16),
  //         decoration: BoxDecoration(
  //           gradient: LinearGradient(
  //             colors: [
  //               color.withOpacity(0.08),
  //               color.withOpacity(0.03),
  //             ],
  //             begin: Alignment.centerLeft,
  //             end: Alignment.centerRight,
  //           ),
  //           borderRadius: BorderRadius.circular(12),
  //           border: Border.all(color: color.withOpacity(0.3), width: 1),
  //           boxShadow: [
  //             BoxShadow(
  //               color: color.withOpacity(0.1),
  //               blurRadius: 8,
  //               spreadRadius: 0,
  //               offset: const Offset(0, 2),
  //             ),
  //           ],
  //         ),
  //         child: Row(
  //           children: [
  //             Container(
  //               padding: const EdgeInsets.all(8),
  //               decoration: BoxDecoration(
  //                 color: color.withOpacity(0.15),
  //                 borderRadius: BorderRadius.circular(10),
  //               ),
  //               child: Icon(icon, color: color, size: 20),
  //             ),
  //             const SizedBox(width: 16),
  //             Expanded(
  //               child: Text(
  //                 _translateItemName(entry.key),
  //                 style: TextStyle(
  //                   fontSize: 14,
  //                   fontWeight: FontWeight.w600,
  //                   color: isDark ? Colors.grey[300] : const Color(0xFF475569),
  //                 ),
  //               ),
  //             ),
  //             Container(
  //               padding:
  //                   const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  //               decoration: BoxDecoration(
  //                 color: color,
  //                 borderRadius: BorderRadius.circular(16),
  //                 boxShadow: [
  //                   BoxShadow(
  //                     color: color.withOpacity(0.3),
  //                     blurRadius: 4,
  //                     spreadRadius: 0,
  //                     offset: const Offset(0, 2),
  //                   ),
  //                 ],
  //               ),
  //               child: Text(
  //                 text,
  //                 style: const TextStyle(
  //                   fontSize: 12,
  //                   fontWeight: FontWeight.w700,
  //                   color: Colors.white,
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       );
  //     }).toList(),
  //   );
  // }

  // Widget _buildTextAnswers(Map<String, String> textAnswers) {
  //   return Column(
  //     children: textAnswers.entries.map((entry) {
  //       return Container(
  //         margin: const EdgeInsets.only(bottom: 8),
  //         padding: const EdgeInsets.all(12),
  //         decoration: BoxDecoration(
  //           color: const Color(0xFF8B5CF6).withOpacity(0.05),
  //           borderRadius: BorderRadius.circular(8),
  //           border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.2)),
  //         ),
  //         child: Row(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Expanded(
  //               flex: 2,
  //               child: Text(
  //                 _translateItemName(entry.key),
  //                 style: TextStyle(
  //                   fontSize: 14,
  //                   fontWeight: FontWeight.w500,
  //                   color: Theme.of(context).brightness == Brightness.dark
  //                       ? Colors.grey[300]
  //                       : const Color(0xFF64748B),
  //                 ),
  //               ),
  //             ),
  //             const SizedBox(width: 8),
  //             Expanded(
  //               flex: 1,
  //               child: Text(
  //                 entry.value,
  //                 style: TextStyle(
  //                   fontSize: 14,
  //                   color: Theme.of(context).brightness == Brightness.dark
  //                       ? Colors.white
  //                       : const Color(0xFF1E293B),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       );
  //     }).toList(),
  //   );
  // }

  // Widget _buildFireSafetyData(Map<String, String> fireSafetyData) {
  //   return Column(
  //     children: fireSafetyData.entries.map((entry) {
  //       return Container(
  //         margin: const EdgeInsets.only(bottom: 8),
  //         padding: const EdgeInsets.all(12),
  //         decoration: BoxDecoration(
  //           color: const Color(0xFFEF4444).withOpacity(0.05),
  //           borderRadius: BorderRadius.circular(8),
  //           border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
  //         ),
  //         child: Row(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Expanded(
  //               flex: 2,
  //               child: Text(
  //                 _translateItemName(entry.key),
  //                 style: TextStyle(
  //                   fontSize: 14,
  //                   fontWeight: FontWeight.w500,
  //                   color: Theme.of(context).brightness == Brightness.dark
  //                       ? Colors.grey[300]
  //                       : const Color(0xFF64748B),
  //                 ),
  //               ),
  //             ),
  //             const SizedBox(width: 8),
  //             Expanded(
  //               flex: 1,
  //               child: Text(
  //                 entry.value,
  //                 style: TextStyle(
  //                   fontSize: 14,
  //                   color: Theme.of(context).brightness == Brightness.dark
  //                       ? Colors.white
  //                       : const Color(0xFF1E293B),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       );
  //     }).toList(),
  //   );
  // }

  // Widget _buildPhotosSection(Map<String, List<String>> sectionPhotos) {
  //   final isDark = Theme.of(context).brightness == Brightness.dark;

  //   return Column(
  //     children: sectionPhotos.entries.map((entry) {
  //       if (entry.value.isEmpty) return const SizedBox.shrink();

  //       return Container(
  //         margin: const EdgeInsets.only(bottom: 20),
  //         padding: const EdgeInsets.all(16),
  //         decoration: BoxDecoration(
  //           gradient: LinearGradient(
  //             colors: [
  //               const Color(0xFF06B6D4).withOpacity(0.08),
  //               const Color(0xFF0891B2).withOpacity(0.03),
  //             ],
  //             begin: Alignment.topLeft,
  //             end: Alignment.bottomRight,
  //           ),
  //           borderRadius: BorderRadius.circular(16),
  //           border: Border.all(
  //             color: const Color(0xFF06B6D4).withOpacity(0.2),
  //           ),
  //         ),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Row(
  //               children: [
  //                 Container(
  //                   padding: const EdgeInsets.all(8),
  //                   decoration: BoxDecoration(
  //                     color: const Color(0xFF06B6D4).withOpacity(0.15),
  //                     borderRadius: BorderRadius.circular(10),
  //                   ),
  //                   child: const Icon(
  //                     Icons.photo_library_rounded,
  //                     color: Color(0xFF06B6D4),
  //                     size: 18,
  //                   ),
  //                 ),
  //                 const SizedBox(width: 12),
  //                 Expanded(
  //                   child: Text(
  //                     _translateSectionName(entry.key),
  //                     style: TextStyle(
  //                       fontSize: 16,
  //                       fontWeight: FontWeight.w700,
  //                       color: isDark ? Colors.white : const Color(0xFF1E293B),
  //                     ),
  //                   ),
  //                 ),
  //                 Container(
  //                   padding:
  //                       const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //                   decoration: BoxDecoration(
  //                     color: const Color(0xFF06B6D4),
  //                     borderRadius: BorderRadius.circular(12),
  //                   ),
  //                   child: Text(
  //                     '${entry.value.length}',
  //                     style: const TextStyle(
  //                       fontSize: 12,
  //                       fontWeight: FontWeight.w700,
  //                       color: Colors.white,
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             const SizedBox(height: 16),
  //             SizedBox(
  //               height: 100,
  //               child: ListView.builder(
  //                 scrollDirection: Axis.horizontal,
  //                 itemCount: entry.value.length,
  //                 itemBuilder: (context, index) {
  //                   return Container(
  //                     margin: const EdgeInsets.only(right: 12),
  //                     width: 100,
  //                     height: 100,
  //                     decoration: BoxDecoration(
  //                       borderRadius: BorderRadius.circular(12),
  //                       border: Border.all(
  //                         color: const Color(0xFF06B6D4).withOpacity(0.3),
  //                         width: 2,
  //                       ),
  //                       boxShadow: [
  //                         BoxShadow(
  //                           color: const Color(0xFF06B6D4).withOpacity(0.2),
  //                           blurRadius: 8,
  //                           spreadRadius: 0,
  //                           offset: const Offset(0, 4),
  //                         ),
  //                       ],
  //                     ),
  //                     child: ClipRRect(
  //                       borderRadius: BorderRadius.circular(10),
  //                       child: Image.network(
  //                         entry.value[index],
  //                         fit: BoxFit.cover,
  //                         loadingBuilder: (context, child, loadingProgress) {
  //                           if (loadingProgress == null) return child;
  //                           return Container(
  //                             color: isDark
  //                                 ? const Color(0xFF1E293B)
  //                                 : Colors.grey[100],
  //                             child: const Center(
  //                               child: CircularProgressIndicator(
  //                                 strokeWidth: 2,
  //                                 color: Color(0xFF06B6D4),
  //                               ),
  //                             ),
  //                           );
  //                         },
  //                         errorBuilder: (context, error, stackTrace) {
  //                           return Container(
  //                             color: isDark
  //                                 ? const Color(0xFF1E293B)
  //                                 : Colors.grey[100],
  //                             child: const Icon(
  //                               Icons.error_outline_rounded,
  //                               color: Color(0xFF06B6D4),
  //                               size: 24,
  //                             ),
  //                           );
  //                         },
  //                       ),
  //                     ),
  //                   );
  //                 },
  //               ),
  //             ),
  //           ],
  //         ),
  //       );
  //     }).toList(),
  //   );
  // }

  // Widget _buildMaintenanceNotes(Map<String, String> maintenanceNotes) {
  //   final isDark = Theme.of(context).brightness == Brightness.dark;
  //   final notesWithContent = maintenanceNotes.entries
  //       .where((entry) => entry.value.isNotEmpty)
  //       .toList();

  //   if (notesWithContent.isEmpty) {
  //     return Container(
  //       padding: const EdgeInsets.all(20),
  //       decoration: BoxDecoration(
  //         gradient: LinearGradient(
  //           colors: [
  //             const Color(0xFF84CC16).withOpacity(0.05),
  //             const Color(0xFF65A30D).withOpacity(0.02),
  //           ],
  //           begin: Alignment.topLeft,
  //           end: Alignment.bottomRight,
  //         ),
  //         borderRadius: BorderRadius.circular(12),
  //         border: Border.all(
  //           color: const Color(0xFF84CC16).withOpacity(0.2),
  //         ),
  //       ),
  //       child: Row(
  //         children: [
  //           Container(
  //             padding: const EdgeInsets.all(8),
  //             decoration: BoxDecoration(
  //               color: const Color(0xFF84CC16).withOpacity(0.15),
  //               borderRadius: BorderRadius.circular(10),
  //             ),
  //             child: const Icon(
  //               Icons.note_outlined,
  //               color: Color(0xFF84CC16),
  //               size: 18,
  //             ),
  //           ),
  //           const SizedBox(width: 12),
  //           Text(
  //             'لا توجد ملاحظات',
  //             style: TextStyle(
  //               fontSize: 14,
  //               fontWeight: FontWeight.w600,
  //               color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
  //             ),
  //           ),
  //         ],
  //       ),
  //     );
  //   }

  //   return Column(
  //     children: notesWithContent.map((entry) {
  //       return AnimatedContainer(
  //         duration: const Duration(milliseconds: 300),
  //         margin: const EdgeInsets.only(bottom: 16),
  //         padding: const EdgeInsets.all(16),
  //         decoration: BoxDecoration(
  //           gradient: LinearGradient(
  //             colors: [
  //               const Color(0xFF84CC16).withOpacity(0.08),
  //               const Color(0xFF65A30D).withOpacity(0.03),
  //             ],
  //             begin: Alignment.topLeft,
  //             end: Alignment.bottomRight,
  //           ),
  //           borderRadius: BorderRadius.circular(12),
  //           border: Border.all(
  //             color: const Color(0xFF84CC16).withOpacity(0.3),
  //             width: 1,
  //           ),
  //           boxShadow: [
  //             BoxShadow(
  //               color: const Color(0xFF84CC16).withOpacity(0.1),
  //               blurRadius: 8,
  //               spreadRadius: 0,
  //               offset: const Offset(0, 2),
  //             ),
  //           ],
  //         ),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Row(
  //               children: [
  //                 Container(
  //                   padding: const EdgeInsets.all(6),
  //                   decoration: BoxDecoration(
  //                     color: const Color(0xFF84CC16).withOpacity(0.15),
  //                     borderRadius: BorderRadius.circular(8),
  //                   ),
  //                   child: const Icon(
  //                     Icons.sticky_note_2_rounded,
  //                     color: Color(0xFF84CC16),
  //                     size: 16,
  //                   ),
  //                 ),
  //                 const SizedBox(width: 10),
  //                 Expanded(
  //                   child: Text(
  //                     _translateItemName(entry.key),
  //                     style: TextStyle(
  //                       fontSize: 14,
  //                       fontWeight: FontWeight.w700,
  //                       color: isDark ? Colors.white : const Color(0xFF1E293B),
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             const SizedBox(height: 12),
  //             Container(
  //               padding: const EdgeInsets.all(12),
  //               decoration: BoxDecoration(
  //                 color: isDark
  //                     ? const Color(0xFF0F172A).withOpacity(0.3)
  //                     : Colors.white.withOpacity(0.7),
  //                 borderRadius: BorderRadius.circular(8),
  //                 border: Border.all(
  //                   color: const Color(0xFF84CC16).withOpacity(0.2),
  //                 ),
  //               ),
  //               child: Text(
  //                 entry.value,
  //                 style: TextStyle(
  //                   fontSize: 14,
  //                   height: 1.5,
  //                   color: isDark ? Colors.grey[300] : const Color(0xFF475569),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       );
  //     }).toList(),
  //   );
  // }

  // Helper methods
  Color _getStatusColor(String status) {
    switch (status) {
      case 'submitted':
        return const Color(0xFF10B981);
      case 'draft':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'submitted':
        return Icons.check_circle_outline;
      case 'draft':
        return Icons.edit_outlined;
      default:
        return Icons.info_outline;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'submitted':
        return 'مرسل';
      case 'draft':
        return 'مسودة';
      default:
        return 'غير محدد';
    }
  }

  Color _getConditionColor(String condition) {
    switch (condition) {
      case 'جيد':
        return const Color(0xFF10B981);
      case 'يحتاج صيانة':
        return const Color(0xFFF59E0B);
      case 'تالف':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _getConditionIcon(String condition) {
    switch (condition) {
      case 'جيد':
        return Icons.check_circle_rounded;
      case 'يحتاج صيانة':
        return Icons.warning_rounded;
      case 'تالف':
        return Icons.error_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  int _getSafetyItemsCount(MaintenanceCount count) {
    final safetyKeys = [
      'fire_boxes',
      'fire_extinguishers',
      'diesel_pump',
      'electric_pump',
      'auxiliary_pump'
    ];

    int itemCount = 0;

    // Add fire safety and pump item counts
    count.itemCounts.forEach((key, value) {
      if (safetyKeys.contains(key)) itemCount++;
    });

    // Add fire safety alarm panel data
    itemCount += count.fireSafetyAlarmPanelData.length;

    // Add fire safety conditions and pump conditions
    itemCount += count.surveyAnswers.entries
        .where((e) =>
            e.key.contains('fire_') ||
            e.key.contains('emergency_') ||
            e.key.contains('smoke_') ||
            e.key.contains('heat_') ||
            e.key.contains('alarm_panel') ||
            e.key.contains('pump'))
        .length;

    // Add fire extinguisher expiry dates
    itemCount += count.textAnswers.entries
        .where((e) => e.key.contains('fire_extinguishers_expiry'))
        .length;

    return itemCount;
  }

  int _getMechanicalItemsCount(MaintenanceCount count) {
    final mechanicalKeys = ['water_pumps'];

    int itemCount = 0;

    // Add water pumps count
    count.itemCounts.forEach((key, value) {
      if (mechanicalKeys.contains(key)) itemCount++;
    });

    // Add water pumps condition
    itemCount += count.surveyAnswers.entries
        .where((e) => e.key == 'water_pumps_condition')
        .length;

    // Add water meter number
    itemCount += count.textAnswers.entries
        .where((e) => e.key == 'water_meter_number')
        .length;

    return itemCount;
  }

  int _getElectricalItemsCount(MaintenanceCount count) {
    final electricalKeys = ['electrical_panels'];

    int itemCount = 0;

    // Add electrical panels count
    count.itemCounts.forEach((key, value) {
      if (electricalKeys.contains(key)) itemCount++;
    });

    // Add electricity meter number only
    itemCount += count.textAnswers.entries
        .where((e) => e.key == 'electricity_meter_number')
        .length;

    return itemCount;
  }

  int _getCivilItemsCount(MaintenanceCount count) {
    int itemCount = count.yesNoAnswers.length;

    return itemCount;
  }

  String _translateItemName(String key) {
    // Arabic translations for item names
    const translations = {
      // Item counts
      'fire_boxes': 'صناديق الحريق',
      'diesel_pump': 'مضخة الديزل',
      'water_pumps': 'مضخات المياه',
      'electric_pump': 'المضخة الكهربائية',
      'auxiliary_pump': 'المضخة المساعدة',
      // 'alarm_panel_count': 'عدد لوحات الإنذار',
      'electrical_panels': 'اللوحات الكهربائية',
      'fire_extinguishers': 'طفايات الحريق',

      // Survey answers
      'emergency_exits': 'مخارج الطوارئ',
      // 'alarm_panel_type': 'نوع لوحة الإنذار',
      'fire_alarm_system': 'نظام إنذار الحريق',
      'fire_boxes_condition': 'حالة صناديق الحريق',
      // 'alarm_panel_condition': 'حالة لوحة الإنذار',
      'diesel_pump_condition': 'حالة مضخة الديزل',
      'electric_pump_condition': 'حالة المضخة الكهربائية',
      'water_pumps_condition': 'حالة مضخات المياه',
      'fire_suppression_system': 'نظام إطفاء الحريق',
      'auxiliary_pump_condition': 'حالة المضخة المساعدة',
      'heat_detectors_condition': 'حالة أجهزة استشعار الحرارة',
      'emergency_exits_condition': 'حالة مخارج الطوارئ',
      'smoke_detectors_condition': 'حالة أجهزة استشعار الدخان',
      'emergency_lights_condition': 'حالة أضواء الطوارئ',
      'fire_alarm_system_condition': 'حالة نظام إنذار الحريق',
      'break_glasses_bells_condition': 'حالة أجراس كسر الزجاج',
      'fire_suppression_system_condition': 'حالة نظام إطفاء الحريق',

      // Yes/No answers
      'wall_cracks': 'تشققات في الجدران',
      'has_elevators': 'يوجد مصاعد',
      'falling_shades': 'سقوط الظلال',
      'has_water_leaks': 'يوجد تسريب مياه',
      'low_railing_height': 'ارتفاع السياج منخفض',
      'concrete_rust_damage': 'أضرار صدأ الخرسانة',
      'roof_insulation_damage': 'أضرار عزل السطح',

      // Text answers
      'water_meter_number': 'رقم عداد المياه',
      'electricity_meter_number': 'رقم عداد الكهرباء',
      'fire_extinguishers_expiry_day': 'يوم انتهاء صلاحية طفايات الحريق',
      'fire_extinguishers_expiry_year': 'سنة انتهاء صلاحية طفايات الحريق',
      'fire_extinguishers_expiry_month': 'شهر انتهاء صلاحية طفايات الحريق',

      // Fire safety alarm panel
      'alarm_panel_type': 'نوع لوحة الإنذار',
      'alarm_panel_count': 'عدد لوحات الإنذار',
      'alarm_panel_condition': 'حالة لوحة الإنذار',

      // Notes
      'alarm_panel_note': 'ملاحظة لوحة الإنذار',
      'heat_detectors_note': 'ملاحظة أجهزة استشعار الحرارة',
      'emergency_exits_note': 'ملاحظة مخارج الطوارئ',
      'smoke_detectors_note': 'ملاحظة أجهزة استشعار الدخان',
      'emergency_lights_note': 'ملاحظة أضواء الطوارئ',
      'fire_alarm_system_note': 'ملاحظة نظام إنذار الحريق',
      'break_glasses_bells_note': 'ملاحظة أجراس كسر الزجاج',
      'fire_suppression_system_note': 'ملاحظة نظام إطفاء الحريق',
    };

    return translations[key] ?? key;
  }

  String _translateSectionName(String section) {
    const translations = {
      'civil': 'القسم المدني',
      'electrical': 'القسم الكهربائي',
      'mechanical': 'القسم الميكانيكي',
      'fire_safety': 'قسم السلامة من الحريق',
    };

    return translations[section] ?? section;
  }

  // Category helper methods
  Map<String, dynamic> _getSafetyItems(MaintenanceCount count) {
    final safetyKeys = [
      'fire_boxes',
      'fire_extinguishers',
      'diesel_pump',
      'electric_pump',
      'auxiliary_pump'
    ];

    Map<String, dynamic> items = {};

    // Add fire safety and pump item counts
    count.itemCounts.forEach((key, value) {
      if (safetyKeys.contains(key)) {
        items[key] = value;
      }
    });

    // Add fire safety alarm panel data
    items.addAll(count.fireSafetyAlarmPanelData);

    // Add fire extinguisher expiry dates
    count.textAnswers.forEach((key, value) {
      if (key.contains('fire_extinguishers_expiry') && value.isNotEmpty) {
        items[key] = value;
      }
    });

    return items;
  }

  Map<String, String> _getSafetyAnswers(MaintenanceCount count) {
    final safetyKeys = [
      'fire_alarm_system_condition',
      'fire_boxes_condition',
      'fire_suppression_system_condition',
      'emergency_exits_condition',
      'emergency_lights_condition',
      'smoke_detectors_condition',
      'heat_detectors_condition',
      'break_glasses_bells_condition',
      'alarm_panel_condition',
      'diesel_pump_condition',
      'electric_pump_condition',
      'auxiliary_pump_condition'
    ];

    Map<String, String> answers = {};

    count.surveyAnswers.forEach((key, value) {
      if (safetyKeys.contains(key)) {
        answers[key] = value;
      }
    });

    return answers;
  }

  List<String> _getSafetyPhotos(MaintenanceCount count) {
    return count.sectionPhotos['fire_safety'] ?? [];
  }

  Map<String, String> _getSafetyNotes(MaintenanceCount count) {
    final safetyKeys = [
      'fire_alarm_system_note',
      'fire_suppression_system_note',
      'emergency_exits_note',
      'emergency_lights_note',
      'smoke_detectors_note',
      'heat_detectors_note',
      'break_glasses_bells_note',
      'alarm_panel_note'
    ];

    Map<String, String> notes = {};

    count.maintenanceNotes.forEach((key, value) {
      if (safetyKeys.contains(key) && value.isNotEmpty) {
        notes[key] = value;
      }
    });

    return notes;
  }

  Map<String, dynamic> _getMechanicalItems(MaintenanceCount count) {
    final mechanicalKeys = ['water_pumps'];

    Map<String, dynamic> items = {};

    // Add water pumps count
    count.itemCounts.forEach((key, value) {
      if (mechanicalKeys.contains(key)) {
        items[key] = value;
      }
    });

    // Add water meter number
    count.textAnswers.forEach((key, value) {
      if (key == 'water_meter_number' && value.isNotEmpty) {
        items[key] = value;
      }
    });

    return items;
  }

  Map<String, String> _getMechanicalAnswers(MaintenanceCount count) {
    final mechanicalKeys = ['water_pumps_condition'];

    Map<String, String> answers = {};

    count.surveyAnswers.forEach((key, value) {
      if (mechanicalKeys.contains(key)) {
        answers[key] = value;
      }
    });

    return answers;
  }

  List<String> _getMechanicalPhotos(MaintenanceCount count) {
    return count.sectionPhotos['mechanical'] ?? [];
  }

  Map<String, String> _getMechanicalNotes(MaintenanceCount count) {
    final mechanicalKeys = [
      'diesel_pump_note',
      'electric_pump_note',
      'auxiliary_pump_note'
    ];

    Map<String, String> notes = {};

    count.maintenanceNotes.forEach((key, value) {
      if (mechanicalKeys.contains(key) && value.isNotEmpty) {
        notes[key] = value;
      }
    });

    return notes;
  }

  Map<String, dynamic> _getElectricalItems(MaintenanceCount count) {
    final electricalKeys = ['electrical_panels'];

    Map<String, dynamic> items = {};

    count.itemCounts.forEach((key, value) {
      if (electricalKeys.contains(key)) {
        items[key] = value;
      }
    });

    // Add text answers for electrical
    count.textAnswers.forEach((key, value) {
      if (key == 'electricity_meter_number') {
        items[key] = value;
      }
    });

    return items;
  }

  Map<String, String> _getElectricalAnswers(MaintenanceCount count) {
    final electricalKeys = ['electrical_panels_condition'];

    Map<String, String> answers = {};

    count.surveyAnswers.forEach((key, value) {
      if (electricalKeys.contains(key)) {
        answers[key] = value;
      }
    });

    return answers;
  }

  List<String> _getElectricalPhotos(MaintenanceCount count) {
    return count.sectionPhotos['electrical'] ?? [];
  }

  Map<String, String> _getElectricalNotes(MaintenanceCount count) {
    final electricalKeys = ['electrical_panels_note'];

    Map<String, String> notes = {};

    count.maintenanceNotes.forEach((key, value) {
      if (electricalKeys.contains(key) && value.isNotEmpty) {
        notes[key] = value;
      }
    });

    return notes;
  }

  Map<String, dynamic> _getCivilItems(MaintenanceCount count) {
    Map<String, dynamic> items = {};

    // Add yes/no answers for civil issues
    count.yesNoAnswers.forEach((key, value) {
      items[key] = value;
    });

    return items;
  }

  Map<String, String> _getCivilAnswers(MaintenanceCount count) {
    // Civil answers are mostly handled in items as yes/no
    return {};
  }

  List<String> _getCivilPhotos(MaintenanceCount count) {
    return count.sectionPhotos['civil'] ?? [];
  }

  Map<String, String> _getCivilNotes(MaintenanceCount count) {
    final civilKeys = ['building_note', 'structure_note'];

    Map<String, String> notes = {};

    count.maintenanceNotes.forEach((key, value) {
      if (civilKeys.contains(key) && value.isNotEmpty) {
        notes[key] = value;
      }
    });

    return notes;
  }

  Widget _buildCategoryHeader(String title, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDataSection(
      String title, IconData icon, Color color, Map<String, dynamic> data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
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
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...data.entries
              .map(
                (entry) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _translateItemName(entry.key),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.grey[300]
                                : const Color(0xFF475569),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          entry.value is bool
                              ? (entry.value ? 'نعم' : 'لا')
                              : '${entry.value}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  Widget _buildModernConditionSection(String title, IconData icon, Color color,
      Map<String, String> conditions) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
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
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...conditions.entries.map((entry) {
            final conditionColor = _getConditionColor(entry.value);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: conditionColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: conditionColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    _getConditionIcon(entry.value),
                    color: conditionColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _translateItemName(entry.key),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark ? Colors.grey[300] : const Color(0xFF475569),
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: conditionColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      entry.value,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildModernPhotosSection(
      String title, IconData icon, Color color, List<String> photos) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
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
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${photos.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      photos[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: color.withOpacity(0.1),
                          child: Icon(
                            Icons.error_outline,
                            color: color,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernNotesSection(
      String title, IconData icon, Color color, Map<String, String> notes) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
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
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...notes.entries
              .map(
                (entry) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _translateItemName(entry.key),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? Colors.grey[300]
                              : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  Widget _buildEmptyCategory(String categoryName, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 48,
              color: color,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد بيانات في قسم $categoryName',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
