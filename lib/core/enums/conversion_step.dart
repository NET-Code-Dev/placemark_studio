enum ConversionStep {
  fileSelection('File Selection', 'Choose CSV file to convert'),
  columnMapping('Column Mapping', 'Map CSV columns to KML fields'),
  dataPreview('Data Preview', 'Review and validate data'),
  geometryAndStyling('Geometry & Styling', 'Configure geometry and appearance'),
  exportOptions('Export Options', 'Choose output format and settings'),
  exportComplete('Export Complete', 'Conversion finished successfully');

  const ConversionStep(this.displayName, this.description);

  final String displayName;
  final String description;

  /// Get the next step in the conversion process
  ConversionStep? get next {
    final currentIndex = values.indexOf(this);
    if (currentIndex < values.length - 1) {
      return values[currentIndex + 1];
    }
    return null;
  }

  /// Get the previous step in the conversion process
  ConversionStep? get previous {
    final currentIndex = values.indexOf(this);
    if (currentIndex > 0) {
      return values[currentIndex - 1];
    }
    return null;
  }

  /// Check if this step is before another step
  bool isBefore(ConversionStep other) {
    return values.indexOf(this) < values.indexOf(other);
  }

  /// Check if this step is after another step
  bool isAfter(ConversionStep other) {
    return values.indexOf(this) > values.indexOf(other);
  }

  /// Get step progress as percentage (0-100)
  int get progressPercentage {
    final currentIndex = values.indexOf(this);
    return ((currentIndex / (values.length - 1)) * 100).round();
  }
}
