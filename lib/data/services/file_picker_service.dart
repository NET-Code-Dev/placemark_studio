import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../../core/errors/app_exception.dart';
import '../../core/constants/app_constants.dart';

abstract class IFilePickerService {
  Future<File?> pickKmlFile();
}

class FilePickerService implements IFilePickerService {
  @override
  Future<File?> pickKmlFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions:
            AppConstants
                .supportedFileExtensions, // Now includes both kml and kmz
        allowMultiple: false,
      );

      if (result?.files.single.path != null) {
        final file = File(result!.files.single.path!);
        await _validateFile(file);
        return file;
      }
      return null;
    } catch (e) {
      throw FileProcessingException(
        'Failed to pick file: ${e.toString()}',
        code: 'FILE_PICKER_ERROR',
        details: e,
      );
    }
  }

  Future<void> _validateFile(File file) async {
    // Check if file exists
    if (!await file.exists()) {
      throw FileProcessingException(
        'Selected file does not exist',
        code: 'FILE_NOT_FOUND',
      );
    }

    // Check file size
    final stat = await file.stat();
    if (stat.size > AppConstants.maxFileSizeBytes) {
      throw FileProcessingException(
        'File size exceeds maximum allowed size of ${AppConstants.maxFileSizeBytes / (1024 * 1024)}MB',
        code: 'FILE_TOO_LARGE',
      );
    }

    // Check file extension
    final extension = file.path.split('.').last.toLowerCase();
    if (!AppConstants.supportedFileExtensions.contains(extension)) {
      throw FileProcessingException(
        'Unsupported file format. Supported formats: ${AppConstants.supportedFileExtensions.join(', ')}',
        code: 'UNSUPPORTED_FORMAT',
      );
    }

    // Enhanced file content validation for both KML and KMZ
    await _validateFileContent(file, extension);
  }

  Future<void> _validateFileContent(File file, String extension) async {
    try {
      if (extension == 'kml') {
        // Validate KML content
        final content = await file.readAsString();
        if (!content.trim().startsWith('<?xml') || !content.contains('<kml')) {
          throw FileProcessingException(
            'Invalid KML file format',
            code: 'INVALID_KML_FORMAT',
          );
        }
      } else if (extension == 'kmz') {
        // Validate KMZ content (basic ZIP validation)
        final bytes = await file.readAsBytes();

        // Check for ZIP file signature (PK)
        if (bytes.length < 4 || bytes[0] != 0x50 || bytes[1] != 0x4B) {
          throw FileProcessingException(
            'Invalid KMZ file format - not a valid ZIP archive',
            code: 'INVALID_KMZ_FORMAT',
          );
        }

        // Note: More detailed KMZ validation can be added when implementing full KMZ parsing
      }
    } catch (e) {
      if (e is FileProcessingException) rethrow;
      throw FileProcessingException(
        'Unable to validate file content: ${e.toString()}',
        code: 'FILE_VALIDATION_ERROR',
        details: e,
      );
    }
  }
}
