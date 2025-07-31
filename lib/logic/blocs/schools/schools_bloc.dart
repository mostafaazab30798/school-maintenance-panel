import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/services/school_assignment_service.dart';
import '../../../data/models/school.dart';
import '../../../data/models/supervisor.dart';
import '../../../data/repositories/supervisor_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'schools_event.dart';
part 'schools_state.dart';

class SchoolsBloc extends Bloc<SchoolsEvent, SchoolsState> {
  final AdminService _adminService;
  final SchoolAssignmentService _schoolService;
  final SupervisorRepository _supervisorRepository;

  SchoolsBloc()
      : _adminService = AdminService(Supabase.instance.client),
        _schoolService = SchoolAssignmentService(Supabase.instance.client),
        _supervisorRepository = SupervisorRepository(Supabase.instance.client),
        super(SchoolsInitial()) {
    on<SchoolsStarted>(_onSchoolsStarted);
    on<SchoolsRefreshed>(_onSchoolsRefreshed);
    on<SchoolsSearchChanged>(_onSchoolsSearchChanged);
  }

  Future<void> _onSchoolsStarted(
    SchoolsStarted event,
    Emitter<SchoolsState> emit,
  ) async {
    emit(SchoolsLoading());
    await _loadSchools(emit);
  }

  Future<void> _onSchoolsRefreshed(
    SchoolsRefreshed event,
    Emitter<SchoolsState> emit,
  ) async {
    emit(SchoolsLoading());
    await _loadSchools(emit);
  }

  void _onSchoolsSearchChanged(
    SchoolsSearchChanged event,
    Emitter<SchoolsState> emit,
  ) {
    if (state is SchoolsLoaded) {
      final currentState = state as SchoolsLoaded;
      final filteredSchools = _filterSchools(currentState.schools, event.query);
      emit(currentState.copyWith(
        filteredSchools: filteredSchools,
        searchQuery: event.query,
      ));
    }
  }

  Future<void> _loadSchools(Emitter<SchoolsState> emit) async {
    try {
      // Get current admin info
      final currentAdmin = await _adminService.getCurrentAdmin();
      if (currentAdmin == null) {
        throw Exception('لا يمكن العثور على بيانات المدير');
      }

      // Get supervisors under this admin
      final supervisors = await _supervisorRepository.fetchSupervisors(
        adminId: currentAdmin.id,
      );

      // 🚀 PERFORMANCE OPTIMIZATION: Get all schools in a single batch query
      final supervisorIds = supervisors.map((s) => s.id).toList();
      final schools = await _schoolService.getSchoolsForMultipleSupervisors(supervisorIds);
      emit(SchoolsLoaded(
        schools: schools,
        filteredSchools: schools,
        searchQuery: '',
      ));
    } catch (e) {
      emit(SchoolsError(e.toString()));
    }
  }

  List<School> _filterSchools(List<School> schools, String query) {
    if (query.isEmpty) return schools;

    return schools.where((school) {
      final name = school.name.toLowerCase();
      final address = school.address?.toLowerCase() ?? '';
      final searchQuery = query.toLowerCase();

      return name.contains(searchQuery) || address.contains(searchQuery);
    }).toList();
  }
} 