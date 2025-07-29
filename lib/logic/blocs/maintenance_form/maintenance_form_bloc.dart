import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/supabase_storage_service.dart';

import 'maintenance_form_event.dart';
import 'maintenance_form_state.dart';

class MaintenanceFormBloc extends Bloc<MaintenanceFormEvent, MaintenanceFormState> {
  final ImagePicker _picker = ImagePicker();
  final SupabaseStorageService _storageService;

  MaintenanceFormBloc({required SupabaseStorageService storageService}) 
      : _storageService = storageService,
        super(MaintenanceFormState.initial()) {
    on<MaintenanceFormStarted>(_onMaintenanceFormStarted);
    on<SchoolNameChanged>(_onSchoolNameChanged);
    on<NotesChanged>(_onNotesChanged);
    on<ScheduledDateChanged>(_onScheduledDateChanged);
    on<ImagesPickRequested>(_onImagesPickRequested);
    on<ImageRemoved>(_onImageRemoved);
    on<MaintenanceFormCleared>(_onMaintenanceFormCleared);
  }

  void _onMaintenanceFormStarted(
    MaintenanceFormStarted event,
    Emitter<MaintenanceFormState> emit,
  ) {
    emit(MaintenanceFormState.initial());
  }

  void _onSchoolNameChanged(
    SchoolNameChanged event,
    Emitter<MaintenanceFormState> emit,
  ) {
    emit(state.copyWith(
      schoolName: event.schoolName,
      hasInteractedWithForm: true,
    ));
  }

  void _onNotesChanged(
    NotesChanged event,
    Emitter<MaintenanceFormState> emit,
  ) {
    emit(state.copyWith(
      notes: event.notes,
      hasInteractedWithForm: true,
    ));
  }

  void _onScheduledDateChanged(
    ScheduledDateChanged event,
    Emitter<MaintenanceFormState> emit,
  ) {
    emit(state.copyWith(
      scheduledDate: event.scheduledDate,
      hasInteractedWithForm: true,
    ));
  }

  Future<void> _onImagesPickRequested(
    ImagesPickRequested event,
    Emitter<MaintenanceFormState> emit,
  ) async {
    // Start uploading state
    emit(state.copyWith(isUploadingImages: true));

    try {
      final picked = await _picker.pickMultiImage();
      if (picked.isEmpty) {
        emit(state.copyWith(isUploadingImages: false));
        return;
      }

      final List<String> newImageUrls = List.from(state.imageUrls);

      // Upload images to Supabase storage
      final uploadedUrls = await _storageService.uploadMultipleImages(picked);
      newImageUrls.addAll(uploadedUrls);

      emit(state.copyWith(
        imageUrls: newImageUrls,
        isUploadingImages: false,
      ));
    } catch (e) {
      // Handle errors
      emit(state.copyWith(isUploadingImages: false));
    }
  }

  void _onImageRemoved(
    ImageRemoved event,
    Emitter<MaintenanceFormState> emit,
  ) {
    final updatedUrls = List<String>.from(state.imageUrls)
      ..removeWhere((url) => url == event.imageUrl);
    
    emit(state.copyWith(imageUrls: updatedUrls));
  }

  void _onMaintenanceFormCleared(
    MaintenanceFormCleared event,
    Emitter<MaintenanceFormState> emit,
  ) {
    emit(MaintenanceFormState.initial());
  }
}
