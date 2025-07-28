import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class MaintenanceFormState extends Equatable {
  final String? schoolName;
  final String? notes;
  final String? scheduledDate;
  final List<String> imageUrls;
  final bool isUploadingImages;
  final bool hasInteractedWithForm;
  
  const MaintenanceFormState({
    this.schoolName,
    this.notes,
    this.scheduledDate,
    this.imageUrls = const [],
    this.isUploadingImages = false,
    this.hasInteractedWithForm = false,
  });
  
  MaintenanceFormState copyWith({
    String? schoolName,
    String? notes,
    String? scheduledDate,
    List<String>? imageUrls,
    bool? isUploadingImages,
    bool? hasInteractedWithForm,
  }) {
    return MaintenanceFormState(
      schoolName: schoolName ?? this.schoolName,
      notes: notes ?? this.notes,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      imageUrls: imageUrls ?? this.imageUrls,
      isUploadingImages: isUploadingImages ?? this.isUploadingImages,
      hasInteractedWithForm: hasInteractedWithForm ?? this.hasInteractedWithForm,
    );
  }
  
  bool get isValid {
    return schoolName != null && 
           schoolName!.isNotEmpty && 
           notes != null && 
           notes!.isNotEmpty && 
           scheduledDate != null && 
           scheduledDate!.isNotEmpty;
  }
  
  @override
  List<Object?> get props => [
    schoolName, 
    notes, 
    scheduledDate, 
    imageUrls, 
    isUploadingImages,
    hasInteractedWithForm,
  ];
  
  factory MaintenanceFormState.initial() => const MaintenanceFormState();
}
