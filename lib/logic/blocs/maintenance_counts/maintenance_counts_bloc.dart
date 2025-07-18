import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/repositories/maintenance_count_repository.dart';
import '../../../data/repositories/damage_count_repository.dart';
import '../../../data/models/damage_count.dart';
import '../../../data/models/maintenance_count.dart';
import '../../../core/services/admin_service.dart';

part 'maintenance_counts_event.dart';
part 'maintenance_counts_state.dart';

class MaintenanceCountsBloc
    extends Bloc<MaintenanceCountsEvent, MaintenanceCountsState> {
  final MaintenanceCountRepository _repository;
  final DamageCountRepository _damageRepository;
  final AdminService _adminService;

  MaintenanceCountsBloc({
    required MaintenanceCountRepository repository,
    required DamageCountRepository damageRepository,
    required AdminService adminService,
  })  : _repository = repository,
        _damageRepository = damageRepository,
        _adminService = adminService,
        super(MaintenanceCountsInitial()) {
    on<LoadSchoolsWithCounts>(_onLoadSchoolsWithCounts);
    on<LoadMaintenanceCountRecords>(_onLoadMaintenanceCountRecords);
    on<LoadDamageCountRecords>(_onLoadDamageCountRecords);
    on<LoadSchoolsWithDamage>(_onLoadSchoolsWithDamage);
    on<LoadMaintenanceCountSummary>(_onLoadMaintenanceCountSummary);
    on<RefreshMaintenanceCounts>(_onRefreshMaintenanceCounts);
    on<LoadDamageCountDetails>(_onLoadDamageCountDetails);
    on<LoadDamageCountSummary>(_onLoadDamageCountSummary);
    on<SaveDamageCount>(_onSaveDamageCount);
  }

  Future<void> _onLoadSchoolsWithCounts(
    LoadSchoolsWithCounts event,
    Emitter<MaintenanceCountsState> emit,
  ) async {
    emit(MaintenanceCountsLoading());

    try {
      // Check admin access
      final admin = await _adminService.getCurrentAdmin();

      if (admin == null) {
        emit(const MaintenanceCountsError('Admin profile not found'));
        return;
      }

      // Get supervisor IDs if regular admin
      List<String> supervisorIds = [];
      if (admin.role == 'admin') {
        // For regular admins, get ALL their assigned supervisor IDs
        supervisorIds = await _adminService.getCurrentAdminSupervisorIds();
      }
      // For super admins, supervisorIds remains empty (no filtering)

      final schools = await _repository.getSchoolsWithMaintenanceCounts(
        supervisorIds: supervisorIds, // Pass all supervisor IDs
      );

      emit(SchoolsWithCountsLoaded(schools: schools));
    } catch (e) {
      emit(MaintenanceCountsError('Failed to load schools with counts: $e'));
    }
  }

  Future<void> _onLoadMaintenanceCountRecords(
    LoadMaintenanceCountRecords event,
    Emitter<MaintenanceCountsState> emit,
  ) async {
    emit(MaintenanceCountsLoading());

    try {
      print('🔍 DEBUG: Starting _onLoadMaintenanceCountRecords');
      
      // Check admin access
      final admin = await _adminService.getCurrentAdmin();
      print('🔍 DEBUG: Admin found: ${admin != null}');
      print('🔍 DEBUG: Admin role: ${admin?.role}');

      if (admin == null) {
        print('❌ ERROR: Admin profile not found');
        emit(const MaintenanceCountsError('Admin profile not found'));
        return;
      }

      // Get supervisor IDs if regular admin
      List<String> supervisorIds = [];
      if (admin.role == 'admin') {
        // For regular admins, get ALL their assigned supervisor IDs
        print('🔍 DEBUG: Getting ALL supervisor IDs for regular admin');
        supervisorIds = await _adminService.getCurrentAdminSupervisorIds();
        print('🔍 DEBUG: All Supervisor IDs: $supervisorIds');
      }
      // For super admins, supervisorIds remains empty (no filtering - can see all data)
      print('🔍 DEBUG: Final supervisor IDs: $supervisorIds');

      print('🔍 DEBUG: Calling repository.getAllMaintenanceCountRecords');
      final records = await _repository.getAllMaintenanceCountRecords(
        supervisorIds: supervisorIds, // Pass all supervisor IDs
        schoolId: event.schoolId,
        status: event.status,
      );

      print('🔍 DEBUG: Repository returned ${records.length} records');
      if (records.isNotEmpty) {
        print('🔍 DEBUG: First record school: ${records.first.schoolName}');
        print('🔍 DEBUG: First record status: ${records.first.status}');
      }

      emit(MaintenanceCountRecordsLoaded(records: records));
    } catch (e, stackTrace) {
      print('❌ ERROR: Failed to load maintenance count records: $e');
      print('❌ ERROR: Stack trace: $stackTrace');
      emit(MaintenanceCountsError('Failed to load maintenance count records: $e'));
    }
  }

  Future<void> _onLoadDamageCountRecords(
    LoadDamageCountRecords event,
    Emitter<MaintenanceCountsState> emit,
  ) async {
    emit(MaintenanceCountsLoading());

    try {
      // Check admin access
      final admin = await _adminService.getCurrentAdmin();

      if (admin == null) {
        emit(const MaintenanceCountsError('Admin profile not found'));
        return;
      }

      // Get supervisor IDs if regular admin
      List<String> supervisorIds = [];
      if (admin.role == 'admin') {
        // For regular admins, get ALL their assigned supervisor IDs
        supervisorIds = await _adminService.getCurrentAdminSupervisorIds();
      }
      // For super admins, supervisorIds remains empty (no filtering)

      final records = await _damageRepository.getAllDamageCountRecords(
        supervisorIds: supervisorIds, // Pass all supervisor IDs
        schoolId: event.schoolId,
        status: event.status,
      );

      emit(DamageCountRecordsLoaded(records: records));
    } catch (e) {
      emit(MaintenanceCountsError('Failed to load damage count records: $e'));
    }
  }

  Future<void> _onLoadSchoolsWithDamage(
    LoadSchoolsWithDamage event,
    Emitter<MaintenanceCountsState> emit,
  ) async {
    emit(MaintenanceCountsLoading());

    try {
      // Check admin access
      final admin = await _adminService.getCurrentAdmin();

      if (admin == null) {
        emit(const MaintenanceCountsError('Admin profile not found'));
        return;
      }

      // Get supervisor IDs if regular admin
      List<String> supervisorIds = [];
      if (admin.role == 'admin') {
        // For regular admins, get ALL their assigned supervisor IDs
        supervisorIds = await _adminService.getCurrentAdminSupervisorIds();
      }
      // For super admins, supervisorIds remains empty (no filtering)

      final schools = await _damageRepository.getSchoolsWithDamageCounts(
        supervisorIds: supervisorIds, // Pass all supervisor IDs
      );

      emit(SchoolsWithDamageLoaded(schools: schools));
    } catch (e) {
      emit(MaintenanceCountsError('Failed to load schools with damage: $e'));
    }
  }

  Future<void> _onLoadMaintenanceCountSummary(
    LoadMaintenanceCountSummary event,
    Emitter<MaintenanceCountsState> emit,
  ) async {
    emit(MaintenanceCountsLoading());

    try {
      // Check admin access
      final admin = await _adminService.getCurrentAdmin();
      if (admin == null) {
        emit(const MaintenanceCountsError('Admin profile not found'));
        return;
      }

      // Get supervisor IDs if regular admin
      List<String> supervisorIds = [];
      if (admin.role == 'admin') {
        // For regular admins, get ALL their assigned supervisor IDs
        supervisorIds = await _adminService.getCurrentAdminSupervisorIds();
      }

      final summary = await _repository.getDashboardSummary(
        supervisorIds: supervisorIds, // Pass all supervisor IDs
      );

      emit(MaintenanceCountSummaryLoaded(summary: summary));
    } catch (e) {
      emit(MaintenanceCountsError(
          'Failed to load maintenance count summary: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshMaintenanceCounts(
    RefreshMaintenanceCounts event,
    Emitter<MaintenanceCountsState> emit,
  ) async {
    // Refresh the current state based on the last successful load
    if (state is SchoolsWithCountsLoaded) {
      add(const LoadSchoolsWithCounts());
    } else if (state is MaintenanceCountRecordsLoaded) {
      add(const LoadMaintenanceCountRecords());
    } else if (state is SchoolsWithDamageLoaded) {
      add(const LoadSchoolsWithDamage());
    } else if (state is MaintenanceCountSummaryLoaded) {
      add(const LoadMaintenanceCountSummary());
    } else if (state is DamageCountRecordsLoaded) {
      add(const LoadDamageCountRecords());
    }
  }

  Future<void> _onLoadDamageCountDetails(
    LoadDamageCountDetails event,
    Emitter<MaintenanceCountsState> emit,
  ) async {
    emit(MaintenanceCountsLoading());

    try {
      // Check admin access
      final admin = await _adminService.getCurrentAdmin();
      if (admin == null) {
        emit(const MaintenanceCountsError('Admin profile not found'));
        return;
      }

      print('🔍 DEBUG: Loading damage count details for school: ${event.schoolId}');
      print('🔍 DEBUG: Admin role: ${admin.role}');

      DamageCount? damageCount;

      if (admin.role == 'super_admin') {
        // For super admins, get all damage counts and use the most recent one
        print('🔍 DEBUG: Super admin - getting all damage counts for school');
        final allDamageCounts = await _damageRepository.getAllDamageCountsForSchool(
          schoolId: event.schoolId,
        );
        
        if (allDamageCounts.isNotEmpty) {
          damageCount = allDamageCounts.first; // Most recent one
          print('🔍 DEBUG: Super admin found ${allDamageCounts.length} damage counts, using most recent');
        } else {
          print('🔍 DEBUG: Super admin found no damage counts for school');
        }
      } else {
        // For regular admins, get supervisor IDs and try to find damage count for any of them
        final supervisorIds = await _adminService.getCurrentAdminSupervisorIds();
        print('🔍 DEBUG: Regular admin - found ${supervisorIds.length} supervisor IDs: $supervisorIds');

        if (supervisorIds.isNotEmpty) {
          // Try to find damage count for any of the assigned supervisors
          for (final supervisorId in supervisorIds) {
            try {
              print('🔍 DEBUG: Trying supervisor ID: $supervisorId');
              final result = await _damageRepository.getDamageCountBySchool(
                schoolId: event.schoolId,
                supervisorId: supervisorId,
              );
              if (result != null) {
                damageCount = result;
                print('🔍 DEBUG: Found damage count for supervisor: $supervisorId');
                break; // Found a damage count, no need to check other supervisors
              } else {
                print('🔍 DEBUG: No damage count found for supervisor: $supervisorId');
              }
            } catch (e) {
              print('⚠️ WARNING: Failed to check supervisor $supervisorId: $e');
              continue; // Try next supervisor
            }
          }
        } else {
          print('🔍 DEBUG: Regular admin has no assigned supervisors');
        }
      }

      if (damageCount != null) {
        print('🔍 DEBUG: Successfully found damage count: ${damageCount.id}');
        emit(DamageCountDetailsLoaded(damageCount: damageCount));
      } else {
        print('🔍 DEBUG: No damage count found for school: ${event.schoolId}');
        emit(const MaintenanceCountsError(
            'No damage count found for this school'));
      }
    } catch (e) {
      print('❌ ERROR: Failed to load damage count details: $e');
      emit(MaintenanceCountsError('Failed to load damage count details: $e'));
    }
  }

  Future<void> _onLoadDamageCountSummary(
    LoadDamageCountSummary event,
    Emitter<MaintenanceCountsState> emit,
  ) async {
    emit(MaintenanceCountsLoading());

    try {
      // Check admin access
      final admin = await _adminService.getCurrentAdmin();
      if (admin == null) {
        emit(const MaintenanceCountsError('Admin profile not found'));
        return;
      }

      // Get supervisor IDs if regular admin
      List<String> supervisorIds = [];
      if (admin.role == 'admin') {
        // For regular admins, get ALL their assigned supervisor IDs
        supervisorIds = await _adminService.getCurrentAdminSupervisorIds();
      }

      final summary = await _damageRepository.getDashboardSummary(
        supervisorIds: supervisorIds, // Pass all supervisor IDs
      );

      emit(DamageCountSummaryLoaded(summary: summary));
    } catch (e) {
      emit(MaintenanceCountsError('Failed to load damage count summary: $e'));
    }
  }

  Future<void> _onSaveDamageCount(
    SaveDamageCount event,
    Emitter<MaintenanceCountsState> emit,
  ) async {
    emit(MaintenanceCountsLoading());

    try {
      // Check admin access
      final admin = await _adminService.getCurrentAdmin();
      if (admin == null) {
        emit(const MaintenanceCountsError('Admin profile not found'));
        return;
      }

      // Get supervisor ID
      String? supervisorId = admin.id;
      if (admin.role == 'admin') {
        final supervisorIds =
            await _adminService.getCurrentAdminSupervisorIds();
        if (supervisorIds.isNotEmpty) {
          supervisorId = supervisorIds.first;
        }
      }

      if (supervisorId == null) {
        emit(const MaintenanceCountsError('Supervisor not found'));
        return;
      }

      final damageCount = DamageCount(
        id: '', // Will be generated by database
        schoolId: event.schoolId,
        schoolName: event.schoolName,
        supervisorId: supervisorId,
        itemCounts: event.itemCounts,
        createdAt: DateTime.now(),
      );

      final savedDamageCount =
          await _damageRepository.upsertDamageCount(damageCount);

      emit(DamageCountSaved(damageCount: savedDamageCount));
    } catch (e) {
      emit(MaintenanceCountsError('Failed to save damage count: $e'));
    }
  }
}
