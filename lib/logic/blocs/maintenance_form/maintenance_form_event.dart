import 'package:equatable/equatable.dart';

sealed class MaintenanceFormEvent extends Equatable {
  const MaintenanceFormEvent();

  @override
  List<Object?> get props => [];
}

final class MaintenanceFormStarted extends MaintenanceFormEvent {
  const MaintenanceFormStarted();
}

final class SchoolNameChanged extends MaintenanceFormEvent {
  final String schoolName;

  const SchoolNameChanged(this.schoolName);

  @override
  List<Object?> get props => [schoolName];
}

final class NotesChanged extends MaintenanceFormEvent {
  final String notes;

  const NotesChanged(this.notes);

  @override
  List<Object?> get props => [notes];
}

final class ScheduledDateChanged extends MaintenanceFormEvent {
  final String scheduledDate;

  const ScheduledDateChanged(this.scheduledDate);

  @override
  List<Object?> get props => [scheduledDate];
}

final class ImagesPickRequested extends MaintenanceFormEvent {
  const ImagesPickRequested();
}

final class ImageRemoved extends MaintenanceFormEvent {
  final String imageUrl;

  const ImageRemoved(this.imageUrl);

  @override
  List<Object?> get props => [imageUrl];
}

final class MaintenanceFormCleared extends MaintenanceFormEvent {
  const MaintenanceFormCleared();
}
