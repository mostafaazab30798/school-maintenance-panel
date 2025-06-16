import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/supervisor.dart';
import '../../../data/repositories/supervisor_repository.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/mixins/admin_filter_mixin.dart';
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
}
