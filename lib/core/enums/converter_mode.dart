enum ConverterMode { none, kmlToCsv, csvToKml }

extension ConverterModeExtension on ConverterMode {
  String get displayName {
    switch (this) {
      case ConverterMode.none:
        return 'Choose Converter';
      case ConverterMode.kmlToCsv:
        return 'KML/KMZ to CSV';
      case ConverterMode.csvToKml:
        return 'CSV to KML/KMZ';
    }
  }

  String get description {
    switch (this) {
      case ConverterMode.none:
        return 'Select the type of conversion you need';
      case ConverterMode.kmlToCsv:
        return 'Converting KML/KMZ files to CSV format';
      case ConverterMode.csvToKml:
        return 'Creating KML/KMZ files from CSV data';
    }
  }
}
