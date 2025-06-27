import 'dart:io';
import 'package:flutter/material.dart';
import 'package:placemark_studio/core/utils/folder_file_naming_helper.dart';
import 'package:placemark_studio/data/models/bounding_box.dart';
import 'package:placemark_studio/data/models/kml_folder.dart';
import 'package:placemark_studio/data/models/placemark.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import '../../data/services/file_picker_service.dart';
import '../../data/services/unified_file_parser_service.dart'; // Changed import
import '../../data/services/csv_export_service.dart';
import '../../data/models/kml_data.dart';
import '../../data/models/export_options.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/enums/export_format.dart';
import 'base_viewmodel.dart';

class HomeViewModel extends BaseViewModel {
  final IFilePickerService _filePickerService;
  final IUnifiedFileParserService _fileParserService; // Changed type
  final ICsvExportService _csvExportService;

  HomeViewModel({
    required IFilePickerService filePickerService,
    required IUnifiedFileParserService
    kmlParserService, // Keep parameter name for compatibility
    required ICsvExportService csvExportService,
  }) : _filePickerService = filePickerService,
       _fileParserService = kmlParserService, // Assign to new field
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
  bool _useSimpleFileNaming = false;

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
  bool get useSimpleFileNaming => _useSimpleFileNaming;
  String? get selectedFileName =>
      _selectedFile != null ? path.basename(_selectedFile!.path) : null;

  List<ExportFormat> get supportedFormats =>
      ExportFormat.values.where((f) => f.isSupported).toList();

  Future<void> _updateWindowTitle([String? fileName]) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      String title = 'Placemark Studio';

      if (fileName != null) {
        title = 'Placemark Studio - KML Converter - $fileName';
      } else if (_selectedFile != null) {
        final currentFileName = path.basename(_selectedFile!.path);
        title = 'Placemark Studio - KML Converter - $currentFileName';
      }

      await windowManager.setTitle(title);
    }
  }

  Future<void> _enterFullscreenMode() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      try {
        // Option 1: True fullscreen (hides taskbar)
        // await windowManager.setFullScreen(true);

        // Option 2: Maximized window (keeps taskbar visible) - comment out line above and uncomment below
        await windowManager.maximize();

        // Update minimum size for fullscreen mode
        await windowManager.setMinimumSize(const Size(1200, 800));
      } catch (e) {
        if (kDebugMode) {
          print('Failed to enter fullscreen: $e');
        }
        // Fallback to maximize if fullscreen fails
        await windowManager.maximize();
      }
    }
  }

  Future<void> _exitFullscreenMode() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      try {
        // Check if we're currently in fullscreen or maximized
        final isMaximized = await windowManager.isMaximized();
        final isFullScreen = await windowManager.isFullScreen();

        if (isFullScreen) {
          // Exit fullscreen
          await windowManager.setFullScreen(false);
        }

        if (isMaximized) {
          // Unmaximize if maximized
          await windowManager.unmaximize();
        }

        // Only resize if we were actually in fullscreen/maximized mode
        if (isFullScreen || isMaximized) {
          // Small delay to ensure fullscreen/maximize state has changed
          await Future.delayed(const Duration(milliseconds: 100));

          // Restore original size and center
          await windowManager.setSize(const Size(800, 600));
          await windowManager.center();
        }

        // Reset minimum size
        await windowManager.setMinimumSize(const Size(800, 600));
      } catch (e) {
        if (kDebugMode) {
          print('Failed to exit fullscreen: $e');
        }
        // Fallback: just try to unmaximize
        try {
          await windowManager.unmaximize();
        } catch (e2) {
          if (kDebugMode) {
            print('Fallback unmaximize also failed: $e2');
          }
        }
      }
    }
  }

  Future<void> pickFile() async {
    try {
      clearError();
      _successMessage = null;

      setLoading();
      final file = await _filePickerService.pickKmlFile();

      if (file != null) {
        _selectedFile = file;

        // Update title and enter fullscreen
        final fileName = path.basename(file.path);
        await _updateWindowTitle(fileName);
        await _enterFullscreenMode();

        // Automatically parse the file and generate preview
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

  Future<void> handleDroppedFile(File file) async {
    try {
      clearError();
      _successMessage = null;

      // Validate file before setting it
      await _validateDroppedFile(file);

      setLoading();
      _selectedFile = file;

      // Update title and enter fullscreen
      final fileName = path.basename(file.path);
      await _updateWindowTitle(fileName);
      await _enterFullscreenMode();

      // Automatically parse the file and generate preview
      await _parseAndPreview();

      setSuccess();
    } on AppException catch (e) {
      setError(e.message, e);
    } catch (e) {
      setError('Failed to process dropped file: ${e.toString()}');
    }
  }

  Future<void> _validateDroppedFile(File file) async {
    // Check if file exists
    if (!await file.exists()) {
      throw FileProcessingException(
        'Dropped file does not exist',
        code: 'FILE_NOT_FOUND',
      );
    }

    // Check file extension
    final extension = file.path.split('.').last.toLowerCase();
    if (!AppConstants.supportedFileExtensions.contains(extension)) {
      throw FileProcessingException(
        'Unsupported file format. Supported formats: ${AppConstants.supportedFileExtensions.join(', ').toUpperCase()}',
        code: 'UNSUPPORTED_FORMAT',
      );
    }

    // Check file size
    final stat = await file.stat();
    if (stat.size > AppConstants.maxFileSizeBytes) {
      throw FileProcessingException(
        'File size exceeds maximum allowed size of ${AppConstants.maxFileSizeBytes / (1024 * 1024)}MB',
        code: 'FILE_TOO_LARGE',
      );
    }

    // Enhanced file content validation for both KML and KMZ
    try {
      if (extension == 'kml') {
        final content = await file.readAsString();
        if (!content.trim().startsWith('<?xml') || !content.contains('<kml')) {
          throw FileProcessingException(
            'Invalid KML file format',
            code: 'INVALID_KML_FORMAT',
          );
        }
      } else if (extension == 'kmz') {
        final bytes = await file.readAsBytes();

        // Check for ZIP file signature (PK)
        if (bytes.length < 4 || bytes[0] != 0x50 || bytes[1] != 0x4B) {
          throw FileProcessingException(
            'Invalid KMZ file format - not a valid ZIP archive',
            code: 'INVALID_KMZ_FORMAT',
          );
        }
      }
    } catch (e) {
      if (e is FileProcessingException) rethrow;
      throw FileProcessingException(
        'Unable to read file content',
        code: 'FILE_READ_ERROR',
      );
    }
  }

  Future<void> _parseAndPreview() async {
    if (_selectedFile == null) return;

    try {
      // Use the unified parser that handles both KML and KMZ
      _kmlData = await _fileParserService.parseFile(_selectedFile!);

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

  void setUseSimpleFileNaming(bool useSimple) {
    if (_useSimpleFileNaming != useSimple) {
      _useSimpleFileNaming = useSimple;
      notifyListeners();
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

  /*
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
    // This is a simplified implementation - need to enhance the KML parser to
    // properly separate layers

    final layerCount = _kmlData!.layersCount;
    final filesCreated = <String>[];

    for (int i = 1; i <= layerCount; i++) {
      final layerFileName = 'layer_$i${_selectedExportFormat.extension}';
      final layerFilePath = path.join(folderPath, layerFileName);

      // For now, just create the main file for each "layer"
      // In a full implementation, filter placemarks by layer
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
*/
  Future<void> _convertToSeparateFiles() async {
    if (_kmlData == null) {
      throw ConversionException('No KML data available for conversion');
    }

    // Determine output directory
    String outputDirectory;
    if (_outputPath != null) {
      outputDirectory = _outputPath!;
    } else {
      outputDirectory = path.dirname(_selectedFile!.path);
    }

    // Create folder for separate files
    final baseName = path.basenameWithoutExtension(_selectedFile!.path);
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final folderName =
        _kmlData!.hasHierarchy
            ? '${baseName}_folders_$timestamp'
            : '${baseName}_layers_$timestamp';
    final folderPath = path.join(outputDirectory, folderName);
    final folder = Directory(folderPath);

    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    final filesCreated = <String>[];
    final exportSummary = <String, int>{};

    try {
      if (_kmlData!.hasHierarchy) {
        // Handle hierarchical structure
        await _exportHierarchicalStructure(
          _kmlData!.folderStructure!,
          folderPath,
          filesCreated,
          exportSummary,
        );
      } else {
        // Handle flat structure (fallback)
        await _exportFlatStructure(folderPath, filesCreated, exportSummary);
      }

      // Generate success message with detailed info
      _successMessage = _generateExportSuccessMessage(
        folderPath,
        filesCreated,
        exportSummary,
      );
    } catch (e) {
      // Clean up folder if export failed
      if (await folder.exists() && filesCreated.isEmpty) {
        await folder.delete(recursive: true);
      }
      rethrow;
    }
  }

  Future<void> _exportHierarchicalStructure(
    KmlFolder rootFolder,
    String outputPath,
    List<String> filesCreated,
    Map<String, int> exportSummary,
  ) async {
    // Build folder counts for better naming
    final folderCounts = FolderFileNamingHelper.buildFolderCountMap(rootFolder);

    // Recursively export each folder that has placemarks
    await _exportFolderRecursively(
      rootFolder,
      outputPath,
      filesCreated,
      exportSummary,
      folderCounts,
      rootFolder, // Pass root folder reference
    );

    // Export summary statistics
    exportSummary['total_folders_processed'] = _countFoldersWithPlacemarks(
      rootFolder,
    );
    exportSummary['max_depth'] = rootFolder.getMaxDepth();
    exportSummary['total_placemarks'] = rootFolder.getTotalPlacemarkCount();
  }

  Future<void> _exportFolderRecursively(
    KmlFolder folder,
    String outputPath,
    List<String> filesCreated,
    Map<String, int> exportSummary,
    Map<String, int> folderCounts,
    KmlFolder rootFolder, {
    String currentPath = '',
  }) async {
    // Generate the proper hierarchical path for this folder
    final hierarchicalPath =
        currentPath.isEmpty
            ? folder.name
            : FolderFileNamingHelper.generatePathFromContext(
              folder,
              currentPath,
            );

    // Export this folder if it has placemarks
    if (folder.placemarks.isNotEmpty) {
      try {
        final fileName = FolderFileNamingHelper.generateFileName(
          folder,
          _selectedExportFormat.extension,
          parentPath: hierarchicalPath,
          folderCounts: folderCounts,
          useSimpleNaming: _useSimpleFileNaming, // Add this parameter
        );

        if (kDebugMode) {
          print(
            'Exporting folder: "${folder.name}" at path "$hierarchicalPath" -> "$fileName"',
          );
        }

        final filePath = path.join(outputPath, fileName);

        // Create a filtered KmlData containing only this folder's placemarks
        final filteredKmlData = _createFilteredKmlData(folder.placemarks);

        // Export this specific folder
        await _exportSpecificFolder(filteredKmlData, filePath);

        filesCreated.add(fileName);

        // Update statistics
        final key = 'depth_${folder.depth}';
        exportSummary[key] = (exportSummary[key] ?? 0) + 1;
        exportSummary['total_placemarks_exported'] =
            (exportSummary['total_placemarks_exported'] ?? 0) +
            folder.placemarks.length;
      } catch (e) {
        if (kDebugMode) {
          print('Error exporting folder "${folder.name}": $e');
          print('Folder depth: ${folder.depth}');
          print('Placemarks count: ${folder.placemarks.length}');
          print('Hierarchical path: "$hierarchicalPath"');
        }
        rethrow; // Re-throw to see the full error in the UI
      }
    }

    // Recursively process subfolders
    for (final subFolder in folder.subFolders) {
      await _exportFolderRecursively(
        subFolder,
        outputPath,
        filesCreated,
        exportSummary,
        folderCounts,
        rootFolder,
        currentPath: hierarchicalPath,
      );
    }
  }

  Future<void> _exportFlatStructure(
    String outputPath,
    List<String> filesCreated,
    Map<String, int> exportSummary,
  ) async {
    // For flat structures, split placemarks evenly across files
    final layerCount = _kmlData!.layersCount;
    final placemarks = _kmlData!.placemarks;
    final placemarksPerLayer = (placemarks.length / layerCount).ceil();

    for (int i = 0; i < layerCount; i++) {
      final startIndex = i * placemarksPerLayer;
      final endIndex = ((i + 1) * placemarksPerLayer).clamp(
        0,
        placemarks.length,
      );

      if (startIndex >= placemarks.length) break;

      final layerPlacemarks = placemarks.sublist(startIndex, endIndex);
      final fileName =
          'layer_${(i + 1).toString().padLeft(2, '0')}${_selectedExportFormat.extension}';
      final filePath = path.join(outputPath, fileName);

      try {
        final filteredKmlData = _createFilteredKmlData(layerPlacemarks);
        await _exportSpecificFolder(filteredKmlData, filePath);

        filesCreated.add(fileName);
        exportSummary['layer_${i + 1}'] = layerPlacemarks.length;
      } catch (e) {
        if (kDebugMode) {
          print('Warning: Failed to export layer ${i + 1}: $e');
        }
      }
    }

    exportSummary['total_layers'] = layerCount;
    exportSummary['total_placemarks'] = placemarks.length;
  }

  KmlData _createFilteredKmlData(List<Placemark> placemarks) {
    // Create a new KmlData with only the specified placemarks
    final allCoordinates =
        placemarks.expand((p) => p.geometry.coordinates).toList();

    final boundingBox =
        allCoordinates.isNotEmpty
            ? BoundingBox.fromCoordinates(allCoordinates)
            : _kmlData!.boundingBox;

    // Extract available fields from these placemarks
    final fields = <String>{
      'name',
      'description',
      'longitude',
      'latitude',
      'elevation',
    };
    for (final placemark in placemarks) {
      fields.addAll(placemark.extendedData.keys);
      // Add fields from description tables if needed
      // This could be enhanced to parse description tables
    }

    return _kmlData!.copyWith(
      placemarks: placemarks,
      boundingBox: boundingBox,
      availableFields: fields,
    );
  }

  Future<void> _exportSpecificFolder(
    KmlData filteredData,
    String filePath,
  ) async {
    // Temporarily swap the current KmlData
    final originalKmlData = _kmlData;
    _kmlData = filteredData;

    try {
      // Create export options
      final exportOptions = ExportOptions(
        format: _selectedExportFormat,
        outputPath: filePath,
      );

      // Export using the existing method
      await _exportToCsv(exportOptions, filePath);
    } finally {
      // Restore original KmlData
      _kmlData = originalKmlData;
    }
  }

  int _countFoldersWithPlacemarks(KmlFolder folder) {
    int count = folder.placemarks.isNotEmpty ? 1 : 0;
    for (final subFolder in folder.subFolders) {
      count += _countFoldersWithPlacemarks(subFolder);
    }
    return count;
  }

  String _generateExportSuccessMessage(
    String folderPath,
    List<String> filesCreated,
    Map<String, int> exportSummary,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('Files converted successfully!');
    buffer.writeln('Output folder: ${path.basename(folderPath)}');
    buffer.writeln('');

    if (_kmlData!.hasHierarchy) {
      buffer.writeln('📁 Hierarchical Export Summary:');
      buffer.writeln('• Files created: ${filesCreated.length}');
      buffer.writeln(
        '• Folders processed: ${exportSummary['total_folders_processed'] ?? 0}',
      );
      buffer.writeln('• Max depth: ${exportSummary['max_depth'] ?? 0} levels');
      buffer.writeln(
        '• Total placemarks: ${exportSummary['total_placemarks_exported'] ?? 0}',
      );

      // Show depth distribution
      final depthStats = <String>[];
      for (int i = 0; i <= (exportSummary['max_depth'] ?? 0); i++) {
        final count = exportSummary['depth_$i'] ?? 0;
        if (count > 0) {
          depthStats.add('L$i: $count files');
        }
      }
      if (depthStats.isNotEmpty) {
        buffer.writeln('• By depth: ${depthStats.join(', ')}');
      }
    } else {
      buffer.writeln('📄 Layer Export Summary:');
      buffer.writeln('• Files created: ${filesCreated.length}');
      buffer.writeln('• Total layers: ${exportSummary['total_layers'] ?? 0}');
      buffer.writeln(
        '• Total placemarks: ${exportSummary['total_placemarks'] ?? 0}',
      );
    }

    buffer.writeln('');
    if (filesCreated.length <= 5) {
      buffer.writeln('Files: ${filesCreated.join(', ')}');
    } else {
      buffer.writeln(
        'Sample files: ${filesCreated.take(3).join(', ')}, ... and ${filesCreated.length - 3} more',
      );
    }

    return buffer.toString();
  }

  Future<void> _exportToCsv(ExportOptions options, String outputPath) async {
    // Use the current KmlData (which might be filtered for a specific folder)
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

    // Don't update preview for individual files in batch export
    if (!outputPath.contains('_layers/')) {
      _generatePreviewData(csvContent);
    }
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
    _useSimpleFileNaming = false;
    clearError();

    // Exit fullscreen and reset title asynchronously without waiting
    _exitFullscreenMode()
        .then((_) {
          // Update title after exiting fullscreen
          _updateWindowTitle();
        })
        .catchError((e) {
          if (kDebugMode) {
            print('Error during window state reset: $e');
          }
          // Still update the title even if window operations fail
          _updateWindowTitle();
        });

    // Notify listeners immediately to update the UI
    notifyListeners();
  }

  void clearMessages() {
    _successMessage = null;
    clearError();
    notifyListeners(); // Add this line to update the UI
  }
}
