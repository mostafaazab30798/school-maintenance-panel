import 'package:flutter_test/flutter_test.dart';
import 'lib/data/models/maintenance_count.dart';

void main() {
  group('MaintenanceCount Merging Tests', () {
    test('should merge multiple maintenance counts for the same school', () {
      // Create test records for the same school
      final record1 = MaintenanceCount(
        id: '1',
        schoolId: 'school_123',
        schoolName: 'Test School',
        supervisorId: 'supervisor_1',
        status: 'draft',
        itemCounts: {
          'fire_extinguishers': 5,
          'emergency_lights': 10,
        },
        textAnswers: {
          'water_meter_number': 'WM001',
        },
        yesNoAnswers: {
          'has_damage': false,
        },
        surveyAnswers: {
          'fire_alarm_condition': 'جيد',
        },
        createdAt: DateTime(2024, 1, 1),
      );

      final record2 = MaintenanceCount(
        id: '2',
        schoolId: 'school_123',
        schoolName: 'Test School',
        supervisorId: 'supervisor_2',
        status: 'submitted',
        itemCounts: {
          'fire_extinguishers': 3,
          'emergency_exits': 8,
        },
        textAnswers: {
          'electricity_meter_number': 'EM001',
        },
        yesNoAnswers: {
          'has_damage': true,
        },
        surveyAnswers: {
          'emergency_lights_condition': 'يحتاج صيانة',
        },
        createdAt: DateTime(2024, 1, 2),
      );

      // Test merging logic
      final records = [record1, record2];
      
      // Simulate the merging logic
      final baseRecord = records.first;
      final mergedItemCounts = Map<String, int>.from(baseRecord.itemCounts);
      final mergedTextAnswers = Map<String, String>.from(baseRecord.textAnswers);
      final mergedYesNoAnswers = Map<String, bool>.from(baseRecord.yesNoAnswers);
      final mergedSurveyAnswers = Map<String, String>.from(baseRecord.surveyAnswers);
      
      // Merge data from other records
      for (int i = 1; i < records.length; i++) {
        final record = records[i];
        
        // Merge item counts (sum the values)
        for (final entry in record.itemCounts.entries) {
          final key = entry.key;
          final value = entry.value;
          mergedItemCounts[key] = (mergedItemCounts[key] ?? 0) + value;
        }

        // Merge text answers (keep non-empty values)
        for (final entry in record.textAnswers.entries) {
          final key = entry.key;
          final value = entry.value;
          if (value.isNotEmpty && (mergedTextAnswers[key]?.isEmpty ?? true)) {
            mergedTextAnswers[key] = value;
          }
        }

        // Merge yes/no answers (if any record has true, keep true)
        for (final entry in record.yesNoAnswers.entries) {
          final key = entry.key;
          final value = entry.value;
          if (value && !(mergedYesNoAnswers[key] ?? false)) {
            mergedYesNoAnswers[key] = true;
          }
        }

        // Merge survey answers (keep non-empty values)
        for (final entry in record.surveyAnswers.entries) {
          final key = entry.key;
          final value = entry.value;
          if (value.isNotEmpty && (mergedSurveyAnswers[key]?.isEmpty ?? true)) {
            mergedSurveyAnswers[key] = value;
          }
        }
      }

      // Verify merged results
      expect(mergedItemCounts['fire_extinguishers'], 8); // 5 + 3
      expect(mergedItemCounts['emergency_lights'], 10); // Only from record1
      expect(mergedItemCounts['emergency_exits'], 8); // Only from record2
      
      expect(mergedTextAnswers['water_meter_number'], 'WM001');
      expect(mergedTextAnswers['electricity_meter_number'], 'EM001');
      
      expect(mergedYesNoAnswers['has_damage'], true); // True from record2
      
      expect(mergedSurveyAnswers['fire_alarm_condition'], 'جيد');
      expect(mergedSurveyAnswers['emergency_lights_condition'], 'يحتاج صيانة');
    });

    test('should handle single record without merging', () {
      final record = MaintenanceCount(
        id: '1',
        schoolId: 'school_123',
        schoolName: 'Test School',
        supervisorId: 'supervisor_1',
        status: 'draft',
        itemCounts: {'fire_extinguishers': 5},
        createdAt: DateTime(2024, 1, 1),
      );

      final records = [record];
      
      // Simulate merging logic for single record
      if (records.length == 1) {
        final result = records.first;
        expect(result.itemCounts['fire_extinguishers'], 5);
        expect(result.supervisorId, 'supervisor_1');
      }
    });

    test('should combine supervisor IDs in merged record', () {
      final record1 = MaintenanceCount(
        id: '1',
        schoolId: 'school_123',
        schoolName: 'Test School',
        supervisorId: 'supervisor_1',
        status: 'draft',
        createdAt: DateTime(2024, 1, 1),
      );

      final record2 = MaintenanceCount(
        id: '2',
        schoolId: 'school_123',
        schoolName: 'Test School',
        supervisorId: 'supervisor_2',
        status: 'submitted',
        createdAt: DateTime(2024, 1, 2),
      );

      final records = [record1, record2];
      
      // Simulate supervisor ID combination
      final Set<String> allSupervisorIds = {records.first.supervisorId};
      for (int i = 1; i < records.length; i++) {
        allSupervisorIds.add(records[i].supervisorId);
      }
      
      final combinedSupervisorIds = allSupervisorIds.join(', ');
      expect(combinedSupervisorIds, 'supervisor_1, supervisor_2');
    });

    test('should set status to submitted if any record is submitted', () {
      final record1 = MaintenanceCount(
        id: '1',
        schoolId: 'school_123',
        schoolName: 'Test School',
        supervisorId: 'supervisor_1',
        status: 'draft',
        createdAt: DateTime(2024, 1, 1),
      );

      final record2 = MaintenanceCount(
        id: '2',
        schoolId: 'school_123',
        schoolName: 'Test School',
        supervisorId: 'supervisor_2',
        status: 'submitted',
        createdAt: DateTime(2024, 1, 2),
      );

      final records = [record1, record2];
      
      // Simulate status logic
      final finalStatus = records.any((r) => r.status == 'submitted') ? 'submitted' : 'draft';
      expect(finalStatus, 'submitted');
    });
  });
} 