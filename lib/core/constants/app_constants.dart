class AppConstants {
  static const String appName = 'Placemark Studio';
  static const String appVersion = '1.0.0';

  // File constraints
  static const int maxFileSizeBytes = 50 * 1024 * 1024; // 50MB
  static const List<String> supportedFileExtensions = ['kml'];

  // CSV export settings
  static const String defaultCsvDelimiter = ',';
  static const int previewRowCount = 5;
  static const int maxPreviewRows = 100;

  // UI constants
  static const double defaultPadding = 16.0;
  static const double defaultCardElevation = 2.0;
  static const double defaultBorderRadius = 8.0;

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
}
