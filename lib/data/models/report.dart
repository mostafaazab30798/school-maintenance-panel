import 'package:equatable/equatable.dart';

class Report extends Equatable {
  final String id;
  final String schoolName;
  final String description;
  final String type;
  final String priority;
  final List<String> images;
  final String status;
  final String supervisorId;
  final String supervisorName;
  final DateTime createdAt;
  final DateTime scheduledDate;
  final List<String> completionPhotos;
  final String? completionNote;
  final DateTime? closedAt;
  final DateTime? updatedAt;
  final String reportSource;

  const Report({
    required this.id,
    required this.schoolName,
    required this.description,
    required this.type,
    required this.priority,
    required this.images,
    required this.status,
    required this.supervisorId,
    required this.supervisorName,
    required this.createdAt,
    required this.scheduledDate,
    required this.completionPhotos,
    this.completionNote,
    this.closedAt,
    this.updatedAt,
    this.reportSource = 'unifier',
  });

  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      id: map['id']?.toString() ?? '',
      schoolName: map['school_name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      priority: map['priority']?.toString() ?? '',
      images: List<String>.from(map['images'] ?? []),
      status: map['status']?.toString() ?? '',
      supervisorId: map['supervisor_id']?.toString() ?? '',
      supervisorName: map['supervisors']?['username']?.toString() ?? 'غير معروف',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
      scheduledDate: map['scheduled_date'] != null ? DateTime.parse(map['scheduled_date']) : DateTime.now(),
      completionPhotos: List<String>.from(map['completion_photos'] ?? []),
      completionNote: map['completion_note']?.toString(),
      closedAt:
          map['closed_at'] != null ? DateTime.parse(map['closed_at']) : null,
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      reportSource: map['report_source']?.toString() ?? 'unifier',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_name': schoolName,
      'description': description,
      'type': type,
      'priority': priority,
      'images': images,
      'status': status,
      'supervisor_id': supervisorId,
      'supervisor_name': supervisorName,
      'username': supervisorName,
      'created_at': createdAt.toIso8601String(),
      'scheduled_date': scheduledDate.toIso8601String(),
      'completion_photos': completionPhotos,
      'completion_note': completionNote,
      'closed_at': closedAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'report_source': reportSource,
    };
  }

  @override
  List<Object?> get props => [
        id,
        schoolName,
        description,
        type,
        priority,
        images,
        status,
        supervisorId,
        supervisorName,
        createdAt,
        scheduledDate,
        completionPhotos,
        completionNote,
        closedAt,
        updatedAt,
        reportSource,
      ];
}
