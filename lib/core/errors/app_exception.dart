abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException(this.message, {this.code, this.details});

  @override
  String toString() => 'AppException: $message';
}

class FileProcessingException extends AppException {
  const FileProcessingException(super.message, {super.code, super.details});
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.code, super.details});
}

class ConversionException extends AppException {
  const ConversionException(super.message, {super.code, super.details});
}
