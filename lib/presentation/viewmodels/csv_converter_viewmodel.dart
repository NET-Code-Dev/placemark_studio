import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../data/models/csv_data.dart';
import '../../../data/models/column_mapping.dart';
import '../../../data/models/kml_generation_options.dart';
import '../../../data/services/csv_parser_service.dart';
import '../../../data/services/kml_generation_service.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/enums/geometry_type.dart';
import '../../../core/enums/export_format.dart';
import 'base_viewmodel.dart';

enum ConversionStep {
  fileSelection,
  columnMapping,
  dataPreview,
  geometryAndStyling,
  exportOptions,
}

class CsvConverterViewModel extends BaseViewModel {
  final ICsvParserService _csvParserService;
  final IKmlGenerationService _kmlGenerationService;

  CsvConverterViewModel({
    required ICsvParserService csvParserService,
    required IKmlGenerationService kmlGenerationService,
  }) : _csvParserService = csvParserService,
       _kmlGenerationService = kmlGenerationService;

  // State variables
  File? _selectedFile;
  CsvData? _csvData;
  ColumnMapping? _columnMapping;
  ConversionStep _currentStep = ConversionStep.fileSelection;
  String? _successMessage;

  // Configuration
  GeometryType _selectedGeometryType = GeometryType.point;
  ExportFormat _selectedExportFormat = ExportFormat.kml;
  KmlGenerationOptions _generationOptions = const KmlGenerationOptions();
  String? _outputPath;

  // Getters
  File? get selectedFile => _selectedFile;
  CsvData? get csvData => _csvData;
  ColumnMapping? get columnMapping => _columnMapping;
  ConversionStep get currentStep => _currentStep;
  String? get successMessage => _successMessage;
  GeometryType get selectedGeometryType => _selectedGeometryType;
  ExportFormat get selectedExportFormat => _selectedExportFormat;
  KmlGenerationOptions get generationOptions => _generationOptions;
  String? get outputPath => _outputPath;

  bool get hasCsvData => _csvData != null;
  bool get hasValidMapping => _columnMapping?.isValid ?? false;
  bool get canProceedToPreview => hasCsvData && hasValidMapping;
  bool get canProceedToStyling =>
      canProceedToPreview && _csvData!.hasValidCoordinates;
  bool get canExport => canProceedToStyling;

  List<String> get availableColumns => _csvData?.headers ?? [];
  List<Map<String, dynamic>> get previewData =>
      _csvData?.rows.take(10).toList() ?? [];

  /// Pick and process CSV file
  Future<void> pickCsvFile() async {
    try {
      clearError();
      _successMessage = null;
      setLoading();

      final file = await _csvParserService.pickCsvFile();
      if (file != null) {
        _selectedFile = file;
        await _processCsvFile();
        _currentStep = ConversionStep.columnMapping;
        setSuccess();
      } else {
        setIdle();
      }
    } on AppException catch (e) {
      setError(e.message, e);
    } catch (e) {
      setError('Failed to process CSV file: ${e.toString()}');
    }
  }

  /// Process the selected CSV file
  Future<void> _processCsvFile() async {
    if (_selectedFile == null) return;

    try {
      _csvData = await _csvParserService.parseCsvFile(_selectedFile!);

      // Auto-detect common column mappings
      _columnMapping = _detectColumnMapping();

      if (kDebugMode) {
        print(
          'CSV processed: ${_csvData!.rows.length} rows, ${_csvData!.headers.length} columns',
        );
        print('Headers: ${_csvData!.headers}');
        print('Auto-detected mapping: ${_columnMapping?.toString()}');
      }
    } catch (e) {
      _csvData = null;
      _columnMapping = null;
      rethrow;
    }
  }

  /// Auto-detect column mappings based on common naming patterns
  ColumnMapping _detectColumnMapping() {
    if (_csvData == null) return ColumnMapping.empty();

    final headers = _csvData!.headers.map((h) => h.toLowerCase()).toList();

    // Detect latitude column
    String? latitudeColumn;
    for (int i = 0; i < headers.length; i++) {
      final header = headers[i];
      if (header.contains('lat') ||
          header == 'y' ||
          header.contains('latitude')) {
        latitudeColumn = _csvData!.headers[i];
        break;
      }
    }

    // Detect longitude column
    String? longitudeColumn;
    for (int i = 0; i < headers.length; i++) {
      final header = headers[i];
      if (header.contains('lon') ||
          header.contains('lng') ||
          header == 'x' ||
          header.contains('longitude')) {
        longitudeColumn = _csvData!.headers[i];
        break;
      }
    }

    // Detect name column
    String? nameColumn;
    for (int i = 0; i < headers.length; i++) {
      final header = headers[i];
      if (header.contains('name') ||
          header.contains('title') ||
          header.contains('label')) {
        nameColumn = _csvData!.headers[i];
        break;
      }
    }

    // Detect elevation column
    String? elevationColumn;
    for (int i = 0; i < headers.length; i++) {
      final header = headers[i];
      if (header.contains('elevation') ||
          header.contains('altitude') ||
          header.contains('height') ||
          header == 'z') {
        elevationColumn = _csvData!.headers[i];
        break;
      }
    }

    // Detect description column
    String? descriptionColumn;
    for (int i = 0; i < headers.length; i++) {
      final header = headers[i];
      if (header.contains('description') ||
          header.contains('desc') ||
          header.contains('notes') ||
          header.contains('comment')) {
        descriptionColumn = _csvData!.headers[i];
        break;
      }
    }

    return ColumnMapping(
      latitudeColumn: latitudeColumn,
      longitudeColumn: longitudeColumn,
      nameColumn: nameColumn,
      elevationColumn: elevationColumn,
      descriptionColumn: descriptionColumn,
    );
  }

  /// Update column mapping
  void updateColumnMapping(ColumnMapping mapping) {
    _columnMapping = mapping;

    // Validate coordinates if mapping is complete
    if (mapping.isValid && _csvData != null) {
      _validateCoordinates();
    }

    notifyListeners();
  }

  /// Validate coordinate data
  void _validateCoordinates() {
    if (_csvData == null || _columnMapping == null) return;

    try {
      _csvData = _csvData!.validateCoordinates(_columnMapping!);

      if (_csvData!.hasValidCoordinates) {
        _successMessage =
            'Coordinates validated successfully. ${_csvData!.validRowCount} valid rows found.';
      } else {
        setError('No valid coordinates found in the CSV data.');
      }
    } catch (e) {
      setError('Coordinate validation failed: ${e.toString()}');
    }
  }

  /// Advance to next step
  void proceedToStep(ConversionStep step) {
    switch (step) {
      case ConversionStep.dataPreview:
        if (!canProceedToPreview) return;
        _currentStep = ConversionStep.dataPreview;
        break;
      case ConversionStep.geometryAndStyling:
        if (!canProceedToStyling) return;
        _currentStep = ConversionStep.geometryAndStyling;
        break;
      case ConversionStep.exportOptions:
        if (!canExport) return;
        _currentStep = ConversionStep.exportOptions;
        break;
      default:
        break;
    }

    clearError();
    notifyListeners();
  }

  /// Set geometry type
  void setGeometryType(GeometryType type) {
    if (_selectedGeometryType != type) {
      _selectedGeometryType = type;
      notifyListeners();
    }
  }

  /// Set export format
  void setExportFormat(ExportFormat format) {
    if (_selectedExportFormat != format) {
      _selectedExportFormat = format;
      notifyListeners();
    }
  }

  /// Update generation options
  void updateGenerationOptions(KmlGenerationOptions options) {
    _generationOptions = options;
    notifyListeners();
  }

  /// Set output path
  void setOutputPath(String? path) {
    _outputPath = path;
    notifyListeners();
  }

  /// Generate and export KML/KMZ file
  Future<void> exportKml() async {
    if (!canExport || _csvData == null || _columnMapping == null) {
      setError('Cannot export: missing required data or configuration');
      return;
    }

    try {
      clearError();
      _successMessage = null;
      setLoading();

      final options = _generationOptions.copyWith(
        geometryType: _selectedGeometryType,
        exportFormat: _selectedExportFormat,
        outputPath: _outputPath,
      );

      final outputFile = await _kmlGenerationService.generateKml(
        csvData: _csvData!,
        columnMapping: _columnMapping!,
        options: options,
      );

      _successMessage =
          'KML file generated successfully!\nSaved to: ${outputFile.path}';
      setSuccess();
    } on AppException catch (e) {
      setError(e.message, e);
    } catch (e) {
      setError('Failed to generate KML: ${e.toString()}');
    }
  }

  /// Reset the converter to initial state
  void reset() {
    _selectedFile = null;
    _csvData = null;
    _columnMapping = null;
    _currentStep = ConversionStep.fileSelection;
    _successMessage = null;
    _selectedGeometryType = GeometryType.point;
    _selectedExportFormat = ExportFormat.kml;
    _generationOptions = const KmlGenerationOptions();
    _outputPath = null;
    clearError();
    notifyListeners();
  }

  /// Clear messages
  void clearMessages() {
    _successMessage = null;
    clearError();
    notifyListeners();
  }
}
