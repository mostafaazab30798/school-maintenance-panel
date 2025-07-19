import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Base event class for supervisor-related events
@immutable
abstract class SupervisorEvent extends Equatable {
  const SupervisorEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all supervisors
class SupervisorsStarted extends SupervisorEvent {
  const SupervisorsStarted();
}

/// Event to fetch a specific supervisor by ID
class SupervisorFetched extends SupervisorEvent {
  final String id;

  const SupervisorFetched(this.id);

  @override
  List<Object?> get props => [id];
}

/// Event to add a new supervisor
class SupervisorAdded extends SupervisorEvent {
  final String username;
  final String email;
  final String phone;
  final String iqamaId;
  final String plateNumbers;
  final String plateEnglishLetters;
  final String plateArabicLetters;
  final String workId;

  const SupervisorAdded({
    required this.username,
    required this.email,
    required this.phone,
    required this.iqamaId,
    required this.plateNumbers,
    required this.plateEnglishLetters,
    required this.plateArabicLetters,
    required this.workId,
  });

  @override
  List<Object?> get props => [
        username,
        email,
        phone,
        iqamaId,
        plateNumbers,
        plateEnglishLetters,
        plateArabicLetters,
        workId,
      ];
}

/// Event to update technicians for a supervisor
class SupervisorTechniciansUpdated extends SupervisorEvent {
  final String supervisorId;
  final List<String> technicians;

  const SupervisorTechniciansUpdated({
    required this.supervisorId,
    required this.technicians,
  });

  @override
  List<Object?> get props => [supervisorId, technicians];
}

/// Event to add a technician to supervisor
class TechnicianAdded extends SupervisorEvent {
  final String supervisorId;
  final String technicianName;

  const TechnicianAdded({
    required this.supervisorId,
    required this.technicianName,
  });

  @override
  List<Object?> get props => [supervisorId, technicianName];
}

/// Event to remove a technician from supervisor
class TechnicianRemoved extends SupervisorEvent {
  final String supervisorId;
  final String technicianName;

  const TechnicianRemoved({
    required this.supervisorId,
    required this.technicianName,
  });

  @override
  List<Object?> get props => [supervisorId, technicianName];
}

/// Event to update supervisor data
class SupervisorUpdated extends SupervisorEvent {
  final String id;
  final String username;
  final String? email; // Optional since it's read-only
  final String phone;
  final String iqamaId;
  final String plateNumbers;
  final String plateEnglishLetters;
  final String plateArabicLetters;
  final String workId;

  const SupervisorUpdated({
    required this.id,
    required this.username,
    this.email, // Optional since it's read-only
    required this.phone,
    required this.iqamaId,
    required this.plateNumbers,
    required this.plateEnglishLetters,
    required this.plateArabicLetters,
    required this.workId,
  });

  @override
  List<Object?> get props => [
        id,
        username,
        email,
        phone,
        iqamaId,
        plateNumbers,
        plateEnglishLetters,
        plateArabicLetters,
        workId,
      ];
}

/// Event to remove a school from supervisor
class SchoolRemovedFromSupervisor extends SupervisorEvent {
  final String supervisorId;
  final String schoolId;

  const SchoolRemovedFromSupervisor({
    required this.supervisorId,
    required this.schoolId,
  });

  @override
  List<Object?> get props => [supervisorId, schoolId];
}

/// Event to remove multiple schools from supervisor
class SchoolsRemovedFromSupervisor extends SupervisorEvent {
  final String supervisorId;
  final List<String> schoolIds;

  const SchoolsRemovedFromSupervisor({
    required this.supervisorId,
    required this.schoolIds,
  });

  @override
  List<Object?> get props => [supervisorId, schoolIds];
}
