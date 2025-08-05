import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../logic/blocs/maintenance_counts/maintenance_counts_bloc.dart';
import '../../data/repositories/maintenance_count_repository.dart';
import '../../data/repositories/damage_count_repository.dart';
import '../../data/repositories/supervisor_repository.dart';
import '../../data/models/maintenance_count.dart';
import '../../data/models/supervisor.dart';
import '../../core/services/admin_service.dart';
import '../widgets/common/shared_app_bar.dart';
import '../widgets/common/error_widget.dart';
import 'maintenance_count_category_screen.dart';

class MaintenanceCountDetailScreen extends StatelessWidget {
  final String schoolId;
  final String schoolName;

  const MaintenanceCountDetailScreen({
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
      )..add(LoadMaintenanceCountRecords(schoolId: schoolId)),
      child: MaintenanceCountDetailView(
        schoolId: schoolId,
        schoolName: schoolName,
      ),
    );
  }
}

class MaintenanceCountDetailView extends StatefulWidget {
  final String schoolId;
  final String schoolName;

  const MaintenanceCountDetailView({
    super.key,
    required this.schoolId,
    required this.schoolName,
  });

  @override
  State<MaintenanceCountDetailView> createState() =>
      _MaintenanceCountDetailViewState();
}

class _MaintenanceCountDetailViewState
    extends State<MaintenanceCountDetailView> with TickerProviderStateMixin {
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
        body: BlocBuilder<MaintenanceCountsBloc, MaintenanceCountsState>(
          builder: (context, state) {
            if (state is MaintenanceCountsLoading) {
              return _buildLoadingState();
            }

            if (state is MaintenanceCountsError) {
              return Center(
                child: AppErrorWidget(
                  message: state.message,
                  onRetry: () => context
                      .read<MaintenanceCountsBloc>()
                      .add(LoadMaintenanceCountRecords(schoolId: widget.schoolId)),
                ),
              );
            }

            if (state is MaintenanceCountRecordsLoaded) {
              final records = state.records;
              final supervisorNames = state.supervisorNames;

              if (records.isEmpty) {
                return _buildEmptyState();
              }

              _animationController.forward();
              return _buildMaintenanceCountsList(context, records, supervisorNames);
            }

            return _buildEmptyState();
          },
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

  Widget _buildMaintenanceCountsList(BuildContext context, List<MaintenanceCount> records, Map<String, String> supervisorNames) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: () async {
          context
              .read<MaintenanceCountsBloc>()
              .add(LoadMaintenanceCountRecords(schoolId: widget.schoolId));
        },
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
                    final count = records[index];
                    return _buildMaintenanceCountCard(count, index, supervisorNames);
                  },
                  childCount: records.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceCountCard(MaintenanceCount count, int index, Map<String, String> supervisorNames) {
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
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_rounded,
                            size: 14,
                            color: isDark
                                ? Colors.grey[400]
                                : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _getSupervisorDisplayText(count.supervisorId, supervisorNames),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.grey[400]
                                    : const Color(0xFF64748B),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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

  /// 🚀 NEW: Helper method to display supervisor names for merged records
  String _getSupervisorDisplayText(String supervisorId, Map<String, String> supervisorNames) {
    // Check if this is a merged record (contains multiple supervisor IDs)
    if (supervisorId.contains(', ')) {
      final supervisorIdList = supervisorId.split(', ');
      final supervisorNameList = <String>[];
      
      for (final id in supervisorIdList) {
        final name = supervisorNames[id.trim()];
        if (name != null && name.isNotEmpty) {
          supervisorNameList.add(name);
        }
      }
      
      if (supervisorNameList.isNotEmpty) {
        if (supervisorNameList.length == 1) {
          return 'المشرف: ${supervisorNameList.first}';
        } else {
          return 'المشرفون: ${supervisorNameList.join('، ')}';
        }
      } else {
        return 'المشرفون: غير محدد';
      }
    } else {
      // Single supervisor
      final supervisorName = supervisorNames[supervisorId];
      return 'المشرف: ${supervisorName ?? 'غير محدد'}';
    }
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
        'title': 'مدني',
        'icon': Icons.business_rounded,
        'color': const Color(0xFF8B5CF6),
        'category': 'civil',
        'itemCount': _getCivilItemsCount(count),
      },
      {
        'title': 'كهرباء',
        'icon': Icons.electrical_services_rounded,
        'color': const Color(0xFFF59E0B),
        'category': 'electrical',
        'itemCount': _getElectricalItemsCount(count),
      },
      {
        'title': 'ميكانيكا',
        'icon': Icons.precision_manufacturing_rounded,
        'color': const Color(0xFF10B981),
        'category': 'mechanical',
        'itemCount': _getMechanicalItemsCount(count),
      },
      {
        'title': 'امن وسلامة',
        'icon': Icons.security_rounded,
        'color': const Color(0xFFEF4444),
        'category': 'safety',
        'itemCount': _getSafetyItemsCount(count),
      },
      {
        'title': 'التكييف',
        'icon': Icons.ac_unit_rounded,
        'color': const Color(0xFF17A2B8),
        'category': 'air_conditioning',
        'itemCount': _getAirConditioningItemsCount(count),
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
              padding: EdgeInsets.symmetric(horizontal: 1),
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
              padding: const EdgeInsets.all(6),
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
                    size: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    category['title'],
                    style: TextStyle(
                      fontSize: 8,
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
                      fontSize: 7,
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
      'fire_hose',
      'diesel_pump',
      'electric_pump',
      'auxiliary_pump',
      'emergency_exits',
      'emergency_lights',
      'breakers',
      'bells',
      'break_glasses_bells',
      'smoke_detectors',
      'heat_detectors',
      'emergency_signs',
      'camera'
    ];

    int itemCount = 0;

    // Add fire safety and pump item counts
    count.itemCounts.forEach((key, value) {
      if (safetyKeys.contains(key)) itemCount++;
    });

    // Add fire safety alarm panel data
    itemCount += count.fireSafetyAlarmPanelData.length;

    // Add fire safety conditions and pump conditions from survey answers
    final safetySurveyKeys = [
      'fire_alarm_system',
      'fire_hose_condition',
      'fire_boxes_condition',
      'alarm_panel_type',
      'alarm_panel_condition',
      'diesel_pump_condition',
      'electric_pump_condition',
      'fire_suppression_system',
      'auxiliary_pump_condition',
      'heat_detectors_condition',
      'emergency_exits_condition',
      'smoke_detectors_condition',
      'emergency_lights_condition',
      'fire_alarm_system_condition',
      'break_glasses_bells_condition',
      'fire_suppression_system_condition'
    ];

    count.surveyAnswers.forEach((key, value) {
      if (safetySurveyKeys.contains(key)) itemCount++;
    });

    // Add fire safety expiry dates
    itemCount += count.textAnswers.entries
        .where((e) =>
            e.key.contains('fire_extinguishers_expiry_'))
        .length;

    return itemCount;
  }

  int _getMechanicalItemsCount(MaintenanceCount count) {
    int itemCount = 0;

    // Handle new heater entries structure
    final heaterEntries = count.heaterEntries;
    if (heaterEntries.isNotEmpty) {
      // Count individual heater entries
      final bathroomHeaters = heaterEntries['bathroom_heaters'] as List<dynamic>?;
      if (bathroomHeaters != null) {
        itemCount += bathroomHeaters.length;
      }
      
      final cafeteriaHeaters = heaterEntries['cafeteria_heaters'] as List<dynamic>?;
      if (cafeteriaHeaters != null) {
        itemCount += cafeteriaHeaters.length;
      }
    } else {
      // Fallback to old structure
      final mechanicalKeys = [
        'bathroom_heaters_1',
        'bathroom_heaters_2',
        'cafeteria_heaters_1',
        'hand_sink',
        'basin_sink',
        'western_toilet',
        'arabic_toilet',
        'arabic_siphon',
        'english_siphon',
        'bidets',
        'wall_exhaust_fans',
        'central_exhaust_fans',
        'cafeteria_exhaust_fans',
        'wall_water_coolers',
        'corridor_water_coolers',
        'water_pumps',
        'sink_mirrors',
        'wall_tap',
        'sink_tap'
      ];

      // Add mechanical item counts
      count.itemCounts.forEach((key, value) {
        if (mechanicalKeys.contains(key)) itemCount++;
      });

      // Add mechanical text answers count
      itemCount += count.textAnswers.entries
          .where((e) => e.value.isNotEmpty && (
            e.key == 'water_meter_number' ||
            e.key == 'bathroom_heaters_capacity' ||
            e.key == 'cafeteria_heaters_capacity'
          ))
          .length;
    }

    // Add water pumps condition
    itemCount += count.surveyAnswers.entries
        .where((e) => e.key == 'water_pumps_condition')
        .length;

    return itemCount;
  }

  int _getElectricalItemsCount(MaintenanceCount count) {
    final electricalKeys = [
      'lamps',
      'projector', 
      'class_bell',
      'speakers',
      'microphone_system',
      'ac_panel',
      'power_panel',
      'lighting_panel',
      'main_distribution_panel',
      'main_breaker',
      'electrical_panels',
    ];

    int itemCount = 0;

    // Add electrical item counts
    count.itemCounts.forEach((key, value) {
      if (electricalKeys.contains(key)) itemCount++;
    });

    // Add electrical text answers count
    itemCount += count.textAnswers.entries
        .where((e) => e.value.isNotEmpty && (
          e.key == 'electricity_meter_number' ||
          e.key == 'power_panel_amperage' ||
          e.key == 'main_breaker_amperage' ||
          e.key == 'lighting_panel_amperage' ||
          e.key == 'ac_panel_amperage' ||
          e.key == 'package_ac_breaker_amperage' ||
          e.key == 'concealed_ac_breaker_amperage' ||
          e.key == 'main_distribution_panel_amperage' ||
          e.key == 'elevators_motor' ||
          e.key == 'elevators_main_parts'
        ))
        .length;

    return itemCount;
  }

  int _getCivilItemsCount(MaintenanceCount count) {
    final civilKeys = [
      'blackboard',
      'internal_windows',
      'external_windows',
      'emergency_signs',
      'single_door',
      'double_door'
    ];

    int itemCount = 0;

    // Add civil item counts
    count.itemCounts.forEach((key, value) {
      if (civilKeys.contains(key)) itemCount++;
    });

    // Add civil/structural yes_no_with_counts survey answers
    final civilSurveyKeys = [
      'elevators',
      'wall_cracks',
      'falling_shades',
      'has_water_leaks',
      'low_railing_height',
      'concrete_rust_damage',
      'roof_insulation_damage'
    ];

    count.yesNoWithCounts.forEach((key, value) {
      if (civilSurveyKeys.contains(key)) itemCount++;
    });

    return itemCount;
  }

  int _getAirConditioningItemsCount(MaintenanceCount count) {
    final airConditioningKeys = [
      'cabinet_ac',
      'split_concealed_ac',
      'hidden_ducts_ac',
      'window_ac',
      'package_ac',
      'concealed_ac_breaker',
      'package_ac_breaker',
      'split_ac', // Legacy key
    ];

    int itemCount = 0;

    // Add air conditioning item counts
    count.itemCounts.forEach((key, value) {
      if (airConditioningKeys.contains(key)) {
        itemCount++;
      }
    });

    // Add air conditioning text answers count
    final acTextAnswers = count.textAnswers.entries
        .where((e) => e.value.isNotEmpty && (
          e.key == 'concealed_ac_breaker_amperage' ||
          e.key == 'package_ac_breaker_amperage'
        ));
    itemCount += acTextAnswers.length;
    return itemCount;
  }

  String _translateItemName(String key) {
    // Arabic translations for item names
    const translations = {
      // Item counts
      'fire_boxes': 'صناديق الحريق',
      'fire_hose': 'خرطوم الحريق',
      'diesel_pump': 'مضخة الديزل',
      'water_pumps': 'مضخات المياه',
      'electric_pump': 'المضخة الكهربائية',
      'auxiliary_pump': 'المضخة المساعدة',
      'emergency_exits': 'مخارج الطوارئ',
      'emergency_lights': 'أضواء الطوارئ',
      'electrical_panels': 'اللوحات الكهربائية',
      'fire_extinguishers': 'طفايات الحريق',

      // Updated AC types
      'split_concealed_ac': 'مكيف سبليت مخفي',
      'hidden_ducts_ac': 'مكيف مخفي بقنوات',
      'window_ac': 'مكيف نافذة',
      'cabinet_ac': 'مكيف خزانة',
      'package_ac': 'مكيف حزمة',

      // Updated sink types
      'hand_sink': 'حوض غسيل اليدين',
      'basin_sink': 'حوض الحوض',

      // Updated siphon types
      'arabic_siphon': 'سيفون عربي',
      'english_siphon': 'سيفون إنجليزي',

      // Updated breaker and bell types
      'breakers': 'قواطع كهربائية',
      'bells': 'أجراس',

      // Updated detector types
      'smoke_detectors': 'أجهزة استشعار الدخان',
      'heat_detectors': 'أجهزة استشعار الحرارة',

      // New item types
      'camera': 'كاميرات',
      'emergency_signs': 'علامات الطوارئ',
      'sink_mirrors': 'مرايا الحوض',
      'wall_tap': 'صنبور الحائط',
      'sink_tap': 'صنبور الحوض',
      'single_door': 'أبواب مفردة',
      'double_door': 'أبواب مزدوجة',

      // Survey answers
      'fire_alarm_system': 'نظام إنذار الحريق',
      'fire_boxes_condition': 'حالة صناديق الحريق',
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
      'break_glasses_bells_condition': 'كاسر',
      'fire_suppression_system_condition': 'حالة نظام إطفاء الحريق',

      // Yes/No answers
      'wall_cracks': 'تشققات في الجدران',
      'has_elevators': 'يوجد مصاعد',
      'falling_shades': 'سقوط الظلال',
      'has_water_leaks': 'يوجد تسريب مياه',
      'low_railing_height': 'ارتفاع السياج منخفض',
      'concrete_rust_damage': 'أضرار صدأ الخرسانة',
      'roof_insulation_damage': 'أضرار عزل السطح',

      // Text answers - Meter numbers
      'water_meter_number': 'رقم عداد المياه',
      'electricity_meter_number': 'رقم عداد الكهرباء',
      
      // Text answers - Fire safety expiry dates
      'fire_extinguishers_expiry_day': 'يوم انتهاء صلاحية طفايات الحريق',
      'fire_extinguishers_expiry_year': 'سنة انتهاء صلاحية طفايات الحريق',
      'fire_extinguishers_expiry_month': 'شهر انتهاء صلاحية طفايات الحريق',

      // Text answers - Electrical amperage values
      'ac_panel_amperage': 'أمبير لوحة التكييف',
      'power_panel_amperage': 'أمبير لوحة الباور',
      'main_breaker_amperage': 'أمبير القاطع الرئيسي',
      'lighting_panel_amperage': 'أمبير لوحة الإنارة',
      'package_ac_breaker_amperage': 'أمبير قاطع التكييف الباكدج',
      'concealed_ac_breaker_amperage': 'أمبير قاطع التكييف الكونسيلد',
      'main_distribution_panel_amperage': 'أمبير لوحة التوزيع الرئيسية',

      // Text answers - Mechanical capacities
      'bathroom_heaters_capacity': 'سعة سخانات الحمام',
      'cafeteria_heaters_capacity': 'سعة سخانات المقصف',

      // Text answers - Elevator information
      'elevators_motor': 'محرك المصاعد',
      'elevators_main_parts': 'الأجزاء الرئيسية للمصاعد',

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
      'break_glasses_bells_note': 'ملاحظة كواسر',
      'fire_suppression_system_note': 'ملاحظة نظام إطفاء الحريق',
    };

    // Handle dynamic heater capacity keys
    if (key.startsWith('bathroom_heaters_') && key.endsWith('_capacity')) {
      return 'سعة سخان الحمام';
    }
    if (key.startsWith('cafeteria_heaters_') && key.endsWith('_capacity')) {
      return 'سعة سخان المقصف';
    }

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
      'fire_hose',
      'diesel_pump',
      'electric_pump',
      'auxiliary_pump',
      'emergency_exits',
      'emergency_lights',
      'breakers',
      'bells',
      'break_glasses_bells',
      'smoke_detectors',
      'heat_detectors'
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

    // Add fire safety text answers
    count.textAnswers.forEach((key, value) {
      if (value.isNotEmpty && (
        key.contains('fire_extinguishers_expiry') ||
        key == 'fire_extinguishers_expiry_day' ||
        key == 'fire_extinguishers_expiry_month' ||
        key == 'fire_extinguishers_expiry_year'
      )) {
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
    Map<String, dynamic> items = {};

    // Handle new heater entries structure
    final heaterEntries = count.heaterEntries;
    if (heaterEntries.isNotEmpty) {
      // Process bathroom heaters
      final bathroomHeaters = heaterEntries['bathroom_heaters'] as List<dynamic>?;
      if (bathroomHeaters != null) {
        for (int i = 0; i < bathroomHeaters.length; i++) {
          final heater = bathroomHeaters[i];
          if (heater is Map<String, dynamic>) {
            final id = heater['id']?.toString() ?? '';
            
            if (id.isNotEmpty) {
              final heaterKey = 'bathroom_heaters_$id';
              final quantity = count.itemCounts[heaterKey] ?? 0;
                          // Try to get capacity from textAnswers
            final capKey = '${heaterKey}_capacity';
            final capacity = count.textAnswers[capKey];
            
            final heaterData = <String, dynamic>{
              'count': quantity,
              'location': 'حمام',
              'id': id,
              'capacity': capacity,
            };
              items[heaterKey] = heaterData;
            }
          }
        }
      }
      
      // Process cafeteria heaters
      final cafeteriaHeaters = heaterEntries['cafeteria_heaters'] as List<dynamic>?;
      if (cafeteriaHeaters != null) {
        for (int i = 0; i < cafeteriaHeaters.length; i++) {
          final heater = cafeteriaHeaters[i];
          if (heater is Map<String, dynamic>) {
            final id = heater['id']?.toString() ?? '';
            
            if (id.isNotEmpty) {
              final heaterKey = 'cafeteria_heaters_$id';
              final quantity = count.itemCounts[heaterKey] ?? 0;
                          // Try to get capacity from textAnswers
            final capKey = '${heaterKey}_capacity';
            final capacity = count.textAnswers[capKey];
            
            final heaterData = <String, dynamic>{
              'count': quantity,
              'location': 'مقصف',
              'id': id,
              'capacity': capacity,
            };
              items[heaterKey] = heaterData;
            }
          }
        }
      }
    } else {
      // Fallback to old structure
      final mechanicalKeys = [
        'bathroom_heaters',
        'cafeteria_heaters',
        'sinks',
        'western_toilet',
        'arabic_toilet',
        'siphons',
        'bidets',
        'wall_exhaust_fans',
        'central_exhaust_fans',
        'cafeteria_exhaust_fans',
        'wall_water_coolers',
        'corridor_water_coolers',
        'water_pumps'
      ];

      // Add mechanical item counts
      count.itemCounts.forEach((key, value) {
        if (mechanicalKeys.contains(key)) {
          items[key] = value;
        }
      });

      // Add mechanical text answers
      count.textAnswers.forEach((key, value) {
        if (value.isNotEmpty && (
          key == 'water_meter_number' ||
          key == 'bathroom_heaters_capacity' ||
          key == 'cafeteria_heaters_capacity'
        )) {
          items[key] = value;
        }
      });
    }

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
    Map<String, dynamic> items = {};

    // Combine AC Panel data
    if (count.itemCounts.containsKey('ac_panel') ||
        count.textAnswers.containsKey('ac_panel_amperage')) {
      final acPanelData = <String, dynamic>{};
      
      if (count.itemCounts.containsKey('ac_panel')) {
        acPanelData['count'] = count.itemCounts['ac_panel'];
      }
      if (count.textAnswers.containsKey('ac_panel_amperage') && 
          count.textAnswers['ac_panel_amperage']!.isNotEmpty) {
        acPanelData['amperage'] = count.textAnswers['ac_panel_amperage'];
      }
      
      if (acPanelData.isNotEmpty) {
        items['ac_panel_combined'] = acPanelData;
      }
    }

    // Combine Power Panel data
    if (count.itemCounts.containsKey('power_panel') ||
        count.textAnswers.containsKey('power_panel_amperage')) {
      final powerPanelData = <String, dynamic>{};
      
      if (count.itemCounts.containsKey('power_panel')) {
        powerPanelData['count'] = count.itemCounts['power_panel'];
      }
      if (count.textAnswers.containsKey('power_panel_amperage') && 
          count.textAnswers['power_panel_amperage']!.isNotEmpty) {
        powerPanelData['amperage'] = count.textAnswers['power_panel_amperage'];
      }
      
      if (powerPanelData.isNotEmpty) {
        items['power_panel_combined'] = powerPanelData;
      }
    }

    // Combine Main Breaker data
    if (count.itemCounts.containsKey('main_breaker') ||
        count.textAnswers.containsKey('main_breaker_amperage')) {
      final mainBreakerData = <String, dynamic>{};
      
      if (count.itemCounts.containsKey('main_breaker')) {
        mainBreakerData['count'] = count.itemCounts['main_breaker'];
      }
      if (count.textAnswers.containsKey('main_breaker_amperage') && 
          count.textAnswers['main_breaker_amperage']!.isNotEmpty) {
        mainBreakerData['amperage'] = count.textAnswers['main_breaker_amperage'];
      }
      
      if (mainBreakerData.isNotEmpty) {
        items['main_breaker_combined'] = mainBreakerData;
      }
    }

    // Combine Lighting Panel data
    if (count.itemCounts.containsKey('lighting_panel') ||
        count.textAnswers.containsKey('lighting_panel_amperage')) {
      final lightingPanelData = <String, dynamic>{};
      
      if (count.itemCounts.containsKey('lighting_panel')) {
        lightingPanelData['count'] = count.itemCounts['lighting_panel'];
      }
      if (count.textAnswers.containsKey('lighting_panel_amperage') && 
          count.textAnswers['lighting_panel_amperage']!.isNotEmpty) {
        lightingPanelData['amperage'] = count.textAnswers['lighting_panel_amperage'];
      }
      
      if (lightingPanelData.isNotEmpty) {
        items['lighting_panel_combined'] = lightingPanelData;
      }
    }

    // Combine Main Distribution Panel data
    if (count.itemCounts.containsKey('main_distribution_panel') ||
        count.textAnswers.containsKey('main_distribution_panel_amperage')) {
      final mainDistPanelData = <String, dynamic>{};
      
      if (count.itemCounts.containsKey('main_distribution_panel')) {
        mainDistPanelData['count'] = count.itemCounts['main_distribution_panel'];
      }
      if (count.textAnswers.containsKey('main_distribution_panel_amperage') && 
          count.textAnswers['main_distribution_panel_amperage']!.isNotEmpty) {
        mainDistPanelData['amperage'] = count.textAnswers['main_distribution_panel_amperage'];
      }
      
      if (mainDistPanelData.isNotEmpty) {
        items['main_distribution_panel_combined'] = mainDistPanelData;
      }
    }

    // Combine Package AC Breaker data
    if (count.itemCounts.containsKey('package_ac_breaker') ||
        count.textAnswers.containsKey('package_ac_breaker_amperage')) {
      final packageAcBreakerData = <String, dynamic>{};
      
      if (count.itemCounts.containsKey('package_ac_breaker')) {
        packageAcBreakerData['count'] = count.itemCounts['package_ac_breaker'];
      }
      if (count.textAnswers.containsKey('package_ac_breaker_amperage') && 
          count.textAnswers['package_ac_breaker_amperage']!.isNotEmpty) {
        packageAcBreakerData['amperage'] = count.textAnswers['package_ac_breaker_amperage'];
      }
      
      if (packageAcBreakerData.isNotEmpty) {
        items['package_ac_breaker_combined'] = packageAcBreakerData;
      }
    }

    // Combine Concealed AC Breaker data
    if (count.itemCounts.containsKey('concealed_ac_breaker') ||
        count.textAnswers.containsKey('concealed_ac_breaker_amperage')) {
      final concealedAcBreakerData = <String, dynamic>{};
      
      if (count.itemCounts.containsKey('concealed_ac_breaker')) {
        concealedAcBreakerData['count'] = count.itemCounts['concealed_ac_breaker'];
      }
      if (count.textAnswers.containsKey('concealed_ac_breaker_amperage') && 
          count.textAnswers['concealed_ac_breaker_amperage']!.isNotEmpty) {
        concealedAcBreakerData['amperage'] = count.textAnswers['concealed_ac_breaker_amperage'];
      }
      
      if (concealedAcBreakerData.isNotEmpty) {
        items['concealed_ac_breaker_combined'] = concealedAcBreakerData;
      }
    }

    // Add simple items that don't need combination
    final simpleElectricalKeys = [
      'lamps',
      'projector', 
      'class_bell',
      'speakers',
      'microphone_system',
      'electrical_panels'
    ];

    count.itemCounts.forEach((key, value) {
      if (simpleElectricalKeys.contains(key)) {
        items[key] = value;
      }
    });

    // Add electricity meter number
    if (count.textAnswers.containsKey('electricity_meter_number') && 
        count.textAnswers['electricity_meter_number']!.isNotEmpty) {
      items['electricity_meter_number'] = count.textAnswers['electricity_meter_number'];
    }

    // Add elevator information
    if (count.textAnswers.containsKey('elevators_motor') && 
        count.textAnswers['elevators_motor']!.isNotEmpty) {
      items['elevators_motor'] = count.textAnswers['elevators_motor'];
    }
    if (count.textAnswers.containsKey('elevators_main_parts') && 
        count.textAnswers['elevators_main_parts']!.isNotEmpty) {
      items['elevators_main_parts'] = count.textAnswers['elevators_main_parts'];
    }

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
    final civilKeys = [
      'blackboard',
      'internal_windows',
      'external_windows'
    ];

    Map<String, dynamic> items = {};

    // Add civil item counts
    count.itemCounts.forEach((key, value) {
      if (civilKeys.contains(key)) {
        items[key] = value;
      }
    });

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
          if (photos.isNotEmpty) ...[
            GridView.builder(
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
                  onTap: () => _showPhotoDialog(context, photos[index]),
                  child: Container(
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
                  ),
                );
              },
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    color: color.withOpacity(0.6),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'لا توجد صور لهذا القسم',
                    style: TextStyle(
                      color: color.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  void _showPhotoDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: InteractiveViewer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
