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