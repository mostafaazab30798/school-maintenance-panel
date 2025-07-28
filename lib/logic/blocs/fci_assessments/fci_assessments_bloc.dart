import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/repositories/fci_assessment_repository.dart';
import '../../../data/models/fci_assessment.dart';
import '../../../core/services/admin_service.dart';

// Events
abstract class FciAssessmentsEvent extends Equatable {
  const FciAssessmentsEvent();

  @override
  List<Object?> get props => [];
}

class FciAssessmentsStarted extends FciAssessmentsEvent {
  final String? status;
  final String? view;

  const FciAssessmentsStarted({this.status, this.view});

  @override
  List<Object?> get props => [status, view];
}

class FciAssessmentsRefresh extends FciAssessmentsEvent {
  final String? status;
  final String? view;

  const FciAssessmentsRefresh({this.status, this.view});

  @override
  List<Object?> get props => [status, view];
}

// States
abstract class FciAssessmentsState extends Equatable {
  const FciAssessmentsState();

  @override
  List<Object?> get props => [];
}

class FciAssessmentsInitial extends FciAssessmentsState {}

class FciAssessmentsLoading extends FciAssessmentsState {}

class FciAssessmentsLoaded extends FciAssessmentsState {
  final List<FciAssessment> assessments;
  final List<Map<String, dynamic>> schoolsWithAssessments;
  final String? status;
  final String? view;

  const FciAssessmentsLoaded({
    required this.assessments,
    required this.schoolsWithAssessments,
    this.status,
    this.view,
  });

  @override
  List<Object?> get props => [assessments, schoolsWithAssessments, status, view];

  FciAssessmentsLoaded copyWith({
    List<FciAssessment>? assessments,
    List<Map<String, dynamic>>? schoolsWithAssessments,
    String? status,
    String? view,
  }) {
    return FciAssessmentsLoaded(
      assessments: assessments ?? this.assessments,
      schoolsWithAssessments: schoolsWithAssessments ?? this.schoolsWithAssessments,
      status: status ?? this.status,
      view: view ?? this.view,
    );
  }
}

class FciAssessmentsFailure extends FciAssessmentsState {
  final String message;

  const FciAssessmentsFailure(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class FciAssessmentsBloc extends Bloc<FciAssessmentsEvent, FciAssessmentsState> {
  final FciAssessmentRepository _repository;
  final AdminService _adminService;

  FciAssessmentsBloc(this._repository, this._adminService) : super(FciAssessmentsInitial()) {
    on<FciAssessmentsStarted>(_onStarted);
    on<FciAssessmentsRefresh>(_onRefresh);
  }

  Future<void> _onStarted(
    FciAssessmentsStarted event,
    Emitter<FciAssessmentsState> emit,
  ) async {
    emit(FciAssessmentsLoading());
    await _loadData(emit, event.status, event.view);
  }

  Future<void> _onRefresh(
    FciAssessmentsRefresh event,
    Emitter<FciAssessmentsState> emit,
  ) async {
    await _loadData(emit, event.status, event.view);
  }

  Future<void> _loadData(
    Emitter<FciAssessmentsState> emit,
    String? status,
    String? view,
  ) async {
    try {
      // 🚀 FILTER: Get supervisor IDs assigned to the current admin
      final supervisorIds = await _adminService.getCurrentAdminSupervisorIds();
      print('🔍 FCI Assessment Bloc: Admin has ${supervisorIds.length} assigned supervisors: $supervisorIds');
      
      List<FciAssessment> assessments = [];
      List<Map<String, dynamic>> schoolsWithAssessments = [];

      if (view == 'schools') {
        // Load schools with assessments (filtered by admin's supervisors)
        schoolsWithAssessments = await _repository.getSchoolsWithAssessments(supervisorIds: supervisorIds);
      } else {
        // Load assessments with optional status filter (filtered by admin's supervisors)
        assessments = await _repository.getAllAssessments(supervisorIds: supervisorIds);
        
        // Filter by status if provided
        if (status != null) {
          assessments = assessments.where((assessment) => assessment.status == status).toList();
        }
      }

      emit(FciAssessmentsLoaded(
        assessments: assessments,
        schoolsWithAssessments: schoolsWithAssessments,
        status: status,
        view: view,
      ));
    } catch (e) {
      emit(FciAssessmentsFailure('فشل في تحميل بيانات تقييمات FCI: $e'));
    }
  }
} 