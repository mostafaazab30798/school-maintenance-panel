import 'package:equatable/equatable.dart';

/// Model representing a technician with enhanced details
class Technician extends Equatable {
  final String name;
  final String workId;
  final String profession;
  final String phoneNumber;

  const Technician({
    required this.name,
    required this.workId,
    required this.profession,
    this.phoneNumber = '',
  });

  /// Creates a copy of this technician with updated fields
  Technician copyWith({
    String? name,
    String? workId,
    String? profession,
    String? phoneNumber,
  }) {
    return Technician(
      name: name ?? this.name,
      workId: workId ?? this.workId,
      profession: profession ?? this.profession,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  /// Creates a Technician from a Map (JSON)
  factory Technician.fromMap(Map<String, dynamic> map) {
    return Technician(
      name: map['name']?.toString() ?? '',
      workId: map['workId']?.toString() ?? '',
      profession: map['profession']?.toString() ?? '',
      phoneNumber: map['phoneNumber']?.toString() ?? '',
    );
  }

  /// Converts the Technician to a Map (JSON)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'workId': workId,
      'profession': profession,
      'phoneNumber': phoneNumber,
    };
  }

  /// Creates a Technician from JSON string
  factory Technician.fromJson(Map<String, dynamic> json) =>
      Technician.fromMap(json);

  /// Converts the Technician to JSON
  Map<String, dynamic> toJson() => toMap();

  /// Creates an empty Technician
  factory Technician.empty() {
    return const Technician(
      name: '',
      workId: '',
      profession: '',
      phoneNumber: '',
    );
  }

  /// Checks if the technician has valid data
  bool get isValid => name.trim().isNotEmpty;

  /// Checks if the technician is complete (all required fields filled)
  bool get isComplete =>
      name.trim().isNotEmpty &&
      workId.trim().isNotEmpty &&
      profession.trim().isNotEmpty;

  /// Checks if the technician has all fields including optional ones
  bool get isFullyComplete => isComplete && phoneNumber.trim().isNotEmpty;

  /// Common profession options
  static const List<String> commonProfessions = [
    'Electrician',
    'Plumber',
    'HVAC Technician',
    'Civil Engineer',
    'Fire Safety Specialist',
    'General Maintenance',
    'Cleaner',
    'Security Guard',
    'IT Technician',
    'Carpenter',
    'Painter',
    'Landscaper',
  ];

  /// Arabic profession translations
  static const Map<String, String> professionTranslations = {
    'Electrician': 'كهربائي',
    'Plumber': 'سباك',
    'HVAC Technician': 'فني تكييف',
    'Civil Engineer': 'مهندس مدني',
    'Fire Safety Specialist': 'أخصائي السلامة من الحرائق',
    'General Maintenance': 'صيانة عامة',
    'Cleaner': 'عامل نظافة',
    'Security Guard': 'حارس أمن',
    'IT Technician': 'فني تقنية معلومات',
    'Carpenter': 'نجار',
    'Painter': 'دهان',
    'Landscaper': 'أخصائي تنسيق حدائق',
  };

  /// Gets the Arabic translation of the profession
  String get professionArabic =>
      professionTranslations[profession] ?? profession;

  /// Creates a display name combining name and workId
  String get displayName => workId.isNotEmpty ? '$name ($workId)' : name;

  /// Creates a full display string with all details
  String get fullDisplay =>
      '$displayName - ${professionArabic.isNotEmpty ? professionArabic : profession}';

  @override
  List<Object?> get props => [name, workId, profession, phoneNumber];

  @override
  String toString() =>
      'Technician(name: $name, workId: $workId, profession: $profession, phoneNumber: $phoneNumber)';
}
