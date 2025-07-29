import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class SupabaseStorageService {
  final SupabaseClient _supabase;
  static const String _bucketName = 'supervisor-app-photos';

  SupabaseStorageService(this._supabase);

  /// Upload a single image to Supabase storage
  Future<String?> uploadImage(XFile imageFile) async {
    try {
      final fileName = _generateFileName(imageFile.name);
      
      // Handle web and mobile platforms differently
      late final String response;
      
      if (kIsWeb) {
        // On web, use bytes instead of file path
        final bytes = await imageFile.readAsBytes();
        response = await _supabase.storage
            .from(_bucketName)
            .uploadBinary(fileName, bytes);
      } else {
        // On mobile, use file path
        response = await _supabase.storage
            .from(_bucketName)
            .upload(fileName, File(imageFile.path));
      }

      if (response.isNotEmpty) {
        final publicUrl = _supabase.storage
            .from(_bucketName)
            .getPublicUrl(fileName);
        return publicUrl;
      }
      return null;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  /// Upload multiple images to Supabase storage
  Future<List<String>> uploadMultipleImages(List<XFile> imageFiles) async {
    final List<String> uploadedUrls = [];
    
    for (final imageFile in imageFiles) {
      final url = await uploadImage(imageFile);
      if (url != null) {
        uploadedUrls.add(url);
      }
    }
    
    return uploadedUrls;
  }

  /// Upload image from bytes
  Future<String?> uploadImageFromBytes(Uint8List bytes, String fileName) async {
    try {
      final finalFileName = _generateFileName(fileName);
      
      // Handle web and mobile platforms differently
      late final String response;
      
      if (kIsWeb) {
        // On web, use bytes directly
        response = await _supabase.storage
            .from(_bucketName)
            .uploadBinary(finalFileName, bytes);
      } else {
        // On mobile, create a temporary file from bytes
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/$finalFileName');
        await tempFile.writeAsBytes(bytes);
        
        response = await _supabase.storage
            .from(_bucketName)
            .upload(finalFileName, tempFile);

        // Clean up temporary file
        await tempFile.delete();
      }

      if (response.isNotEmpty) {
        final publicUrl = _supabase.storage
            .from(_bucketName)
            .getPublicUrl(finalFileName);
        return publicUrl;
      }
      return null;
    } catch (e) {
      print('Error uploading image from bytes: $e');
      return null;
    }
  }

  /// Delete an image from Supabase storage
  Future<bool> deleteImage(String fileName) async {
    try {
      await _supabase.storage
          .from(_bucketName)
          .remove([fileName]);
      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  /// Generate a unique filename with timestamp
  String _generateFileName(String originalName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = originalName.split('.').last;
    return 'image_${timestamp}_${DateTime.now().microsecondsSinceEpoch}.$extension';
  }

  /// Get the bucket name
  String get bucketName => _bucketName;
} 