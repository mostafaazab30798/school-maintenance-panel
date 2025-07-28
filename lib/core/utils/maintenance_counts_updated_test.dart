import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/maintenance_count_repository.dart';
import '../../data/models/maintenance_count.dart';

class MaintenanceCountsUpdatedTest {
  static Future<void> testUpdatedMaintenanceCounts() async {
    try {
      print('🔍 Testing Updated Maintenance Counts System...');
      
      final supabase = Supabase.instance.client;
      final repository = MaintenanceCountRepository(supabase);
      
      // Test 1: Get maintenance count records with new structure
      print('📋 Test 1: Getting maintenance count records with updated structure...');
      final records = await repository.getAllMaintenanceCountRecords(limit: 5);
      print('✅ Found ${records.length} maintenance count records');
      
      if (records.isNotEmpty) {
        final record = records.first;
        print('📝 Sample record analysis:');
        print('  - ID: ${record.id}');
        print('  - School: ${record.schoolName}');
        print('  - Status: ${record.status}');
        print('  - Created: ${record.createdAt}');
        print('  - Total item counts: ${record.itemCounts.length}');
        
        // Check for updated AC types
        print('  - Has updated AC data: ${record.hasUpdatedACData}');
        if (record.hasUpdatedACData) {
          print('    - Split concealed AC: ${record.itemCounts['split_concealed_ac']}');
          print('    - Hidden ducts AC: ${record.itemCounts['hidden_ducts_ac']}');
        }
        
        // Check for updated sink types
        print('  - Has updated sink data: ${record.hasUpdatedSinkData}');
        if (record.hasUpdatedSinkData) {
          print('    - Hand sink: ${record.itemCounts['hand_sink']}');
          print('    - Basin sink: ${record.itemCounts['basin_sink']}');
        }
        
        // Check for updated siphon types
        print('  - Has updated siphon data: ${record.hasUpdatedSiphonData}');
        if (record.hasUpdatedSiphonData) {
          print('    - Arabic siphon: ${record.itemCounts['arabic_siphon']}');
          print('    - English siphon: ${record.itemCounts['english_siphon']}');
        }
        
        // Check for updated breaker data
        print('  - Has updated breaker data: ${record.hasUpdatedBreakerData}');
        if (record.hasUpdatedBreakerData) {
          print('    - Breakers: ${record.itemCounts['breakers']}');
          print('    - Bells: ${record.itemCounts['bells']}');
        }
        
        // Check for updated detector data
        print('  - Has updated detector data: ${record.hasUpdatedDetectorData}');
        if (record.hasUpdatedDetectorData) {
          print('    - Smoke detectors: ${record.itemCounts['smoke_detectors']}');
          print('    - Heat detectors: ${record.itemCounts['heat_detectors']}');
        }
        
        // Check for new data
        print('  - Has new data: ${record.hasNewData}');
        if (record.hasNewData) {
          print('    - Cameras: ${record.itemCounts['camera']}');
          print('    - Emergency signs: ${record.itemCounts['emergency_signs']}');
          print('    - Sink mirrors: ${record.itemCounts['sink_mirrors']}');
          print('    - Wall tap: ${record.itemCounts['wall_tap']}');
          print('    - Sink tap: ${record.itemCounts['sink_tap']}');
          print('    - Single doors: ${record.itemCounts['single_door']}');
          print('    - Double doors: ${record.itemCounts['double_door']}');
        }
        
        // Test item counts by category
        print('  - Mechanical items count: ${_countMechanicalItems(record)}');
        print('  - Electrical items count: ${_countElectricalItems(record)}');
        print('  - Civil items count: ${_countCivilItems(record)}');
        print('  - Safety items count: ${_countSafetyItems(record)}');
      }
      
      // Test 2: Check if new item types are recognized
      print('\n📋 Test 2: Checking new item type recognition...');
      final allItemTypes = MaintenanceItemTypes.getAllItemTypes();
      print('✅ Total item types supported: ${allItemTypes.length}');
      
      // Check specific new items
      final newItems = [
        'split_concealed_ac',
        'hidden_ducts_ac',
        'hand_sink',
        'basin_sink',
        'arabic_siphon',
        'english_siphon',
        'breakers',
        'bells',
        'smoke_detectors',
        'heat_detectors',
        'camera',
        'emergency_signs',
        'sink_mirrors',
        'wall_tap',
        'sink_tap',
        'single_door',
        'double_door'
      ];
      
      for (final item in newItems) {
        if (allItemTypes.contains(item)) {
          print('✅ $item is supported');
        } else {
          print('❌ $item is NOT supported');
        }
      }
      
      print('\n🎉 Updated maintenance counts test completed successfully!');
      
    } catch (e, stackTrace) {
      print('❌ ERROR: Failed to test updated maintenance counts: $e');
      print('❌ Stack trace: $stackTrace');
    }
  }
  
  static int _countMechanicalItems(MaintenanceCount record) {
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
    
    int itemCount = 0;
    for (final key in mechanicalKeys) {
      if (record.itemCounts.containsKey(key)) {
        itemCount++;
      }
    }
    return itemCount;
  }
  
  static int _countElectricalItems(MaintenanceCount record) {
    final electricalKeys = [
      'lamps',
      'projector', 
      'class_bell',
      'speakers',
      'microphone_system',
      'ac_panel',
      'split_concealed_ac',
      'hidden_ducts_ac',
      'window_ac',
      'cabinet_ac',
      'package_ac',
      'power_panel',
      'lighting_panel',
      'main_distribution_panel',
      'main_breaker',
      'concealed_ac_breaker',
      'package_ac_breaker',
      'electrical_panels',
      'breakers',
      'bells',
      'smoke_detectors',
      'heat_detectors',
      'camera'
    ];
    
    int itemCount = 0;
    for (final key in electricalKeys) {
      if (record.itemCounts.containsKey(key)) {
        itemCount++;
      }
    }
    return itemCount;
  }
  
  static int _countCivilItems(MaintenanceCount record) {
    final civilKeys = [
      'blackboard',
      'internal_windows',
      'external_windows',
      'emergency_signs',
      'single_door',
      'double_door'
    ];
    
    int itemCount = 0;
    for (final key in civilKeys) {
      if (record.itemCounts.containsKey(key)) {
        itemCount++;
      }
    }
    return itemCount;
  }
  
  static int _countSafetyItems(MaintenanceCount record) {
    final safetyKeys = [
      'fire_boxes',
      'fire_hose',
      'diesel_pump',
      'electric_pump',
      'auxiliary_pump',
      'emergency_exits',
      'emergency_lights',
      'fire_extinguishers',
      'breakers',
      'bells',
      'smoke_detectors',
      'heat_detectors',
      'emergency_signs'
    ];
    
    int itemCount = 0;
    for (final key in safetyKeys) {
      if (record.itemCounts.containsKey(key)) {
        itemCount++;
      }
    }
    return itemCount;
  }
} 