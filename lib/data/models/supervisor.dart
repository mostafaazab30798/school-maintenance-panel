import 'package:equatable/equatable.dart';

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
  });

  factory Supervisor.fromMap(Map<String, dynamic> map) {
    return Supervisor(
      id: map['id'] as String,
      username: (map['username'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      phone: (map['phone'] ?? '') as String,
      createdAt: DateTime.parse(map['created_at']),
      iqamaId: (map['iqama_id'] ?? '') as String,
      plateNumbers: (map['plate_numbers'] ?? '') as String,
      plateEnglishLetters: (map['plate_english_letters'] ?? '') as String,
      plateArabicLetters: (map['plate_arabic_letters'] ?? '') as String,
      workId: (map['work_id'] ?? '') as String,
      authUserId: map['auth_user_id'] as String?,
      adminId: map['admin_id'] as String?,
    );
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
    };
  }

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
      ];
}
