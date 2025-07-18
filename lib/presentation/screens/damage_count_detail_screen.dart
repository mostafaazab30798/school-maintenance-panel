import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../logic/blocs/maintenance_counts/maintenance_counts_bloc.dart';
import '../../data/repositories/maintenance_count_repository.dart';
import '../../data/repositories/damage_count_repository.dart';
import '../../data/models/damage_count.dart';
import '../../core/services/admin_service.dart';
import '../widgets/common/shared_app_bar.dart';
import '../widgets/common/error_widget.dart';

class DamageCountDetailScreen extends StatelessWidget {
  final String schoolId;
  final String schoolName;

  const DamageCountDetailScreen({
    super.key,
    required this.schoolId,
    required this.schoolName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MaintenanceCountsBloc(
        repository: MaintenanceCountRepository(Supabase.instance.client),
        damageRepository: DamageCountRepository(Supabase.instance.client),
        adminService: AdminService(Supabase.instance.client),
      )..add(LoadDamageCountDetails(schoolId: schoolId)),
      child: DamageCountDetailView(
        schoolId: schoolId,
        schoolName: schoolName,
      ),
    );
  }
}

class DamageCountDetailView extends StatelessWidget {
  final String schoolId;
  final String schoolName;

  const DamageCountDetailView({
    super.key,
    required this.schoolId,
    required this.schoolName,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: SharedAppBar(
          title: "$schoolName - تفاصيل التوالف",
        ),
        body: BlocBuilder<MaintenanceCountsBloc, MaintenanceCountsState>(
          builder: (context, state) {
            if (state is MaintenanceCountsLoading) {
              return _buildLoadingState(context);
            }

            if (state is MaintenanceCountsError) {
              return Center(
                child: AppErrorWidget(
                  message: state.message,
                  onRetry: () => context
                      .read<MaintenanceCountsBloc>()
                      .add(LoadDamageCountDetails(schoolId: schoolId)),
                ),
              );
            }

            if (state is DamageCountDetailsLoaded) {
              return _buildDamageDetails(context, state.damageCount);
            }

            return _buildEmptyState(context);
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFEF4444).withOpacity(0.1),
                  const Color(0xFFDC2626).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFEF4444).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'جاري تحميل تفاصيل التوالف...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[300] : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1E293B).withOpacity(0.8),
                    const Color(0xFF334155).withOpacity(0.6),
                  ]
                : [
                    Colors.white.withOpacity(0.9),
                    const Color(0xFFF8FAFC).withOpacity(0.7),
                  ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? const Color(0xFF334155).withOpacity(0.5)
                : const Color(0xFFE2E8F0).withOpacity(0.8),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF10B981).withOpacity(0.15),
                    const Color(0xFF059669).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 48,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'لا توجد توالف مسجلة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'هذه المدرسة لا تحتوي على تلف مسجل',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDamageDetails(BuildContext context, DamageCount damageCount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        // Summary header
        SliverToBoxAdapter(
          child: _buildSummaryHeader(context, damageCount, isDark),
        ),

        // Category sections
        SliverToBoxAdapter(
          child: _buildCategorySections(context, damageCount, isDark),
        ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 20),
        ),
      ],
    );
  }

  Widget _buildSummaryHeader(
      BuildContext context, DamageCount damageCount, bool isDark) {
    final damagedItems = damageCount.itemCounts.entries
        .where((entry) => entry.value > 0)
        .toList();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1E293B).withOpacity(0.95),
                  const Color(0xFF334155).withOpacity(0.8),
                ]
              : [
                  Colors.white.withOpacity(0.95),
                  const Color(0xFFF8FAFC).withOpacity(0.9),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEF4444).withOpacity(0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : const Color(0xFF64748B).withOpacity(0.08),
            offset: const Offset(0, 4),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFEF4444).withOpacity(0.15),
                      const Color(0xFFDC2626).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إجمالي التوالف المسجلة',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${damagedItems.length} نوع تالف',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'المجموع: ${damageCount.totalDamagedItems}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF334155).withOpacity(0.3)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Text(
                  'تاريخ التسجيل: ${_formatDate(damageCount.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySections(
      BuildContext context, DamageCount damageCount, bool isDark) {
    final categories = [
      {
        'key': 'fire_safety',
        'title': 'أمن وسلامة',
        'icon': Icons.local_fire_department_rounded,
        'color': const Color(0xFFDC2626),
      },
      {
        'key': 'mechanical',
        'title': 'سباكة وميكانيكا',
        'icon': Icons.plumbing_rounded,
        'color': const Color(0xFF2563EB),
      },
      {
        'key': 'electrical',
        'title': 'أعمال كهربائية',
        'icon': Icons.electrical_services_rounded,
        'color': const Color(0xFFF59E0B),
      },
      {
        'key': 'civil',
        'title': 'أعمال مدنية',
        'icon': Icons.construction_rounded,
        'color': const Color(0xFF059669),
      },
      {
        'key': 'air_conditioning',
        'title': 'تكييف الهواء',
        'icon': Icons.ac_unit_rounded,
        'color': const Color(0xFF8B5CF6),
      },
    ];

    return Column(
      children: categories.map((category) {
        final categoryKey = category['key'] as String;
        final categoryItems = _getCategoryDamageItems(damageCount, categoryKey);
        final categoryPhotos = damageCount.sectionPhotos[categoryKey] ?? [];

        if (categoryItems.isEmpty && categoryPhotos.isEmpty) {
          return const SizedBox.shrink();
        }

        return _buildCategorySection(
          context,
          category['title'] as String,
          category['icon'] as IconData,
          category['color'] as Color,
          categoryItems,
          categoryPhotos,
          isDark,
        );
      }).toList(),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    Map<String, int> items,
    List<String> photos,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1E293B).withOpacity(0.95),
                  const Color(0xFF334155).withOpacity(0.8),
                ]
              : [
                  Colors.white.withOpacity(0.95),
                  const Color(0xFFF8FAFC).withOpacity(0.9),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : const Color(0xFF64748B).withOpacity(0.08),
            offset: const Offset(0, 4),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: color.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ),
                if (items.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: color.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${items.values.fold(0, (a, b) => a + b)} تلف',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Category content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Damaged items
                if (items.isNotEmpty) ...[
                  Text(
                    'العناصر التالفة:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: items.entries.map((entry) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: color.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getItemDisplayName(entry.key),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${entry.value}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  if (photos.isNotEmpty) const SizedBox(height: 16),
                ],

                // Photos section
                if (photos.isNotEmpty) ...[
                  Text(
                    'الصور المرفقة (${photos.length}):',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPhotosGrid(context, photos, color, isDark),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosGrid(
      BuildContext context, List<String> photos, Color color, bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _showImageViewer(context, photos, index),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: photos[index],
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: color.withOpacity(0.1),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.withOpacity(0.1),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showImageViewer(
      BuildContext context, List<String> images, int initialIndex) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: images.length,
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  child: CachedNetworkImage(
                    imageUrl: images[index],
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.error_outline,
                          color: Colors.white, size: 48),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, int> _getCategoryDamageItems(
      DamageCount damageCount, String category) {
    final categoryItems = <String, int>{};

    // This is a simplified mapping - you may need to adjust based on your actual data structure
    // For now, we'll include all damaged items for each category
    // In a real implementation, you'd filter based on item categories

    switch (category) {
      case 'fire_safety':
        // Filter fire safety related items
        damageCount.itemCounts.forEach((key, value) {
          if (value > 0 && _isFireSafetyItem(key)) {
            categoryItems[key] = value;
          }
        });
        break;
      case 'mechanical':
        // Filter mechanical related items
        damageCount.itemCounts.forEach((key, value) {
          if (value > 0 && _isMechanicalItem(key)) {
            categoryItems[key] = value;
          }
        });
        break;
      case 'electrical':
        // Filter electrical related items
        damageCount.itemCounts.forEach((key, value) {
          if (value > 0 && _isElectricalItem(key)) {
            categoryItems[key] = value;
          }
        });
        break;
      case 'civil':
        // Filter civil related items
        damageCount.itemCounts.forEach((key, value) {
          if (value > 0 && _isCivilItem(key)) {
            categoryItems[key] = value;
          }
        });
        break;
      case 'air_conditioning':
        // Filter air conditioning related items
        damageCount.itemCounts.forEach((key, value) {
          if (value > 0 && _isAirConditioningItem(key)) {
            categoryItems[key] = value;
          }
        });
        break;
    }

    return categoryItems;
  }

  bool _isFireSafetyItem(String itemKey) {
    final fireSafetyItems = [
      'co2_9kg',
      'dry_powder_6kg',
      'fire_pump_1750',
      'fire_alarm_panel',
      'fire_suppression_box',
      'fire_extinguishing_networks',
      'thermal_wires_alarm_networks',
    ];
    return fireSafetyItems.contains(itemKey);
  }

  bool _isMechanicalItem(String itemKey) {
    final mechanicalItems = [
      'joky_pump',
      'water_sink',
      'upvc_50_meter',
      'upvc_pipes_4_5',
      'booster_pump_3_phase',
      'glass_fiber_tank_3000',
      'glass_fiber_tank_4000',
      'glass_fiber_tank_5000',
      'pvc_pipe_connection_4',
      'electric_water_heater_50l',
      'electric_water_heater_100l',
      'feeding_pipes',
      'external_drainage_pipes',
    ];
    return mechanicalItems.contains(itemKey);
  }

  bool _isElectricalItem(String itemKey) {
    final electricalItems = [
      'copper_cable',
      'circuit_breaker_250',
      'circuit_breaker_400',
      'circuit_breaker_1250',
      'fluorescent_36w_sub_branch',
      'fluorescent_48w_main_branch',
      'electrical_distribution_unit',
    ];
    return electricalItems.contains(itemKey);
  }

  bool _isCivilItem(String itemKey) {
    final civilItems = [
      'low_boxes',
      'hidden_boxes',
      'plastic_chair',
      'plastic_chair_external',
      'site_tile_damage',
      'external_facade_paint',
      'internal_wall_ceiling_paint',
      'external_plastering',
      'internal_wall_ceiling_plastering',
      'internal_marble_damage',
      'internal_tile_damage',
      'main_building_roof_insulation',
      'internal_windows',
      'external_windows',
      'metal_slats_suspended_ceiling',
      'suspended_ceiling_grids',
      'underground_tanks',
    ];
    return civilItems.contains(itemKey);
  }

  bool _isAirConditioningItem(String itemKey) {
    final airConditioningItems = [
      'split_ac',
      'window_ac',
      'cabinet_ac',
      'package_ac',
    ];
    return airConditioningItems.contains(itemKey);
  }

  String _getItemDisplayName(String itemKey) {
    const itemNames = {
      // أعمال الميكانيك والسباكة (Mechanical and Plumbing Work)
      'plastic_chair': 'كرسي شرقي',
      'plastic_chair_external': 'كرسي افرنجي',
      'water_sink': 'حوض مغسلة مع القاعدة',
      'hidden_boxes': 'صناديق طرد مخفي-للكرسي العربي',
      'low_boxes': 'صناديق طرد واطي-للكرسي الافرنجي',
      'upvc_pipes_4_5':
          'مواسير قطر من(4 الى 0.5) بوصة upvc class 5 وضغط داخلي 16pin',
      'glass_fiber_tank_5000': 'خزان علوي فايبر جلاس سعة 5000 لتر',
      'glass_fiber_tank_4000': 'خزان علوي فايبر جلاس سعة 4000 لتر',
      'glass_fiber_tank_3000': 'خزان علوي فايبر جلاس سعة 3000 لتر',
      'booster_pump_3_phase': 'مضخات مياة 3 حصان- Booster Pump',
      'elevator_pulley_machine': 'محرك  + صندوق تروس مصاعد - Elevators',

      // أعمال الكهرباء (Electrical Work)
      'circuit_breaker_250': 'قاطع كهرباني سعة (250) أمبير',
      'circuit_breaker_400': 'قاطع كهرباني سعة (400) أمبير',
      'circuit_breaker_1250': 'قاطع كهرباني سعة 1250 أمبير',
      'electrical_distribution_unit': 'أغطية لوحات التوزيع الفرعية',
      'copper_cable': 'كبل نحاس  مسلح مقاس (4*16)',
      'fluorescent_48w_main_branch':
          'لوحة توزيع فرعية (48) خط مزوده عدد (24) قاطع فرعي مزدوج سعة (30 امبير) وقاطع رئيسي سعة 125 امبير',
      'fluorescent_36w_sub_branch':
          'لوحة توزيع فرعية (36) خط مزوده عدد (24) قاطع فرعي مزدوج سعة (30 امبير) وقاطع رئيسي سعة 125 امبير',
      'electric_water_heater_50l': 'سخانات المياه الكهربائية سعة 50 لتر',
      'electric_water_heater_100l': 'سخانات المياه الكهربائية سعة 100 لتر',

      // أعمال مدنية (Civil Work)
      'upvc_50_meter': 'قماش مظلات من مادة (UPVC) لفة (50) متر مربع',

      // أعمال الامن والسلامة (Safety and Security Work)
      'pvc_pipe_connection_4':
          'محبس حريق OS&Y من قطر 4 بوصة الى 3 بوصة كامل Flange End',
      'fire_alarm_panel':
          'لوحة انذار معنونه كاملة ( مع الاكسسوارات ) والبطارية ( 12/10/8 ) زون',
      'dry_powder_6kg': 'طفاية حريق Dry powder وزن 6 كيلو',
      'co2_9kg': 'طفاية حريق CO2 وزن(9) كيلو',
      'fire_pump_1750': 'مضخة حريق 1750 دورة/د وتصرف 125 جالون/ضغط 7 بار',
      'joky_pump': 'مضخة حريق تعويضيه جوكي ضغط 7 بار',
      'fire_suppression_box': 'صدنوق إطفاء حريق بكامل عناصره',

      // التكييف (Air Conditioning)
      'cabinet_ac': 'دولابي',
      'split_ac': 'سبليت',
      'window_ac': 'شباك',
      'package_ac': 'باكدج',

      // New items from items.md - Civil Works (using actual database keys)
      'site_tile_damage': 'هبوط او تلف بلاط الموقع العام',
      'external_facade_paint': 'دهانات الواجهات الخارجية',
      'internal_wall_ceiling_paint': 'دهانات الحوائط والاسقف الداخلية',
      'external_plastering': 'اللياسة الخارجية',
      'internal_wall_ceiling_plastering': 'لياسة الحوائط والاسقف الداخلية',
      'internal_marble_damage': 'هبوط او تلف رخام الارضيات والحوائط الداخلية',
      'internal_tile_damage': 'هبوط او تلف بلاط الارضيات والحوائط الداخلية',
      'main_building_roof_insulation': 'عزل سطج المبنى الرئيسي',
      'internal_windows': 'النوافذ الداخلية',
      'external_windows': 'النوافذ الخارجية',
      'metal_slats_suspended_ceiling': 'شرائح معدنية ( اسقف مستعارة )',
      'suspended_ceiling_grids': 'تربيعات (اسقف مستعارة)',
      'underground_tanks': 'الخزانات الارضية',

      // New items from items.md - Mechanical Works (using actual database keys)
      'feeding_pipes': 'مواسير التغذية',
      'external_drainage_pipes': 'مواسير الصرف الخارجية',

      // New items from items.md - Fire Safety Works (using actual database keys)
      'fire_extinguishing_networks': 'شبكات الحريق والاطفاء',
      'thermal_wires_alarm_networks': 'اسلاك حرارية لشبكات الانذار',
    };

    return itemNames[itemKey] ?? itemKey;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
