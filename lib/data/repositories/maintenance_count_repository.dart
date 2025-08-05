import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/maintenance_count.dart';

class MaintenanceCountRepository {
  final SupabaseClient _client;

  MaintenanceCountRepository(this._client);

  /// Fetch all maintenance counts with optional filtering
  Future<List<MaintenanceCount>> getMaintenanceCounts({
    int page = 0,
    int limit = 20,
    String? supervisorId,
    String? schoolId,
    String? status,
  }) async {
    try {
      // RULE: For complex queries with range/order, apply filters after select but before range/order
      var query = _client.from('maintenance_counts').select('''
        id,
        school_id,
        school_name,
        supervisor_id,
        status,
        item_counts,
        text_answers,
        yes_no_answers,
        yes_no_with_counts,
        survey_answers,
        maintenance_notes,
        fire_safety_alarm_panel_data,
        fire_safety_condition_only_data,
        fire_safety_expiry_dates,
        section_photos,
        heater_entries,
        created_at,
        updated_at
      ''');

      // Apply filters first
      if (supervisorId != null) {
        query = query.eq('supervisor_id', supervisorId);
      }

      if (schoolId != null) {
        query = query.eq('school_id', schoolId);
      }

      if (status != null) {
        query = query.eq('status', status);
      }

      // Then apply range and order
      final response = await query
          .range(page * limit, (page + 1) * limit - 1)
          .order('created_at', ascending: false);

      return response
          .map<MaintenanceCount>((data) => MaintenanceCount.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch maintenance counts: $e');
    }
  }

  /// Fetch all maintenance count records with detailed data (for listing)
  Future<List<MaintenanceCount>> getAllMaintenanceCountRecords({
    List<String>? supervisorIds,
    String? schoolId,
    String? status,
    int limit = 50,
  }) async {
    try {
      print('🔍 DEBUG: Starting getAllMaintenanceCountRecords');
      print('🔍 DEBUG: supervisorIds: $supervisorIds');
      print('🔍 DEBUG: schoolId: $schoolId');
      print('🔍 DEBUG: status: $status');
      print('🔍 DEBUG: limit: $limit');

      var query = _client.from('maintenance_counts').select('''
        id,
        school_id,
        school_name,
        supervisor_id,
        status,
        item_counts,
        text_answers,
        yes_no_answers,
        yes_no_with_counts,
        survey_answers,
        maintenance_notes,
        fire_safety_alarm_panel_data,
        fire_safety_condition_only_data,
        fire_safety_expiry_dates,
        section_photos,
        heater_entries,
        created_at,
        updated_at
      ''');

      // Apply filters
      if (supervisorIds != null && supervisorIds.isNotEmpty) {
        query = query.inFilter('supervisor_id', supervisorIds);
        print('🔍 DEBUG: Applied supervisor filter for IDs: $supervisorIds');
      }

      if (schoolId != null) {
        query = query.eq('school_id', schoolId);
        print('🔍 DEBUG: Applied school filter: $schoolId');
      }

      if (status != null) {
        query = query.eq('status', status);
        print('🔍 DEBUG: Applied status filter: $status');
      }

      print('🔍 DEBUG: Executing query...');
      
      // Apply order and limit
      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      print('🔍 DEBUG: Query executed successfully');
      print('🔍 DEBUG: Response type: ${response.runtimeType}');
      print('🔍 DEBUG: Response length: ${response?.length ?? 'null'}');
      
      if (response != null && response.isNotEmpty) {
        print('🔍 DEBUG: First record: ${response.first}');
      }

      final result = response
          .map<MaintenanceCount>((data) => MaintenanceCount.fromMap(data))
          .toList();

      print('🔍 DEBUG: Parsed ${result.length} MaintenanceCount objects');
      return result;
    } catch (e, stackTrace) {
      print('❌ ERROR: Failed to fetch maintenance count records: $e');
      print('❌ ERROR: Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get schools that have maintenance counts
  Future<List<Map<String, dynamic>>> getSchoolsWithMaintenanceCounts({
    List<String>? supervisorIds,
  }) async {
    try {
      // Direct database query to avoid infinite recursion
      var query = _client.from('maintenance_counts').select('''
        school_id,
        school_name
      ''');

      // Apply supervisor filter if provided
      if (supervisorIds != null && supervisorIds.isNotEmpty) {
        query = query.inFilter('supervisor_id', supervisorIds);
      }

      final response = await query.order('school_name');

      // Handle empty response
      if (response == null || response.isEmpty) {
        return [];
      }

      // Group by school and count maintenance records
      final Map<String, Map<String, dynamic>> schoolCounts = {};

      for (final item in response) {
        final schoolId = item['school_id']?.toString() ?? '';
        final schoolName = item['school_name']?.toString() ?? '';

        if (schoolId.isNotEmpty) {
          if (!schoolCounts.containsKey(schoolId)) {
            schoolCounts[schoolId] = {
              'school_id': schoolId,
              'school_name': schoolName,
              'address': '', // Default empty address
              'maintenance_count': 0,
            };
          }
          schoolCounts[schoolId]!['maintenance_count'] =
              (schoolCounts[schoolId]!['maintenance_count'] as int) + 1;
        }
      }

      return schoolCounts.values.toList();
    } catch (e) {
      // Return empty list instead of throwing exception for better UX
      print('⚠️ WARNING: Failed to fetch schools with maintenance counts: $e');
      return [];
    }
  }

  /// Get schools with damaged items (schools that have damage data from damage_inventory table)
  Future<List<Map<String, dynamic>>> getSchoolsWithDamage({
    String? supervisorId,
  }) async {
    try {
      // RULE: Supabase query pattern is: from() -> select() -> where/eq/filter -> order()
      // Never apply filters before select() - it causes NoSuchMethodError
      var query = _client.from('damage_inventory').select('''
            school_id,
            school_name,
            supervisor_id,
            damage_type,
            damage_severity,
            damage_description
          ''');

      // Apply supervisor filter after select
      if (supervisorId != null) {
        query = query.eq('supervisor_id', supervisorId);
      }

      // Finally apply ordering
      final response = await query.order('school_name');

      // Handle empty response
      if (response == null || response.isEmpty) {
        return [];
      }

      final Map<String, Map<String, dynamic>> schoolData = {};

      for (final item in response) {
        final schoolId = item['school_id']?.toString() ?? '';
        final schoolName = item['school_name']?.toString() ?? '';

        if (schoolId.isNotEmpty) {
          if (!schoolData.containsKey(schoolId)) {
            schoolData[schoolId] = {
              'school_id': schoolId,
              'school_name': schoolName,
              'address': '', // Default empty address
              'damage_reports_count': 0,
            };
          }
          schoolData[schoolId]!['damage_reports_count'] =
              (schoolData[schoolId]!['damage_reports_count'] as int) + 1;
        }
      }

      return schoolData.values.toList();
    } catch (e) {
      // Return empty list instead of throwing exception for better UX
      print('⚠️ WARNING: Failed to fetch schools with damage: $e');
      return [];
    }
  }

  /// Get summary statistics for dashboard
  Future<Map<String, int>> getDashboardSummary({List<String>? supervisorIds}) async {
    try {
      // Use merged records for more accurate statistics
      final mergedRecords = await getMergedMaintenanceCountRecords(
        supervisorIds: supervisorIds,
        limit: 1000, // Get all records for statistics
      );

      // Handle empty response
      if (mergedRecords.isEmpty) {
        return {
          'total_maintenance_counts': 0,
          'schools_with_counts': 0,
          'schools_with_damage': 0,
          'submitted_counts': 0,
          'draft_counts': 0,
        };
      }

      final Set<String> schoolsWithCounts = {};
      final Set<String> schoolsWithDamage = {};
      int totalCounts = mergedRecords.length;
      int submittedCounts = 0;

      for (final record in mergedRecords) {
        final status = record.status;
        final schoolId = record.schoolId;

        if (schoolId.isNotEmpty) {
          schoolsWithCounts.add(schoolId);
        }

        if (status == 'submitted') {
          submittedCounts++;
        }

        // Check for damage data
        if (record.hasDamageData && schoolId.isNotEmpty) {
          schoolsWithDamage.add(schoolId);
        }
      }

      return {
        'total_maintenance_counts': totalCounts,
        'schools_with_counts': schoolsWithCounts.length,
        'schools_with_damage': schoolsWithDamage.length,
        'submitted_counts': submittedCounts,
        'draft_counts': totalCounts - submittedCounts,
      };
    } catch (e) {
      print('⚠️ WARNING: Failed to get dashboard summary: $e');
      return {
        'total_maintenance_counts': 0,
        'schools_with_counts': 0,
        'schools_with_damage': 0,
        'submitted_counts': 0,
        'draft_counts': 0,
      };
    }
  }

  /// 🚀 NEW: Get merged maintenance count records (combines duplicates by school)
  Future<List<MaintenanceCount>> getMergedMaintenanceCountRecords({
    List<String>? supervisorIds,
    String? schoolId,
    String? status,
    int limit = 50,
  }) async {
    try {
      print('🔍 DEBUG: Starting getMergedMaintenanceCountRecords');
      print('🔍 DEBUG: supervisorIds: $supervisorIds');
      print('🔍 DEBUG: schoolId: $schoolId');
      print('🔍 DEBUG: status: $status');

      // For Excel export, use a more efficient approach with smaller chunks
      if (limit > 200) {
        print('🔍 DEBUG: Large limit detected ($limit), using optimized approach');
        return await _getMergedMaintenanceCountsOptimized(
          supervisorIds: supervisorIds,
          schoolId: schoolId,
          status: status,
          limit: limit,
        );
      }

      // For regular queries, use the original approach but with reduced initial load
      final allRecords = await getAllMaintenanceCountRecords(
        supervisorIds: supervisorIds,
        schoolId: schoolId,
        status: status,
        limit: 500, // Reduced from 1000 to prevent timeouts
      );

      print('🔍 DEBUG: Retrieved ${allRecords.length} records for merging');

      // Group records by school ID
      final Map<String, List<MaintenanceCount>> schoolGroups = {};
      
      for (final record in allRecords) {
        final schoolId = record.schoolId;
        if (schoolId.isNotEmpty) {
          schoolGroups.putIfAbsent(schoolId, () => []).add(record);
        }
      }

      print('🔍 DEBUG: Grouped into ${schoolGroups.length} schools');

      // Merge records for each school
      final List<MaintenanceCount> mergedRecords = [];
      
      for (final entry in schoolGroups.entries) {
        final schoolId = entry.key;
        final records = entry.value;
        
        if (records.length == 1) {
          // Single record, no merging needed
          mergedRecords.add(records.first);
        } else {
          // Multiple records, merge them
          print('🔍 DEBUG: Merging ${records.length} records for school: $schoolId');
          final mergedRecord = _mergeMaintenanceCounts(records);
          mergedRecords.add(mergedRecord);
        }
      }

      // Sort by creation date (most recent first) and apply limit
      mergedRecords.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      final limitedRecords = mergedRecords.take(limit).toList();
      
      print('🔍 DEBUG: Returning ${limitedRecords.length} merged records');
      return limitedRecords;
    } catch (e, stackTrace) {
      print('❌ ERROR: Failed to get merged maintenance count records: $e');
      print('❌ ERROR: Stack trace: $stackTrace');
      return [];
    }
  }

  /// 🚀 OPTIMIZED: Get merged maintenance counts for large exports
  Future<List<MaintenanceCount>> _getMergedMaintenanceCountsOptimized({
    List<String>? supervisorIds,
    String? schoolId,
    String? status,
    int limit = 2000,
  }) async {
    try {
      print('🔍 DEBUG: Starting optimized merge for large export (limit: $limit)');
      
      // Use direct database query to get schools to avoid infinite recursion
      var query = _client.from('maintenance_counts').select('''
        school_id,
        school_name
      ''');

      // Apply supervisor filter if provided
      if (supervisorIds != null && supervisorIds.isNotEmpty) {
        query = query.inFilter('supervisor_id', supervisorIds);
      }

      final schoolsResponse = await query.order('school_name');
      
      if (schoolsResponse == null || schoolsResponse.isEmpty) {
        print('🔍 DEBUG: No schools found with maintenance counts');
        return [];
      }

      // Get unique schools
      final Set<String> uniqueSchools = {};
      final Map<String, String> schoolNames = {};
      
      for (final item in schoolsResponse) {
        final schoolId = item['school_id']?.toString() ?? '';
        final schoolName = item['school_name']?.toString() ?? '';
        if (schoolId.isNotEmpty) {
          uniqueSchools.add(schoolId);
          schoolNames[schoolId] = schoolName;
        }
      }
      
      final schools = uniqueSchools.toList();
      print('🔍 DEBUG: Found ${schools.length} unique schools with maintenance counts');
      
      final List<MaintenanceCount> mergedRecords = [];
      int processedSchools = 0;
      
      // Process schools in smaller chunks to prevent timeout
      const chunkSize = 15; // Reduced chunk size
      
      for (int i = 0; i < schools.length; i += chunkSize) {
        final chunk = schools.skip(i).take(chunkSize);
        
        // Process chunk in parallel with timeout
        final futures = chunk.map((schoolId) async {
          try {
            final schoolCounts = await getMaintenanceCounts(schoolId: schoolId)
                .timeout(const Duration(seconds: 8), onTimeout: () {
              print('⚠️ WARNING: Timeout getting counts for school: $schoolId');
              return <MaintenanceCount>[];
            });
            
            if (schoolCounts.isNotEmpty) {
              // Merge counts for this school
              if (schoolCounts.length == 1) {
                return schoolCounts.first;
              } else {
                return _mergeMaintenanceCounts(schoolCounts);
              }
            }
            return null;
          } catch (e) {
            print('⚠️ WARNING: Error processing school $schoolId: $e');
            return null;
          }
        });
        
        // Wait for chunk to complete with timeout
        final chunkResults = await Future.wait(futures)
            .timeout(const Duration(seconds: 25), onTimeout: () {
          print('⚠️ WARNING: Timeout processing chunk ${i ~/ chunkSize + 1}');
          return List<MaintenanceCount?>.filled(chunk.length, null);
        });
        
        // Add valid results
        for (final result in chunkResults) {
          if (result != null) {
            mergedRecords.add(result);
          }
        }
        
        processedSchools += chunk.length;
        print('🔍 DEBUG: Processed $processedSchools/${schools.length} schools');
        
        // Add small delay between chunks to prevent overwhelming the database
        if (i + chunkSize < schools.length) {
          await Future.delayed(const Duration(milliseconds: 150));
        }
        
        // Check if we have enough records
        if (mergedRecords.length >= limit) {
          print('🔍 DEBUG: Reached limit of $limit records');
          break;
        }
      }
      
      // Sort by creation date and apply limit
      mergedRecords.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final limitedRecords = mergedRecords.take(limit).toList();
      
      print('🔍 DEBUG: Optimized merge completed with ${limitedRecords.length} records');
      return limitedRecords;
    } catch (e) {
      print('❌ ERROR: Optimized merge failed: $e');
      // Fallback to empty list
      return [];
    }
  }

  /// 🚀 NEW: Merge multiple maintenance counts for the same school
  MaintenanceCount _mergeMaintenanceCounts(List<MaintenanceCount> records) {
    if (records.isEmpty) {
      throw Exception('Cannot merge empty list of maintenance counts');
    }

    if (records.length == 1) {
      return records.first;
    }

    // Use the first record as the base
    final baseRecord = records.first;
    
    // Merge all data from other records
    final mergedItemCounts = Map<String, int>.from(baseRecord.itemCounts);
    final mergedTextAnswers = Map<String, String>.from(baseRecord.textAnswers);
    final mergedYesNoAnswers = Map<String, bool>.from(baseRecord.yesNoAnswers);
    final mergedYesNoWithCounts = Map<String, int>.from(baseRecord.yesNoWithCounts);
    final mergedSurveyAnswers = Map<String, String>.from(baseRecord.surveyAnswers);
    final mergedMaintenanceNotes = Map<String, String>.from(baseRecord.maintenanceNotes);
    final mergedFireSafetyAlarmPanelData = Map<String, String>.from(baseRecord.fireSafetyAlarmPanelData);
    final mergedFireSafetyConditionOnlyData = Map<String, String>.from(baseRecord.fireSafetyConditionOnlyData);
    final mergedFireSafetyExpiryDates = Map<String, String>.from(baseRecord.fireSafetyExpiryDates);
    final mergedSectionPhotos = Map<String, List<String>>.from(baseRecord.sectionPhotos);
    final mergedHeaterEntries = Map<String, dynamic>.from(baseRecord.heaterEntries);

    // Track all supervisor IDs
    final Set<String> allSupervisorIds = {baseRecord.supervisorId};
    
    // Track the most recent creation date
    DateTime mostRecentCreatedAt = baseRecord.createdAt;
    DateTime? mostRecentUpdatedAt = baseRecord.updatedAt;

    // Merge data from other records
    for (int i = 1; i < records.length; i++) {
      final record = records[i];
      allSupervisorIds.add(record.supervisorId);

      // Update timestamps
      if (record.createdAt.isAfter(mostRecentCreatedAt)) {
        mostRecentCreatedAt = record.createdAt;
      }
      if (record.updatedAt != null && 
          (mostRecentUpdatedAt == null || record.updatedAt!.isAfter(mostRecentUpdatedAt))) {
        mostRecentUpdatedAt = record.updatedAt;
      }

      // Merge item counts (sum the values)
      for (final entry in record.itemCounts.entries) {
        final key = entry.key;
        final value = entry.value;
        mergedItemCounts[key] = (mergedItemCounts[key] ?? 0) + value;
      }

      // Merge text answers (keep non-empty values, prefer newer ones)
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

      // Merge yes/no with counts (sum the values)
      for (final entry in record.yesNoWithCounts.entries) {
        final key = entry.key;
        final value = entry.value;
        mergedYesNoWithCounts[key] = (mergedYesNoWithCounts[key] ?? 0) + value;
      }

      // Merge survey answers (keep non-empty values, prefer newer ones)
      for (final entry in record.surveyAnswers.entries) {
        final key = entry.key;
        final value = entry.value;
        if (value.isNotEmpty && (mergedSurveyAnswers[key]?.isEmpty ?? true)) {
          mergedSurveyAnswers[key] = value;
        }
      }

      // Merge maintenance notes (concatenate with line breaks)
      for (final entry in record.maintenanceNotes.entries) {
        final key = entry.key;
        final value = entry.value;
        if (value.isNotEmpty) {
          final existingNote = mergedMaintenanceNotes[key] ?? '';
          if (existingNote.isNotEmpty) {
            mergedMaintenanceNotes[key] = '$existingNote\n$value';
          } else {
            mergedMaintenanceNotes[key] = value;
          }
        }
      }

      // Merge fire safety alarm panel data (keep non-empty values)
      for (final entry in record.fireSafetyAlarmPanelData.entries) {
        final key = entry.key;
        final value = entry.value;
        if (value.isNotEmpty && (mergedFireSafetyAlarmPanelData[key]?.isEmpty ?? true)) {
          mergedFireSafetyAlarmPanelData[key] = value;
        }
      }

      // Merge fire safety condition only data (keep non-empty values)
      for (final entry in record.fireSafetyConditionOnlyData.entries) {
        final key = entry.key;
        final value = entry.value;
        if (value.isNotEmpty && (mergedFireSafetyConditionOnlyData[key]?.isEmpty ?? true)) {
          mergedFireSafetyConditionOnlyData[key] = value;
        }
      }

      // Merge fire safety expiry dates (keep non-empty values)
      for (final entry in record.fireSafetyExpiryDates.entries) {
        final key = entry.key;
        final value = entry.value;
        if (value.isNotEmpty && (mergedFireSafetyExpiryDates[key]?.isEmpty ?? true)) {
          mergedFireSafetyExpiryDates[key] = value;
        }
      }

      // Merge section photos (combine all photos)
      for (final entry in record.sectionPhotos.entries) {
        final key = entry.key;
        final photos = entry.value;
        if (photos.isNotEmpty) {
          final existingPhotos = mergedSectionPhotos[key] ?? [];
          mergedSectionPhotos[key] = [...existingPhotos, ...photos];
        }
      }

      // Merge heater entries (combine all entries)
      for (final entry in record.heaterEntries.entries) {
        final key = entry.key;
        final value = entry.value;
        
        if (value is List) {
          final existingList = mergedHeaterEntries[key] as List? ?? [];
          mergedHeaterEntries[key] = [...existingList, ...value];
        } else if (value is Map) {
          // For map values, merge them
          final existingMap = mergedHeaterEntries[key] as Map? ?? {};
          mergedHeaterEntries[key] = {...existingMap, ...value};
        } else {
          // For other types, keep the value if not already present
          if (!mergedHeaterEntries.containsKey(key)) {
            mergedHeaterEntries[key] = value;
          }
        }
      }
    }

    // Create merged record
    return MaintenanceCount(
      id: baseRecord.id, // Use the first record's ID
      schoolId: baseRecord.schoolId,
      schoolName: baseRecord.schoolName,
      supervisorId: allSupervisorIds.join(', '), // Combine all supervisor IDs
      status: records.any((r) => r.status == 'submitted') ? 'submitted' : 'draft',
      itemCounts: mergedItemCounts,
      textAnswers: mergedTextAnswers,
      yesNoAnswers: mergedYesNoAnswers,
      yesNoWithCounts: mergedYesNoWithCounts,
      surveyAnswers: mergedSurveyAnswers,
      maintenanceNotes: mergedMaintenanceNotes,
      fireSafetyAlarmPanelData: mergedFireSafetyAlarmPanelData,
      fireSafetyConditionOnlyData: mergedFireSafetyConditionOnlyData,
      fireSafetyExpiryDates: mergedFireSafetyExpiryDates,
      sectionPhotos: mergedSectionPhotos,
      heaterEntries: mergedHeaterEntries,
      createdAt: mostRecentCreatedAt,
      updatedAt: mostRecentUpdatedAt,
    );
  }
}
