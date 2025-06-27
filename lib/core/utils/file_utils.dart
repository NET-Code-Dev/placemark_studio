import 'dart:io';
import '../constants/app_constants.dart';

class FileUtils {
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  static String getFileExtension(String filePath) {
    return filePath.split('.').last.toLowerCase();
  }

  static String getFileName(String filePath) {
    return filePath.split('/').last;
  }

  static String getFileNameWithoutExtension(String filePath) {
    final fileName = getFileName(filePath);
    final lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex == -1) return fileName;
    return fileName.substring(0, lastDotIndex);
  }

  /// Updated to validate both KML and KMZ files
  static Future<bool> isValidKmlFile(File file) async {
    try {
      final extension = getFileExtension(file.path);

      if (extension == 'kml') {
        // Validate KML content
        final content = await file.readAsString();
        return content.trim().startsWith('<?xml') && content.contains('<kml');
      } else if (extension == 'kmz') {
        // Validate KMZ content (basic ZIP validation)
        final bytes = await file.readAsBytes();

        // Check for ZIP file signature (PK)
        return bytes.length >= 4 && bytes[0] == 0x50 && bytes[1] == 0x4B;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check if file extension is supported
  static bool isSupportedFileType(String filePath) {
    final extension = getFileExtension(filePath);
    return AppConstants.supportedFileExtensions.contains(extension);
  }

  /// Get human-readable file type description
  static String getFileTypeDescription(String filePath) {
    final extension = getFileExtension(filePath);
    return AppConstants.fileTypeDescriptions[extension] ?? 'Unknown file type';
  }

  static String sanitizeFileName(String fileName) {
    // Remove or replace invalid characters for file names
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
  }
}
