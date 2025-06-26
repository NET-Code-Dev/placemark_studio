import 'dart:io';

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

  static Future<bool> isValidKmlFile(File file) async {
    try {
      final content = await file.readAsString();
      return content.trim().startsWith('<?xml') && content.contains('<kml');
    } catch (e) {
      return false;
    }
  }

  static String sanitizeFileName(String fileName) {
    // Remove or replace invalid characters for file names
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
  }
}
