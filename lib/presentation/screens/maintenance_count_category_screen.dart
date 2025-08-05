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
      case 'air_conditioning':
        return _buildAirConditioningCategory(context);
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

  Widget _buildAirConditioningCategory(BuildContext context) {
    final items = _getAirConditioningItems();
    final conditions = _getAirConditioningConditions();
    final photos = _getAirConditioningPhotos();
    final merged = _mergeItemsWithConditions(items, conditions);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (merged.isNotEmpty) ...[
          _buildSectionTitle('أنظمة التكييف'),
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
      } else if (entry.key == 'fire_extinguishers_combined') {
        if (value.containsKey('count')) {
          parts.add('العدد: ${value['count']}');
        }
        if (value.containsKey('expiry_date')) {
          parts.add('تاريخ الانتهاء: ${value['expiry_date']}');
        }
      } else if (entry.key == 'ac_panel_combined' || 
                 entry.key == 'power_panel_combined' ||
                 entry.key == 'main_breaker_combined' ||
                 entry.key == 'lighting_panel_combined' ||
                 entry.key == 'main_distribution_panel_combined' ||
                 entry.key == 'package_ac_breaker_combined' ||
                 entry.key == 'concealed_ac_breaker_combined') {
        if (value.containsKey('count')) {
          parts.add('العدد: ${value['count']}');
        }
        if (value.containsKey('amperage')) {
          parts.add('الأمبير: ${value['amperage']}');
        }
      } else if (entry.key == 'breakers_combined' ||
                 entry.key == 'bells_combined' ||
                 entry.key == 'break_glasses_bells_combined' ||
                 entry.key == 'smoke_detectors_combined' ||
                 entry.key == 'heat_detectors_combined' ||
                 entry.key == 'emergency_exits_combined' ||
                 entry.key == 'emergency_lights_combined') {
        if (value.containsKey('count')) {
          parts.add('العدد: ${value['count']}');
        }
        if (value.containsKey('condition')) {
          parts.add('الحالة: ${value['condition']}');
        }
      } else if (entry.key == 'bathroom_heaters_combined' ||
                 entry.key == 'cafeteria_heaters_combined') {
        if (value.containsKey('count')) {
          parts.add('العدد: ${value['count']}');
        }
        if (value.containsKey('capacity')) {
          parts.add('السعة: ${value['capacity']}');
        }
      } else if (entry.key == 'water_pumps_combined') {
        if (value.containsKey('count')) {
          parts.add('العدد: ${value['count']}');
        }
        if (value.containsKey('condition')) {
          parts.add('الحالة: ${value['condition']}');
        }
      } else if (entry.key.startsWith('bathroom_heaters_') ||
                 entry.key.startsWith('cafeteria_heaters_')) {
        if (value.containsKey('count')) {
          parts.add('العدد: ${value['count']}');
        }
        if (value.containsKey('location')) {
          parts.add('الموقع: ${value['location']}');
        }
        if (value.containsKey('id')) {
          // Try to get capacity from textAnswers
          final heaterId = value['id'] as String? ?? '';
          final location = value['location'] as String? ?? '';
          String? capacity;
          
          // Look for capacity in textAnswers
          final capKey = '${entry.key}_capacity';
          final capValue = count.textAnswers[capKey];
          if (capValue != null && capValue.isNotEmpty) {
            capacity = capValue;
          }
          
          if (capacity != null && capacity.isNotEmpty) {
            parts.add('السعة: $capacity لتر');
          } else {
            parts.add('الرقم: $heaterId');
          }
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
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
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
    if (photos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.photo_library_outlined,
              color: Colors.grey.withOpacity(0.6),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'لا توجد صور لهذا القسم',
              style: TextStyle(
                color: Colors.grey.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

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
          onTap: () => _showPhotoDialog(context, photos[index]),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
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

    // Add fire hose (new item)
    if (count.itemCounts.containsKey('fire_hose')) {
      items['fire_hose'] = count.itemCounts['fire_hose'];
    }

    // Add fire hose condition from survey answers
    if (count.surveyAnswers.containsKey('fire_hose_condition')) {
      items['fire_hose_condition'] = count.surveyAnswers['fire_hose_condition'];
    }

    // Combine fire extinguishers with expiry dates
    if (count.itemCounts.containsKey('fire_extinguishers') ||
        count.textAnswers.containsKey('fire_extinguishers_expiry_day') ||
        count.textAnswers.containsKey('fire_extinguishers_expiry_month') ||
        count.textAnswers.containsKey('fire_extinguishers_expiry_year')) {
      final fireExtinguishersData = <String, dynamic>{};

      if (count.itemCounts.containsKey('fire_extinguishers')) {
        fireExtinguishersData['count'] = count.itemCounts['fire_extinguishers'];
      }

      // Combine expiry date parts
      final day = count.textAnswers['fire_extinguishers_expiry_day'] ?? '';
      final month = count.textAnswers['fire_extinguishers_expiry_month'] ?? '';
      final year = count.textAnswers['fire_extinguishers_expiry_year'] ?? '';
      
      if (day.isNotEmpty || month.isNotEmpty || year.isNotEmpty) {
        final expiryDate = [day, month, year].where((part) => part.isNotEmpty).join('/');
        if (expiryDate.isNotEmpty) {
          fireExtinguishersData['expiry_date'] = expiryDate;
        }
      }

      if (fireExtinguishersData.isNotEmpty) {
        items['fire_extinguishers_combined'] = fireExtinguishersData;
      }
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
    if (count.fireSafetyAlarmPanelData.isNotEmpty ||
        count.surveyAnswers.containsKey('alarm_panel_type') ||
        count.surveyAnswers.containsKey('alarm_panel_condition')) {
      final alarmPanelData = <String, dynamic>{};

      // Combine all alarm panel information
      if (count.fireSafetyAlarmPanelData.containsKey('alarm_panel_type')) {
        alarmPanelData['type'] =
            count.fireSafetyAlarmPanelData['alarm_panel_type'];
      }
      if (count.surveyAnswers.containsKey('alarm_panel_type')) {
        alarmPanelData['type'] = count.surveyAnswers['alarm_panel_type'];
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

    // Create combined items for emergency exits and emergency lights
    if (count.itemCounts.containsKey('emergency_exits') ||
        count.surveyAnswers.containsKey('emergency_exits_condition')) {
      final emergencyExitsData = <String, dynamic>{};
      
      if (count.itemCounts.containsKey('emergency_exits')) {
        emergencyExitsData['count'] = count.itemCounts['emergency_exits'];
      }
      if (count.surveyAnswers.containsKey('emergency_exits_condition')) {
        emergencyExitsData['condition'] = count.surveyAnswers['emergency_exits_condition'];
      }
      
      if (emergencyExitsData.isNotEmpty) {
        items['emergency_exits_combined'] = emergencyExitsData;
      }
    }

    if (count.itemCounts.containsKey('emergency_lights') ||
        count.surveyAnswers.containsKey('emergency_lights_condition')) {
      final emergencyLightsData = <String, dynamic>{};
      
      if (count.itemCounts.containsKey('emergency_lights')) {
        emergencyLightsData['count'] = count.itemCounts['emergency_lights'];
      }
      if (count.surveyAnswers.containsKey('emergency_lights_condition')) {
        emergencyLightsData['condition'] = count.surveyAnswers['emergency_lights_condition'];
      }
      
      if (emergencyLightsData.isNotEmpty) {
        items['emergency_lights_combined'] = emergencyLightsData;
      }
    }

    // Add new safety items with counts
    final newSafetyItems = [
      'emergency_signs',
      'camera',
      'break_glasses_bells'
    ];

    count.itemCounts.forEach((key, value) {
      if (newSafetyItems.contains(key)) {
        items[key] = value;
      }
    });

    // Create combined items for items with both count and status
    // Breakers
    if (count.itemCounts.containsKey('breakers') ||
        count.surveyAnswers.containsKey('breakers_condition')) {
      final breakersData = <String, dynamic>{};
      
      if (count.itemCounts.containsKey('breakers')) {
        breakersData['count'] = count.itemCounts['breakers'];
      }
      if (count.surveyAnswers.containsKey('breakers_condition')) {
        breakersData['condition'] = count.surveyAnswers['breakers_condition'];
      }
      
      if (breakersData.isNotEmpty) {
        items['breakers_combined'] = breakersData;
      }
    }

    // Bells
    if (count.itemCounts.containsKey('bells') ||
        count.surveyAnswers.containsKey('break_glasses_bells_condition')) {
      final bellsData = <String, dynamic>{};
      
      if (count.itemCounts.containsKey('bells')) {
        bellsData['count'] = count.itemCounts['bells'];
      }
      if (count.surveyAnswers.containsKey('break_glasses_bells_condition')) {
        bellsData['condition'] = count.surveyAnswers['break_glasses_bells_condition'];
      }
      
      if (bellsData.isNotEmpty) {
        items['bells_combined'] = bellsData;
      }
    }

    // Break glasses bells
    if (count.itemCounts.containsKey('break_glasses_bells') ||
        count.surveyAnswers.containsKey('break_glasses_bells_condition')) {
      final breakGlassesBellsData = <String, dynamic>{};
      
      if (count.itemCounts.containsKey('break_glasses_bells')) {
        breakGlassesBellsData['count'] = count.itemCounts['break_glasses_bells'];
      }
      if (count.surveyAnswers.containsKey('break_glasses_bells_condition')) {
        breakGlassesBellsData['condition'] = count.surveyAnswers['break_glasses_bells_condition'];
      }
      
      if (breakGlassesBellsData.isNotEmpty) {
        items['break_glasses_bells_combined'] = breakGlassesBellsData;
      }
    }

    // Smoke detectors
    if (count.itemCounts.containsKey('smoke_detectors') ||
        count.surveyAnswers.containsKey('smoke_detectors_condition')) {
      final smokeDetectorsData = <String, dynamic>{};
      
      if (count.itemCounts.containsKey('smoke_detectors')) {
        smokeDetectorsData['count'] = count.itemCounts['smoke_detectors'];
      }
      if (count.surveyAnswers.containsKey('smoke_detectors_condition')) {
        smokeDetectorsData['condition'] = count.surveyAnswers['smoke_detectors_condition'];
      }
      
      if (smokeDetectorsData.isNotEmpty) {
        items['smoke_detectors_combined'] = smokeDetectorsData;
      }
    }

    // Heat detectors
    if (count.itemCounts.containsKey('heat_detectors') ||
        count.surveyAnswers.containsKey('heat_detectors_condition')) {
      final heatDetectorsData = <String, dynamic>{};
      
      if (count.itemCounts.containsKey('heat_detectors')) {
        heatDetectorsData['count'] = count.itemCounts['heat_detectors'];
      }
      if (count.surveyAnswers.containsKey('heat_detectors_condition')) {
        heatDetectorsData['condition'] = count.surveyAnswers['heat_detectors_condition'];
      }
      
      if (heatDetectorsData.isNotEmpty) {
        items['heat_detectors_combined'] = heatDetectorsData;
      }
    }

    // Add survey answers for safety systems
    final safetySurveyKeys = [
      'fire_alarm_system',
      'fire_suppression_system',
      'heat_detectors_condition',
      'emergency_exits_condition',
      'smoke_detectors_condition',
      'emergency_lights_condition',
      'fire_alarm_system_condition',
      'break_glasses_bells_condition',
      'fire_suppression_system_condition'
    ];

    count.surveyAnswers.forEach((key, value) {
      if (safetySurveyKeys.contains(key)) {
        items[key] = value;
      }
    });

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
    Map<String, dynamic> items = {};

    // Handle new heater entries structure
    final heaterEntries = count.heaterEntries;
    print('UI - Heater entries: $heaterEntries'); // Debug
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
              final heaterData = <String, dynamic>{
                'count': quantity,
                'location': 'حمام',
                'id': id,
              };
              
              // Add capacity if available
              final capacityKey = 'bathroom_heaters_${id}_capacity';
              final capacity = count.textAnswers[capacityKey];
              if (capacity != null && capacity.isNotEmpty) {
                heaterData['capacity'] = '$capacity لتر';
              }
              
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
              final heaterData = <String, dynamic>{
                'count': quantity,
                'location': 'مقصف',
                'id': id,
              };
              
              // Add capacity if available
              final capacityKey = 'cafeteria_heaters_${id}_capacity';
              final capacity = count.textAnswers[capacityKey];
              if (capacity != null && capacity.isNotEmpty) {
                heaterData['capacity'] = '$capacity لتر';
              }
              
              items[heaterKey] = heaterData;
            }
          }
        }
      }
    } else {
      // Fallback to old structure
      // Combine Bathroom Heaters data
      if (count.itemCounts.containsKey('bathroom_heaters') ||
          count.textAnswers.containsKey('bathroom_heaters_capacity')) {
        final bathroomHeatersData = <String, dynamic>{};
        
        if (count.itemCounts.containsKey('bathroom_heaters')) {
          bathroomHeatersData['count'] = count.itemCounts['bathroom_heaters'];
        }
        if (count.textAnswers.containsKey('bathroom_heaters_capacity') && 
            count.textAnswers['bathroom_heaters_capacity']!.isNotEmpty) {
          bathroomHeatersData['capacity'] = count.textAnswers['bathroom_heaters_capacity'];
        }
        
        if (bathroomHeatersData.isNotEmpty) {
          items['bathroom_heaters_combined'] = bathroomHeatersData;
        }
      }

      // Combine Cafeteria Heaters data
      if (count.itemCounts.containsKey('cafeteria_heaters') ||
          count.textAnswers.containsKey('cafeteria_heaters_capacity')) {
        final cafeteriaHeatersData = <String, dynamic>{};
        
        if (count.itemCounts.containsKey('cafeteria_heaters')) {
          cafeteriaHeatersData['count'] = count.itemCounts['cafeteria_heaters'];
        }
        if (count.textAnswers.containsKey('cafeteria_heaters_capacity') && 
            count.textAnswers['cafeteria_heaters_capacity']!.isNotEmpty) {
          cafeteriaHeatersData['capacity'] = count.textAnswers['cafeteria_heaters_capacity'];
        }
        
        if (cafeteriaHeatersData.isNotEmpty) {
          items['cafeteria_heaters_combined'] = cafeteriaHeatersData;
        }
      }
    }

    // Add simple mechanical items that don't need combination
    final simpleMechanicalKeys = [
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
      'sink_mirrors',
      'wall_tap',
      'sink_tap'
    ];

    count.itemCounts.forEach((key, value) {
      if (simpleMechanicalKeys.contains(key)) {
        items[key] = value;
      }
    });

    // Create combined item for water pumps
    if (count.itemCounts.containsKey('water_pumps') ||
        count.surveyAnswers.containsKey('water_pumps_condition')) {
      final waterPumpsData = <String, dynamic>{};
      
      if (count.itemCounts.containsKey('water_pumps')) {
        waterPumpsData['count'] = count.itemCounts['water_pumps'];
      }
      if (count.surveyAnswers.containsKey('water_pumps_condition')) {
        waterPumpsData['condition'] = count.surveyAnswers['water_pumps_condition'];
      }
      
      if (waterPumpsData.isNotEmpty) {
        items['water_pumps_combined'] = waterPumpsData;
      }
    }

    // Add water meter number
    if (count.textAnswers.containsKey('water_meter_number') && 
        count.textAnswers['water_meter_number']!.isNotEmpty) {
      items['water_meter_number'] = count.textAnswers['water_meter_number'];
    }

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
    Map<String, dynamic> items = {};

    // Note: AC Panel data is now handled in the Air Conditioning category

    // Add electrical items (excluding AC units - those go to Air Conditioning category)
    if (count.itemCounts.containsKey('lamps')) {
      items['lamps'] = count.itemCounts['lamps'];
    }

    if (count.itemCounts.containsKey('projector')) {
      items['projector'] = count.itemCounts['projector'];
    }

    if (count.itemCounts.containsKey('class_bell')) {
      items['class_bell'] = count.itemCounts['class_bell'];
    }

    if (count.itemCounts.containsKey('speakers')) {
      items['speakers'] = count.itemCounts['speakers'];
    }

    if (count.itemCounts.containsKey('microphone_system')) {
      items['microphone_system'] = count.itemCounts['microphone_system'];
    }

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
      'electrical_panels',
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

    // Add simple civil items that don't need combination
    final simpleCivilKeys = [
      'blackboard',
      'internal_windows',
      'external_windows',
      'emergency_signs',
      'single_door',
      'double_door'
    ];

    count.itemCounts.forEach((key, value) {
      if (simpleCivilKeys.contains(key)) {
        items[key] = value;
      }
    });

    // Add yes_no_with_counts survey answers for civil/structural issues
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
      if (civilSurveyKeys.contains(key)) {
        // Convert integer value (0/1) to boolean for display
        items[key] = value == 1;
      }
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

  Map<String, dynamic> _getAirConditioningItems() {
    Map<String, dynamic> items = {};

    // Add air conditioning units
    final airConditioningKeys = [
      'cabinet_ac',
      'split_concealed_ac',
      'hidden_ducts_ac',
      'window_ac',
      'package_ac',
    ];

    count.itemCounts.forEach((key, value) {
      if (airConditioningKeys.contains(key)) {
        items[key] = value;
      }
    });



    return items;
  }

  Map<String, String> _getAirConditioningConditions() {
    return {};
  }

  List<String> _getAirConditioningPhotos() {
    return count.sectionPhotos['air_conditioning'] ?? [];
  }

  Map<String, String> _getAirConditioningNotes() {
    final airConditioningKeys = ['ac_note'];

    Map<String, String> notes = {};
    count.maintenanceNotes.forEach((key, value) {
      if (airConditioningKeys.contains(key) && value.isNotEmpty) {
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
      case 'emergency_lights':
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
      case 'break_glasses_bells':
        noteKey = 'break_glasses_bells_note';
        break;
      case 'breakers_combined':
        noteKey = 'breakers_note';
        break;
      case 'bells_combined':
        noteKey = 'break_glasses_bells_note';
        break;
      case 'break_glasses_bells_combined':
        noteKey = 'break_glasses_bells_note';
        break;
      case 'smoke_detectors_combined':
        noteKey = 'smoke_detectors_note';
        break;
      case 'heat_detectors_combined':
        noteKey = 'heat_detectors_note';
        break;
      case 'emergency_exits_combined':
        noteKey = 'emergency_exits_note';
        break;
      case 'emergency_lights_combined':
        noteKey = 'emergency_lights_note';
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
      case 'fire_hose':
      case 'fire_hose_condition':
        noteKey = 'fire_hose_note';
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
      case 'water_pumps':
      case 'water_pumps_condition':
        noteKey = 'water_pumps_note';
        break;
      case 'water_pumps_combined':
        noteKey = 'water_pumps_note';
        break;
      case 'electrical_panels':
      case 'electrical_panels_condition':
        noteKey = 'electrical_panels_note';
        break;
      case 'split_ac':
      case 'window_ac':
      case 'cabinet_ac':
      case 'package_ac':
        noteKey = 'ac_systems_note';
        break;
      case 'ac_panel':
      case 'ac_panel_combined':
        noteKey = 'ac_panel_note';
        break;
      case 'power_panel':
      case 'power_panel_combined':
        noteKey = 'power_panel_note';
        break;
      case 'main_breaker':
      case 'main_breaker_combined':
        noteKey = 'main_breaker_note';
        break;
      case 'lighting_panel':
      case 'lighting_panel_combined':
        noteKey = 'lighting_panel_note';
        break;
      case 'main_distribution_panel':
      case 'main_distribution_panel_combined':
        noteKey = 'main_distribution_panel_note';
        break;
      case 'package_ac_breaker':
      case 'package_ac_breaker_combined':
        noteKey = 'package_ac_breaker_note';
        break;
      case 'concealed_ac_breaker':
      case 'concealed_ac_breaker_combined':
        noteKey = 'concealed_ac_breaker_note';
        break;
      case 'water_meter_number':
        noteKey = 'water_meter_note';
        break;
      case 'electricity_meter_number':
        noteKey = 'electricity_meter_note';
        break;
      case 'elevators_motor':
        noteKey = 'elevators_motor_note';
        break;
      case 'elevators_main_parts':
        noteKey = 'elevators_main_parts_note';
        break;
      case 'elevators':
        noteKey = 'elevators_note';
        break;
      case 'wall_cracks':
        noteKey = 'wall_cracks_note';
        break;
      case 'falling_shades':
        noteKey = 'falling_shades_note';
        break;
      case 'has_water_leaks':
        noteKey = 'has_water_leaks_note';
        break;
      case 'low_railing_height':
        noteKey = 'low_railing_height_note';
        break;
      case 'concrete_rust_damage':
        noteKey = 'concrete_rust_damage_note';
        break;
      case 'roof_insulation_damage':
        noteKey = 'roof_insulation_damage_note';
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
      case 'fire_hose':
      case 'fire_hose_condition':
        return Icons.local_fire_department_rounded;
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
      case 'water_pumps_combined':
        return Icons.water_damage_rounded;
      case 'electrical_panels':
      case 'electrical_panels_condition':
        return Icons.electrical_services_rounded;
      
      // Electrical items
      case 'lamps':
        return Icons.lightbulb_rounded;
      case 'projector':
        return Icons.video_camera_back_rounded;
      case 'class_bell':
        return Icons.notifications_active_rounded;
      case 'speakers':
        return Icons.speaker_rounded;
      case 'microphone_system':
        return Icons.mic_rounded;
      case 'ac_panel':
        return Icons.ac_unit_rounded;
      case 'split_concealed_ac':
        return Icons.ac_unit_rounded;
      case 'hidden_ducts_ac':
        return Icons.ac_unit_rounded;
      case 'window_ac':
        return Icons.ac_unit_rounded;
      case 'cabinet_ac':
        return Icons.ac_unit_rounded;
      case 'package_ac':
        return Icons.ac_unit_rounded;
      case 'power_panel':
        return Icons.power_rounded;
      case 'lighting_panel':
        return Icons.light_mode_rounded;
      case 'main_distribution_panel':
        return Icons.dashboard_rounded;
      case 'main_breaker':
        return Icons.power_settings_new_rounded;
      case 'concealed_ac_breaker':
      case 'package_ac_breaker':
        return Icons.ac_unit_rounded;
      case 'breakers':
        return Icons.power_settings_new_rounded;
      case 'bells':
        return Icons.notifications_active_rounded;
      case 'break_glasses_bells':
        return Icons.notifications_active_rounded;
      case 'smoke_detectors':
        return Icons.sensors_rounded;
      case 'heat_detectors':
        return Icons.thermostat_rounded;
      case 'breakers_combined':
        return Icons.power_settings_new_rounded;
      case 'bells_combined':
        return Icons.notifications_active_rounded;
      case 'break_glasses_bells_combined':
        return Icons.notifications_active_rounded;
      case 'smoke_detectors_combined':
        return Icons.sensors_rounded;
      case 'heat_detectors_combined':
        return Icons.thermostat_rounded;
      case 'emergency_exits_combined':
        return Icons.exit_to_app_rounded;
      case 'emergency_lights_combined':
        return Icons.lightbulb_rounded;
      case 'camera':
        return Icons.videocam_rounded;
      
      // Combined electrical items
      case 'ac_panel_combined':
        return Icons.ac_unit_rounded;
      case 'power_panel_combined':
        return Icons.power_rounded;
      case 'main_breaker_combined':
        return Icons.power_settings_new_rounded;
      case 'lighting_panel_combined':
        return Icons.light_mode_rounded;
      case 'main_distribution_panel_combined':
        return Icons.dashboard_rounded;
      case 'package_ac_breaker_combined':
        return Icons.ac_unit_rounded;
      case 'concealed_ac_breaker_combined':
        return Icons.ac_unit_rounded;

      // Updated Mechanical items
      case 'bathroom_heaters_1':
      case 'bathroom_heaters_2':
      case 'cafeteria_heaters_1':
        return Icons.hot_tub_rounded;
      case 'hand_sink':
      case 'basin_sink':
        return Icons.wash_rounded;
      case 'western_toilet':
      case 'arabic_toilet':
        return Icons.wc_rounded;
      case 'arabic_siphon':
      case 'english_siphon':
        return Icons.water_drop_rounded;
      case 'bidets':
        return Icons.shower_rounded;
      case 'wall_exhaust_fans':
      case 'central_exhaust_fans':
      case 'cafeteria_exhaust_fans':
        return Icons.air_rounded;
      case 'wall_water_coolers':
      case 'corridor_water_coolers':
        return Icons.local_drink_rounded;
      case 'sink_mirrors':
        return Icons.image_rounded;
      case 'wall_tap':
      case 'sink_tap':
        return Icons.water_drop_rounded;
      
      // Combined mechanical items
      case 'bathroom_heaters_combined':
        return Icons.hot_tub_rounded;
      case 'cafeteria_heaters_combined':
        return Icons.hot_tub_rounded;
      
      // Individual heater entries
      case var heaterKey when heaterKey.startsWith('bathroom_heaters_'):
        return Icons.hot_tub_rounded;
      case var heaterKey when heaterKey.startsWith('cafeteria_heaters_'):
        return Icons.hot_tub_rounded;

      // Updated Civil items
      case 'blackboard':
        return Icons.edit_rounded;
      case 'internal_windows':
      case 'external_windows':
        return Icons.window_rounded;
      case 'emergency_signs':
        return Icons.warning_rounded;
      case 'single_door':
      case 'double_door':
        return Icons.door_front_door_rounded;
      
      case 'fire_alarm_system':
      case 'fire_alarm_system_condition':
        return Icons.alarm_rounded;
      case 'fire_suppression_system':
      case 'fire_suppression_system_condition':
        return Icons.security_rounded;
      case 'emergency_exits':
      case 'emergency_exits_condition':
        return Icons.exit_to_app_rounded;
      case 'emergency_lights':
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
      
      // Electrical amperage values
      case 'ac_panel_amperage':
        return Icons.ac_unit_rounded;
      case 'power_panel_amperage':
        return Icons.power_rounded;
      case 'main_breaker_amperage':
        return Icons.power_settings_new_rounded;
      case 'lighting_panel_amperage':
        return Icons.light_mode_rounded;
      case 'package_ac_breaker_amperage':
      case 'concealed_ac_breaker_amperage':
        return Icons.ac_unit_rounded;
      case 'main_distribution_panel_amperage':
        return Icons.dashboard_rounded;
      
      // Mechanical capacities
      case 'bathroom_heaters_capacity':
      case 'cafeteria_heaters_capacity':
        return Icons.hot_tub_rounded;
      
      // Elevator information
      case 'elevators_motor':
      case 'elevators_main_parts':
        return Icons.elevator_rounded;
      
      // Combined safety items
      case 'fire_extinguishers_combined':
        return Icons.local_fire_department_rounded;
      
      // Fire safety expiry dates
      case 'fire_extinguishers_expiry_day':
      case 'fire_extinguishers_expiry_month':
      case 'fire_extinguishers_expiry_year':
        return Icons.calendar_today_rounded;
      
      // Civil/Structural survey answers
      case 'elevators':
        return Icons.elevator_rounded;
      case 'wall_cracks':
        return Icons.broken_image_rounded;
      case 'falling_shades':
        return Icons.umbrella_rounded;
      case 'has_water_leaks':
        return Icons.water_damage_rounded;
      case 'low_railing_height':
        return Icons.fence_rounded;
      case 'concrete_rust_damage':
        return Icons.construction_rounded;
      case 'roof_insulation_damage':
        return Icons.roofing_rounded;
      
      default:
        return Icons.inventory_rounded;
    }
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
      'electrical_panels': 'اللوحات الكهربائية',
      'fire_extinguishers': 'طفايات الحريق',

      // Updated AC types
      'split_concealed_ac': 'مكيف سبليت مخفي',
      'hidden_ducts_ac': 'مكيف مخفي بقنوات',
      'window_ac': 'مكيف نافذة',
      'cabinet_ac': 'مكيف خزانة',
      'package_ac': 'مكيف حزمة',

      // Electrical items
      'lamps': 'مصابيح',
      'projector': 'بروجكتور',
      'class_bell': 'جرس الفصل',
      'speakers': 'مكبرات صوت',
      'microphone_system': 'نظام ميكروفون',
      'ac_panel': 'لوحة تكييف',
      'power_panel': 'لوحة باور',
      'lighting_panel': 'لوحة انارة',
      'main_distribution_panel': 'لوحة توزيع رئيسية',
      'main_breaker': 'القاطع الرئيسي',
      'concealed_ac_breaker': 'قاطع تكييف كونسيلد',
      'package_ac_breaker': 'قاطع تكييف باكدج',
      'breakers': 'قواطع كهربائية',
      'bells': 'أجراس',
      'break_glasses_bells': 'كواسر',
      'smoke_detectors': 'أجهزة استشعار الدخان',
      'heat_detectors': 'أجهزة استشعار الحرارة',
      'camera': 'كاميرات',

      // Combined electrical items
      'ac_panel_combined': 'لوحة تكييف',
      'power_panel_combined': 'لوحة باور',
      'main_breaker_combined': 'القاطع الرئيسي',
      'lighting_panel_combined': 'لوحة انارة',
      'main_distribution_panel_combined': 'لوحة توزيع رئيسية',
      'package_ac_breaker_combined': 'قاطع تكييف باكدج',
      'concealed_ac_breaker_combined': 'قاطع تكييف كونسيلد',

      // Updated Mechanical items
      'bathroom_heaters_1': 'سخانات حمام 1',
      'bathroom_heaters_2': 'سخانات حمام 2',
      'cafeteria_heaters_1': 'سخانات مقصف 1',
      'hand_sink': 'حوض غسيل اليدين',
      'basin_sink': 'حوض الحوض',
      'western_toilet': 'كرسي افرنجي',
      'arabic_toilet': 'كرسي عربي',
      'arabic_siphon': 'سيفون عربي',
      'english_siphon': 'سيفون إنجليزي',
      'bidets': 'شطافات',
      'wall_exhaust_fans': 'مراوح شفط جدارية',
      'central_exhaust_fans': 'مراوح شفط مركزية',
      'cafeteria_exhaust_fans': 'مراوح شفط مقصف',
      'wall_water_coolers': 'برادات مياة جدارية',
      'corridor_water_coolers': 'برادات مياة للممرات',
      'sink_mirrors': 'مرايا الحوض',
      'wall_tap': 'صنبور الحائط',
      'sink_tap': 'صنبور الحوض',

      // Combined mechanical items
      'bathroom_heaters_combined': 'سخانات حمام',
      'cafeteria_heaters_combined': 'سخانات مقصف',
      'water_pumps_combined': 'مضخات المياه',
      
      // Individual heater entries
      'bathroom_heater_': 'سخان حمام',
      'cafeteria_heater_': 'سخان مقصف',

      // Updated Civil items
      'blackboard': 'سبورة',
      'internal_windows': 'نوافذ داخلية',
      'external_windows': 'نوافذ خارجية',
      'emergency_signs': 'علامات الطوارئ',
      'single_door': 'أبواب مفردة',
      'double_door': 'أبواب مزدوجة',
      
      // Combined safety items
      'fire_extinguishers_combined': 'طفايات الحريق',
      'fire_boxes_combined': 'صناديق الحريق',
      'diesel_pump_combined': 'مضخة الديزل',
      'electric_pump_combined': 'المضخة الكهربائية',
      'auxiliary_pump_combined': 'المضخة المساعدة',
      'alarm_panel_combined': 'لوحة الإنذار',
      'breakers_combined': 'قواطع كهربائية',
      'bells_combined': 'أجراس',
      'break_glasses_bells_combined': 'كواسر',
      'smoke_detectors_combined': 'كواشف دخان',
      'heat_detectors_combined': 'كواشف حرارة',
      'emergency_exits_combined': 'مخارج الطوارئ',
      'emergency_lights_combined': 'أضواء الطوارئ',

      // Survey answers - Safety conditions
      'emergency_exits': 'مخارج الطوارئ',
      'emergency_lights': 'أضواء الطوارئ',
      'fire_alarm_system': 'نظام إنذار الحريق',
      'fire_boxes_condition': 'حالة صناديق الحريق',
      'fire_hose_condition': 'حالة خرطوم الحريق',
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
      'alarm_panel_type': 'نوع لوحة الإنذار',
      'alarm_panel_condition': 'حالة لوحة الإنذار',

      // Boolean survey answers - Civil/Structural
      'elevators': 'مصاعد',
      'wall_cracks': 'تشققات في الجدران',
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
      'fire_extinguishers_expiry_date': 'تاريخ انتهاء طفايات الحريق',

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
      'alarm_panel_count': 'عدد لوحات الإنذار',
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
}
