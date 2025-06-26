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
        allowedExtensions: AppConstants.supportedFileExtensions,
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
  }
}
