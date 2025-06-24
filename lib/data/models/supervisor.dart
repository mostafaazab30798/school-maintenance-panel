import 'package:equatable/equatable.dart';
import 'technician.dart';

class Supervisor extends Equatable {
  final String id;
  final String username;
  final String email;
  final String phone;
  final DateTime createdAt;
  final String iqamaId;
  final String plateNumbers;
  final String plateEnglishLetters;
  final String plateArabicLetters;
  final String workId;
  final String? authUserId; // Link to Supabase Auth user
  final String? adminId;
  final List<String> technicians; // Legacy field for simple technicians
  final List<Technician>
      techniciansDetailed; // Enhanced field for detailed technicians

  const Supervisor({
    required this.id,
    required this.username,
    required this.email,
    required this.phone,
    required this.createdAt,
    required this.iqamaId,
    required this.plateNumbers,
    required this.plateEnglishLetters,
    required this.plateArabicLetters,
    required this.workId,
    this.authUserId,
    this.adminId,
    this.technicians = const [], // Default empty list
    this.techniciansDetailed = const [], // Default empty list
  });

  factory Supervisor.fromMap(Map<String, dynamic> map) {
    return Supervisor(
      id: map['id'] as String? ?? '',
      username: (map['username'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      phone: (map['phone'] ?? '') as String,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      iqamaId: (map['iqama_id'] ?? '') as String,
      plateNumbers: (map['plate_numbers'] ?? '') as String,
      plateEnglishLetters: (map['plate_english_letters'] ?? '') as String,
      plateArabicLetters: (map['plate_arabic_letters'] ?? '') as String,
      workId: (map['work_id'] ?? '') as String,
      authUserId: map['auth_user_id'] as String?,
      adminId: map['admin_id'] as String?,
      technicians: _parseTechnicians(map['technicians']),
      techniciansDetailed:
          _parseTechniciansDetailed(map['technicians_detailed']),
    );
  }

  static List<String> _parseTechnicians(dynamic techniciansData) {
    if (techniciansData == null) return [];
    if (techniciansData is List) {
      return techniciansData.map((e) => e.toString()).toList();
    }
    return [];
  }

  static List<Technician> _parseTechniciansDetailed(
      dynamic techniciansDetailedData) {
    // Only parse the detailed format
    if (techniciansDetailedData != null && techniciansDetailedData is List) {
      try {
        return techniciansDetailedData
            .map((e) => Technician.fromMap(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        print('Error parsing technicians_detailed: $e');
      }
    }

    return [];
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone': phone,
      'created_at': createdAt.toIso8601String(),
      'iqama_id': iqamaId,
      'plate_numbers': plateNumbers,
      'plate_english_letters': plateEnglishLetters,
      'plate_arabic_letters': plateArabicLetters,
      'work_id': workId,
      if (authUserId != null) 'auth_user_id': authUserId,
      if (adminId != null) 'admin_id': adminId,
      'technicians': technicians,
      'technicians_detailed':
          techniciansDetailed.map((t) => t.toMap()).toList(),
    };
  }

  /// Create a copy with updated fields
  Supervisor copyWith({
    String? id,
    String? username,
    String? email,
    String? phone,
    DateTime? createdAt,
    String? iqamaId,
    String? plateNumbers,
    String? plateEnglishLetters,
    String? plateArabicLetters,
    String? workId,
    String? authUserId,
    String? adminId,
    List<String>? technicians,
    List<Technician>? techniciansDetailed,
  }) {
    return Supervisor(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      iqamaId: iqamaId ?? this.iqamaId,
      plateNumbers: plateNumbers ?? this.plateNumbers,
      plateEnglishLetters: plateEnglishLetters ?? this.plateEnglishLetters,
      plateArabicLetters: plateArabicLetters ?? this.plateArabicLetters,
      workId: workId ?? this.workId,
      authUserId: authUserId ?? this.authUserId,
      adminId: adminId ?? this.adminId,
      technicians: technicians ?? this.technicians,
      techniciansDetailed: techniciansDetailed ?? this.techniciansDetailed,
    );
  }

  /// Helper getter to get all technicians (prioritizes detailed over simple)
  List<Technician> get allTechnicians {
    if (techniciansDetailed.isNotEmpty) {
      return techniciansDetailed;
    }
    // Convert simple technicians to detailed format for consistent usage
    return technicians
        .map((name) => Technician(name: name, workId: '', profession: ''))
        .toList();
  }

  /// Helper getter to check if supervisor uses detailed technician format
  bool get usesDetailedTechnicians => techniciansDetailed.isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        username,
        email,
        phone,
        createdAt,
        iqamaId,
        plateNumbers,
        plateEnglishLetters,
        plateArabicLetters,
        workId,
        authUserId,
        adminId,
        technicians, // Add to props for equality comparison
        techniciansDetailed, // Add to props for equality comparison
      ];
}
