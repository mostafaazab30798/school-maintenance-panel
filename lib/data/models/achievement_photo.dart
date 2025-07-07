import 'package:equatable/equatable.dart';

class AchievementPhoto extends Equatable {
  final String id;
  final String achievementId;
  final String photoUrl;
  final String? photoDescription;
  final int? fileSize;
  final String? mimeType;
  final DateTime uploadTimestamp;
  final String? schoolId;
  final String? schoolName;
  final String? achievementType;
  final String? supervisorId;

  const AchievementPhoto({
    required this.id,
    required this.achievementId,
    required this.photoUrl,
    this.photoDescription,
    this.fileSize,
    this.mimeType,
    required this.uploadTimestamp,
    this.schoolId,
    this.schoolName,
    this.achievementType,
    this.supervisorId,
  });

  factory AchievementPhoto.fromMap(Map<String, dynamic> map) {
    return AchievementPhoto(
      id: map['id'] as String,
      achievementId: map['achievement_id'] as String,
      photoUrl: map['photo_url'] as String,
      photoDescription: map['photo_description'] as String?,
      fileSize: map['file_size'] as int?,
      mimeType: map['mime_type'] as String?,
      uploadTimestamp: DateTime.parse(map['upload_timestamp']),
      schoolId: map['school_id'] as String?,
      schoolName: map['school_name'] as String?,
      achievementType: map['achievement_type'] as String?,
      supervisorId: map['supervisor_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'achievement_id': achievementId,
      'photo_url': photoUrl,
      'photo_description': photoDescription,
      'file_size': fileSize,
      'mime_type': mimeType,
      'upload_timestamp': uploadTimestamp.toIso8601String(),
      'school_id': schoolId,
      'school_name': schoolName,
      'achievement_type': achievementType,
      'supervisor_id': supervisorId,
    };
  }

  String get achievementTypeDisplayName {
    switch (achievementType) {
      case 'maintenance_achievement':
        return 'إنجاز صيانة';
      case 'ac_achievement':
        return 'إنجاز مكيفات';
      case 'checklist':
        return 'قائمة مراجعة';
      default:
        return achievementType ?? 'غير محدد';
    }
  }

  @override
  List<Object?> get props => [
        id,
        achievementId,
        photoUrl,
        photoDescription,
        fileSize,
        mimeType,
        uploadTimestamp,
        schoolId,
        schoolName,
        achievementType,
        supervisorId,
      ];
}
