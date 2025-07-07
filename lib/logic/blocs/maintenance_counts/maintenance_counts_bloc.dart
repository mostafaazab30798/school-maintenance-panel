import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/repositories/maintenance_count_repository.dart';
import '../../../data/repositories/damage_count_repository.dart';
import '../../../data/models/damage_count.dart';
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

      // Get supervisor ID if regular admin
      String? supervisorId;
      if (admin.role == 'admin') {
        // For regular admins, get their assigned supervisor IDs
        final supervisorIds =
            await _adminService.getCurrentAdminSupervisorIds();
        if (supervisorIds.isNotEmpty) {
          supervisorId =
              supervisorIds.first; // Use first supervisor for filtering
        }
      }
      // For super admins, supervisorId remains null (no filtering)

      final schools = await _repository.getSchoolsWithMaintenanceCounts(
        supervisorId: supervisorId,
      );

      emit(SchoolsWithCountsLoaded(schools: schools));
    } catch (e) {
      emit(MaintenanceCountsError('Failed to load schools with counts: $e'));
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

      // Get supervisor ID if regular admin
      String? supervisorId;
      if (admin.role == 'admin') {
        // For regular admins, get their assigned supervisor IDs
        final supervisorIds =
            await _adminService.getCurrentAdminSupervisorIds();
        if (supervisorIds.isNotEmpty) {
          supervisorId =
              supervisorIds.first; // Use first supervisor for filtering
        }
      }
      // For super admins, supervisorId remains null (no filtering)

      final schools = await _damageRepository.getSchoolsWithDamageCounts(
        supervisorId: supervisorId,
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

      // Get supervisor ID if regular admin
      String? supervisorId;
      if (admin.role == 'admin') {
        // For regular admins, get their assigned supervisor IDs
        final supervisorIds =
            await _adminService.getCurrentAdminSupervisorIds();
        if (supervisorIds.isNotEmpty) {
          supervisorId = supervisorIds.first; // Use first supervisor ID
        }
      }

      final summary = await _repository.getDashboardSummary(
        supervisorId: supervisorId,
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
    } else if (state is SchoolsWithDamageLoaded) {
      add(const LoadSchoolsWithDamage());
    } else if (state is MaintenanceCountSummaryLoaded) {
      add(const LoadMaintenanceCountSummary());
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

      // Get supervisor ID if regular admin
      String? supervisorId;
      if (admin.role == 'admin') {
        final supervisorIds =
            await _adminService.getCurrentAdminSupervisorIds();
        if (supervisorIds.isNotEmpty) {
          supervisorId = supervisorIds.first;
        }
      }

      final damageCount = await _damageRepository.getDamageCountBySchool(
        schoolId: event.schoolId,
        supervisorId: supervisorId,
      );

      if (damageCount != null) {
        emit(DamageCountDetailsLoaded(damageCount: damageCount));
      } else {
        emit(const MaintenanceCountsError(
            'No damage count found for this school'));
      }
    } catch (e) {
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

      // Get supervisor ID if regular admin
      String? supervisorId;
      if (admin.role == 'admin') {
        final supervisorIds =
            await _adminService.getCurrentAdminSupervisorIds();
        if (supervisorIds.isNotEmpty) {
          supervisorId = supervisorIds.first;
        }
      }

      final summary = await _damageRepository.getDashboardSummary(
        supervisorId: supervisorId,
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
