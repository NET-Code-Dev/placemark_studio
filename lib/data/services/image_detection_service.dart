import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

/// Service for detecting, validating, and managing images for KMZ export
class ImageService {
  // Supported image formats
  static const Set<String> supportedFormats = {
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.bmp',
    '.webp',
  };

  /// Detect image files in the same directory as the CSV file
  static Future<List<File>> detectImageFiles(String csvFilePath) async {
    try {
      final csvDirectory = Directory(path.dirname(csvFilePath));
      final imageFiles = <File>[];

      if (!await csvDirectory.exists()) {
        if (kDebugMode) {
          print('CSV directory does not exist: ${csvDirectory.path}');
        }
        return imageFiles;
      }

      final entities = await csvDirectory.list().toList();

      for (final entity in entities) {
        if (entity is File) {
          final extension = path.extension(entity.path).toLowerCase();
          if (supportedFormats.contains(extension)) {
            // Validate the image file
            if (await _validateImageFile(entity)) {
              imageFiles.add(entity);
            }
          }
        }
      }

      if (kDebugMode) {
        print(
          'Detected ${imageFiles.length} valid image files in ${csvDirectory.path}',
        );
        for (final file in imageFiles) {
          print('  - ${path.basename(file.path)}');
        }
      }

      return imageFiles;
    } catch (e) {
      if (kDebugMode) {
        print('Error detecting image files: $e');
      }
      return [];
    }
  }

  /// Validate that an image file is accessible and has a valid format
  static Future<bool> _validateImageFile(File imageFile) async {
    try {
      // Check if file exists and is readable
      if (!await imageFile.exists()) {
        return false;
      }

      // Check file size (reasonable limits)
      final stats = await imageFile.stat();
      if (stats.size == 0) {
        if (kDebugMode) {
          print('Image file is empty: ${imageFile.path}');
        }
        return false;
      }

      // Check if file is too large (> 50MB)
      if (stats.size > 50 * 1024 * 1024) {
        if (kDebugMode) {
          print(
            'Image file too large (${stats.size} bytes): ${imageFile.path}',
          );
        }
        return false;
      }

      // Try to read the first few bytes to verify it's an image
      final bytes = await imageFile.openRead(0, 16).toList();
      final headerBytes = bytes.expand((chunk) => chunk).take(16).toList();

      if (headerBytes.length < 4) {
        return false;
      }

      // Check for common image file signatures
      if (_hasValidImageSignature(headerBytes)) {
        return true;
      }

      if (kDebugMode) {
        print('Invalid image signature for file: ${imageFile.path}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error validating image file ${imageFile.path}: $e');
      }
      return false;
    }
  }

  /// Check if the file has a valid image signature
  static bool _hasValidImageSignature(List<int> bytes) {
    if (bytes.length < 4) return false;

    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return true;
    }

    // PNG: 89 50 4E 47
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true;
    }

    // GIF: 47 49 46 38
    if (bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return true;
    }

    // BMP: 42 4D
    if (bytes[0] == 0x42 && bytes[1] == 0x4D) {
      return true;
    }

    // WebP: 52 49 46 46 (RIFF)
    if (bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46) {
      return true;
    }

    return false;
  }

  /// Associate image files with CSV data based on image column values
  static Map<String, File> associateImagesWithData({
    required List<File> imageFiles,
    required List<String> imageColumnValues,
  }) {
    final associations = <String, File>{};
    final availableImages = <String, File>{};

    // Create a map of available images by filename (without extension)
    for (final imageFile in imageFiles) {
      final filename = path.basename(imageFile.path);
      final filenameWithoutExt = path.basenameWithoutExtension(imageFile.path);

      // Store both full filename and filename without extension
      availableImages[filename.toLowerCase()] = imageFile;
      availableImages[filenameWithoutExt.toLowerCase()] = imageFile;
    }

    // Match CSV image column values to available images
    for (final imageValue in imageColumnValues) {
      if (imageValue.trim().isEmpty) continue;

      final normalizedValue = imageValue.trim().toLowerCase();

      // Try exact match first
      if (availableImages.containsKey(normalizedValue)) {
        associations[imageValue] = availableImages[normalizedValue]!;
        continue;
      }

      // Try adding common extensions
      for (final ext in supportedFormats) {
        final withExt = '$normalizedValue$ext';
        if (availableImages.containsKey(withExt)) {
          associations[imageValue] = availableImages[withExt]!;
          break;
        }
      }
    }

    if (kDebugMode) {
      print('Image associations created:');
      print('  Total image column values: ${imageColumnValues.length}');
      print('  Successful matches: ${associations.length}');
      print('  Available images: ${imageFiles.length}');

      final missingImages =
          imageColumnValues
              .where(
                (value) =>
                    value.trim().isNotEmpty && !associations.containsKey(value),
              )
              .toSet();

      if (missingImages.isNotEmpty) {
        print('  Missing images:');
        for (final missing in missingImages) {
          print('    - $missing');
        }
      }
    }

    return associations;
  }

  /// Get list of unique image files that are actually referenced in the CSV
  static List<File> getReferencedImageFiles({
    required Map<String, File> imageAssociations,
  }) {
    final referencedFiles = <File>{};
    referencedFiles.addAll(imageAssociations.values);
    return referencedFiles.toList();
  }

  /// Get statistics about image usage
  static Map<String, dynamic> getImageStatistics({
    required List<String> imageColumnValues,
    required List<File> availableImages,
    required Map<String, File> associations,
  }) {
    final nonEmptyValues =
        imageColumnValues.where((value) => value.trim().isNotEmpty).toList();

    final uniqueValues = nonEmptyValues.toSet();
    final matchedValues = associations.keys.toSet();
    final missingValues = uniqueValues.difference(matchedValues);

    return {
      'totalRows': imageColumnValues.length,
      'rowsWithImageValues': nonEmptyValues.length,
      'uniqueImageValues': uniqueValues.length,
      'availableImageFiles': availableImages.length,
      'successfulMatches': associations.length,
      'missingImages': missingValues.length,
      'missingImagesList': missingValues.toList(),
      'matchPercentage':
          uniqueValues.isEmpty
              ? 0.0
              : (matchedValues.length / uniqueValues.length * 100),
    };
  }

  /// Optimize image size for KMZ (optional - for future enhancement)
  static Future<File?> optimizeImageForKmz(
    File originalImage, {
    int maxWidth = 1024,
    int maxHeight = 1024,
    int quality = 85,
  }) async {
    // This would require image processing library like `image` package
    // For now, just return the original file
    // TODO: Implement image optimization in future enhancement
    return originalImage;
  }

  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
