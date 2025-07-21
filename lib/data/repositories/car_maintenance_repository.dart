import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/car_maintenance.dart';

class CarMaintenanceRepository {
  final SupabaseClient _client;

  CarMaintenanceRepository(this._client);

  /// Fetch car maintenance data for a specific supervisor
  Future<CarMaintenance?> getCarMaintenanceBySupervisorId(String supervisorId) async {
    try {
      final response = await _client
          .from('car_maintenance')
          .select('*')
          .eq('supervisor_id', supervisorId)
          .single();

      return CarMaintenance.fromMap(response);
    } catch (e) {
      // If no record found, return null instead of throwing
      if (e.toString().contains('No rows returned')) {
        return null;
      }
      throw Exception('Failed to fetch car maintenance: $e');
    }
  }

  /// Create or update car maintenance record
  Future<CarMaintenance> upsertCarMaintenance(CarMaintenance carMaintenance) async {
    try {
      final response = await _client
          .from('car_maintenance')
          .upsert(carMaintenance.toMap())
          .select()
          .single();

      return CarMaintenance.fromMap(response);
    } catch (e) {
      throw Exception('Failed to upsert car maintenance: $e');
    }
  }

  /// Update maintenance meter reading
  Future<CarMaintenance> updateMaintenanceMeter(
    String supervisorId,
    int maintenanceMeter,
    DateTime maintenanceMeterDate,
  ) async {
    try {
      final response = await _client
          .from('car_maintenance')
          .upsert({
            'supervisor_id': supervisorId,
            'maintenance_meter': maintenanceMeter,
            'maintenance_meter_date': maintenanceMeterDate.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return CarMaintenance.fromMap(response);
    } catch (e) {
      throw Exception('Failed to update maintenance meter: $e');
    }
  }

  /// Add tyre change record
  Future<CarMaintenance> addTyreChange(
    String supervisorId,
    TyreChange tyreChange,
  ) async {
    try {
      // First get existing record
      final existing = await getCarMaintenanceBySupervisorId(supervisorId);
      
      List<TyreChange> updatedTyreChanges = [];
      if (existing != null) {
        updatedTyreChanges = List.from(existing.tyreChanges);
      }
      updatedTyreChanges.add(tyreChange);

      final response = await _client
          .from('car_maintenance')
          .upsert({
            'supervisor_id': supervisorId,
            'tyre_changes': updatedTyreChanges.map((change) => change.toMap()).toList(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return CarMaintenance.fromMap(response);
    } catch (e) {
      throw Exception('Failed to add tyre change: $e');
    }
  }

  /// Get all car maintenance records (for admin purposes)
  Future<List<CarMaintenance>> getAllCarMaintenance() async {
    try {
      final response = await _client
          .from('car_maintenance')
          .select('*')
          .order('updated_at', ascending: false);

      return response
          .map<CarMaintenance>((data) => CarMaintenance.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch all car maintenance: $e');
    }
  }

  /// Delete car maintenance record
  Future<void> deleteCarMaintenance(String supervisorId) async {
    try {
      await _client
          .from('car_maintenance')
          .delete()
          .eq('supervisor_id', supervisorId);
    } catch (e) {
      throw Exception('Failed to delete car maintenance: $e');
    }
  }
} 