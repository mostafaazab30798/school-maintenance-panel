import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'maintenance_form_event.dart';
import 'maintenance_form_state.dart';

class MaintenanceFormBloc extends Bloc<MaintenanceFormEvent, MaintenanceFormState> {
  final ImagePicker _picker = ImagePicker();

  MaintenanceFormBloc() : super(MaintenanceFormState.initial()) {
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

      for (var file in picked) {
        final bytes = await file.readAsBytes();
        final base64Image = base64Encode(bytes);
        final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final publicId = 'image_$timestamp';

        final response = await http.post(
          Uri.parse('https://api.cloudinary.com/v1_1/dg7rsus0g/image/upload'),
          body: {
            'file': 'data:image/jpeg;base64,$base64Image',
            'upload_preset': 'managment_upload',
            'public_id': publicId,
            'folder': 'maintenance_reports'
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final url = data['secure_url'];
          newImageUrls.add(url);
        }
      }

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
