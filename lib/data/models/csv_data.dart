import 'column_mapping.dart';

class CsvData {
  final String fileName;
  final List<String> headers;
  final List<Map<String, dynamic>> rows;
  final List<String> validationErrors;
  final int validRowCount;

  const CsvData({
    required this.fileName,
    required this.headers,
    required this.rows,
    this.validationErrors = const [],
    this.validRowCount = 0,
  });

  // Core getters
  int get totalRowCount => rows.length;
  bool get hasValidCoordinates => validRowCount > 0;
  bool get isEmpty => rows.isEmpty;
  bool get isNotEmpty => rows.isNotEmpty;

  /// Validate coordinate data against column mapping
  CsvData validateCoordinates(ColumnMapping mapping) {
    if (!mapping.isValid || rows.isEmpty) {
      return copyWith(validationErrors: [], validRowCount: 0);
    }

    final errors = <String>[];
    int validCount = 0;

    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      final rowNumber = i + 1;
      bool rowIsValid = true;

      try {
        // Validate latitude
        final latValue = row[mapping.latitudeColumn];
        if (latValue == null || latValue.toString().trim().isEmpty) {
          errors.add('Row $rowNumber: Missing latitude value');
          rowIsValid = false;
        } else {
          final latitude = _parseCoordinate(latValue);
          if (latitude == null) {
            errors.add('Row $rowNumber: Invalid latitude format: "$latValue"');
            rowIsValid = false;
          } else if (latitude < -90 || latitude > 90) {
            errors.add(
              'Row $rowNumber: Latitude out of range (-90 to 90): $latitude',
            );
            rowIsValid = false;
          }
        }

        // Validate longitude
        final lonValue = row[mapping.longitudeColumn];
        if (lonValue == null || lonValue.toString().trim().isEmpty) {
          errors.add('Row $rowNumber: Missing longitude value');
          rowIsValid = false;
        } else {
          final longitude = _parseCoordinate(lonValue);
          if (longitude == null) {
            errors.add('Row $rowNumber: Invalid longitude format: "$lonValue"');
            rowIsValid = false;
          } else if (longitude < -180 || longitude > 180) {
            errors.add(
              'Row $rowNumber: Longitude out of range (-180 to 180): $longitude',
            );
            rowIsValid = false;
          }
        }

        // Validate name if required
        if (mapping.nameColumn != null) {
          final nameValue = row[mapping.nameColumn];
          if (nameValue == null || nameValue.toString().trim().isEmpty) {
            errors.add('Row $rowNumber: Missing name/title value');
            rowIsValid = false;
          }
        }

        // Validate elevation if provided
        if (mapping.elevationColumn != null) {
          final elevValue = row[mapping.elevationColumn];
          if (elevValue != null && elevValue.toString().trim().isNotEmpty) {
            final elevation = _parseCoordinate(elevValue);
            if (elevation == null) {
              errors.add(
                'Row $rowNumber: Invalid elevation format: "$elevValue"',
              );
              // Don't mark row as invalid for elevation issues
            }
          }
        }

        if (rowIsValid) {
          validCount++;
        }
      } catch (e) {
        errors.add('Row $rowNumber: Validation error: ${e.toString()}');
      }
    }

    return copyWith(validationErrors: errors, validRowCount: validCount);
  }

  /// Parse coordinate value from various formats
  double? _parseCoordinate(dynamic value) {
    if (value == null) return null;

    try {
      if (value is double) return value;
      if (value is int) return value.toDouble();

      final stringValue = value.toString().trim();
      if (stringValue.isEmpty) return null;

      // Handle common coordinate formats
      // Remove any non-numeric characters except decimal point and minus sign
      final cleanValue = stringValue
          .replaceAll(
            RegExp(r'[^\d.\-+]'),
            '',
          ) // Keep digits, decimal, minus, plus
          .replaceAll(RegExp(r'^\+'), ''); // Remove leading plus sign

      if (cleanValue.isEmpty) return null;

      return double.tryParse(cleanValue);
    } catch (e) {
      return null;
    }
  }

  /// Get all unique values from a specific column
  List<String> getUniqueValuesFromColumn(String columnName) {
    if (!headers.contains(columnName)) return [];

    final uniqueValues = <String>{};
    for (final row in rows) {
      final value = row[columnName];
      if (value != null && value.toString().isNotEmpty) {
        uniqueValues.add(value.toString());
      }
    }

    return uniqueValues.toList()..sort();
  }

  /// Get sample values from a column for preview
  List<String> getSampleValuesFromColumn(String columnName, {int limit = 5}) {
    if (!headers.contains(columnName)) return [];

    final samples = <String>[];
    for (int i = 0; i < rows.length && samples.length < limit; i++) {
      final value = rows[i][columnName];
      if (value != null && value.toString().isNotEmpty) {
        final stringValue = value.toString();
        if (!samples.contains(stringValue)) {
          samples.add(stringValue);
        }
      }
    }

    return samples;
  }

  /// Get data summary for display
  Map<String, dynamic> getSummary() {
    return {
      'fileName': fileName,
      'totalRows': totalRowCount,
      'validRows': validRowCount,
      'columnCount': headers.length,
      'hasValidCoordinates': hasValidCoordinates,
      'errorCount': validationErrors.length,
    };
  }

  /// Get validation summary as a readable string
  String getValidationSummary() {
    if (validRowCount == 0) {
      return 'No valid coordinate data found';
    }

    final invalidCount = totalRowCount - validRowCount;
    if (invalidCount == 0) {
      return 'All $validRowCount rows have valid coordinates';
    }

    return '$validRowCount valid rows, $invalidCount rows with errors';
  }

  CsvData copyWith({
    String? fileName,
    List<String>? headers,
    List<Map<String, dynamic>>? rows,
    List<String>? validationErrors,
    int? validRowCount,
  }) {
    return CsvData(
      fileName: fileName ?? this.fileName,
      headers: headers ?? this.headers,
      rows: rows ?? this.rows,
      validationErrors: validationErrors ?? this.validationErrors,
      validRowCount: validRowCount ?? this.validRowCount,
    );
  }

  @override
  String toString() {
    return 'CsvData(fileName: $fileName, rows: ${rows.length}, headers: ${headers.length})';
  }
}
