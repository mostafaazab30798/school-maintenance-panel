abstract class SuperAdminEvent {}

class LoadSuperAdminData extends SuperAdminEvent {
  final bool forceRefresh;
  LoadSuperAdminData({this.forceRefresh = false});
}

class CreateNewAdmin extends SuperAdminEvent {
  final String name;
  final String email;
  final String authUserId;

  CreateNewAdmin({
    required this.name,
    required this.email,
    required this.authUserId,
  });
}

class DeleteAdminEvent extends SuperAdminEvent {
  final String adminId;
  DeleteAdminEvent(this.adminId);
}

class AssignSupervisorsToAdmin extends SuperAdminEvent {
  final String adminId;
  final List<String> supervisorIds;

  AssignSupervisorsToAdmin({
    required this.adminId,
    required this.supervisorIds,
  });
}

class CreateNewAdminComplete extends SuperAdminEvent {
  final String name;
  final String email;
  final String password;
  final String role;

  CreateNewAdminComplete({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });
}

class CreateNewAdminManual extends SuperAdminEvent {
  final String name;
  final String email;
  final String authUserId;
  final String role;

  CreateNewAdminManual({
    required this.name,
    required this.email,
    required this.authUserId,
    required this.role,
  });
}

class SupervisorTechniciansUpdatedEvent extends SuperAdminEvent {
  final String supervisorId;
  final List<String> technicians; // Legacy support
  final List<dynamic> techniciansDetailed; // New enhanced format

  SupervisorTechniciansUpdatedEvent({
    required this.supervisorId,
    this.technicians = const [],
    this.techniciansDetailed = const [],
  });
}
