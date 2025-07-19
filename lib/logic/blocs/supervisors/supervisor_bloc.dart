import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/supervisor.dart';
import '../../../data/repositories/supervisor_repository.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/services/bloc_manager.dart';
import '../../../core/services/cache_invalidation_service.dart';
import '../../../core/services/school_assignment_service.dart';
import '../../../core/mixins/admin_filter_mixin.dart';
import '../super_admin/super_admin_event.dart';
import '../super_admin/super_admin_state.dart';
import 'supervisor_event.dart';
import 'supervisor_state.dart';
import 'dart:async';

/// Bloc for managing supervisor-related state and events
class SupervisorBloc extends Bloc<SupervisorEvent, SupervisorState>
    with AdminFilterMixin {
  final SupervisorRepository supervisorRepository;

  @override
  final AdminService adminService;

  SupervisorBloc(this.supervisorRepository, this.adminService)
      : super(SupervisorInitial()) {
    on<SupervisorsStarted>(_onSupervisorsStarted);
    on<SupervisorFetched>(_onSupervisorFetched);
    on<SupervisorAdded>(_onSupervisorAdded);
    // Add new handlers for technician management
    on<SupervisorTechniciansUpdated>(_onTechniciansUpdated);
    on<TechnicianAdded>(_onTechnicianAdded);
    on<TechnicianRemoved>(_onTechnicianRemoved);
    on<SupervisorUpdated>(_onSupervisorUpdated);
    on<SchoolRemovedFromSupervisor>(_onSchoolRemovedFromSupervisor);
    on<SchoolsRemovedFromSupervisor>(_onSchoolsRemovedFromSupervisor);
  }



  Future<void> _onSupervisorsStarted(
      SupervisorsStarted event, Emitter<SupervisorState> emit) async {
    emit(SupervisorLoading());
    try {
      logAdminFilterDebug('Starting supervisor fetch with admin filtering',
          context: 'SupervisorBloc');

      // Use AdminFilterMixin to apply admin-based filtering
      // Note: For supervisors, the repository already has the logic, so we'll use a simpler approach
      final isSuperAdmin = await this.isSuperAdmin();
      logAdminFilterDebug(
          'Admin type: ${isSuperAdmin ? 'Super Admin' : 'Regular Admin'}',
          context: 'SupervisorBloc');

      List<Supervisor> supervisors;

      if (isSuperAdmin) {
        // Super admin sees all supervisors
        logAdminFilterDebug('Fetching all supervisors for super admin',
            context: 'SupervisorBloc');
        supervisors = await supervisorRepository.fetchSupervisors();
      } else {
        // Regular admin sees only their assigned supervisors
        logAdminFilterDebug('Fetching assigned supervisors for regular admin',
            context: 'SupervisorBloc');
        supervisors =
            await supervisorRepository.fetchSupervisorsForCurrentAdmin();
      }

      logAdminFilterDebug(
          'Supervisor fetch completed: ${supervisors.length} supervisors',
          context: 'SupervisorBloc');

      emit(SupervisorLoaded(supervisors));
    } catch (e) {
      logAdminFilterDebug('Supervisor fetch error: $e',
          context: 'SupervisorBloc');
      emit(SupervisorError(e.toString()));
    }
  }

  Future<void> _onSupervisorFetched(
      SupervisorFetched event, Emitter<SupervisorState> emit) async {
    emit(SupervisorLoading());
    try {
      final supervisors =
          await supervisorRepository.fetchSupervisorsForCurrentAdmin();
      emit(SupervisorLoaded(supervisors));
    } catch (e) {
      emit(SupervisorError(e.toString()));
    }
  }

  Future<void> _onSupervisorAdded(
      SupervisorAdded event, Emitter<SupervisorState> emit) async {
    emit(SupervisorLoading());
    try {
      // Generate a unique ID for the new supervisor
      final id = const Uuid().v4();

      // Create a new supervisor object
      final supervisor = Supervisor(
        id: id,
        username: event.username,
        email: event.email,
        phone: event.phone,
        createdAt: DateTime.now(),
        iqamaId: event.iqamaId,
        plateNumbers: event.plateNumbers,
        plateEnglishLetters: event.plateEnglishLetters,
        plateArabicLetters: event.plateArabicLetters,
        workId: event.workId,
      );

      // Save the supervisor to the repository
      // This will also create a Supabase Auth user and link it to the supervisor
      await supervisorRepository.createSupervisor(supervisor);

      // The supervisor is now registered in Supabase Auth
      // They can use the mobile app to request a magic link with their email

      // Check if current user is super admin to determine which supervisors to reload
      final isSuperAdmin = await this.isSuperAdmin();
      List<Supervisor> supervisors;

      if (isSuperAdmin) {
        supervisors = await supervisorRepository.fetchSupervisors();
      } else {
        supervisors =
            await supervisorRepository.fetchSupervisorsForCurrentAdmin();
      }

      emit(SupervisorLoaded(supervisors));
    } catch (e) {
      emit(SupervisorError(e.toString()));
    }
  }

  Future<void> _onSupervisorUpdated(
      SupervisorUpdated event, Emitter<SupervisorState> emit) async {
    emit(SupervisorUpdating(supervisorId: event.id));
    try {
      // Update the supervisor in the repository
      final updates = {
        'username': event.username,
        'phone': event.phone,
        'iqama_id': event.iqamaId,
        'plate_numbers': event.plateNumbers,
        'plate_english_letters': event.plateEnglishLetters,
        'plate_arabic_letters': event.plateArabicLetters,
        'work_id': event.workId,
      };
      
      // Only update email if provided (for backward compatibility)
      if (event.email != null) {
        updates['email'] = event.email!;
      }
      
      await supervisorRepository.updateSupervisor(event.id, updates);

      // 🚀 Critical Fix: Clear all supervisor-related caches
      CacheInvalidationService.invalidateSupervisorCaches();

      // Reload supervisors to reflect changes
      final isSuperAdmin = await this.isSuperAdmin();
      List<Supervisor> supervisors;

      if (isSuperAdmin) {
        supervisors = await supervisorRepository.fetchSupervisors();
      } else {
        supervisors =
            await supervisorRepository.fetchSupervisorsForCurrentAdmin();
      }

      emit(SupervisorLoaded(supervisors));

      // Also refresh SuperAdminBloc to update all UI screens
      try {
        final superAdminBloc = BlocManager().getSuperAdminBloc();
        superAdminBloc.add(LoadSuperAdminData(forceRefresh: true));
        print('SupervisorBloc: Triggered SuperAdminBloc refresh after updating supervisor');
      } catch (e) {
        print('SupervisorBloc: Failed to refresh SuperAdminBloc: $e');
      }
    } catch (e) {
      emit(SupervisorError('Failed to update supervisor: $e'));
    }
  }

  Future<void> _onTechniciansUpdated(
    SupervisorTechniciansUpdated event,
    Emitter<SupervisorState> emit,
  ) async {
    print(
        'SupervisorBloc: Updating technicians for ${event.supervisorId} with ${event.technicians}');

    emit(SupervisorTechnicianUpdating(
      supervisorId: event.supervisorId,
      operation: 'update',
    ));

    try {
      // 🚀 Critical Fix: Use SuperAdminBloc to handle the update directly
      // This ensures immediate UI updates like supervisor assignment does
      final superAdminBloc = BlocManager().getSuperAdminBloc();
      superAdminBloc.add(SupervisorTechniciansUpdatedEvent(
        supervisorId: event.supervisorId,
        technicians: event.technicians,
      ));

      print('SupervisorBloc: Delegated technician update to SuperAdminBloc');

      // Wait for SuperAdminBloc to complete its update
      await superAdminBloc.stream
          .firstWhere((state) => state is SuperAdminLoaded)
          .timeout(const Duration(seconds: 10));

      print('SupervisorBloc: SuperAdminBloc update completed');

      // Now update local supervisor state
      final isSuperAdmin = await this.isSuperAdmin();
      List<Supervisor> supervisors;

      if (isSuperAdmin) {
        supervisors = await supervisorRepository.fetchSupervisors();
      } else {
        supervisors =
            await supervisorRepository.fetchSupervisorsForCurrentAdmin();
      }

      emit(SupervisorLoaded(supervisors));
      print('SupervisorBloc: Local supervisor state updated');
    } catch (e) {
      print('SupervisorBloc: Error updating technicians: $e');
      emit(SupervisorError('Failed to update technicians: $e'));
    }
  }

  Future<void> _onTechnicianAdded(
    TechnicianAdded event,
    Emitter<SupervisorState> emit,
  ) async {
    emit(SupervisorTechnicianUpdating(
      supervisorId: event.supervisorId,
      operation: 'add',
    ));

    try {
      await supervisorRepository.addTechnicianToSupervisor(
        event.supervisorId,
        event.technicianName,
      );

      // 🚀 Critical Fix: Clear all supervisor-related caches
      CacheInvalidationService.invalidateSupervisorCaches();
      print('SupervisorBloc: Caches invalidated after adding technician');

      // Add a small delay to ensure database changes are committed
      await Future.delayed(const Duration(milliseconds: 100));

      // Reload supervisors to reflect changes
      add(const SupervisorsStarted());

      // Also refresh SuperAdminBloc to update all UI screens
      try {
        final superAdminBloc = BlocManager().getSuperAdminBloc();
        superAdminBloc.add(LoadSuperAdminData(forceRefresh: true));
        print(
            'SupervisorBloc: Triggered SuperAdminBloc refresh after adding technician');

        // Give the SuperAdminBloc time to process the refresh
        await Future.delayed(const Duration(milliseconds: 200));
        print('SupervisorBloc: Add technician refresh completed');
      } catch (e) {
        print('SupervisorBloc: Failed to refresh SuperAdminBloc: $e');
      }
    } catch (e) {
      emit(SupervisorError('Failed to add technician: $e'));
    }
  }

  Future<void> _onTechnicianRemoved(
    TechnicianRemoved event,
    Emitter<SupervisorState> emit,
  ) async {
    emit(SupervisorTechnicianUpdating(
      supervisorId: event.supervisorId,
      operation: 'remove',
    ));

    try {
      await supervisorRepository.removeTechnicianFromSupervisor(
        event.supervisorId,
        event.technicianName,
      );

      // 🚀 Critical Fix: Clear all supervisor-related caches
      CacheInvalidationService.invalidateSupervisorCaches();
      print('SupervisorBloc: Caches invalidated after removing technician');

      // Add a small delay to ensure database changes are committed
      await Future.delayed(const Duration(milliseconds: 100));

      // Reload supervisors to reflect changes
      add(const SupervisorsStarted());

      // Also refresh SuperAdminBloc to update all UI screens
      try {
        final superAdminBloc = BlocManager().getSuperAdminBloc();
        superAdminBloc.add(LoadSuperAdminData(forceRefresh: true));
        print(
            'SupervisorBloc: Triggered SuperAdminBloc refresh after removing technician');

        // Give the SuperAdminBloc time to process the refresh
        await Future.delayed(const Duration(milliseconds: 200));
        print('SupervisorBloc: Remove technician refresh completed');
      } catch (e) {
        print('SupervisorBloc: Failed to refresh SuperAdminBloc: $e');
      }
    } catch (e) {
      emit(SupervisorError('Failed to remove technician: $e'));
    }
  }

  Future<void> _onSchoolRemovedFromSupervisor(
    SchoolRemovedFromSupervisor event,
    Emitter<SupervisorState> emit,
  ) async {
    print('🔍 DEBUG: _onSchoolRemovedFromSupervisor called');
    print('🔍 DEBUG: supervisorId: ${event.supervisorId}');
    print('🔍 DEBUG: schoolId: ${event.schoolId}');
    
    emit(SupervisorSchoolRemoving(
      supervisorId: event.supervisorId,
      schoolId: event.schoolId,
    ));

    try {
      // Import the school assignment service
      final schoolService = SchoolAssignmentService(Supabase.instance.client);
      
      // Remove the school assignment
      await schoolService.removeSchoolFromSupervisor(
        event.supervisorId,
        event.schoolId,
      );

      // 🚀 Critical Fix: Clear all supervisor-related caches
      CacheInvalidationService.invalidateSupervisorCaches();
      print('SupervisorBloc: Caches invalidated after removing school');

      // Add a small delay to ensure database changes are committed
      await Future.delayed(const Duration(milliseconds: 100));

      // Reload supervisors to reflect changes
      add(const SupervisorsStarted());

      // Also refresh SuperAdminBloc to update all UI screens
      try {
        final superAdminBloc = BlocManager().getSuperAdminBloc();
        superAdminBloc.add(LoadSuperAdminData(forceRefresh: true));
        print(
            'SupervisorBloc: Triggered SuperAdminBloc refresh after removing school');

        // Give the SuperAdminBloc time to process the refresh
        await Future.delayed(const Duration(milliseconds: 200));
        print('SupervisorBloc: Remove school refresh completed');
      } catch (e) {
        print('SupervisorBloc: Failed to refresh SuperAdminBloc: $e');
      }
    } catch (e) {
      emit(SupervisorError('Failed to remove school: $e'));
    }
  }

  Future<void> _onSchoolsRemovedFromSupervisor(
    SchoolsRemovedFromSupervisor event,
    Emitter<SupervisorState> emit,
  ) async {
    emit(SupervisorSchoolsRemoving(
      supervisorId: event.supervisorId,
      schoolIds: event.schoolIds,
    ));

    try {
      // Import the school assignment service
      final schoolService = SchoolAssignmentService(Supabase.instance.client);
      
      // Remove the school assignments
      await schoolService.removeSchoolsFromSupervisor(
        event.supervisorId,
        event.schoolIds,
      );

      // 🚀 Critical Fix: Clear all supervisor-related caches
      CacheInvalidationService.invalidateSupervisorCaches();
      print('SupervisorBloc: Caches invalidated after removing schools');

      // Add a small delay to ensure database changes are committed
      await Future.delayed(const Duration(milliseconds: 100));

      // Reload supervisors to reflect changes
      add(const SupervisorsStarted());

      // Also refresh SuperAdminBloc to update all UI screens
      try {
        final superAdminBloc = BlocManager().getSuperAdminBloc();
        superAdminBloc.add(LoadSuperAdminData(forceRefresh: true));
        print(
            'SupervisorBloc: Triggered SuperAdminBloc refresh after removing schools');

        // Give the SuperAdminBloc time to process the refresh
        await Future.delayed(const Duration(milliseconds: 200));
        print('SupervisorBloc: Remove schools refresh completed');
      } catch (e) {
        print('SupervisorBloc: Failed to refresh SuperAdminBloc: $e');
      }
    } catch (e) {
      emit(SupervisorError('Failed to remove schools: $e'));
    }
  }
}
