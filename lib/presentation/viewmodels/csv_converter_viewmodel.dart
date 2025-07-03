import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../../../data/models/csv_data.dart';
import '../../../data/models/column_mapping.dart';
import '../../../data/models/kml_generation_options.dart';
import '../../../data/models/styling_options.dart';
import '../../../data/models/styling_rule.dart';
import '../../../data/models/styling_compatibility.dart';
import '../../../data/services/csv_parser_service.dart';
import '../../../data/services/kml_generation_service.dart';
import '../../../data/services/enhanced_kml_generation_service.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/enums/geometry_type.dart';
import '../../../core/enums/export_format.dart';
import '../../../core/enums/conversion_step.dart';
import 'base_viewmodel.dart';

class CsvConverterViewModel extends BaseViewModel {
  final ICsvParserService _csvParserService;
  final IKmlGenerationService _kmlGenerationService;
  final IEnhancedKmlGenerationService _enhancedKmlGenerationService;

  CsvConverterViewModel({
    required ICsvParserService csvParserService,
    required IKmlGenerationService kmlGenerationService,
    IEnhancedKmlGenerationService? enhancedKmlGenerationService,
  }) : _csvParserService = csvParserService,
       _kmlGenerationService = kmlGenerationService,
       _enhancedKmlGenerationService =
           enhancedKmlGenerationService ?? EnhancedKmlGenerationService();

  // State variables
  File? _selectedFile;
  CsvData? _csvData;
  ColumnMapping? _columnMapping;
  ConversionStep _currentStep = ConversionStep.fileSelection;
  String? _successMessage;
  List<String> _selectedDescriptionColumns = [];
  bool _useDescriptionTable = false;
  String _descriptionTableStyle = 'simple';

  // Configuration
  GeometryType _selectedGeometryType = GeometryType.point;
  ExportFormat _selectedExportFormat = ExportFormat.kml;
  KmlGenerationOptions _generationOptions = const KmlGenerationOptions();
  StylingOptions _stylingOptions = StylingOptions.forGeometry(
    GeometryType.point,
  );

  // Enhanced styling support
  EnhancedStylingOptions? _enhancedStylingOptions;
  bool _useEnhancedStyling = false;

  // Output path options
  String? _customOutputPath;
  bool _useDefaultLocation = true;

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
  List<String> get selectedDescriptionColumns => _selectedDescriptionColumns;
  bool get useDescriptionTable => _useDescriptionTable;
  String get descriptionTableStyle => _descriptionTableStyle;

  // Enhanced styling getters
  EnhancedStylingOptions get enhancedStylingOptions =>
      _enhancedStylingOptions ??
      StylingCompatibility.createEnhanced(
        geometryType: _selectedGeometryType,
        existingOptions: _stylingOptions,
      );
  bool get useEnhancedStyling => _useEnhancedStyling;

  // Output path getters
  String? get customOutputPath => _customOutputPath;
  bool get useDefaultLocation => _useDefaultLocation;
  String? get csvFilePath => _selectedFile?.path;

  bool get hasCsvData => _csvData != null;
  bool get hasValidMapping => _columnMapping?.isValid ?? false;
  bool get canProceedToPreview => hasCsvData && hasValidMapping;
  bool get canProceedToStyling =>
      canProceedToPreview && _csvData!.hasValidCoordinates;
  bool get canExport => canProceedToStyling;

  List<String> get availableColumns => _csvData?.headers ?? [];
  List<Map<String, dynamic>> get previewData =>
      _csvData?.rows.take(10).toList() ?? [];

  // Default filename based on CSV name and export format
  String get defaultFileName {
    if (_selectedFile == null) return 'converted_data.kml';

    final baseName = path.basenameWithoutExtension(_selectedFile!.path);
    final extension =
        _selectedExportFormat == ExportFormat.kmz ? '.kmz' : '.kml';
    return '$baseName$extension';
  }

  // Final output path (either custom or default location)
  String get finalOutputPath {
    if (!_useDefaultLocation && _customOutputPath != null) {
      return _customOutputPath!;
    } else if (_selectedFile != null) {
      final csvDir = path.dirname(_selectedFile!.path);
      return path.join(csvDir, defaultFileName);
    } else {
      // Fallback to downloads directory
      return path.join(_getDownloadsDirectory(), defaultFileName);
    }
  }

  /// Get platform-specific downloads directory
  String _getDownloadsDirectory() {
    if (Platform.isWindows) {
      return path.join(Platform.environment['USERPROFILE'] ?? '.', 'Downloads');
    } else {
      return path.join(Platform.environment['HOME'] ?? '.', 'Downloads');
    }
  }

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

  void updateDescriptionColumns(List<String> columns) {
    _selectedDescriptionColumns = columns;
    _updateGenerationOptionsWithDescription();
    notifyListeners();
  }

  void setUseDescriptionTable(bool useTable) {
    _useDescriptionTable = useTable;
    if (!useTable) {
      _selectedDescriptionColumns = []; // Clear selections when disabled
    }
    _updateGenerationOptionsWithDescription();
    notifyListeners();
  }

  void setDescriptionTableStyle(String style) {
    _descriptionTableStyle = style;
    _updateGenerationOptionsWithDescription();
    notifyListeners();
  }

  /// Update generation options with description table settings
  void _updateGenerationOptionsWithDescription() {
    _generationOptions = _generationOptions.copyWith(
      useDescriptionTable: _useDescriptionTable,
      descriptionColumns:
          _useDescriptionTable ? _selectedDescriptionColumns : null,
      descriptionTableStyle:
          _useDescriptionTable ? _descriptionTableStyle : null,
    );
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

  /// Initialize styling with Google Earth defaults
  void _initializeDefaultStyling(GeometryType geometryType) {
    _stylingOptions = StylingOptions.withGoogleEarthDefaults(geometryType);

    if (kDebugMode) {
      print('Initialized styling with Google Earth defaults for $geometryType');
      print('Default icon: ${_stylingOptions.defaultStyle.icon?.displayName}');
      print('Default color: ${_stylingOptions.defaultStyle.color.name}');
      print('Default scale: ${_stylingOptions.defaultStyle.scale}');
      print(
        'Default label color: ${_stylingOptions.defaultStyle.labelColor.name}',
      );
      print('Default label scale: ${_stylingOptions.defaultStyle.labelScale}');
    }

    notifyListeners();
  }

  /// Set geometry type and initialize appropriate defaults
  void setGeometryType(GeometryType geometryType) {
    if (_selectedGeometryType != geometryType) {
      _selectedGeometryType = geometryType;

      // Initialize with Google Earth defaults for this geometry type
      _initializeDefaultStyling(geometryType);

      notifyListeners();
    }
  }

  /// Set custom output path
  void setCustomOutputPath(String? outputPath) {
    _customOutputPath = outputPath;
    notifyListeners();
  }

  /// Toggle between default location (same as CSV) and custom location
  void setUseDefaultLocation(bool useDefault) {
    _useDefaultLocation = useDefault;
    if (useDefault) {
      _customOutputPath = null; // Clear custom path when switching to default
    }
    notifyListeners();
  }

  /// Set export format and update default filename
  void setExportFormat(ExportFormat format) {
    if (_selectedExportFormat != format) {
      _selectedExportFormat = format;

      // Update custom output path if it exists to match new extension
      if (_customOutputPath != null) {
        final directory = path.dirname(_customOutputPath!);
        final newFileName = defaultFileName;
        _customOutputPath = path.join(directory, newFileName);
      }

      notifyListeners();
    }
  }

  /// Update generation options
  void updateGenerationOptions(KmlGenerationOptions options) {
    _generationOptions = options;
    notifyListeners();
  }

  /*
  /// Update styling options (legacy method)
  void updateStylingOptions(StylingOptions options) {
    _stylingOptions = options;
    _useEnhancedStyling = false;
    notifyListeners();
  }
*/

  /// Update styling options (called when user makes selections)
  void updateStylingOptions(StylingOptions options) {
    _stylingOptions = options;

    if (kDebugMode) {
      print('User updated styling options:');
      print('Icon: ${options.defaultStyle.icon?.displayName}');
      print('Color: ${options.defaultStyle.color.name}');
      print('Scale: ${options.defaultStyle.scale}');
      print('Label color: ${options.defaultStyle.labelColor.name}');
      print('Label scale: ${options.defaultStyle.labelScale}');
    }

    notifyListeners();
  }

  /// Update enhanced styling options (new method)
  void updateEnhancedStylingOptions(EnhancedStylingOptions options) {
    _enhancedStylingOptions = options;
    _useEnhancedStyling = true;
    // Also update legacy styling for backward compatibility
    _stylingOptions = StylingCompatibility.toLegacy(options);

    if (kDebugMode) {
      print('Enhanced styling updated:');
      print('  Rules: ${options.rules.length}');
      print('  Column: ${options.stylingColumn}');
      print('  Rule-based: ${options.useRuleBasedStyling}');
    }

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

  Future<void> exportToKml() async {
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

      final documentName =
          _generationOptions.documentName.isNotEmpty
              ? _generationOptions.documentName
              : 'Converted from ${_csvData!.fileName}';

      final documentDescription =
          _generationOptions.documentDescription.isNotEmpty
              ? _generationOptions.documentDescription
              : 'Generated by Placemark Studio from CSV data';

      // Create style rule from current styling (could be defaults or user selections)
      final currentStyle = _stylingOptions.defaultStyle;
      Map<String, StyleRule> styleRulesForExport = {};

      // Always add the current style (whether defaults or user selections)
      styleRulesForExport['defaultUserStyle'] = StyleRule(
        columnName: '_default_',
        columnValue: '_default_',
        color: currentStyle.color.kmlValue,
        iconUrl: currentStyle.icon?.url ?? KmlIcon.pushpin.url,
        scale: currentStyle.scale,
        labelColor: currentStyle.labelColor.kmlValue,
        labelScale: currentStyle.labelScale,
      );

      if (kDebugMode) {
        print('Exporting with style:');
        print(
          '  Color: ${currentStyle.color.name} (${currentStyle.color.kmlValue})',
        );
        print('  Icon: ${currentStyle.icon?.displayName}');
        print('  Scale: ${currentStyle.scale}');
        print(
          '  Label Color: ${currentStyle.labelColor.name} (${currentStyle.labelColor.kmlValue})',
        );
        print('  Label Scale: ${currentStyle.labelScale}');
      }

      // Add criteria-based rules if enabled
      if (_stylingOptions.useColumnBasedStyling) {
        final criteriaRules = _stylingOptions.toStyleRules();
        styleRulesForExport.addAll(criteriaRules);
      }

      final exportOptions = _generationOptions.copyWith(
        geometryType: _selectedGeometryType,
        documentName: documentName,
        documentDescription: documentDescription,
        useCustomIcons:
            true, // Always true since we always have user's default style
        styleRules: styleRulesForExport,
      );

      // Determine final output path
      final outputFilePath = finalOutputPath;

      // Ensure output directory exists
      final outputDir = Directory(path.dirname(outputFilePath));
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }

      late File outputFile;

      // Check if we should use enhanced styling
      if (_useEnhancedStyling &&
          _enhancedStylingOptions != null &&
          _enhancedStylingOptions!.useRuleBasedStyling &&
          _enhancedStylingOptions!.rules.isNotEmpty) {
        if (kDebugMode) {
          print('Using Enhanced KML Generation Service');
          print(
            'Enhanced styling rules: ${_enhancedStylingOptions!.rules.length}',
          );
          print('Output path: $outputFilePath');
        }

        // Use enhanced service for rule-based styling
        outputFile = await _enhancedKmlGenerationService.generateKmlWithRules(
          csvData: _csvData!,
          columnMapping: _columnMapping!,
          stylingOptions: _enhancedStylingOptions!,
          documentName: documentName,
          documentDescription: documentDescription,
          geometryType: _selectedGeometryType,
          includeElevation: _generationOptions.includeElevation,
          includeDescription: _generationOptions.includeDescription,
        );

        // Move file to desired location if generated elsewhere
        if (outputFile.path != outputFilePath) {
          final finalFile = File(outputFilePath);
          await outputFile.copy(finalFile.path);
          await outputFile.delete(); // Clean up temp file
          outputFile = finalFile;
        }
      } else {
        if (kDebugMode) {
          print('Using Legacy KML Generation Service');
          print('Style rules count: ${styleRulesForExport.length}');
          print(
            'Default style: ${styleRulesForExport['defaultUserStyle']?.color} - ${styleRulesForExport['defaultUserStyle']?.iconUrl}',
          );
          print('Output path: $outputFilePath');
        }

        // Use legacy service
        outputFile = await _kmlGenerationService.generateKml(
          csvData: _csvData!,
          columnMapping: _columnMapping!,
          options: exportOptions,
        );

        // Move file to desired location if generated elsewhere
        if (outputFile.path != outputFilePath) {
          final finalFile = File(outputFilePath);
          await outputFile.copy(finalFile.path);
          await outputFile.delete(); // Clean up temp file
          outputFile = finalFile;
        }
      }

      _outputPath = outputFile.path;

      final validRowCount = _csvData!.validRowCount;
      //  setLoading();
      _successMessage =
          'Successfully exported $validRowCount features to KML format';

      if (kDebugMode) {
        print('KML export completed: $_outputPath');
        print('Features exported: $validRowCount');
      }

      notifyListeners();
    } catch (e) {
      setLoading();
      setError('Export failed: ${e.toString()}');
      if (kDebugMode) {
        print('KML export error: $e');
      }
    }
  }

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

      final documentName =
          _generationOptions.documentName.isNotEmpty
              ? _generationOptions.documentName
              : 'Converted from ${_csvData!.fileName}';

      final documentDescription =
          _generationOptions.documentDescription.isNotEmpty
              ? _generationOptions.documentDescription
              : 'Generated by Placemark Studio from CSV data with images';

      // Create style rule from current styling (could be defaults or user selections)
      final currentStyle = _stylingOptions.defaultStyle;

      Map<String, StyleRule> styleRulesForExport = {};

      // Always add the current style (whether defaults or user selections)
      styleRulesForExport['defaultUserStyle'] = StyleRule(
        columnName: '_default_',
        columnValue: '_default_',
        color: currentStyle.color.kmlValue,
        iconUrl: currentStyle.icon?.url ?? KmlIcon.pushpin.url,
        scale: currentStyle.scale,
        labelColor: currentStyle.labelColor.kmlValue,
        labelScale: currentStyle.labelScale,
      );

      if (kDebugMode) {
        print('Exporting with style:');
        print(
          '  Color: ${currentStyle.color.name} (${currentStyle.color.kmlValue})',
        );
        print('  Icon: ${currentStyle.icon?.displayName}');
        print('  Scale: ${currentStyle.scale}');
        print(
          '  Label Color: ${currentStyle.labelColor.name} (${currentStyle.labelColor.kmlValue})',
        );
        print('  Label Scale: ${currentStyle.labelScale}');
      }

      // Add criteria-based rules if enabled
      if (_stylingOptions.useColumnBasedStyling) {
        final criteriaRules = _stylingOptions.toStyleRules();
        styleRulesForExport.addAll(criteriaRules);
      }

      late File outputFile;

      // Check if we should use enhanced styling
      if (_useEnhancedStyling &&
          _enhancedStylingOptions != null &&
          _enhancedStylingOptions!.useRuleBasedStyling &&
          _enhancedStylingOptions!.rules.isNotEmpty) {
        if (kDebugMode) {
          print('Using Enhanced KMZ Generation Service');
          print(
            'Enhanced styling rules: ${_enhancedStylingOptions!.rules.length}',
          );
        }

        // Use enhanced service for rule-based styling
        outputFile = await _enhancedKmlGenerationService.generateKmzWithRules(
          csvData: _csvData!,
          columnMapping: _columnMapping!,
          stylingOptions: _enhancedStylingOptions!,
          documentName: documentName,
          documentDescription: documentDescription,
          geometryType: _selectedGeometryType,
          imageFiles: imageFiles,
          includeElevation: _generationOptions.includeElevation,
          includeDescription: _generationOptions.includeDescription,
        );
      } else {
        if (kDebugMode) {
          print('Using Legacy KMZ Generation Service');
          print('Style rules count: ${styleRulesForExport.length}');
        }

        // Use legacy service
        final exportOptions = _generationOptions.copyWith(
          geometryType: _selectedGeometryType,
          documentName: documentName,
          documentDescription: documentDescription,
          useCustomIcons:
              true, // Always true since we always have user's default style
          styleRules: styleRulesForExport,
        );

        outputFile = await _kmlGenerationService.generateKmz(
          csvData: _csvData!,
          columnMapping: _columnMapping!,
          options: exportOptions,
          imageFiles: imageFiles,
        );
      }

      _outputPath = outputFile.path;

      final validRowCount = _csvData!.validRowCount;
      final imageCount = imageFiles?.length ?? 0;
      setLoading();
      _successMessage =
          'Successfully exported $validRowCount features and $imageCount images to KMZ format';

      if (kDebugMode) {
        print('KMZ export completed: $_outputPath');
        print('Features exported: $validRowCount');
        print('Images included: $imageCount');
      }

      notifyListeners();
    } catch (e) {
      setLoading();
      setError('Export failed: ${e.toString()}');
      if (kDebugMode) {
        print('KMZ export error: $e');
      }
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
    _selectedDescriptionColumns = [];
    _useDescriptionTable = false;
    _descriptionTableStyle = 'simple';

    // Reset to defaults
    _selectedGeometryType = GeometryType.point;
    _selectedExportFormat = ExportFormat.kml;
    _generationOptions = const KmlGenerationOptions();
    _stylingOptions = StylingOptions.forGeometry(GeometryType.point);
    _enhancedStylingOptions = null;
    _useEnhancedStyling = false;
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
