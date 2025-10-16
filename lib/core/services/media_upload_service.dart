import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

/// Service for handling media file uploads with compression and validation
class MediaUploadService {
  static const int _maxImageWidth = 1920;
  static const int _maxImageHeight = 1920;
  static const int _imageQuality = 85;
  static const int _maxFileSize = 50 * 1024 * 1024; // 50MB

  /// Upload a file with compression if it's an image
  Future<String> uploadFile(File file) async {
    try {
      // Validate file size
      if (await file.length() > _maxFileSize) {
        throw Exception('File size exceeds maximum allowed size of 50MB');
      }

      // Check if it's an image and compress if needed
      final extension = path.extension(file.path).toLowerCase();
      if (_isImageFile(extension)) {
        return await _uploadImage(file);
      } else {
        return await _uploadGenericFile(file);
      }
    } catch (e) {
      throw Exception('Failed to upload file: ${e.toString()}');
    }
  }

  /// Upload and compress image files
  Future<String> _uploadImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Invalid image file');
      }

      // Resize if needed
      var processedImage = image;
      if (image.width > _maxImageWidth || image.height > _maxImageHeight) {
        processedImage = img.copyResize(
          image,
          width: _maxImageWidth,
          height: _maxImageHeight,
        );
      }

      // Compress image
      final compressedBytes = img.encodeJpg(processedImage, quality: _imageQuality);
      
      // TODO: Implement actual upload to storage service
      // For now, return a mock URL but use the compressed bytes length for validation
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final fileSize = compressedBytes.length;
      if (fileSize > _maxFileSize) {
        throw Exception('Compressed file size exceeds maximum allowed size of 50MB');
      }
      return 'https://storage.example.com/uploads/$fileName';
    } catch (e) {
      throw Exception('Failed to process image: ${e.toString()}');
    }
  }

  /// Upload generic files (non-images)
  Future<String> _uploadGenericFile(File file) async {
    try {
      // TODO: Implement actual upload to storage service
      // For now, return a mock URL
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      return 'https://storage.example.com/uploads/$fileName';
    } catch (e) {
      throw Exception('Failed to upload file: ${e.toString()}');
    }
  }

  /// Check if file is an image based on extension
  bool _isImageFile(String extension) {
    const imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    return imageExtensions.contains(extension);
  }

  /// Upload bytes data (useful for in-memory files)
  Future<String> uploadBytes(Uint8List bytes, String fileName) async {
    try {
      if (bytes.length > _maxFileSize) {
        throw Exception('File size exceeds maximum allowed size of 50MB');
      }

      // TODO: Implement actual upload to storage service
      // For now, return a mock URL
      final uploadFileName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      return 'https://storage.example.com/uploads/$uploadFileName';
    } catch (e) {
      throw Exception('Failed to upload bytes: ${e.toString()}');
    }
  }

  /// Delete uploaded file
  Future<bool> deleteFile(String fileUrl) async {
    try {
      // TODO: Implement actual deletion from storage service
      // For now, return success
      return true;
    } catch (e) {
      throw Exception('Failed to delete file: ${e.toString()}');
    }
  }
}
