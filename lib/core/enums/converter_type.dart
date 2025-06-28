enum ConverterType {
  kmlToCsv('KML/KMZ to CSV', 'Convert KML and KMZ files to CSV format'),
  csvToKml('CSV to KML/KMZ', 'Create KML/KMZ files from CSV data'),
  multiFileMerge('Multi-File Merge', 'Combine multiple files into one'),
  batchProcessing(
    'Batch Processing',
    'Process multiple files with same settings',
  );

  const ConverterType(this.displayName, this.description);

  final String displayName;
  final String description;

  bool get isAvailable {
    switch (this) {
      case ConverterType.kmlToCsv:
      case ConverterType.csvToKml:
        return true;
      case ConverterType.multiFileMerge:
      case ConverterType.batchProcessing:
        return false;
    }
  }
}
