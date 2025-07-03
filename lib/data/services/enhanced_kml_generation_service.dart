import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import '../../core/errors/app_exception.dart';
import '../../core/enums/geometry_type.dart';
import '../models/csv_data.dart';
import '../models/column_mapping.dart';
import '../models/styling_rule.dart';
import '../models/styling_options.dart';

abstract class IEnhancedKmlGenerationService {
  Future<File> generateKmlWithRules({
    required CsvData csvData,
    required ColumnMapping columnMapping,
    required EnhancedStylingOptions stylingOptions,
    required String documentName,
    required String documentDescription,
    required GeometryType geometryType,
    bool includeElevation = true,
    bool includeDescription = true,
  });

  Future<File> generateKmzWithRules({
    required CsvData csvData,
    required ColumnMapping columnMapping,
    required EnhancedStylingOptions stylingOptions,
    required String documentName,
    required String documentDescription,
    required GeometryType geometryType,
    List<File>? imageFiles,
    bool includeElevation = true,
    bool includeDescription = true,
  });
}

class EnhancedKmlGenerationService implements IEnhancedKmlGenerationService {
  @override
  Future<File> generateKmlWithRules({
    required CsvData csvData,
    required ColumnMapping columnMapping,
    required EnhancedStylingOptions stylingOptions,
    required String documentName,
    required String documentDescription,
    required GeometryType geometryType,
    bool includeElevation = true,
    bool includeDescription = true,
    List<File>? imageFiles,
    String? imageColumnName,
    Map<String, File>? imageAssociations,
  }) async {
    try {
      if (!csvData.hasValidCoordinates) {
        throw ConversionException(
          'Cannot generate KML: No valid coordinate data found',
          code: 'NO_VALID_COORDINATES',
        );
      }

      if (!columnMapping.isValid) {
        throw ConversionException(
          'Cannot generate KML: Invalid column mapping',
          code: 'INVALID_COLUMN_MAPPING',
        );
      }

      // Generate KML content with enhanced styling
      final kmlContent = _generateEnhancedKmlContent(
        csvData,
        columnMapping,
        stylingOptions,
        documentName,
        documentDescription,
        geometryType,
        includeElevation,
        includeDescription,
      );

      // Determine output path
      final outputPath = _determineOutputPath(csvData.fileName, documentName);

      // Write file
      final file = File(outputPath);
      await file.writeAsString(kmlContent, encoding: utf8);

      if (kDebugMode) {
        print('Enhanced KML file generated: $outputPath');
        print('File size: ${await file.length()} bytes');
        print('Placemarks processed: ${csvData.rows.length}');
        print('Styling rules applied: ${stylingOptions.rules.length}');
        print('Geometry type: ${geometryType.displayName}');
      }

      return file;
    } catch (e) {
      if (e is AppException) rethrow;

      throw ConversionException(
        'Failed to generate enhanced KML file: ${e.toString()}',
        code: 'ENHANCED_KML_GENERATION_ERROR',
        details: e,
      );
    }
  }

  @override
  Future<File> generateKmzWithRules({
    required CsvData csvData,
    required ColumnMapping columnMapping,
    required EnhancedStylingOptions stylingOptions,
    required String documentName,
    required String documentDescription,
    required GeometryType geometryType,
    List<File>? imageFiles,
    bool includeElevation = true,
    bool includeDescription = true,
  }) async {
    try {
      // Generate KML content
      final kmlContent = _generateEnhancedKmlContent(
        csvData,
        columnMapping,
        stylingOptions,
        documentName,
        documentDescription,
        geometryType,
        includeElevation,
        includeDescription,
      );

      // Create archive
      final archive = Archive();

      // Add KML file to archive
      final kmlFile = ArchiveFile(
        'doc.kml',
        kmlContent.length,
        kmlContent.codeUnits,
      );
      archive.addFile(kmlFile);

      // Add image files if provided
      if (imageFiles != null && imageFiles.isNotEmpty) {
        for (final imageFile in imageFiles) {
          if (await imageFile.exists()) {
            final imageBytes = await imageFile.readAsBytes();
            final imageName = path.basename(imageFile.path);
            final archiveImageFile = ArchiveFile(
              imageName,
              imageBytes.length,
              imageBytes,
            );
            archive.addFile(archiveImageFile);
          }
        }
      }

      // Create KMZ file
      final encoder = ZipEncoder();
      final kmzBytes = encoder.encode(archive);

      // Write KMZ file
      final outputPath = _determineOutputPath(
        csvData.fileName,
        documentName,
        isKmz: true,
      );
      final file = File(outputPath);
      await file.writeAsBytes(kmzBytes!);

      if (kDebugMode) {
        print('Enhanced KMZ file generated: $outputPath');
        print('Archive contains ${archive.length} files');
        print('Total size: ${await file.length()} bytes');
      }

      return file;
    } catch (e) {
      if (e is AppException) rethrow;

      throw ConversionException(
        'Failed to generate enhanced KMZ file: ${e.toString()}',
        code: 'ENHANCED_KMZ_GENERATION_ERROR',
        details: e,
      );
    }
  }

  /// Generate enhanced KML content with criteria-based styling
  String _generateEnhancedKmlContent(
    CsvData csvData,
    ColumnMapping columnMapping,
    EnhancedStylingOptions stylingOptions,
    String documentName,
    String documentDescription,
    GeometryType geometryType,
    bool includeElevation,
    bool includeDescription,
  ) {
    final buffer = StringBuffer();
    int processedCount = 0;
    int skippedCount = 0;

    // KML header
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<kml xmlns="http://www.opengis.net/kml/2.2">');
    buffer.writeln('<Document>');
    buffer.writeln('<name>${_escapeXml(documentName)}</name>');
    buffer.writeln(
      '<description>${_escapeXml(documentDescription)}</description>',
    );

    // Add enhanced styles
    _addEnhancedStyles(buffer, stylingOptions);

    // Generate geometry based on type
    switch (geometryType) {
      case GeometryType.point:
        _generateEnhancedPointPlacemarks(
          buffer,
          csvData,
          columnMapping,
          stylingOptions,
          includeElevation,
          includeDescription,
          (processed, skipped) {
            processedCount = processed;
            skippedCount = skipped;
          },
        );
        break;

      case GeometryType.lineString:
        _generateEnhancedLineStringPlacemark(
          buffer,
          csvData,
          columnMapping,
          stylingOptions,
          includeElevation,
          includeDescription,
          (processed, skipped) {
            processedCount = processed;
            skippedCount = skipped;
          },
        );
        break;

      case GeometryType.polygon:
        _generateEnhancedPolygonPlacemark(
          buffer,
          csvData,
          columnMapping,
          stylingOptions,
          includeElevation,
          includeDescription,
          (processed, skipped) {
            processedCount = processed;
            skippedCount = skipped;
          },
        );
        break;

      default:
        throw ConversionException(
          'Unsupported geometry type: ${geometryType.displayName}',
          code: 'UNSUPPORTED_GEOMETRY_TYPE',
        );
    }

    // KML footer
    buffer.writeln('</Document>');
    buffer.writeln('</kml>');

    if (kDebugMode) {
      print('Enhanced KML generation complete:');
      print('  Processed: $processedCount features');
      print('  Skipped: $skippedCount features');
      print('  Styling rules: ${stylingOptions.rules.length}');
    }

    return buffer.toString();
  }

  /// Add enhanced styles including rule-based styles
  void _addEnhancedStyles(
    StringBuffer buffer,
    EnhancedStylingOptions stylingOptions,
  ) {
    // Add default style
    buffer.writeln('<Style id="defaultStyle">');
    _writeStyleContent(buffer, stylingOptions.defaultStyle);
    buffer.writeln('</Style>');

    // Add rule-based styles
    if (stylingOptions.useRuleBasedStyling) {
      for (final rule in stylingOptions.rules) {
        if (rule.isEnabled) {
          buffer.writeln('<Style id="${rule.ruleId}">');
          _writeStyleContent(buffer, rule.style);
          buffer.writeln('</Style>');
        }
      }
    }
  }

  /// Write style content for a GeometryStyle
  void _writeStyleContent(StringBuffer buffer, GeometryStyle style) {
    // Icon style (for points)
    if (style.icon != null) {
      buffer.writeln('  <IconStyle>');
      buffer.writeln('    <color>${style.color.kmlValue}</color>');
      buffer.writeln('    <scale>1.0</scale>');
      buffer.writeln('    <Icon>');
      buffer.writeln('      <href>${style.icon!.url}</href>');
      buffer.writeln('    </Icon>');
      buffer.writeln('  </IconStyle>');
    }

    // Line style (for lines and polygon borders)
    buffer.writeln('  <LineStyle>');
    buffer.writeln('    <color>${style.color.kmlValue}</color>');
    buffer.writeln('    <width>${style.lineWidth}</width>');
    buffer.writeln('  </LineStyle>');

    // Poly style (for polygon fills)
    buffer.writeln('  <PolyStyle>');
    final polyColor =
        style.color.kmlValue.substring(0, 2) +
        (255 * style.opacity).round().toRadixString(16).padLeft(2, '0') +
        style.color.kmlValue.substring(4);
    buffer.writeln('    <color>$polyColor</color>');
    buffer.writeln('    <fill>${style.filled ? 1 : 0}</fill>');
    buffer.writeln('    <outline>${style.outlined ? 1 : 0}</outline>');
    buffer.writeln('  </PolyStyle>');

    // Label style
    buffer.writeln('  <LabelStyle>');
    buffer.writeln('    <color>ff000000</color>');
    buffer.writeln('    <scale>0.9</scale>');
    buffer.writeln('  </LabelStyle>');
  }

  /// Generate enhanced point placemarks with rule-based styling
  void _generateEnhancedPointPlacemarks(
    StringBuffer buffer,
    CsvData csvData,
    ColumnMapping columnMapping,
    EnhancedStylingOptions stylingOptions,
    bool includeElevation,
    bool includeDescription,
    Function(int processed, int skipped) onProgress,
  ) {
    int processedCount = 0;
    int skippedCount = 0;

    for (final row in csvData.rows) {
      try {
        // Extract coordinates
        final lat = _extractCoordinate(row, columnMapping.latitudeColumn);
        final lon = _extractCoordinate(row, columnMapping.longitudeColumn);

        if (lat == null || lon == null) {
          skippedCount++;
          continue;
        }

        // Extract other data
        final name = row[columnMapping.nameColumn]?.toString() ?? 'Unnamed';
        final elevation =
            includeElevation
                ? _extractCoordinate(row, columnMapping.elevationColumn)
                : null;
        final description =
            includeDescription && columnMapping.descriptionColumn != null
                ? row[columnMapping.descriptionColumn]?.toString() ?? ''
                : '';

        // Determine style based on rules
        final styleId = _determineStyleId(row, stylingOptions);

        // Generate placemark
        buffer.writeln('<Placemark>');
        buffer.writeln('  <name>${_escapeXml(name)}</name>');

        if (description.isNotEmpty) {
          buffer.writeln(
            '  <description>${_escapeXml(description)}</description>',
          );
        }

        buffer.writeln('  <styleUrl>#$styleId</styleUrl>');
        buffer.writeln('  <Point>');

        final coordinates =
            elevation != null ? '$lon,$lat,$elevation' : '$lon,$lat';
        buffer.writeln('    <coordinates>$coordinates</coordinates>');

        buffer.writeln('  </Point>');
        buffer.writeln('</Placemark>');

        processedCount++;
      } catch (e) {
        if (kDebugMode) {
          print('Error processing row $processedCount: $e');
        }
        skippedCount++;
      }
    }

    onProgress(processedCount, skippedCount);
  }

  /// Generate enhanced linestring placemark with rule-based styling
  void _generateEnhancedLineStringPlacemark(
    StringBuffer buffer,
    CsvData csvData,
    ColumnMapping columnMapping,
    EnhancedStylingOptions stylingOptions,
    bool includeElevation,
    bool includeDescription,
    Function(int processed, int skipped) onProgress,
  ) {
    int processedCount = 0;
    int skippedCount = 0;
    final coordinates = <String>[];

    // Collect all valid coordinates
    for (final row in csvData.rows) {
      try {
        final lat = _extractCoordinate(row, columnMapping.latitudeColumn);
        final lon = _extractCoordinate(row, columnMapping.longitudeColumn);

        if (lat != null && lon != null) {
          final elevation =
              includeElevation
                  ? _extractCoordinate(row, columnMapping.elevationColumn)
                  : null;

          final coord =
              elevation != null ? '$lon,$lat,$elevation' : '$lon,$lat';
          coordinates.add(coord);
          processedCount++;
        } else {
          skippedCount++;
        }
      } catch (e) {
        skippedCount++;
      }
    }

    if (coordinates.isNotEmpty) {
      // Use first row for name and description
      final firstRow = csvData.rows.first;
      final name = firstRow[columnMapping.nameColumn]?.toString() ?? 'Path';
      final description =
          includeDescription && columnMapping.descriptionColumn != null
              ? firstRow[columnMapping.descriptionColumn]?.toString() ?? ''
              : '';

      // Determine style (use first row's data for styling decision)
      final styleId = _determineStyleId(firstRow, stylingOptions);

      buffer.writeln('<Placemark>');
      buffer.writeln('  <name>${_escapeXml(name)}</name>');

      if (description.isNotEmpty) {
        buffer.writeln(
          '  <description>${_escapeXml(description)}</description>',
        );
      }

      buffer.writeln('  <styleUrl>#$styleId</styleUrl>');
      buffer.writeln('  <LineString>');
      buffer.writeln('    <coordinates>${coordinates.join(' ')}</coordinates>');
      buffer.writeln('  </LineString>');
      buffer.writeln('</Placemark>');
    }

    onProgress(processedCount, skippedCount);
  }

  /// Generate enhanced polygon placemark with rule-based styling
  void _generateEnhancedPolygonPlacemark(
    StringBuffer buffer,
    CsvData csvData,
    ColumnMapping columnMapping,
    EnhancedStylingOptions stylingOptions,
    bool includeElevation,
    bool includeDescription,
    Function(int processed, int skipped) onProgress,
  ) {
    int processedCount = 0;
    int skippedCount = 0;
    final coordinates = <String>[];

    // Collect all valid coordinates
    for (final row in csvData.rows) {
      try {
        final lat = _extractCoordinate(row, columnMapping.latitudeColumn);
        final lon = _extractCoordinate(row, columnMapping.longitudeColumn);

        if (lat != null && lon != null) {
          final elevation =
              includeElevation
                  ? _extractCoordinate(row, columnMapping.elevationColumn)
                  : null;

          final coord =
              elevation != null ? '$lon,$lat,$elevation' : '$lon,$lat';
          coordinates.add(coord);
          processedCount++;
        } else {
          skippedCount++;
        }
      } catch (e) {
        skippedCount++;
      }
    }

    if (coordinates.isNotEmpty) {
      // Ensure polygon is closed (first and last coordinates should be the same)
      if (coordinates.first != coordinates.last) {
        coordinates.add(coordinates.first);
      }

      // Use first row for name and description
      final firstRow = csvData.rows.first;
      final name = firstRow[columnMapping.nameColumn]?.toString() ?? 'Polygon';
      final description =
          includeDescription && columnMapping.descriptionColumn != null
              ? firstRow[columnMapping.descriptionColumn]?.toString() ?? ''
              : '';

      // Determine style (use first row's data for styling decision)
      final styleId = _determineStyleId(firstRow, stylingOptions);

      buffer.writeln('<Placemark>');
      buffer.writeln('  <name>${_escapeXml(name)}</name>');

      if (description.isNotEmpty) {
        buffer.writeln(
          '  <description>${_escapeXml(description)}</description>',
        );
      }

      buffer.writeln('  <styleUrl>#$styleId</styleUrl>');
      buffer.writeln('  <Polygon>');
      buffer.writeln('    <outerBoundaryIs>');
      buffer.writeln('      <LinearRing>');
      buffer.writeln(
        '        <coordinates>${coordinates.join(' ')}</coordinates>',
      );
      buffer.writeln('      </LinearRing>');
      buffer.writeln('    </outerBoundaryIs>');
      buffer.writeln('  </Polygon>');
      buffer.writeln('</Placemark>');
    }

    onProgress(processedCount, skippedCount);
  }

  /// Determine which style to use for a row based on enhanced styling rules
  String _determineStyleId(
    Map<String, dynamic> row,
    EnhancedStylingOptions stylingOptions,
  ) {
    if (!stylingOptions.useRuleBasedStyling ||
        stylingOptions.stylingColumn == null) {
      return 'defaultStyle';
    }

    final columnValue = row[stylingOptions.stylingColumn]?.toString();
    if (columnValue == null) return 'defaultStyle';

    // Get rules sorted by priority (highest first)
    final rules = stylingOptions.rulesByPriority;

    // Find first matching rule
    for (final rule in rules) {
      if (rule.isEnabled && rule.matches(columnValue)) {
        return rule.ruleId;
      }
    }

    return 'defaultStyle';
  }

  /// Extract coordinate value from row
  double? _extractCoordinate(Map<String, dynamic> row, String? columnName) {
    if (columnName == null) return null;

    final value = row[columnName];
    if (value == null) return null;

    try {
      if (value is double) return value;
      if (value is int) return value.toDouble();

      final stringValue = value.toString().trim();
      if (stringValue.isEmpty) return null;

      // Handle common coordinate formats
      final cleanValue = stringValue
          .replaceAll(
            RegExp(r'[^\d\-\+\.]'),
            '',
          ) // Remove non-numeric chars except -+.
          .replaceAll(RegExp(r'^\+'), ''); // Remove leading +

      return double.tryParse(cleanValue);
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing coordinate "$value": $e');
      }
      return null;
    }
  }

  /// Determine output path for generated files
  String _determineOutputPath(
    String originalFileName,
    String documentName, {
    bool isKmz = false,
  }) {
    final directory = Directory.systemTemp;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = isKmz ? 'kmz' : 'kml';

    // Create safe filename from document name
    final safeDocName =
        documentName
            .replaceAll(RegExp(r'[^\w\s-]'), '')
            .replaceAll(RegExp(r'\s+'), '_')
            .toLowerCase();

    final fileName = '${safeDocName}_$timestamp.$extension';
    return path.join(directory.path, fileName);
  }

  /// Escape XML special characters
  String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}

/// Extension methods for enhanced styling validation
extension EnhancedStylingValidation on EnhancedStylingOptions {
  /// Validate styling options against CSV data
  StylingValidationResult validateAgainstData(
    List<Map<String, dynamic>> csvRows,
    List<String> csvHeaders,
  ) {
    final result = StylingValidationResult();

    if (!useRuleBasedStyling || stylingColumn == null) {
      result.isValid = true;
      result.message = 'Default styling will be applied to all features';
      return result;
    }

    // Check if styling column exists in CSV
    if (!csvHeaders.contains(stylingColumn)) {
      result.isValid = false;
      result.message = 'Styling column "$stylingColumn" not found in CSV data';
      return result;
    }

    // Get all values from the styling column
    final columnValues =
        csvRows
            .map((row) => row[stylingColumn]?.toString())
            .where((value) => value != null)
            .cast<String>()
            .toList();

    if (columnValues.isEmpty) {
      result.isValid = false;
      result.message =
          'No valid values found in styling column "$stylingColumn"';
      return result;
    }

    // Validate rules
    final validation = validateRules(columnValues);
    result.matchedCount = validation.totalMatchedValues;
    result.unmatchedCount = validation.unmatchedCount;
    result.totalValues = columnValues.length;
    result.hasOverlappingRules = validation.hasOverlappingRules;
    result.conflictingValues = validation.getConflictingValues();

    // Determine overall validity
    result.isValid = rules.isNotEmpty;

    if (validation.hasUnmatchedValues) {
      result.message =
          '${validation.unmatchedCount} values will use default styling';
    } else {
      result.message = 'All values have matching styling rules';
    }

    if (validation.hasOverlappingRules) {
      result.warnings.add(
        'Some values match multiple rules - highest priority will be used',
      );
    }

    return result;
  }
}

/// Result of styling validation
class StylingValidationResult {
  bool isValid = false;
  String message = '';
  int matchedCount = 0;
  int unmatchedCount = 0;
  int totalValues = 0;
  bool hasOverlappingRules = false;
  List<String> conflictingValues = [];
  List<String> warnings = [];

  double get matchPercentage =>
      totalValues > 0 ? (matchedCount / totalValues * 100) : 0;

  bool get hasWarnings => warnings.isNotEmpty;

  String get summary {
    final parts = <String>[];

    if (isValid) {
      parts.add('Valid configuration');
      if (matchedCount > 0) {
        parts.add(
          '$matchedCount/$totalValues matched (${matchPercentage.toStringAsFixed(1)}%)',
        );
      }
    } else {
      parts.add('Invalid configuration');
    }

    if (hasWarnings) {
      parts.add('${warnings.length} warnings');
    }

    return parts.join(' • ');
  }
}
