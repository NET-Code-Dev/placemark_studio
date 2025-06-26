abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException(this.message, {this.code, this.details});

  @override
  String toString() => 'AppException: $message';
}

class FileProcessingException extends AppException {
  const FileProcessingException(String message, {String? code, dynamic details})
    : super(message, code: code, details: details);
}

class ValidationException extends AppException {
  const ValidationException(String message, {String? code, dynamic details})
    : super(message, code: code, details: details);
}

class ConversionException extends AppException {
  const ConversionException(String message, {String? code, dynamic details})
    : super(message, code: code, details: details);
}
