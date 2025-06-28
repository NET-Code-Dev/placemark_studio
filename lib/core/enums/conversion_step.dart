enum ConversionStep {
  fileSelection,
  columnMapping,
  dataPreview,
  geometryAndStyling,
  exportOptions;

  // Use the built-in index property for comparisons
  bool operator >=(ConversionStep other) => index >= other.index;
  bool operator >(ConversionStep other) => index > other.index;
  bool operator <=(ConversionStep other) => index <= other.index;
  bool operator <(ConversionStep other) => index < other.index;

  String get displayName {
    switch (this) {
      case ConversionStep.fileSelection:
        return 'File Selection';
      case ConversionStep.columnMapping:
        return 'Column Mapping';
      case ConversionStep.dataPreview:
        return 'Data Preview';
      case ConversionStep.geometryAndStyling:
        return 'Geometry & Styling';
      case ConversionStep.exportOptions:
        return 'Export Options';
    }
  }

  String get description {
    switch (this) {
      case ConversionStep.fileSelection:
        return 'Select your CSV file';
      case ConversionStep.columnMapping:
        return 'Map CSV columns to KML fields';
      case ConversionStep.dataPreview:
        return 'Preview and validate your data';
      case ConversionStep.geometryAndStyling:
        return 'Configure geometry and styling';
      case ConversionStep.exportOptions:
        return 'Set export options and generate file';
    }
  }
}
