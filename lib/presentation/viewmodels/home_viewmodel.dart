import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import '../../data/services/file_picker_service.dart';
import '../../data/services/kml_parser_service.dart';
import '../../data/services/csv_export_service.dart';
import '../../data/models/kml_data.dart';
import '../../data/models/export_options.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/enums/export_format.dart';
import 'base_viewmodel.dart';

class HomeViewModel extends BaseViewModel {
  final IFilePickerService _filePickerService;
  final IKmlParserService _kmlParserService;
  final ICsvExportService _csvExportService;

  HomeViewModel({
    required IFilePickerService filePickerService,
    required IKmlParserService kmlParserService,
    required ICsvExportService csvExportService,
  }) : _filePickerService = filePickerService,
       _kmlParserService = kmlParserService,
       _csvExportService = csvExportService;

  File? _selectedFile;
  KmlData? _kmlData;
  String? _successMessage;
  List<List<String>>? _previewData;
  ExportFormat _selectedExportFormat = ExportFormat.csv;
  String? _outputPath;
  Map<String, List<String>>? _duplicateHeaders;
  final Map<String, bool> _duplicateHandling = {};
  bool _separateLayers = false;

  // Getters
  File? get selectedFile => _selectedFile;
  KmlData? get kmlData => _kmlData;
  String? get successMessage => _successMessage;
  List<List<String>>? get previewData => _previewData;
  ExportFormat get selectedExportFormat => _selectedExportFormat;
  String? get outputPath => _outputPath;
  Map<String, List<String>>? get duplicateHeaders => _duplicateHeaders;
  Map<String, bool> get duplicateHandling =>
      Map.unmodifiable(_duplicateHandling);
  bool get separateLayers => _separateLayers;

  bool get hasSelectedFile => _selectedFile != null;
  bool get hasKmlData => _kmlData != null;
  bool get hasPreviewData => _previewData != null;
  bool get hasDuplicateHeaders => _duplicateHeaders?.isNotEmpty ?? false;
  bool get hasOutputPath => _outputPath != null;
  String? get selectedFileName =>
      _selectedFile != null ? path.basename(_selectedFile!.path) : null;

  List<ExportFormat> get supportedFormats =>
      ExportFormat.values.where((f) => f.isSupported).toList();

  Future<void> pickFile() async {
    try {
      clearError();
      _successMessage = null;

      setLoading();
      final file = await _filePickerService.pickKmlFile();

      if (file != null) {
        _selectedFile = file;

        // Automatically parse the KML file and generate preview
        await _parseAndPreview();

        setSuccess();
      } else {
        setIdle();
      }
    } on AppException catch (e) {
      setError(e.message, e);
    } catch (e) {
      setError('Failed to select file: ${e.toString()}');
    }
  }

  Future<void> _parseAndPreview() async {
    if (_selectedFile == null) return;

    try {
      // Parse KML file
      _kmlData = await _kmlParserService.parseKmlFile(_selectedFile!);

      // Detect duplicate headers
      _duplicateHeaders = _csvExportService.detectDuplicateHeaders(_kmlData!);

      // Initialize duplicate handling (default to keep all)
      _duplicateHandling.clear();
      _duplicateHeaders?.keys.forEach((header) {
        _duplicateHandling[header] = true;
      });

      // Generate preview data
      await _generatePreview();
    } catch (e) {
      _kmlData = null;
      _previewData = null;
      _duplicateHeaders = null;
      rethrow;
    }
  }

  Future<void> _generatePreview() async {
    if (_kmlData == null) return;

    try {
      // Create export options for preview
      final exportOptions = ExportOptions.csv();

      // Export to CSV content
      final csvContent = await _csvExportService.exportToCsv(
        _kmlData!,
        exportOptions,
      );

      // Generate preview data
      _generatePreviewData(csvContent);
    } catch (e) {
      if (kDebugMode) {
        print('Warning: Failed to generate preview: $e');
      }
      _previewData = null;
    }
  }

  void setSelectedExportFormat(ExportFormat format) {
    if (_selectedExportFormat != format) {
      _selectedExportFormat = format;
      notifyListeners();
    }
  }

  void setSeparateLayers(bool separate) {
    if (_separateLayers != separate) {
      _separateLayers = separate;
      notifyListeners();
    }
  }

  void setDuplicateHandling(String header, bool keep) {
    _duplicateHandling[header] = keep;
    notifyListeners();

    // Regenerate preview with new duplicate handling
    if (_kmlData != null) {
      _generatePreview();
    }
  }

  Future<void> selectOutputPath() async {
    try {
      String? outputDirectory = await FilePicker.platform.getDirectoryPath();
      if (outputDirectory != null) {
        if (_separateLayers) {
          // For separate layers, just use the directory
          _outputPath = outputDirectory;
        } else {
          // For single file, include the filename
          final fileName = _getDefaultFileName();
          _outputPath = path.join(outputDirectory, fileName);
        }
        notifyListeners();
      }
    } catch (e) {
      setError('Failed to select output path: ${e.toString()}');
    }
  }

  String _getDefaultFileName() {
    if (_selectedFile == null) {
      return 'output${_selectedExportFormat.extension}';
    }

    final baseName = path.basenameWithoutExtension(_selectedFile!.path);
    return '$baseName${_selectedExportFormat.extension}';
  }

  Future<void> convertFile() async {
    if (_selectedFile == null || _kmlData == null) {
      setError('No file selected or parsed');
      return;
    }

    try {
      clearError();
      _successMessage = null;

      setLoading();

      if (_separateLayers && _kmlData!.layersCount > 1) {
        await _convertToSeparateFiles();
      } else {
        await _convertToSingleFile();
      }

      setSuccess();
    } on AppException catch (e) {
      setError(e.message, e);
    } catch (e) {
      setError('Failed to convert file: ${e.toString()}');
    }
  }

  Future<void> _convertToSingleFile() async {
    // Determine output path
    String outputFilePath;
    if (_outputPath != null) {
      outputFilePath = _outputPath!;
    } else {
      // Default to same directory as input file
      final inputDir = path.dirname(_selectedFile!.path);
      final fileName = _getDefaultFileName();
      outputFilePath = path.join(inputDir, fileName);
    }

    // Create export options
    final exportOptions = ExportOptions(
      format: _selectedExportFormat,
      outputPath: outputFilePath,
    );

    // Export based on selected format
    switch (_selectedExportFormat) {
      case ExportFormat.csv:
        await _exportToCsv(exportOptions, outputFilePath);
        break;
      default:
        throw ConversionException(
          'Export format ${_selectedExportFormat.description} is not yet supported',
          code: 'UNSUPPORTED_FORMAT',
        );
    }

    _successMessage = 'File converted successfully!\nSaved to: $outputFilePath';
  }

  Future<void> _convertToSeparateFiles() async {
    // Determine output directory
    String outputDirectory;
    if (_outputPath != null) {
      outputDirectory = _outputPath!;
    } else {
      outputDirectory = path.dirname(_selectedFile!.path);
    }

    // Create folder for separate files
    final baseName = path.basenameWithoutExtension(_selectedFile!.path);
    final folderPath = path.join(outputDirectory, '${baseName}_layers');
    final folder = Directory(folderPath);

    if (!await folder.exists()) {
      await folder.create();
    }

    // For now, create one file per layer (this would need layer detection logic)
    // This is a simplified implementation - you'd need to enhance the KML parser
    // to properly separate layers

    final layerCount = _kmlData!.layersCount;
    final filesCreated = <String>[];

    for (int i = 1; i <= layerCount; i++) {
      final layerFileName = 'layer_$i${_selectedExportFormat.extension}';
      final layerFilePath = path.join(folderPath, layerFileName);

      // For now, just create the main file for each "layer"
      // In a full implementation, you'd filter placemarks by layer
      final exportOptions = ExportOptions(
        format: _selectedExportFormat,
        outputPath: layerFilePath,
      );

      await _exportToCsv(exportOptions, layerFilePath);
      filesCreated.add(layerFileName);
    }

    _successMessage =
        'Files converted successfully!\n'
        'Created ${filesCreated.length} files in: $folderPath\n'
        'Files: ${filesCreated.join(', ')}';
  }

  Future<void> _exportToCsv(ExportOptions options, String outputPath) async {
    // Export to CSV content with duplicate handling
    final headers = _csvExportService.buildHeadersWithDuplicates(
      _kmlData!,
      _duplicateHandling,
    );
    final csvOptions = options.copyWith(selectedFields: headers);

    final csvContent = await _csvExportService.exportToCsv(
      _kmlData!,
      csvOptions,
    );

    // Save CSV file
    await _csvExportService.saveCsvFile(csvContent, outputPath);

    // Update preview with final data
    _generatePreviewData(csvContent);
  }

  // Legacy method for backward compatibility
  Future<void> convertToCSV() async {
    await convertFile();
  }

  void _generatePreviewData(String csvContent) {
    final lines = csvContent.split('\n');
    final previewLines =
        lines.take(AppConstants.previewRowCount + 1).toList(); // +1 for header

    _previewData =
        previewLines
            .where((line) => line.trim().isNotEmpty)
            .map((line) => _parseCsvLine(line))
            .where((row) => row.isNotEmpty) // Filter out empty rows
            .toList();

    // Ensure all rows have the same number of columns as the header
    if (_previewData!.isNotEmpty) {
      final headerCount = _previewData!.first.length;
      _previewData =
          _previewData!.map((row) {
            if (row.length < headerCount) {
              // Pad with empty strings
              final paddedRow = List<String>.from(row);
              while (paddedRow.length < headerCount) {
                paddedRow.add('');
              }
              return paddedRow;
            } else if (row.length > headerCount) {
              // Trim excess columns
              return row.take(headerCount).toList();
            }
            return row;
          }).toList();
    }
  }

  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    var current = '';
    var inQuotes = false;
    var i = 0;

    while (i < line.length) {
      final char = line[i];

      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          // Escaped quote
          current += '"';
          i += 2;
        } else {
          // Toggle quote state
          inQuotes = !inQuotes;
          i++;
        }
      } else if (char == ',' && !inQuotes) {
        // Field separator
        result.add(current.trim());
        current = '';
        i++;
      } else {
        current += char;
        i++;
      }
    }

    result.add(current.trim());
    return result;
  }

  Future<FileStat?> getFileStats() async {
    if (_selectedFile == null) return null;

    try {
      return await _selectedFile!.stat();
    } catch (e) {
      return null;
    }
  }

  void clearSelection() {
    _selectedFile = null;
    _kmlData = null;
    _previewData = null;
    _successMessage = null;
    _outputPath = null;
    _duplicateHeaders = null;
    _duplicateHandling.clear();
    _separateLayers = false;
    clearError();
  }

  void clearMessages() {
    _successMessage = null;
    clearError();
  }
}
