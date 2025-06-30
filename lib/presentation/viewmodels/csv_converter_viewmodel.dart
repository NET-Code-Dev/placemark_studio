import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../../../data/models/csv_data.dart';
import '../../../data/models/column_mapping.dart';
import '../../../data/models/kml_generation_options.dart';
import '../../../data/models/styling_options.dart';
import '../../../data/services/csv_parser_service.dart';
import '../../../data/services/kml_generation_service.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/enums/geometry_type.dart';
import '../../../core/enums/export_format.dart';
import '../../../core/enums/conversion_step.dart';
import 'base_viewmodel.dart';

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
  StylingOptions _stylingOptions = StylingOptions.forGeometry(
    GeometryType.point,
  );
  String? _outputPath;
  List<String>? _previewColumnValues;

  // Getters
  File? get selectedFile => _selectedFile;
  CsvData? get csvData => _csvData;
  ColumnMapping? get columnMapping => _columnMapping;
  ConversionStep get currentStep => _currentStep;
  String? get successMessage => _successMessage;
  GeometryType get selectedGeometryType => _selectedGeometryType;
  ExportFormat get selectedExportFormat => _selectedExportFormat;
  KmlGenerationOptions get generationOptions => _generationOptions;
  StylingOptions get currentStylingOptions => _stylingOptions;
  String? get outputPath => _outputPath;
  List<String>? get previewColumnValues => _previewColumnValues;

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

  /// Handle dropped CSV file (for drag and drop)
  Future<void> processCsvFile(File file) async {
    try {
      clearError();
      _successMessage = null;
      setLoading();

      _selectedFile = file;
      await _processCsvFile();
      _currentStep = ConversionStep.columnMapping;
      setSuccess();
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
    if (_csvData == null || _csvData!.headers.isEmpty) {
      return ColumnMapping.empty();
    }

    final headers = _csvData!.headers;

    if (kDebugMode) {
      print('=== COLUMN MAPPING DETECTION ===');
      print('Total headers: ${headers.length}');
      print(
        'Headers: ${headers.take(10).join(', ')}${headers.length > 10 ? '...' : ''}',
      );
    }

    // If we only have one header, the CSV parsing failed
    if (headers.length == 1) {
      if (kDebugMode) {
        print('WARNING: Only 1 column detected. CSV parsing may have failed.');
        print('Single header content: ${headers.first}');
      }
      return ColumnMapping.empty();
    }

    String? latitudeColumn;
    String? longitudeColumn;
    String? nameColumn;
    String? elevationColumn;
    String? descriptionColumn;

    // Detect latitude column
    for (final header in headers) {
      final lowerHeader = header.toLowerCase().trim();
      if (_isLatitudeColumn(lowerHeader)) {
        latitudeColumn = header;
        if (kDebugMode) print('Detected latitude column: $header');
        break;
      }
    }

    // Detect longitude column
    for (final header in headers) {
      final lowerHeader = header.toLowerCase().trim();
      if (_isLongitudeColumn(lowerHeader)) {
        longitudeColumn = header;
        if (kDebugMode) print('Detected longitude column: $header');
        break;
      }
    }

    // Detect name column
    for (final header in headers) {
      final lowerHeader = header.toLowerCase().trim();
      if (_isNameColumn(lowerHeader)) {
        nameColumn = header;
        if (kDebugMode) print('Detected name column: $header');
        break;
      }
    }

    // Detect elevation column
    for (final header in headers) {
      final lowerHeader = header.toLowerCase().trim();
      if (_isElevationColumn(lowerHeader)) {
        elevationColumn = header;
        if (kDebugMode) print('Detected elevation column: $header');
        break;
      }
    }

    // Detect description column
    for (final header in headers) {
      final lowerHeader = header.toLowerCase().trim();
      if (_isDescriptionColumn(lowerHeader)) {
        descriptionColumn = header;
        if (kDebugMode) print('Detected description column: $header');
        break;
      }
    }

    final mapping = ColumnMapping(
      latitudeColumn: latitudeColumn,
      longitudeColumn: longitudeColumn,
      nameColumn: nameColumn,
      elevationColumn: elevationColumn,
      descriptionColumn: descriptionColumn,
    );

    if (kDebugMode) {
      print(
        'Final mapping: lat=$latitudeColumn, lon=$longitudeColumn, name=$nameColumn',
      );
      print('Mapping is valid: ${mapping.isValid}');
    }

    return mapping;
  }

  bool _isLatitudeColumn(String header) {
    return header == 'latitude' ||
        header == 'lat' ||
        header == 'y' ||
        header.contains('lat') && !header.contains('lon') ||
        header == 'northing';
  }

  bool _isLongitudeColumn(String header) {
    return header == 'longitude' ||
        header == 'lon' ||
        header == 'lng' ||
        header == 'long' ||
        header == 'x' ||
        header.contains('lon') && !header.contains('lat') ||
        header == 'easting';
  }

  bool _isNameColumn(String header) {
    return header == 'name' ||
        header == 'title' ||
        header == 'label' ||
        header == 'point_name' ||
        header == 'site_name' ||
        header.contains('name') ||
        header.contains('title') ||
        header.contains('label');
  }

  bool _isElevationColumn(String header) {
    return header == 'elevation' ||
        header == 'altitude' ||
        header == 'height' ||
        header == 'z' ||
        header.contains('elev') ||
        header.contains('alt') ||
        header.contains('height');
  }

  bool _isDescriptionColumn(String header) {
    return header == 'description' ||
        header == 'desc' ||
        header.contains('desc');
  }

  /// Update column mapping
  void updateColumnMapping(ColumnMapping mapping) {
    _columnMapping = mapping;

    // Validate coordinates if mapping is complete
    if (mapping.hasCoordinates && _csvData != null) {
      _validateCoordinates();
    } else {
      // Clear validation if mapping is incomplete
      if (_csvData != null) {
        _csvData = _csvData!.copyWith(validationErrors: [], validRowCount: 0);
      }
    }

    notifyListeners();
  }

  /// Validate coordinate data
  void _validateCoordinates() {
    if (_csvData == null || _columnMapping == null) return;

    try {
      _csvData = _csvData!.validateCoordinates(_columnMapping!);

      if (_csvData!.hasValidCoordinates) {
        final validCount = _csvData!.validRowCount;
        final totalCount = _csvData!.totalRowCount;
        final errorCount = _csvData!.validationErrors.length;

        if (errorCount == 0) {
          _successMessage = 'All $validCount rows have valid coordinates!';
        } else {
          _successMessage =
              '$validCount of $totalCount rows have valid coordinates.';
        }

        // Clear any previous errors since we have valid data
        clearError();
      } else {
        setError(
          'No valid coordinates found in the CSV data. Please check your column mapping and data format.',
        );
      }
    } catch (e) {
      setError('Coordinate validation failed: ${e.toString()}');
    }
  }

  /// Manual validation trigger for user-initiated validation
  void validateData() {
    if (_csvData == null || _columnMapping == null) {
      setError('No data or column mapping available for validation');
      return;
    }

    if (!_columnMapping!.hasCoordinates) {
      setError(
        'Please map both latitude and longitude columns before validation',
      );
      return;
    }

    _validateCoordinates();
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
      case ConversionStep.exportComplete:
        _currentStep = ConversionStep.exportComplete;
        break;
      default:
        _currentStep = step;
        break;
    }

    clearError();
    notifyListeners();
  }

  /// Set geometry type
  void setGeometryType(GeometryType type) {
    if (_selectedGeometryType != type) {
      _selectedGeometryType = type;
      // Update styling options for new geometry type
      _stylingOptions = StylingOptions.forGeometry(type);
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

  /// Update styling options
  void updateStylingOptions(StylingOptions options) {
    _stylingOptions = options;
    notifyListeners();
  }

  /// Preview column values for styling
  void previewColumnValuesForStyling(String columnName) {
    if (_csvData == null) return;

    try {
      final uniqueValues = _csvData!.getUniqueValuesFromColumn(columnName);
      _previewColumnValues =
          uniqueValues.take(10).toList(); // Limit to 10 for UI
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to preview column values: $e');
      }
    }
  }

  /// Set output path
  void setOutputPath(String? path) {
    _outputPath = path;
    notifyListeners();
  }

  /// Export CSV data to KML file
  Future<void> exportToKml() async {
    if (!canExport) {
      setError('Cannot export: Data validation failed');
      return;
    }

    try {
      clearError();
      _successMessage = null;
      setLoading();

      // Validate data one more time before export
      if (_csvData == null || _columnMapping == null) {
        throw ConversionException(
          'Missing required data for export',
          code: 'MISSING_EXPORT_DATA',
        );
      }

      // Update generation options with current settings including styling
      final exportOptions = _generationOptions.copyWith(
        geometryType: _selectedGeometryType,
        documentName:
            _generationOptions.documentName.isNotEmpty
                ? _generationOptions.documentName
                : 'Converted from ${_csvData!.fileName}',
        documentDescription:
            _generationOptions.documentDescription.isNotEmpty
                ? _generationOptions.documentDescription
                : 'Generated by Placemark Studio from CSV data',
        useCustomIcons: _stylingOptions.useColumnBasedStyling,
        styleRules:
            _stylingOptions.useColumnBasedStyling
                ? _stylingOptions.toStyleRules()
                : null,
      );

      // Generate KML file
      final outputFile = await _kmlGenerationService.generateKml(
        csvData: _csvData!,
        columnMapping: _columnMapping!,
        options: exportOptions,
      );

      _outputPath = outputFile.path;

      // Count successful exports for user feedback
      final validRowCount = _csvData!.validRowCount;
      _successMessage =
          'KML file exported successfully!\n'
          'Location: ${outputFile.path}\n'
          'Placemarks: $validRowCount\n'
          'File size: ${_formatFileSize(await outputFile.length())}';

      _currentStep = ConversionStep.exportComplete;
      setSuccess();

      if (kDebugMode) {
        print('KML export completed successfully');
        print('Output path: ${outputFile.path}');
        print('File size: ${await outputFile.length()} bytes');
      }
    } on AppException catch (e) {
      setError('Export failed: ${e.message}', e);
    } catch (e) {
      setError('Export failed: ${e.toString()}');
      if (kDebugMode) {
        print('Export error: $e');
      }
    }
  }

  /// Export CSV data to KMZ file (for future milestone)
  Future<void> exportToKmz({List<File>? imageFiles}) async {
    if (!canExport) {
      setError('Cannot export: Data validation failed');
      return;
    }

    try {
      clearError();
      _successMessage = null;
      setLoading();

      if (_csvData == null || _columnMapping == null) {
        throw ConversionException(
          'Missing required data for export',
          code: 'MISSING_EXPORT_DATA',
        );
      }

      // Update generation options
      final exportOptions = _generationOptions.copyWith(
        geometryType: _selectedGeometryType,
        documentName:
            _generationOptions.documentName.isNotEmpty
                ? _generationOptions.documentName
                : 'Converted from ${_csvData!.fileName}',
        documentDescription:
            _generationOptions.documentDescription.isNotEmpty
                ? _generationOptions.documentDescription
                : 'Generated by Placemark Studio from CSV data with images',
        useCustomIcons: _stylingOptions.useColumnBasedStyling,
        styleRules:
            _stylingOptions.useColumnBasedStyling
                ? _stylingOptions.toStyleRules()
                : null,
      );

      // Generate KMZ file
      final outputFile = await _kmlGenerationService.generateKmz(
        csvData: _csvData!,
        columnMapping: _columnMapping!,
        options: exportOptions,
        imageFiles: imageFiles,
      );

      _outputPath = outputFile.path;

      final validRowCount = _csvData!.validRowCount;
      final imageCount = imageFiles?.length ?? 0;
      _successMessage =
          'KMZ file exported successfully!\n'
          'Location: ${outputFile.path}\n'
          'Placemarks: $validRowCount\n'
          'Images: $imageCount\n'
          'File size: ${_formatFileSize(await outputFile.length())}';

      _currentStep = ConversionStep.exportComplete;
      setSuccess();

      if (kDebugMode) {
        print('KMZ export completed successfully');
        print('Output path: ${outputFile.path}');
        print('Images included: $imageCount');
      }
    } on AppException catch (e) {
      setError('Export failed: ${e.message}', e);
    } catch (e) {
      setError('Export failed: ${e.toString()}');
    }
  }

  /// Get export progress information
  Map<String, dynamic> get exportInfo {
    if (_csvData == null) return {};

    return {
      'totalRows': _csvData!.rows.length,
      'validRows': _csvData!.validRowCount,
      'invalidRows': _csvData!.rows.length - _csvData!.validRowCount,
      'geometryType': _selectedGeometryType.displayName,
      'exportFormat': _selectedExportFormat.displayName,
      'hasElevation': _columnMapping?.elevationColumn != null,
      'hasDescription': _columnMapping?.descriptionColumn != null,
    };
  }

  /// Format file size for display
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Reset converter state for new file
  void resetConverter() {
    _selectedFile = null;
    _csvData = null;
    _columnMapping = null;
    _currentStep = ConversionStep.fileSelection;
    _successMessage = null;
    _outputPath = null;

    // Reset to defaults
    _selectedGeometryType = GeometryType.point;
    _selectedExportFormat = ExportFormat.kml;
    _generationOptions = const KmlGenerationOptions();
    _stylingOptions = StylingOptions.forGeometry(GeometryType.point);
    _previewColumnValues = null;

    clearError();
    notifyListeners();
  }

  /// Open output folder (platform-specific implementation needed)
  Future<void> openOutputFolder() async {
    if (_outputPath == null) return;

    try {
      final outputDir = Directory(path.dirname(_outputPath!));

      if (await outputDir.exists()) {
        // Platform-specific folder opening logic would go here
        // For now, just show the path
        _successMessage = 'Output folder: ${outputDir.path}';
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to open output folder: $e');
      }
    }
  }
}
