import 'package:flutter/material.dart';
import '../../data/models/maintenance_count.dart';

class MaintenanceCountCategoryScreen extends StatelessWidget {
  final MaintenanceCount count;
  final String category;
  final String categoryTitle;
  final IconData categoryIcon;
  final Color categoryColor;
  final String schoolName;

  const MaintenanceCountCategoryScreen({
    super.key,
    required this.count,
    required this.category,
    required this.categoryTitle,
    required this.categoryIcon,
    required this.categoryColor,
    required this.schoolName,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            categoryTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              _buildCategoryContent(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: categoryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            categoryIcon,
            color: categoryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          schoolName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryContent(BuildContext context) {
    switch (category) {
      case 'safety':
        return _buildSafetyCategory(context);
      case 'mechanical':
        return _buildMechanicalCategory(context);
      case 'electrical':
        return _buildElectricalCategory(context);
      case 'civil':
        return _buildCivilCategory(context);
      default:
        return _buildEmptyState(context);
    }
  }

  Widget _buildSafetyCategory(BuildContext context) {
    final items = _getSafetyItems();
    final conditions = _getSafetyConditions();
    final photos = _getSafetyPhotos();
    final merged = _mergeItemsWithConditions(items, conditions);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (merged.isNotEmpty) ...[
          _buildSectionTitle('المعدات والأنظمة'),
          const SizedBox(height: 12),
          _buildItemsGrid(context, merged),
          const SizedBox(height: 24),
        ],
        if (photos.isNotEmpty) ...[
          _buildSectionTitle('الصور'),
          const SizedBox(height: 12),
          _buildPhotosSection(context, photos),
          const SizedBox(height: 24),
        ],
        if (merged.isEmpty && photos.isEmpty) _buildEmptyState(context),
      ],
    );
  }

  Widget _buildMechanicalCategory(BuildContext context) {
    final items = _getMechanicalItems();
    final conditions = _getMechanicalConditions();
    final photos = _getMechanicalPhotos();
    final merged = _mergeItemsWithConditions(items, conditions);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (merged.isNotEmpty) ...[
          _buildSectionTitle('المضخات والمعدات'),
          const SizedBox(height: 12),
          _buildItemsGrid(context, merged),
          const SizedBox(height: 24),
        ],
        if (photos.isNotEmpty) ...[
          _buildSectionTitle('الصور'),
          const SizedBox(height: 12),
          _buildPhotosSection(context, photos),
          const SizedBox(height: 24),
        ],
        if (merged.isEmpty && photos.isEmpty) _buildEmptyState(context),
      ],
    );
  }

  Widget _buildElectricalCategory(BuildContext context) {
    final items = _getElectricalItems();
    final conditions = _getElectricalConditions();
    final photos = _getElectricalPhotos();
    final merged = _mergeItemsWithConditions(items, conditions);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (merged.isNotEmpty) ...[
          _buildSectionTitle('الأنظمة الكهربائية'),
          const SizedBox(height: 12),
          _buildItemsGrid(context, merged),
          const SizedBox(height: 24),
        ],
        if (photos.isNotEmpty) ...[
          _buildSectionTitle('الصور'),
          const SizedBox(height: 12),
          _buildPhotosSection(context, photos),
          const SizedBox(height: 24),
        ],
        if (merged.isEmpty && photos.isEmpty) _buildEmptyState(context),
      ],
    );
  }

  Widget _buildCivilCategory(BuildContext context) {
    final items = _getCivilItems();
    final conditions = _getCivilConditions();
    final photos = _getCivilPhotos();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (items.isNotEmpty) ...[
          _buildSectionTitle('البنية التحتية'),
          const SizedBox(height: 12),
          _buildItemsGrid(context, items),
          const SizedBox(height: 24),
        ],
        if (conditions.isNotEmpty) ...[
          _buildSectionTitle('حالة البناء'),
          const SizedBox(height: 12),
          _buildConditionsGrid(context, conditions),
          const SizedBox(height: 24),
        ],
        if (photos.isNotEmpty) ...[
          _buildSectionTitle('الصور'),
          const SizedBox(height: 12),
          _buildPhotosSection(context, photos),
          const SizedBox(height: 24),
        ],
        if (items.isEmpty && conditions.isEmpty && photos.isEmpty)
          _buildEmptyState(context),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildItemsGrid(BuildContext context, Map<String, dynamic> items) {
    final entries = items.entries.toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 2.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return _buildItemCard(context, entry);
          },
        );
      },
    );
  }

  Widget _buildConditionsGrid(
      BuildContext context, Map<String, String> conditions) {
    final entries = conditions.entries.toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 3.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return _buildConditionCard(context, entry);
          },
        );
      },
    );
  }

  Widget _buildItemCard(BuildContext context, MapEntry<String, dynamic> entry) {
    final value = entry.value;
    String displayValue;

    // Special handling for combined data
    if (value is Map<String, dynamic>) {
      final parts = <String>[];

      if (entry.key == 'alarm_panel_combined') {
        if (value.containsKey('count')) {
          parts.add('العدد: ${value['count']}');
        }
        if (value.containsKey('type')) {
          parts.add('النوع: ${value['type']}');
        }
        if (value.containsKey('condition')) {
          parts.add('الحالة: ${value['condition']}');
        }
      } else {
        // Handle other combined items (pumps, fire boxes)
        if (value.containsKey('count')) {
          parts.add('العدد: ${value['count']}');
        }
        if (value.containsKey('condition')) {
          parts.add('الحالة: ${value['condition']}');
        }
      }

      displayValue = parts.join('\n');
    } else {
      displayValue = value is bool ? (value ? 'نعم' : 'لا') : '$value';
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : Colors.white;

    // Get note for this item
    final note = _getItemNote(entry.key);

    // Special handling for fire extinguisher
    final isFireExtinguisher = entry.key == 'fire_extinguishers';
    final fireExtinguisherExpiryDate = _getFireExtinguisherExpiryDate();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardColor.withOpacity(0.9),
            cardColor.withOpacity(0.7),
          ],
        ),
        border: Border.all(
          color: categoryColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: categoryColor.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.white.withOpacity(0.8),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        categoryColor.withOpacity(0.2),
                        categoryColor.withOpacity(0.1),
                      ],
                    ),
                    border: Border.all(
                      color: categoryColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    _getItemIcon(entry.key),
                    color: categoryColor,
                    size: 18,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: categoryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    displayValue,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _translateItemName(entry.key),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // Fire extinguisher expiry date
            if (isFireExtinguisher &&
                fireExtinguisherExpiryDate.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 12,
                      color: const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'انتهاء: $fireExtinguisherExpiryDate',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Note if exists
            if (note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.note_alt_rounded,
                      size: 12,
                      color: const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        note,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF10B981),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConditionCard(
      BuildContext context, MapEntry<String, String> entry) {
    final conditionColor = _getConditionColor(entry.value);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final note = _getItemNote(entry.key);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardColor.withOpacity(0.9),
            cardColor.withOpacity(0.7),
          ],
        ),
        border: Border.all(
          color: conditionColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: conditionColor.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.white.withOpacity(0.8),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        conditionColor.withOpacity(0.2),
                        conditionColor.withOpacity(0.1),
                      ],
                    ),
                    border: Border.all(
                      color: conditionColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    _getConditionIcon(entry.value),
                    color: conditionColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _translateItemName(entry.key),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            // Note if exists
            if (note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.note_alt_rounded,
                      size: 12,
                      color: const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        note,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF10B981),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
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

  Widget _buildPhotosSection(BuildContext context, List<String> photos) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        itemBuilder: (context, index) {
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _showPhotoDialog(context, photos[index]),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  photos[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.error_outline,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context, Map<String, String> notes) {
    return Column(
      children: notes.entries.map((entry) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _translateItemName(entry.key),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                entry.value,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              categoryIcon,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد بيانات في هذا القسم',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
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

  // Helper methods for data extraction
  Map<String, dynamic> _getSafetyItems() {
    Map<String, dynamic> items = {};

    // Combine fire boxes with their condition
    if (count.itemCounts.containsKey('fire_boxes') ||
        count.surveyAnswers.containsKey('fire_boxes_condition')) {
      final fireBoxesData = <String, dynamic>{};

      if (count.itemCounts.containsKey('fire_boxes')) {
        fireBoxesData['count'] = count.itemCounts['fire_boxes'];
      }
      if (count.surveyAnswers.containsKey('fire_boxes_condition')) {
        fireBoxesData['condition'] =
            count.surveyAnswers['fire_boxes_condition'];
      }

      items['fire_boxes_combined'] = fireBoxesData;
    }

    // Keep fire extinguishers as is (already has expiry date handling)
    if (count.itemCounts.containsKey('fire_extinguishers')) {
      items['fire_extinguishers'] = count.itemCounts['fire_extinguishers'];
    }

    // Combine diesel pump with its condition
    if (count.itemCounts.containsKey('diesel_pump') ||
        count.surveyAnswers.containsKey('diesel_pump_condition')) {
      final dieselPumpData = <String, dynamic>{};

      if (count.itemCounts.containsKey('diesel_pump')) {
        dieselPumpData['count'] = count.itemCounts['diesel_pump'];
      }
      if (count.surveyAnswers.containsKey('diesel_pump_condition')) {
        dieselPumpData['condition'] =
            count.surveyAnswers['diesel_pump_condition'];
      }

      items['diesel_pump_combined'] = dieselPumpData;
    }

    // Combine electric pump with its condition
    if (count.itemCounts.containsKey('electric_pump') ||
        count.surveyAnswers.containsKey('electric_pump_condition')) {
      final electricPumpData = <String, dynamic>{};

      if (count.itemCounts.containsKey('electric_pump')) {
        electricPumpData['count'] = count.itemCounts['electric_pump'];
      }
      if (count.surveyAnswers.containsKey('electric_pump_condition')) {
        electricPumpData['condition'] =
            count.surveyAnswers['electric_pump_condition'];
      }

      items['electric_pump_combined'] = electricPumpData;
    }

    // Combine auxiliary pump with its condition
    if (count.itemCounts.containsKey('auxiliary_pump') ||
        count.surveyAnswers.containsKey('auxiliary_pump_condition')) {
      final auxiliaryPumpData = <String, dynamic>{};

      if (count.itemCounts.containsKey('auxiliary_pump')) {
        auxiliaryPumpData['count'] = count.itemCounts['auxiliary_pump'];
      }
      if (count.surveyAnswers.containsKey('auxiliary_pump_condition')) {
        auxiliaryPumpData['condition'] =
            count.surveyAnswers['auxiliary_pump_condition'];
      }

      items['auxiliary_pump_combined'] = auxiliaryPumpData;
    }

    // Combine alarm panel data into a single item
    if (count.fireSafetyAlarmPanelData.isNotEmpty) {
      final alarmPanelData = <String, dynamic>{};

      // Combine all alarm panel information
      if (count.fireSafetyAlarmPanelData.containsKey('alarm_panel_type')) {
        alarmPanelData['type'] =
            count.fireSafetyAlarmPanelData['alarm_panel_type'];
      }
      if (count.fireSafetyAlarmPanelData.containsKey('alarm_panel_count')) {
        alarmPanelData['count'] =
            count.fireSafetyAlarmPanelData['alarm_panel_count'];
      }

      // Add condition from survey answers
      if (count.surveyAnswers.containsKey('alarm_panel_condition')) {
        alarmPanelData['condition'] =
            count.surveyAnswers['alarm_panel_condition'];
      }

      if (alarmPanelData.isNotEmpty) {
        items['alarm_panel_combined'] = alarmPanelData;
      }
    }

    return items;
  }

  Map<String, String> _getSafetyConditions() {
    final safetyKeys = [
      'fire_alarm_system_condition',
      // 'fire_boxes_condition', // Now part of combined fire boxes item
      'fire_suppression_system_condition',
      'emergency_exits_condition',
      'emergency_lights_condition',
      'smoke_detectors_condition',
      'heat_detectors_condition',
      'break_glasses_bells_condition',
      // 'alarm_panel_condition', // Now part of combined alarm panel item
      // 'diesel_pump_condition', // Now part of combined diesel pump item
      // 'electric_pump_condition', // Now part of combined electric pump item
      // 'auxiliary_pump_condition' // Now part of combined auxiliary pump item
    ];

    Map<String, String> conditions = {};
    count.surveyAnswers.forEach((key, value) {
      if (safetyKeys.contains(key)) {
        conditions[key] = value;
      }
    });

    return conditions;
  }

  List<String> _getSafetyPhotos() {
    return count.sectionPhotos['fire_safety'] ?? [];
  }

  Map<String, String> _getSafetyNotes() {
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

  Map<String, dynamic> _getMechanicalItems() {
    final mechanicalKeys = ['water_pumps'];

    Map<String, dynamic> items = {};
    count.itemCounts.forEach((key, value) {
      if (mechanicalKeys.contains(key)) {
        items[key] = value;
      }
    });

    count.textAnswers.forEach((key, value) {
      if (key == 'water_meter_number' && value.isNotEmpty) {
        items[key] = value;
      }
    });

    return items;
  }

  Map<String, String> _getMechanicalConditions() {
    final mechanicalKeys = ['water_pumps_condition'];

    Map<String, String> conditions = {};
    count.surveyAnswers.forEach((key, value) {
      if (mechanicalKeys.contains(key)) {
        conditions[key] = value;
      }
    });

    return conditions;
  }

  List<String> _getMechanicalPhotos() {
    return count.sectionPhotos['mechanical'] ?? [];
  }

  Map<String, String> _getMechanicalNotes() {
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

  Map<String, dynamic> _getElectricalItems() {
    final electricalKeys = ['electrical_panels'];

    Map<String, dynamic> items = {};
    count.itemCounts.forEach((key, value) {
      if (electricalKeys.contains(key)) {
        items[key] = value;
      }
    });

    count.textAnswers.forEach((key, value) {
      if (key == 'electricity_meter_number' && value.isNotEmpty) {
        items[key] = value;
      }
    });

    return items;
  }

  Map<String, String> _getElectricalConditions() {
    final electricalKeys = ['electrical_panels_condition'];

    Map<String, String> conditions = {};
    count.surveyAnswers.forEach((key, value) {
      if (electricalKeys.contains(key)) {
        conditions[key] = value;
      }
    });

    return conditions;
  }

  List<String> _getElectricalPhotos() {
    return count.sectionPhotos['electrical'] ?? [];
  }

  Map<String, String> _getElectricalNotes() {
    final electricalKeys = ['electrical_panels_note'];

    Map<String, String> notes = {};
    count.maintenanceNotes.forEach((key, value) {
      if (electricalKeys.contains(key) && value.isNotEmpty) {
        notes[key] = value;
      }
    });

    return notes;
  }

  Map<String, dynamic> _getCivilItems() {
    Map<String, dynamic> items = {};
    count.yesNoAnswers.forEach((key, value) {
      items[key] = value;
    });
    return items;
  }

  Map<String, String> _getCivilConditions() {
    return {};
  }

  List<String> _getCivilPhotos() {
    return count.sectionPhotos['civil'] ?? [];
  }

  Map<String, String> _getCivilNotes() {
    final civilKeys = ['building_note', 'structure_note'];

    Map<String, String> notes = {};
    count.maintenanceNotes.forEach((key, value) {
      if (civilKeys.contains(key) && value.isNotEmpty) {
        notes[key] = value;
      }
    });

    return notes;
  }

  Map<String, dynamic> _mergeItemsWithConditions(
    Map<String, dynamic> items,
    Map<String, String> conditions,
  ) {
    final merged = Map<String, dynamic>.from(items);
    merged.addAll(conditions);
    return merged;
  }

  Color _getConditionColor(String condition) {
    switch (condition) {
      case 'جيد':
        return Colors.green;
      case 'يحتاج صيانة':
        return Colors.orange;
      case 'تالف':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getItemNote(String key) {
    // Get corresponding note key for the item
    String noteKey = '';
    switch (key) {
      case 'fire_alarm_system':
      case 'fire_alarm_system_condition':
        noteKey = 'fire_alarm_system_note';
        break;
      case 'fire_suppression_system':
      case 'fire_suppression_system_condition':
        noteKey = 'fire_suppression_system_note';
        break;
      case 'emergency_exits':
      case 'emergency_exits_condition':
        noteKey = 'emergency_exits_note';
        break;
      case 'emergency_lights_condition':
        noteKey = 'emergency_lights_note';
        break;
      case 'smoke_detectors_condition':
        noteKey = 'smoke_detectors_note';
        break;
      case 'heat_detectors_condition':
        noteKey = 'heat_detectors_note';
        break;
      case 'break_glasses_bells_condition':
        noteKey = 'break_glasses_bells_note';
        break;
      case 'alarm_panel_condition':
      case 'alarm_panel_type':
      case 'alarm_panel_count':
      case 'alarm_panel_combined':
        noteKey = 'alarm_panel_note';
        break;
      case 'fire_boxes':
      case 'fire_boxes_condition':
      case 'fire_boxes_combined':
        noteKey = 'fire_boxes_note';
        break;
      case 'diesel_pump':
      case 'diesel_pump_condition':
      case 'diesel_pump_combined':
        noteKey = 'diesel_pump_note';
        break;
      case 'electric_pump':
      case 'electric_pump_condition':
      case 'electric_pump_combined':
        noteKey = 'electric_pump_note';
        break;
      case 'auxiliary_pump':
      case 'auxiliary_pump_condition':
      case 'auxiliary_pump_combined':
        noteKey = 'auxiliary_pump_note';
        break;
    }

    return count.maintenanceNotes[noteKey] ?? '';
  }

  String _getFireExtinguisherExpiryDate() {
    final day = count.textAnswers['fire_extinguishers_expiry_day'] ?? '';
    final month = count.textAnswers['fire_extinguishers_expiry_month'] ?? '';
    final year = count.textAnswers['fire_extinguishers_expiry_year'] ?? '';

    if (day.isNotEmpty && month.isNotEmpty && year.isNotEmpty) {
      return '$day/$month/$year';
    }
    return '';
  }

  IconData _getItemIcon(String key) {
    switch (key) {
      case 'fire_boxes':
      case 'fire_boxes_condition':
      case 'fire_boxes_combined':
        return Icons.inbox_rounded;
      case 'fire_extinguishers':
        return Icons.local_fire_department_rounded;
      case 'diesel_pump':
      case 'diesel_pump_condition':
      case 'diesel_pump_combined':
        return Icons.local_gas_station_rounded;
      case 'electric_pump':
      case 'electric_pump_condition':
      case 'electric_pump_combined':
        return Icons.power_rounded;
      case 'auxiliary_pump':
      case 'auxiliary_pump_condition':
      case 'auxiliary_pump_combined':
        return Icons.backup_rounded;
      case 'water_pumps':
      case 'water_pumps_condition':
        return Icons.water_damage_rounded;
      case 'electrical_panels':
      case 'electrical_panels_condition':
        return Icons.electrical_services_rounded;
      case 'fire_alarm_system':
      case 'fire_alarm_system_condition':
        return Icons.alarm_rounded;
      case 'fire_suppression_system':
      case 'fire_suppression_system_condition':
        return Icons.security_rounded;
      case 'emergency_exits':
      case 'emergency_exits_condition':
        return Icons.exit_to_app_rounded;
      case 'emergency_lights_condition':
        return Icons.lightbulb_rounded;
      case 'smoke_detectors_condition':
        return Icons.smoke_free_rounded;
      case 'heat_detectors_condition':
        return Icons.thermostat_rounded;
      case 'break_glasses_bells_condition':
        return Icons.notification_important_rounded;
      case 'alarm_panel_type':
      case 'alarm_panel_count':
      case 'alarm_panel_condition':
      case 'alarm_panel_combined':
        return Icons.dashboard_rounded;
      case 'water_meter_number':
        return Icons.water_drop_rounded;
      case 'electricity_meter_number':
        return Icons.electric_bolt_rounded;
      case 'wall_cracks':
        return Icons.broken_image_rounded;
      case 'has_elevators':
        return Icons.elevator_rounded;
      case 'falling_shades':
        return Icons.warning_rounded;
      case 'has_water_leaks':
        return Icons.water_rounded;
      case 'low_railing_height':
        return Icons.fence_rounded;
      case 'concrete_rust_damage':
        return Icons.construction_rounded;
      case 'roof_insulation_damage':
        return Icons.roofing_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String _translateItemName(String key) {
    const translations = {
      // Item counts
      'fire_boxes': 'صناديق الحريق',
      'fire_boxes_combined': 'صناديق الحريق',
      'diesel_pump': 'مضخة الديزل',
      'diesel_pump_combined': 'مضخة الديزل',
      'water_pumps': 'مضخات المياه',
      'electric_pump': 'المضخة الكهربائية',
      'electric_pump_combined': 'المضخة الكهربائية',
      'auxiliary_pump': 'المضخة المساعدة',
      'auxiliary_pump_combined': 'المضخة المساعدة',
      'electrical_panels': 'اللوحات الكهربائية',
      'fire_extinguishers': 'طفايات الحريق',

      // Survey answers
      'emergency_exits': 'مخارج الطوارئ',
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
      'fire_extinguishers_expiry_date': 'تاريخ انتهاء طفايات الحريق',

      // Fire safety alarm panel
      'alarm_panel_type': 'نوع لوحة الإنذار',
      'alarm_panel_count': 'عدد لوحات الإنذار',
      'alarm_panel_condition': 'حالة لوحة الإنذار',
      'alarm_panel_combined': 'لوحة إنذار الحريق',

      // Notes
      'alarm_panel_note': 'ملاحظة لوحة الإنذار',
      'heat_detectors_note': 'ملاحظة أجهزة استشعار الحرارة',
      'emergency_exits_note': 'ملاحظة مخارج الطوارئ',
      'smoke_detectors_note': 'ملاحظة أجهزة استشعار الدخان',
      'emergency_lights_note': 'ملاحظة أضواء الطوارئ',
      'fire_alarm_system_note': 'ملاحظة نظام إنذار الحريق',
      'break_glasses_bells_note': 'ملاحظة أجراس كسر الزجاج',
      'fire_suppression_system_note': 'ملاحظة نظام إطفاء الحريق',
      'building_note': 'ملاحظة البناء',
      'structure_note': 'ملاحظة الهيكل',
    };

    return translations[key] ?? key;
  }
}
