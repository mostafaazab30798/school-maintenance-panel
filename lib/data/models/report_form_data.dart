// lib/data/models/report_form_data.dart
class ReportFormData {
  @override
  String toString() {
    return 'ReportFormData(schoolName: \$schoolName, description: \$description, type: \$type, priority: \$priority, date: \$scheduledDate, images: \$imageUrls, supervisorId: \$supervisorId, reportSource: \$reportSource)';
  }

  String? schoolName;
  String? description;
  String? type;
  String? priority;
  String? scheduledDate;
  List<String> imageUrls;
  String? supervisorId;
  String? reportSource;

  ReportFormData({
    this.schoolName,
    this.description,
    this.type,
    this.priority,
    this.scheduledDate,
    this.imageUrls = const [],
    this.supervisorId,
    this.reportSource,
  });

  ReportFormData copyWith({
    String? schoolName,
    String? description,
    String? type,
    String? priority,
    String? scheduledDate,
    List<String>? imageUrls,
    String? supervisorId,
    String? reportSource,
  }) {
    return ReportFormData(
      schoolName: schoolName ?? this.schoolName,
      description: description ?? this.description,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      imageUrls: imageUrls ?? List<String>.from(this.imageUrls),
      supervisorId: supervisorId ?? this.supervisorId,
      reportSource: reportSource ?? this.reportSource,
    );
  }

  Map<String, dynamic> toMap() {
    // Create a base map with common fields
    final map = <String, dynamic>{
      'description': description ?? '',
      'images': imageUrls,
      'status': 'pending',
      'supervisor_id': supervisorId ?? '',
      'created_at': DateTime.now().toIso8601String(),
      'completion_photos': [],
      'school_name': schoolName ?? '',
      'report_source': reportSource ?? 'unifier',
    };

    // Add type-specific fields
    if (type?.toLowerCase() == 'maintenance') {
      // For maintenance reports - include priority with default value to satisfy database trigger
      map['priority'] = 'routine'; // Default priority for maintenance reports
      map['scheduled_date'] = scheduledDate;
    } else {
      // For regular reports - include all fields including priority
      map['type'] = type ?? '';
      map['priority'] = priority ??
          'routine'; // Ensure priority is never null for regular reports
      map['scheduled_date'] = scheduledDate;
      map['updated_at'] = DateTime.now().toIso8601String();
    }

    return map;
  }
}
