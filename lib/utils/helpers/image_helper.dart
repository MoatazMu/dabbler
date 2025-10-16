/// Helper class for image processing, compression, and avatar management
library;
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

/// Comprehensive image processing helper for profile avatars and media
class ImageHelper {
  // Image size constraints
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
  static const int thumbnailSize = 150;
  static const int fullSize = 800;
  static const int maxDimension = 2048;
  
  // Supported formats
  static const List<String> supportedFormats = ['.jpg', '.jpeg', '.png', '.webp'];
  
  // Quality settings
  static const int defaultQuality = 85;
  static const int thumbnailQuality = 90;
  static const int highQuality = 95;
  
  /// Compress an image file to specified dimensions and quality
  static Future<File?> compressImage(
    File imageFile, {
    int maxWidth = fullSize,
    int maxHeight = fullSize,
    int quality = defaultQuality,
    String? outputPath,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Unable to decode image');
      }
      
      // Calculate resize dimensions maintaining aspect ratio
      final resized = _resizeImage(image, maxWidth, maxHeight);
      
      // Encode with appropriate format
      final compressed = _encodeImage(resized, quality, imageFile.path);
      
      // Create output file
      final compressedFile = File(
        outputPath ?? _generateCompressedPath(imageFile.path)
      );
      
      await compressedFile.writeAsBytes(compressed);
      return compressedFile;
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }

  /// Compress image from bytes data
  static Future<Uint8List?> compressImageBytes(
    Uint8List imageBytes, {
    int maxWidth = fullSize,
    int maxHeight = fullSize,
    int quality = defaultQuality,
  }) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;
      
      final resized = _resizeImage(image, maxWidth, maxHeight);
      return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
    } catch (e) {
      print('Error compressing image bytes: $e');
      return null;
    }
  }

  /// Check if file format is supported for image uploads
  static bool isValidImageFormat(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    return supportedFormats.contains(extension);
  }

  /// Validate image file size
  static bool isValidImageSize(File file) {
    try {
      return file.lengthSync() <= maxImageSizeBytes;
    } catch (e) {
      return false;
    }
  }

  /// Validate image bytes size
  static bool isValidImageBytesSize(Uint8List bytes) {
    return bytes.length <= maxImageSizeBytes;
  }

  /// Get detailed image validation results
  static Future<Map<String, dynamic>> validateImage(File imageFile) async {
    final validation = <String, dynamic>{
      'isValid': true,
      'errors': <String>[],
      'warnings': <String>[],
      'fileSize': 0,
      'dimensions': {'width': 0, 'height': 0},
      'format': '',
    };

    try {
      // Check if file exists
      if (!await imageFile.exists()) {
        validation['isValid'] = false;
        validation['errors'].add('Image file does not exist');
        return validation;
      }

      // Check file size
      final fileSize = await imageFile.length();
      validation['fileSize'] = fileSize;
      
      if (fileSize > maxImageSizeBytes) {
        validation['isValid'] = false;
        validation['errors'].add('Image size exceeds ${(maxImageSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB limit');
      }

      // Check format
      final fileName = path.basename(imageFile.path);
      validation['format'] = path.extension(fileName).toLowerCase();
      
      if (!isValidImageFormat(fileName)) {
        validation['isValid'] = false;
        validation['errors'].add('Unsupported image format. Use JPG, PNG, or WebP');
      }

      // Check image dimensions and quality
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        validation['isValid'] = false;
        validation['errors'].add('Cannot decode image file');
        return validation;
      }

      validation['dimensions'] = {
        'width': image.width,
        'height': image.height,
      };

      // Add warnings for very large images
      if (image.width > maxDimension || image.height > maxDimension) {
        validation['warnings'].add('Image will be resized to fit maximum dimensions');
      }

      // Add warnings for very small images
      if (image.width < thumbnailSize && image.height < thumbnailSize) {
        validation['warnings'].add('Image is very small and may appear pixelated');
      }

    } catch (e) {
      validation['isValid'] = false;
      validation['errors'].add('Error processing image: $e');
    }

    return validation;
  }

  /// Generate multiple image sizes (thumbnail, full, original)
  static Future<Map<String, File?>> generateImageSizes(
    File originalFile, {
    String? outputDirectory,
  }) async {
    final results = <String, File?>{
      'thumbnail': null,
      'full': null,
      'original': originalFile,
    };

    try {
      final outputDir = outputDirectory ?? path.dirname(originalFile.path);
      final baseName = path.basenameWithoutExtension(originalFile.path);
      
      // Generate thumbnail
      results['thumbnail'] = await compressImage(
        originalFile,
        maxWidth: thumbnailSize,
        maxHeight: thumbnailSize,
        quality: thumbnailQuality,
        outputPath: path.join(outputDir, '${baseName}_thumb.jpg'),
      );

      // Generate full size
      results['full'] = await compressImage(
        originalFile,
        maxWidth: fullSize,
        maxHeight: fullSize,
        quality: defaultQuality,
        outputPath: path.join(outputDir, '${baseName}_full.jpg'),
      );

    } catch (e) {
      print('Error generating image sizes: $e');
    }

    return results;
  }

  /// Get avatar URL with fallback to default avatar
  static String getAvatarUrl(String? url, {bool thumbnail = false}) {
    if (url == null || url.isEmpty) {
      return 'assets/Avatar/default-avatar.png';
    }
    
    // Handle thumbnail requests for stored avatars
    if (thumbnail && url.contains('avatars/')) {
      return url.replaceFirst('avatars/', 'avatars/thumb_');
    }
    
    return url;
  }

  /// Get gender-specific default avatar
  static String getDefaultAvatarForGender(String? gender) {
    switch (gender?.toLowerCase()) {
      case 'male':
        return 'assets/Avatar/male-1.png';
      case 'female':
        return 'assets/Avatar/female-1.png';
      default:
        return 'assets/Avatar/default-avatar.png';
    }
  }

  /// Get random default avatar from available options
  static String getRandomDefaultAvatar({String? gender}) {
    final random = DateTime.now().millisecondsSinceEpoch % 6 + 1;
    
    switch (gender?.toLowerCase()) {
      case 'male':
        return 'assets/Avatar/male-$random.png';
      case 'female':
        return 'assets/Avatar/female-${random > 5 ? 5 : random}.png';
      default:
        return random <= 3 
          ? 'assets/Avatar/male-$random.png'
          : 'assets/Avatar/female-${random - 3}.png';
    }
  }

  /// Create circular crop of image
  static Future<File?> createCircularAvatar(
    File imageFile, {
    int size = fullSize,
    String? outputPath,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // Create a square image
      final minDimension = [image.width, image.height].reduce((a, b) => a < b ? a : b);
      final square = img.copyCrop(
        image,
        x: (image.width - minDimension) ~/ 2,
        y: (image.height - minDimension) ~/ 2,
        width: minDimension,
        height: minDimension,
      );

      // Resize to target size
      final resized = img.copyResize(square, width: size, height: size);

      // Create circular mask
      final circular = _createCircularMask(resized);
      
      final encoded = img.encodePng(circular);
      final outputFile = File(
        outputPath ?? _generateCircularPath(imageFile.path)
      );
      
      await outputFile.writeAsBytes(encoded);
      return outputFile;
    } catch (e) {
      print('Error creating circular avatar: $e');
      return null;
    }
  }

  /// Extract dominant color from image
  static Future<Map<String, int>?> extractDominantColor(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // Resize to small image for faster processing
      final small = img.copyResize(image, width: 50, height: 50);
      
      final colorCounts = <int, int>{};
      
      // Count pixel colors
      for (int y = 0; y < small.height; y++) {
        for (int x = 0; x < small.width; x++) {
          final pixel = small.getPixel(x, y);
          // Extract RGB values from pixel
          final r = pixel.r.toInt();
          final g = pixel.g.toInt();
          final b = pixel.b.toInt();
          final color = (r << 16) | (g << 8) | b;
          colorCounts[color] = (colorCounts[color] ?? 0) + 1;
        }
      }
      
      // Find most common color
      final dominantColor = colorCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      
      // Extract RGB components
      return {
        'r': (dominantColor >> 16) & 0xFF,
        'g': (dominantColor >> 8) & 0xFF,
        'b': dominantColor & 0xFF,
      };
    } catch (e) {
      print('Error extracting dominant color: $e');
      return null;
    }
  }

  /// Clean up temporary image files
  static Future<void> cleanupTempImages(List<File> tempFiles) async {
    for (final file in tempFiles) {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Error deleting temp file ${file.path}: $e');
      }
    }
  }

  /// Private helper methods
  static img.Image _resizeImage(img.Image image, int maxWidth, int maxHeight) {
    // Calculate dimensions maintaining aspect ratio
    double aspectRatio = image.width / image.height;
    int targetWidth = image.width;
    int targetHeight = image.height;

    if (targetWidth > maxWidth) {
      targetWidth = maxWidth;
      targetHeight = (targetWidth / aspectRatio).round();
    }

    if (targetHeight > maxHeight) {
      targetHeight = maxHeight;
      targetWidth = (targetHeight * aspectRatio).round();
    }

    return img.copyResize(
      image,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.cubic,
    );
  }

  static Uint8List _encodeImage(img.Image image, int quality, String originalPath) {
    final extension = path.extension(originalPath).toLowerCase();
    
    switch (extension) {
      case '.png':
        return Uint8List.fromList(img.encodePng(image));
      case '.webp':
        // Note: image package may not support WebP encoding, fallback to JPEG
        return Uint8List.fromList(img.encodeJpg(image, quality: quality));
      default:
        return Uint8List.fromList(img.encodeJpg(image, quality: quality));
    }
  }

  static String _generateCompressedPath(String originalPath) {
    final dir = path.dirname(originalPath);
    final name = path.basenameWithoutExtension(originalPath);
    return path.join(dir, 'compressed_$name.jpg');
  }

  static String _generateCircularPath(String originalPath) {
    final dir = path.dirname(originalPath);
    final name = path.basenameWithoutExtension(originalPath);
    return path.join(dir, 'circular_$name.png');
  }

  static img.Image _createCircularMask(img.Image image) {
    final center = image.width / 2;
    final radius = center;
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final distance = ((x - center) * (x - center) + (y - center) * (y - center));
        if (distance > radius * radius) {
          image.setPixel(x, y, img.ColorRgba8(0, 0, 0, 0)); // Transparent
        }
      }
    }
    
    return image;
  }

  /// Get file size in human readable format
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// Check if image needs optimization
  static Future<bool> needsOptimization(File imageFile) async {
    try {
      final fileSize = await imageFile.length();
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) return false;
      
      // Needs optimization if file is large or dimensions are too big
      return fileSize > (1024 * 1024) || // > 1MB
             image.width > fullSize ||
             image.height > fullSize;
    } catch (e) {
      return false;
    }
  }
}
