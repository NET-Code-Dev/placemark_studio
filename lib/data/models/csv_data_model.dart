class CsvRow {
  final Map<String, String> data;
  final int rowIndex;
  final List<String> validationErrors;

  CsvRow({
    required this.data,
    required this.rowIndex,
    this.validationErrors = const [],
  });

  String? getValue(String columnName) => data[columnName];

  bool get isValid => validationErrors.isEmpty;

  CsvRow copyWith({
    Map<String, String>? data,
    int? rowIndex,
    List<String>? validationErrors,
  }) {
    return CsvRow(
      data: data ?? this.data,
      rowIndex: rowIndex ?? this.rowIndex,
      validationErrors: validationErrors ?? this.validationErrors,
    );
  }
}

class CsvData {
  final List<String> headers;
  final List<CsvRow> rows;
  final String fileName;
  final DateTime importedAt;

  CsvData({
    required this.headers,
    required this.rows,
    required this.fileName,
    required this.importedAt,
  });

  int get totalRows => rows.length;
  int get validRows => rows.where((row) => row.isValid).length;
  int get invalidRows => rows.where((row) => !row.isValid).length;

  List<String> get allValidationErrors {
    return rows.expand((row) => row.validationErrors).toList();
  }
}

class ColumnMapping {
  final String? nameColumn;
  final String? latitudeColumn;
  final String? longitudeColumn;
  final String? elevationColumn;
  final String? descriptionColumn;

  ColumnMapping({
    this.nameColumn,
    this.latitudeColumn,
    this.longitudeColumn,
    this.elevationColumn,
    this.descriptionColumn,
  });

  bool get isValid =>
      nameColumn != null && latitudeColumn != null && longitudeColumn != null;

  ColumnMapping copyWith({
    String? nameColumn,
    String? latitudeColumn,
    String? longitudeColumn,
    String? elevationColumn,
    String? descriptionColumn,
  }) {
    return ColumnMapping(
      nameColumn: nameColumn ?? this.nameColumn,
      latitudeColumn: latitudeColumn ?? this.latitudeColumn,
      longitudeColumn: longitudeColumn ?? this.longitudeColumn,
      elevationColumn: elevationColumn ?? this.elevationColumn,
      descriptionColumn: descriptionColumn ?? this.descriptionColumn,
    );
  }
}
