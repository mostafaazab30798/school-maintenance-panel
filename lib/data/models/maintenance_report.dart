import 'package:equatable/equatable.dart';

class MaintenanceReport extends Equatable {
  final String id;
  final String supervisorId;
  final String supervisorName;
  final String schoolId;
  final String description;
  final String status;
  final List<String> images;
  final DateTime createdAt;
  final DateTime? closedAt;
  final List<String> completionPhotos;
  final String? completionNote;

  const MaintenanceReport({
    required this.id,
    required this.supervisorId,
    required this.supervisorName,
    required this.schoolId,
    required this.description,
    required this.status,
    required this.images,
    required this.createdAt,
    this.closedAt,
    required this.completionPhotos,
    this.completionNote,
  });

  factory MaintenanceReport.fromMap(Map<String, dynamic> map) {
    return MaintenanceReport(
      id: map['id']?.toString() ?? '',
      supervisorId: map['supervisor_id']?.toString() ?? '',
      supervisorName: map['supervisors']?['username']?.toString() ?? 'غير معروف',
      schoolId: map['school_name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
      images: List<String>.from(map['images'] ?? []),
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
      closedAt:
          map['closed_at'] != null ? DateTime.parse(map['closed_at']) : null,
      completionPhotos: List<String>.from(map['completion_photos'] ?? []),
      completionNote: map['completion_note']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supervisor_id': supervisorId,
      'supervisor_name': supervisorName,
      'username': supervisorName,
      'school_name': schoolId,
      'description': description,
      'status': status,
      'images': images,
      'created_at': createdAt.toIso8601String(),
      'closed_at': closedAt?.toIso8601String(),
      'completion_photos': completionPhotos,
      'completion_note': completionNote,
    };
  }

  @override
  List<Object?> get props => [
        id,
        supervisorId,
        supervisorName,
        schoolId,
        description,
        status,
        images,
        createdAt,
        closedAt,
        completionPhotos,
        completionNote,
      ];
}
