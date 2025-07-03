import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import '../../core/errors/app_exception.dart';
import '../../core/enums/geometry_type.dart';
import '../models/csv_data.dart';
import '../models/column_mapping.dart';
import '../models/kml_generation_options.dart';
import '../models/styling_options.dart';
import '../models/styling_rule.dart';

abstract class IKmlGenerationService {
  Future<File> generateKml({
    required CsvData csvData,
    required ColumnMapping columnMapping,
    required KmlGenerationOptions options,
  });

  Future<File> generateKmz({
    required CsvData csvData,
    required ColumnMapping columnMapping,
    required KmlGenerationOptions options,
    List<File>? imageFiles,
  });

  Future<File> generateKmlWithEnhancedStyling({
    required CsvData csvData,
    required ColumnMapping columnMapping,
    required KmlGenerationOptions options,
    EnhancedStylingOptions? enhancedStyling,
  });

  Future<File> generateKmzWithEnhancedStyling({
    required CsvData csvData,
    required ColumnMapping columnMapping,
    required KmlGenerationOptions options,
    EnhancedStylingOptions? enhancedStyling,
    List<File>? imageFiles,
    String? imageColumnName,
    Map<String, File>? imageAssociations,
  });
}

class KmlGenerationService implements IKmlGenerationService {
  @override
  Future<File> generateKml({
    required CsvData csvData,
    required ColumnMapping columnMapping,
    required KmlGenerationOptions options,
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

      // Generate KML content
      final kmlContent = _generateKmlContent(csvData, columnMapping, options);

      // Determine output path
      final outputPath = _determineOutputPath(csvData.fileName, options);

      // Write file
      final file = File(outputPath);
      await file.writeAsString(kmlContent, encoding: utf8);

      if (kDebugMode) {
        print('KML file generated: $outputPath');
        print('File size: ${await file.length()} bytes');
        print('Placemarks processed: ${csvData.rows.length}');
        print('Geometry type: ${options.geometryType.displayName}');
      }

      return file;
    } catch (e) {
      if (e is AppException) rethrow;

      throw ConversionException(
        'Failed to generate KML file: ${e.toString()}',
        code: 'KML_GENERATION_ERROR',
        details: e,
      );
    }
  }

  @override
  Future<File> generateKmz({
    required CsvData csvData,
    required ColumnMapping columnMapping,
    required KmlGenerationOptions options,
    List<File>? imageFiles,
  }) async {
    try {
      // Generate KML content
      final kmlContent = _generateKmlContent(csvData, columnMapping, options);

      // Create archive
      final archive = Archive();

      // Add KML file to archive
      final kmlBytes = utf8.encode(kmlContent);
      archive.addFile(ArchiveFile('doc.kml', kmlBytes.length, kmlBytes));

      // Add image files if provided
      if (imageFiles != null && imageFiles.isNotEmpty) {
        for (final imageFile in imageFiles) {
          if (await imageFile.exists()) {
            final imageBytes = await imageFile.readAsBytes();
            final imageName = path.basename(imageFile.path);
            archive.addFile(
              ArchiveFile(imageName, imageBytes.length, imageBytes),
            );
          }
        }
      }

      // Compress archive
      final zipData = ZipEncoder().encode(archive);

      if (zipData == null) {
        throw ConversionException(
          'Failed to create KMZ archive',
          code: 'KMZ_COMPRESSION_ERROR',
        );
      }

      // Determine output path
      final outputPath = _determineOutputPath(
        csvData.fileName,
        options,
        isKmz: true,
      );

      // Write KMZ file
      final file = File(outputPath);
      await file.writeAsBytes(zipData);

      if (kDebugMode) {
        print('KMZ file generated: $outputPath');
        print('File size: ${await file.length()} bytes');
        print('Archive contains ${archive.files.length} files');
      }

      return file;
    } catch (e) {
      if (e is AppException) rethrow;

      throw ConversionException(
        'Failed to generate KMZ file: ${e.toString()}',
        code: 'KMZ_GENERATION_ERROR',
        details: e,
      );
    }
  }

  @override
  Future<File> generateKmlWithEnhancedStyling({
    required CsvData csvData,
    required ColumnMapping columnMapping,
    required KmlGenerationOptions options,
    EnhancedStylingOptions? enhancedStyling,
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

      // Use your existing _generateKmlContent but enhanced
      final kmlContent = _generateKmlContentEnhanced(
        csvData,
        columnMapping,
        options,
        enhancedStyling: enhancedStyling,
      );

      // Use your existing _determineOutputPath
      final outputPath = _determineOutputPath(csvData.fileName, options);
      final file = File(outputPath);
      await file.writeAsString(kmlContent, encoding: utf8);

      if (kDebugMode) {
        print('Enhanced KML file generated: $outputPath');
        print('File size: ${await file.length()} bytes');
      }

      return file;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ConversionException(
        'Failed to generate KML file: ${e.toString()}',
        code: 'KML_GENERATION_ERROR',
        details: e,
      );
    }
  }

  @override
  Future<File> generateKmzWithEnhancedStyling({
    required CsvData csvData,
    required ColumnMapping columnMapping,
    required KmlGenerationOptions options,
    EnhancedStylingOptions? enhancedStyling,
    List<File>? imageFiles,
    String? imageColumnName,
    Map<String, File>? imageAssociations,
  }) async {
    try {
      if (!csvData.hasValidCoordinates) {
        throw ConversionException(
          'Cannot generate KMZ: No valid coordinate data found',
          code: 'NO_VALID_COORDINATES',
        );
      }

      if (!columnMapping.isValid) {
        throw ConversionException(
          'Cannot generate KMZ: Invalid column mapping',
          code: 'INVALID_COLUMN_MAPPING',
        );
      }

      // Use enhanced KML generation with image support
      final kmlContent = _generateKmlContentEnhanced(
        csvData,
        columnMapping,
        options,
        enhancedStyling: enhancedStyling,
        imageColumnName: imageColumnName,
        imageAssociations: imageAssociations,
      );

      // Create KMZ archive (similar to your existing logic)
      final archive = Archive();

      // Add KML file
      final kmlBytes = utf8.encode(kmlContent);
      archive.addFile(ArchiveFile('doc.kml', kmlBytes.length, kmlBytes));

      // Add image files if provided
      final addedImages = <String>{};
      if (imageFiles != null && imageFiles.isNotEmpty) {
        for (final imageFile in imageFiles) {
          if (await imageFile.exists()) {
            final imageName = path.basename(imageFile.path);

            // Avoid duplicate images
            if (!addedImages.contains(imageName)) {
              final imageBytes = await imageFile.readAsBytes();
              archive.addFile(
                ArchiveFile(imageName, imageBytes.length, imageBytes),
              );
              addedImages.add(imageName);

              if (kDebugMode) {
                print(
                  'Added image to KMZ: $imageName (${imageBytes.length} bytes)',
                );
              }
            }
          }
        }
      }

      // Create KMZ file
      final zipData = ZipEncoder().encode(archive);
      if (zipData == null) {
        throw ConversionException(
          'Failed to create KMZ archive',
          code: 'KMZ_COMPRESSION_ERROR',
        );
      }

      // Use your existing _determineOutputPath
      final outputPath = _determineOutputPath(
        csvData.fileName,
        options,
        isKmz: true,
      );
      final file = File(outputPath);
      await file.writeAsBytes(zipData);

      if (kDebugMode) {
        print('Enhanced KMZ file generated: $outputPath');
        print('Archive contains ${archive.files.length} files');
        print('File size: ${await file.length()} bytes');
      }

      return file;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ConversionException(
        'Failed to generate KMZ file: ${e.toString()}',
        code: 'KMZ_GENERATION_ERROR',
        details: e,
      );
    }
  }

  /// Generate KML content from CSV data
  String _generateKmlContent(
    CsvData csvData,
    ColumnMapping columnMapping,
    KmlGenerationOptions options,
  ) {
    final buffer = StringBuffer();
    int processedCount = 0;
    int skippedCount = 0;

    // KML header
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<kml xmlns="http://www.opengis.net/kml/2.2">');
    buffer.writeln('<Document>');
    buffer.writeln('<name>${_escapeXml(options.documentName)}</name>');
    buffer.writeln(
      '<description>${_escapeXml(options.documentDescription)}</description>',
    );

    // Add styles
    _addStyles(buffer, options);

    // Generate geometry based on type
    switch (options.geometryType) {
      case GeometryType.point:
        _generatePointPlacemarks(buffer, csvData, columnMapping, options, (
          processed,
          skipped,
        ) {
          processedCount = processed;
          skippedCount = skipped;
        });
        break;

      case GeometryType.lineString:
        _generateLineStringPlacemark(buffer, csvData, columnMapping, options, (
          processed,
          skipped,
        ) {
          processedCount = processed;
          skippedCount = skipped;
        });
        break;

      case GeometryType.polygon:
        _generatePolygonPlacemark(buffer, csvData, columnMapping, options, (
          processed,
          skipped,
        ) {
          processedCount = processed;
          skippedCount = skipped;
        });
        break;

      default:
        // Fallback to points for unsupported geometry types
        _generatePointPlacemarks(buffer, csvData, columnMapping, options, (
          processed,
          skipped,
        ) {
          processedCount = processed;
          skippedCount = skipped;
        });
        break;
    }

    // KML footer
    buffer.writeln('</Document>');
    buffer.writeln('</kml>');

    if (kDebugMode) {
      print('KML generation completed:');
      print('  Geometry type: ${options.geometryType.displayName}');
      print('  Processed: $processedCount features');
      print('  Skipped: $skippedCount rows');
      print(
        '  Success rate: ${(processedCount / csvData.rows.length * 100).toStringAsFixed(1)}%',
      );
    }

    return buffer.toString();
  }

  String _generateKmlContentEnhanced(
    CsvData csvData,
    ColumnMapping columnMapping,
    KmlGenerationOptions options, {
    EnhancedStylingOptions? enhancedStyling,
    String? imageColumnName,
    Map<String, File>? imageAssociations,
  }) {
    final buffer = StringBuffer();
    int processedCount = 0;
    int skippedCount = 0;

    // KML header (same as your existing)
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<kml xmlns="http://www.opengis.net/kml/2.2">');
    buffer.writeln('<Document>');
    buffer.writeln('<name>${_escapeXml(options.documentName)}</name>');
    buffer.writeln(
      '<description>${_escapeXml(options.documentDescription)}</description>',
    );

    // Add styles (enhanced or use your existing)
    if (enhancedStyling != null) {
      _addEnhancedStyles(buffer, enhancedStyling);
    } else {
      _addStyles(buffer, options); // Your existing method
    }

    // Get image column index if specified
    int? imageColumnIndex;
    if (imageColumnName != null) {
      imageColumnIndex = csvData.headers.indexOf(imageColumnName);
    }

    // Generate geometry (enhanced versions of your existing logic)
    switch (options.geometryType) {
      case GeometryType.point:
        _generatePointPlacemarksEnhanced(
          buffer,
          csvData,
          columnMapping,
          options,
          enhancedStyling: enhancedStyling,
          imageColumnIndex: imageColumnIndex,
          imageAssociations: imageAssociations,
          onProgress: (processed, skipped) {
            processedCount = processed;
            skippedCount = skipped;
          },
        );
        break;

      case GeometryType.lineString:
        _generateLineStringPlacemarkEnhanced(
          buffer,
          csvData,
          columnMapping,
          options,
          enhancedStyling: enhancedStyling,
          imageColumnIndex: imageColumnIndex,
          imageAssociations: imageAssociations,
          onProgress: (processed, skipped) {
            processedCount = processed;
            skippedCount = skipped;
          },
        );
        break;

      case GeometryType.polygon:
        _generatePolygonPlacemarkEnhanced(
          buffer,
          csvData,
          columnMapping,
          options,
          enhancedStyling: enhancedStyling,
          imageColumnIndex: imageColumnIndex,
          imageAssociations: imageAssociations,
          onProgress: (processed, skipped) {
            processedCount = processed;
            skippedCount = skipped;
          },
        );
        break;

      default:
        throw ConversionException(
          'Unsupported geometry type: ${options.geometryType.displayName}',
          code: 'UNSUPPORTED_GEOMETRY_TYPE',
        );
    }

    // KML footer (same as your existing)
    buffer.writeln('</Document>');
    buffer.writeln('</kml>');

    if (kDebugMode) {
      print('Enhanced KML generation complete:');
      print('  Processed: $processedCount features');
      print('  Skipped: $skippedCount features');
      if (enhancedStyling != null) {
        print('  Enhanced styling rules: ${enhancedStyling.rules.length}');
      }
    }

    return buffer.toString();
  }

  void _generatePointPlacemarksEnhanced(
    StringBuffer buffer,
    CsvData csvData,
    ColumnMapping columnMapping,
    KmlGenerationOptions options, {
    EnhancedStylingOptions? enhancedStyling,
    int? imageColumnIndex,
    Map<String, File>? imageAssociations,
    required Function(int, int) onProgress,
  }) {
    int processed = 0;
    int skipped = 0;

    for (int i = 0; i < csvData.rows.length; i++) {
      final row = csvData.rows[i];

      // Convert to Map (same as your existing logic)
      final rowMap = <String, dynamic>{};
      for (int j = 0; j < csvData.headers.length && j < row.length; j++) {
        rowMap[csvData.headers[j]] = row[j];
      }

      // Use your existing coordinate parsing
      final lat = _parseCoordinate(rowMap[columnMapping.latitudeColumn]);
      final lon = _parseCoordinate(rowMap[columnMapping.longitudeColumn]);

      if (lat == null || lon == null) {
        skipped++;
        continue;
      }

      // Extract data (same as your existing logic)
      final name =
          rowMap[columnMapping.nameColumn]?.toString() ?? 'Point ${i + 1}';
      final elevation = _extractElevation(
        rowMap,
        columnMapping,
        options,
      ); // Your existing method

      // NEW: Get image reference if available
      String? imageReference;
      if (imageColumnIndex != null &&
          row.length > imageColumnIndex &&
          imageAssociations != null) {
        final imageValue = row[imageColumnIndex]?.toString()?.trim() ?? '';
        if (imageValue.isNotEmpty &&
            imageAssociations.containsKey(imageValue)) {
          imageReference = path.basename(imageAssociations[imageValue]!.path);
        }
      }

      // Determine style (enhanced or use your existing)
      final styleId =
          enhancedStyling != null
              ? _determineEnhancedStyleId(rowMap, enhancedStyling)
              : _determineStyleId(rowMap, options); // Your existing method

      // Generate placemark (enhanced description)
      buffer.writeln('<Placemark>');
      buffer.writeln('<name>${_escapeXml(name)}</name>');

      // NEW: Enhanced description with image
      final description = _generateDescriptionEnhanced(
        rowMap,
        columnMapping,
        options,
        imageReference: imageReference,
      );

      if (description.isNotEmpty) {
        buffer.writeln('<description><![CDATA[$description]]></description>');
      }

      if (styleId != null) {
        buffer.writeln('<styleUrl>#$styleId</styleUrl>');
      }

      buffer.writeln('<Point>');
      final coordinates =
          elevation != null ? '$lon,$lat,$elevation' : '$lon,$lat';
      buffer.writeln('<coordinates>$coordinates</coordinates>');
      buffer.writeln('</Point>');
      buffer.writeln('</Placemark>');

      processed++;
    }

    onProgress(processed, skipped);
  }

  // ADD THIS NEW HELPER METHOD:
  void _generateLineStringPlacemarkEnhanced(
    StringBuffer buffer,
    CsvData csvData,
    ColumnMapping columnMapping,
    KmlGenerationOptions options, {
    EnhancedStylingOptions? enhancedStyling,
    int? imageColumnIndex,
    Map<String, File>? imageAssociations,
    required Function(int, int) onProgress,
  }) {
    int processed = 0;
    int skipped = 0;
    final coordinates = <String>[];
    String? lineImageReference;

    // Use your existing coordinate collection logic, but add image detection
    for (int i = 0; i < csvData.rows.length; i++) {
      final row = csvData.rows[i];
      final rowMap = <String, dynamic>{};
      for (int j = 0; j < csvData.headers.length && j < row.length; j++) {
        rowMap[csvData.headers[j]] = row[j];
      }

      final lat = _parseCoordinate(
        rowMap[columnMapping.latitudeColumn],
      ); // Your existing method
      final lon = _parseCoordinate(
        rowMap[columnMapping.longitudeColumn],
      ); // Your existing method

      if (lat != null && lon != null) {
        final elevation = _extractElevation(
          rowMap,
          columnMapping,
          options,
        ); // Your existing method
        final coord = elevation != null ? '$lon,$lat,$elevation' : '$lon,$lat';
        coordinates.add(coord);
        processed++;

        // NEW: Get first available image for the line
        if (lineImageReference == null &&
            imageColumnIndex != null &&
            row.length > imageColumnIndex &&
            imageAssociations != null) {
          final imageValue = row[imageColumnIndex]?.toString()?.trim() ?? '';
          if (imageValue.isNotEmpty &&
              imageAssociations.containsKey(imageValue)) {
            lineImageReference = path.basename(
              imageAssociations[imageValue]!.path,
            );
          }
        }
      } else {
        skipped++;
      }
    }

    if (coordinates.isNotEmpty) {
      // Use your existing placemark generation logic
      final firstRowMap = <String, dynamic>{};
      final firstRow = csvData.rows.first;
      for (int j = 0; j < csvData.headers.length && j < firstRow.length; j++) {
        firstRowMap[csvData.headers[j]] = firstRow[j];
      }

      final name = firstRowMap[columnMapping.nameColumn]?.toString() ?? 'Path';
      final styleId =
          enhancedStyling != null
              ? _determineEnhancedStyleId(firstRowMap, enhancedStyling)
              : _determineStyleId(firstRowMap, options); // Your existing method

      buffer.writeln('<Placemark>');
      buffer.writeln('<name>${_escapeXml(name)}</name>');

      // NEW: Enhanced description with image
      final description = _generateLineDescriptionEnhanced(
        processed,
        imageReference: lineImageReference,
      );

      if (description.isNotEmpty) {
        buffer.writeln('<description><![CDATA[$description]]></description>');
      }

      if (styleId != null) {
        buffer.writeln('<styleUrl>#$styleId</styleUrl>');
      }

      buffer.writeln('<LineString>');
      buffer.writeln('<coordinates>${coordinates.join(' ')}</coordinates>');
      buffer.writeln('</LineString>');
      buffer.writeln('</Placemark>');
    }

    onProgress(processed, skipped);
  }

  // ADD THIS NEW HELPER METHOD:
  void _generatePolygonPlacemarkEnhanced(
    StringBuffer buffer,
    CsvData csvData,
    ColumnMapping columnMapping,
    KmlGenerationOptions options, {
    EnhancedStylingOptions? enhancedStyling,
    int? imageColumnIndex,
    Map<String, File>? imageAssociations,
    required Function(int, int) onProgress,
  }) {
    // Similar to _generateLineStringPlacemarkEnhanced but for polygons
    // Use your existing polygon generation logic + add image support
    int processed = 0;
    int skipped = 0;
    final coordinates = <String>[];
    String? polygonImageReference;

    // Collect coordinates (same as your existing logic)
    for (int i = 0; i < csvData.rows.length; i++) {
      final row = csvData.rows[i];
      final rowMap = <String, dynamic>{};
      for (int j = 0; j < csvData.headers.length && j < row.length; j++) {
        rowMap[csvData.headers[j]] = row[j];
      }

      final lat = _parseCoordinate(rowMap[columnMapping.latitudeColumn]);
      final lon = _parseCoordinate(rowMap[columnMapping.longitudeColumn]);

      if (lat != null && lon != null) {
        final elevation = _extractElevation(rowMap, columnMapping, options);
        final coord = elevation != null ? '$lon,$lat,$elevation' : '$lon,$lat';
        coordinates.add(coord);
        processed++;

        // NEW: Get first available image for the polygon
        if (polygonImageReference == null &&
            imageColumnIndex != null &&
            row.length > imageColumnIndex &&
            imageAssociations != null) {
          final imageValue = row[imageColumnIndex]?.toString()?.trim() ?? '';
          if (imageValue.isNotEmpty &&
              imageAssociations.containsKey(imageValue)) {
            polygonImageReference = path.basename(
              imageAssociations[imageValue]!.path,
            );
          }
        }
      } else {
        skipped++;
      }
    }

    if (coordinates.length >= 3) {
      // Ensure polygon is closed (same as your existing logic)
      if (coordinates.first != coordinates.last) {
        coordinates.add(coordinates.first);
      }

      // Generate polygon placemark
      final firstRowMap = <String, dynamic>{};
      final firstRow = csvData.rows.first;
      for (int j = 0; j < csvData.headers.length && j < firstRow.length; j++) {
        firstRowMap[csvData.headers[j]] = firstRow[j];
      }

      final name =
          firstRowMap[columnMapping.nameColumn]?.toString() ?? 'Polygon';
      final styleId =
          enhancedStyling != null
              ? _determineEnhancedStyleId(firstRowMap, enhancedStyling)
              : _determineStyleId(firstRowMap, options);

      buffer.writeln('<Placemark>');
      buffer.writeln('<name>${_escapeXml(name)}</name>');

      // NEW: Enhanced description with image
      final description = _generatePolygonDescriptionEnhanced(
        processed,
        imageReference: polygonImageReference,
      );

      if (description.isNotEmpty) {
        buffer.writeln('<description><![CDATA[$description]]></description>');
      }

      if (styleId != null) {
        buffer.writeln('<styleUrl>#$styleId</styleUrl>');
      }

      buffer.writeln('<Polygon>');
      buffer.writeln('<outerBoundaryIs>');
      buffer.writeln('<LinearRing>');
      buffer.writeln('<coordinates>${coordinates.join(' ')}</coordinates>');
      buffer.writeln('</LinearRing>');
      buffer.writeln('</outerBoundaryIs>');
      buffer.writeln('</Polygon>');
      buffer.writeln('</Placemark>');
    }

    onProgress(processed, skipped);
  }

  // ADD THIS NEW HELPER METHOD:
  String? _determineEnhancedStyleId(
    Map<String, dynamic> row,
    EnhancedStylingOptions enhancedStyling,
  ) {
    if (!enhancedStyling.useRuleBasedStyling ||
        enhancedStyling.stylingColumn == null) {
      return 'defaultStyle';
    }

    final columnValue = row[enhancedStyling.stylingColumn]?.toString();
    if (columnValue == null) return 'defaultStyle';

    // Find first matching rule
    for (final rule in enhancedStyling.rulesByPriority) {
      if (rule.isEnabled && rule.matches(columnValue)) {
        return rule.ruleId;
      }
    }

    return 'defaultStyle';
  }

  // ADD THIS NEW HELPER METHOD:
  void _addEnhancedStyles(
    StringBuffer buffer,
    EnhancedStylingOptions enhancedStyling,
  ) {
    // Add default style
    buffer.writeln('<Style id="defaultStyle">');
    _writeEnhancedStyleContent(buffer, enhancedStyling.defaultStyle);
    buffer.writeln('</Style>');

    // Add rule-based styles
    if (enhancedStyling.useRuleBasedStyling) {
      for (final rule in enhancedStyling.rules) {
        if (rule.isEnabled) {
          buffer.writeln('<Style id="${rule.ruleId}">');
          _writeEnhancedStyleContent(buffer, rule.style);
          buffer.writeln('</Style>');
        }
      }
    }
  }

  // ADD THIS NEW HELPER METHOD:
  void _writeEnhancedStyleContent(StringBuffer buffer, GeometryStyle style) {
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

    // Line style
    buffer.writeln('  <LineStyle>');
    buffer.writeln('    <color>${style.color.kmlValue}</color>');
    buffer.writeln('    <width>${style.lineWidth}</width>');
    buffer.writeln('  </LineStyle>');

    // Poly style
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

  // ADD THIS NEW HELPER METHOD:
  String _generateDescriptionEnhanced(
    Map<String, dynamic> row,
    ColumnMapping columnMapping,
    KmlGenerationOptions options, {
    String? imageReference,
  }) {
    final buffer = StringBuffer();

    // NEW: Add image if available
    if (imageReference != null) {
      buffer.writeln('<div style="text-align: center; margin-bottom: 10px;">');
      buffer.writeln(
        '<img src="$imageReference" style="max-width: 300px; max-height: 200px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);" alt="Location Image"/>',
      );
      buffer.writeln('</div>');
    }

    // Use your existing description generation logic
    final originalDescription = _generateDescription(
      row,
      columnMapping,
      options,
    );
    if (originalDescription.isNotEmpty) {
      buffer.writeln(originalDescription);
    }

    return buffer.toString();
  }

  // ADD THIS NEW HELPER METHOD:
  String _generateLineDescriptionEnhanced(
    int pointCount, {
    String? imageReference,
  }) {
    final buffer = StringBuffer();

    if (imageReference != null) {
      buffer.writeln('<div style="text-align: center; margin-bottom: 10px;">');
      buffer.writeln(
        '<img src="$imageReference" style="max-width: 300px; max-height: 200px; border-radius: 8px;" alt="Path Image"/>',
      );
      buffer.writeln('</div>');
    }

    buffer.writeln('<h4>Path Information</h4>');
    buffer.writeln('<p><strong>Total Points:</strong> $pointCount</p>');
    buffer.writeln(
      '<p><strong>Generated:</strong> ${DateTime.now().toString().split('.')[0]}</p>',
    );

    return buffer.toString();
  }

  // ADD THIS NEW HELPER METHOD:
  String _generatePolygonDescriptionEnhanced(
    int pointCount, {
    String? imageReference,
  }) {
    final buffer = StringBuffer();

    if (imageReference != null) {
      buffer.writeln('<div style="text-align: center; margin-bottom: 10px;">');
      buffer.writeln(
        '<img src="$imageReference" style="max-width: 300px; max-height: 200px; border-radius: 8px;" alt="Area Image"/>',
      );
      buffer.writeln('</div>');
    }

    buffer.writeln('<h4>Area Information</h4>');
    buffer.writeln('<p><strong>Boundary Points:</strong> $pointCount</p>');
    buffer.writeln(
      '<p><strong>Generated:</strong> ${DateTime.now().toString().split('.')[0]}</p>',
    );

    return buffer.toString();
  }

  /*
  /// Add styles including enhanced default styling
  void _addStylesWithDefaults(
    StringBuffer buffer,
    EnhancedStylingOptions stylingOptions,
  ) {
    // Default style with user preferences
    final defaultStyle = stylingOptions.defaultStyle;

    buffer.writeln('<Style id="defaultStyle">');
    buffer.writeln('  <IconStyle>');
    buffer.writeln('    <color>${defaultStyle.color.kmlValue}</color>');
    buffer.writeln('    <scale>${defaultStyle.scale}</scale>');
    buffer.writeln('    <Icon>');
    buffer.writeln(
      '      <href>${defaultStyle.icon?.url ?? KmlIcon.pushpin.url}</href>',
    );
    buffer.writeln('    </Icon>');
    buffer.writeln('  </IconStyle>');
    buffer.writeln('  <LabelStyle>');
    buffer.writeln('    <color>${defaultStyle.labelColor.kmlValue}</color>');
    buffer.writeln('    <scale>${defaultStyle.labelScale}</scale>');
    buffer.writeln('  </LabelStyle>');
    buffer.writeln('</Style>');

    // Add rule-based styles
    for (final rule in stylingOptions.rules.where((r) => r.isEnabled)) {
      buffer.writeln('<Style id="${rule.ruleId}">');
      buffer.writeln('  <IconStyle>');
      buffer.writeln('    <color>${rule.style.color.kmlValue}</color>');
      buffer.writeln('    <scale>${rule.style.scale}</scale>');
      buffer.writeln('    <Icon>');
      buffer.writeln(
        '      <href>${rule.style.icon?.url ?? KmlIcon.pushpin.url}</href>',
      );
      buffer.writeln('    </Icon>');
      buffer.writeln('  </IconStyle>');
      buffer.writeln('  <LabelStyle>');
      buffer.writeln('    <color>${rule.style.labelColor.kmlValue}</color>');
      buffer.writeln('    <scale>${rule.style.labelScale}</scale>');
      buffer.writeln('  </LabelStyle>');
      buffer.writeln('</Style>');
    }
  }
*/
  /// Generate individual point placemarks from CSV rows
  void _generatePointPlacemarks(
    StringBuffer buffer,
    CsvData csvData,
    ColumnMapping columnMapping,
    KmlGenerationOptions options,
    Function(int processed, int skipped) onStats,
  ) {
    int processedCount = 0;
    int skippedCount = 0;

    for (int i = 0; i < csvData.rows.length; i++) {
      final row = csvData.rows[i];

      try {
        final placemark = _createPointPlacemark(row, columnMapping, options, i);
        if (placemark != null) {
          buffer.writeln(placemark);
          processedCount++;
        } else {
          skippedCount++;
        }
      } catch (e) {
        skippedCount++;
        if (kDebugMode) {
          print('Warning: Skipping row ${i + 1}: ${e.toString()}');
        }
      }
    }

    onStats(processedCount, skippedCount);
  }

  /// Generate single LineString placemark from all valid CSV coordinates
  void _generateLineStringPlacemark(
    StringBuffer buffer,
    CsvData csvData,
    ColumnMapping columnMapping,
    KmlGenerationOptions options,
    Function(int processed, int skipped) onStats,
  ) {
    final coordinates = <String>[];
    int processedCount = 0;
    int skippedCount = 0;

    // Collect all valid coordinates
    for (int i = 0; i < csvData.rows.length; i++) {
      final row = csvData.rows[i];

      try {
        final latValue = row[columnMapping.latitudeColumn];
        final lonValue = row[columnMapping.longitudeColumn];

        if (latValue == null || lonValue == null) {
          skippedCount++;
          continue;
        }

        final latitude = _parseCoordinate(latValue);
        final longitude = _parseCoordinate(lonValue);

        if (latitude == null || longitude == null) {
          skippedCount++;
          continue;
        }

        if (latitude < -90 ||
            latitude > 90 ||
            longitude < -180 ||
            longitude > 180) {
          skippedCount++;
          continue;
        }

        final elevation = _extractElevation(row, columnMapping, options);
        final coord =
            elevation != null && elevation != 0.0
                ? '$longitude,$latitude,$elevation'
                : '$longitude,$latitude';

        coordinates.add(coord);
        processedCount++;
      } catch (e) {
        skippedCount++;
      }
    }

    if (coordinates.length < 2) {
      if (kDebugMode) {
        print(
          'Warning: LineString requires at least 2 coordinates. Found: ${coordinates.length}',
        );
      }
      onStats(0, csvData.rows.length);
      return;
    }

    // Create LineString placemark
    buffer.writeln('  <Placemark>');
    buffer.writeln('    <name>${_escapeXml(options.documentName)} Path</name>');
    buffer.writeln(
      '    <description>Generated path from ${coordinates.length} points</description>',
    );

    // Style reference
    buffer.writeln('    <styleUrl>#lineStringStyle</styleUrl>');

    // LineString geometry
    buffer.writeln('    <LineString>');
    buffer.writeln('      <tessellate>1</tessellate>');
    buffer.writeln('      <coordinates>');
    buffer.writeln('        ${coordinates.join(' ')}');
    buffer.writeln('      </coordinates>');
    buffer.writeln('    </LineString>');
    buffer.writeln('  </Placemark>');

    // Report statistics: 1 placemark created, but track coordinates processed/skipped
    // Report placemark count (consistent with current approach)
    onStats(1, skippedCount);

    // Log the coordinate processing for debugging:
    if (kDebugMode) {
      print('LineString generation completed:');
      print('  Coordinates processed: $processedCount');
      print('  Coordinates skipped: $skippedCount');
      print('  Placemarks created: 1');
    }
  }

  /// Generate single Polygon placemark from all valid CSV coordinates
  void _generatePolygonPlacemark(
    StringBuffer buffer,
    CsvData csvData,
    ColumnMapping columnMapping,
    KmlGenerationOptions options,
    Function(int processed, int skipped) onStats,
  ) {
    final coordinates = <String>[];
    int processedCount = 0;
    int skippedCount = 0;

    // Collect all valid coordinates
    for (int i = 0; i < csvData.rows.length; i++) {
      final row = csvData.rows[i];

      try {
        final latValue = row[columnMapping.latitudeColumn];
        final lonValue = row[columnMapping.longitudeColumn];

        if (latValue == null || lonValue == null) {
          skippedCount++;
          continue;
        }

        final latitude = _parseCoordinate(latValue);
        final longitude = _parseCoordinate(lonValue);

        if (latitude == null || longitude == null) {
          skippedCount++;
          continue;
        }

        if (latitude < -90 ||
            latitude > 90 ||
            longitude < -180 ||
            longitude > 180) {
          skippedCount++;
          continue;
        }

        final elevation = _extractElevation(row, columnMapping, options);
        final coord =
            elevation != null && elevation != 0.0
                ? '$longitude,$latitude,$elevation'
                : '$longitude,$latitude';

        coordinates.add(coord);
        processedCount++;
      } catch (e) {
        skippedCount++;
      }
    }

    if (coordinates.length < 3) {
      if (kDebugMode) {
        print(
          'Warning: Polygon requires at least 3 coordinates. Found: ${coordinates.length}',
        );
      }
      onStats(0, csvData.rows.length);
      return;
    }

    // Ensure polygon is closed (first point = last point)
    if (coordinates.first != coordinates.last) {
      coordinates.add(coordinates.first);
    }

    // Create Polygon placemark
    buffer.writeln('  <Placemark>');
    buffer.writeln('    <name>${_escapeXml(options.documentName)} Area</name>');
    buffer.writeln(
      '    <description>Generated polygon from ${coordinates.length - 1} points</description>',
    );

    // Style reference
    buffer.writeln('    <styleUrl>#polygonStyle</styleUrl>');

    // Polygon geometry
    buffer.writeln('    <Polygon>');
    buffer.writeln('      <tessellate>1</tessellate>');
    buffer.writeln('      <outerBoundaryIs>');
    buffer.writeln('        <LinearRing>');
    buffer.writeln('          <coordinates>');
    buffer.writeln('            ${coordinates.join(' ')}');
    buffer.writeln('          </coordinates>');
    buffer.writeln('        </LinearRing>');
    buffer.writeln('      </outerBoundaryIs>');
    buffer.writeln('    </Polygon>');
    buffer.writeln('  </Placemark>');

    // Report statistics: 1 placemark created, but track coordinates processed/skipped
    // Option 1: Report placemark count
    onStats(1, skippedCount); // 1 placemark created

    // Log the coordinate processing for debugging:
    if (kDebugMode) {
      print('Polygon generation completed:');
      print('  Coordinates processed: $processedCount');
      print('  Coordinates skipped: $skippedCount');
      print('  Placemarks created: 1');
    }
  }

  /// Create a point placemark from a CSV row
  String? _createPointPlacemark(
    Map<String, dynamic> row,
    ColumnMapping columnMapping,
    KmlGenerationOptions options,
    int index,
  ) {
    // Extract coordinates
    final latValue = row[columnMapping.latitudeColumn];
    final lonValue = row[columnMapping.longitudeColumn];

    if (latValue == null || lonValue == null) {
      return null; // Skip rows without coordinates
    }

    final latitude = _parseCoordinate(latValue);
    final longitude = _parseCoordinate(lonValue);

    if (latitude == null || longitude == null) {
      return null; // Skip rows with invalid coordinates
    }

    // Validate coordinate ranges
    if (latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      if (kDebugMode) {
        print(
          'Warning: Invalid coordinate range at row ${index + 1}: lat=$latitude, lon=$longitude',
        );
      }
      return null; // Skip rows with out-of-range coordinates
    }

    final buffer = StringBuffer();
    buffer.writeln('  <Placemark>');

    // Name
    final name =
        columnMapping.nameColumn != null
            ? row[columnMapping.nameColumn]?.toString() ??
                'Placemark ${index + 1}'
            : 'Placemark ${index + 1}';
    buffer.writeln('    <name>${_escapeXml(name)}</name>');

    // Description
    if (options.includeDescription) {
      final description = _generateDescription(row, columnMapping, options);
      if (description.isNotEmpty) {
        buffer.writeln(
          '    <description><![CDATA[$description]]></description>',
        );
      }
    }

    // Style reference
    final styleId = _determineStyleId(row, options);
    if (styleId != null) {
      buffer.writeln('    <styleUrl>#$styleId</styleUrl>');
    }

    // Point geometry
    final elevation = _extractElevation(row, columnMapping, options);
    final coords =
        elevation != null && elevation != 0.0
            ? '$longitude,$latitude,$elevation'
            : '$longitude,$latitude';

    buffer.writeln('    <Point>');
    buffer.writeln('      <coordinates>$coords</coordinates>');
    buffer.writeln('    </Point>');

    buffer.writeln('  </Placemark>');
    return buffer.toString();
  }

  /// Add styles to KML document based on geometry type and options
  void _addStyles(StringBuffer buffer, KmlGenerationOptions options) {
    // Default fallback values
    String defaultColor = 'ff0000ff';
    String defaultIconUrl =
        'http://maps.google.com/mapfiles/kml/pushpin/wht-pushpin.png';
    double defaultIconScale = 1.0; // NEW: Default icon scale
    String defaultLabelColor = 'ff000000'; // NEW: Default label color
    double defaultLabelScale = 0.9; // NEW: Default label scale

    // FIXED: Get all styling properties from user's default style
    if (options.useCustomIcons && options.styleRules.isNotEmpty) {
      final defaultUserStyle = options.styleRules['defaultUserStyle'];
      if (defaultUserStyle != null) {
        defaultColor = defaultUserStyle.color;
        defaultIconUrl = defaultUserStyle.iconUrl;
        defaultIconScale =
            defaultUserStyle.scale ?? 1.0; // NEW: Use user's icon scale
        defaultLabelColor =
            defaultUserStyle.labelColor ??
            'ff000000'; // NEW: Use user's label color
        defaultLabelScale =
            defaultUserStyle.labelScale ?? 0.9; // NEW: Use user's label scale

        if (kDebugMode) {
          print('Using user default style: $defaultColor - $defaultIconUrl');
          print(
            'Icon scale: $defaultIconScale, Label: $defaultLabelColor @ ${defaultLabelScale}x',
          );
        }
      } else {
        // Fallback to first available rule
        final firstRule = options.styleRules.values.first;
        defaultColor = firstRule.color;
        defaultIconUrl = firstRule.iconUrl;
        defaultIconScale = firstRule.scale ?? 1.0; // NEW
        defaultLabelColor = firstRule.labelColor ?? 'ff000000'; // NEW
        defaultLabelScale = firstRule.labelScale ?? 0.9; // NEW
      }
    }

    // Default point style - NOW USES ALL USER SELECTIONS
    buffer.writeln('<Style id="defaultStyle">');
    buffer.writeln('  <IconStyle>');
    buffer.writeln('    <color>$defaultColor</color>');
    buffer.writeln(
      '    <scale>$defaultIconScale</scale>',
    ); // FIXED: Use user's scale
    buffer.writeln('    <Icon>');
    buffer.writeln('      <href>$defaultIconUrl</href>');
    buffer.writeln('    </Icon>');
    buffer.writeln('  </IconStyle>');
    buffer.writeln('  <LabelStyle>');
    buffer.writeln(
      '    <color>$defaultLabelColor</color>',
    ); // FIXED: Use user's label color
    buffer.writeln(
      '    <scale>$defaultLabelScale</scale>',
    ); // FIXED: Use user's label scale
    buffer.writeln('  </LabelStyle>');
    buffer.writeln('</Style>');

    // LineString style - ALSO FIXED
    buffer.writeln('<Style id="lineStringStyle">');
    buffer.writeln('  <LineStyle>');
    buffer.writeln('    <color>$defaultColor</color>');
    buffer.writeln('    <width>3</width>');
    buffer.writeln('  </LineStyle>');
    buffer.writeln('  <LabelStyle>');
    buffer.writeln('    <color>$defaultLabelColor</color>'); // FIXED
    buffer.writeln('    <scale>$defaultLabelScale</scale>'); // FIXED
    buffer.writeln('  </LabelStyle>');
    buffer.writeln('</Style>');

    // Polygon style - ALSO FIXED
    buffer.writeln('<Style id="polygonStyle">');
    buffer.writeln('  <LineStyle>');
    buffer.writeln('    <color>$defaultColor</color>');
    buffer.writeln('    <width>2</width>');
    buffer.writeln('  </LineStyle>');
    buffer.writeln('  <PolyStyle>');
    final transparentColor = '7f${defaultColor.substring(2)}';
    buffer.writeln('    <color>$transparentColor</color>');
    buffer.writeln('    <fill>1</fill>');
    buffer.writeln('    <outline>1</outline>');
    buffer.writeln('  </PolyStyle>');
    buffer.writeln('  <LabelStyle>');
    buffer.writeln('    <color>$defaultLabelColor</color>'); // FIXED
    buffer.writeln('    <scale>$defaultLabelScale</scale>'); // FIXED
    buffer.writeln('  </LabelStyle>');
    buffer.writeln('</Style>');

    // Custom styles from criteria-based rules - ALSO FIXED
    if (options.useCustomIcons && options.styleRules.isNotEmpty) {
      for (final entry in options.styleRules.entries) {
        final styleId = entry.key;
        final rule = entry.value;

        if (styleId == 'defaultUserStyle') continue;

        buffer.writeln('<Style id="$styleId">');
        buffer.writeln('  <IconStyle>');
        buffer.writeln('    <color>${rule.color}</color>');
        buffer.writeln(
          '    <scale>${rule.scale ?? defaultIconScale}</scale>',
        ); // FIXED
        buffer.writeln('    <Icon>');
        buffer.writeln('      <href>${rule.iconUrl}</href>');
        buffer.writeln('    </Icon>');
        buffer.writeln('  </IconStyle>');
        buffer.writeln('  <LabelStyle>');
        buffer.writeln(
          '    <color>${rule.labelColor ?? defaultLabelColor}</color>',
        ); // FIXED
        buffer.writeln(
          '    <scale>${rule.labelScale ?? defaultLabelScale}</scale>',
        ); // FIXED
        buffer.writeln('  </LabelStyle>');
        buffer.writeln('</Style>');
      }
    }
  }

  /// Determine which style to use for a row
  String? _determineStyleId(
    Map<String, dynamic> row,
    KmlGenerationOptions options,
  ) {
    if (!options.useCustomIcons || options.styleRules.isEmpty) {
      return 'defaultStyle';
    }

    // Check style rules
    for (final entry in options.styleRules.entries) {
      final styleId = entry.key;
      final rule = entry.value;

      final cellValue = row[rule.columnName]?.toString() ?? '';
      if (cellValue == rule.columnValue) {
        return styleId;
      }
    }

    return 'defaultStyle';
  }

  /// Extract elevation from row
  double? _extractElevation(
    Map<String, dynamic> row,
    ColumnMapping columnMapping,
    KmlGenerationOptions options,
  ) {
    if (!options.includeElevation || columnMapping.elevationColumn == null) {
      return null;
    }

    final elevValue = row[columnMapping.elevationColumn];
    return _parseCoordinate(elevValue);
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
      final cleanValue =
          stringValue
              .replaceAll(
                RegExp(r'[^\d\-\+\.]'),
                '',
              ) // Remove non-numeric chars except -+.
              .trim();

      if (cleanValue.isEmpty) return null;

      return double.tryParse(cleanValue);
    } catch (e) {
      if (kDebugMode) {
        print('Warning: Failed to parse coordinate: $value');
      }
      return null;
    }
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

  /// Determine output file path
  String _determineOutputPath(
    String inputFileName,
    KmlGenerationOptions options, {
    bool isKmz = false,
  }) {
    if (options.outputPath != null && options.outputPath!.isNotEmpty) {
      return options.outputPath!;
    }

    // Generate default path based on input file
    final baseName = path.basenameWithoutExtension(inputFileName);
    final extension = isKmz ? '.kmz' : '.kml';
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Use Downloads directory as default
    String downloadsPath;

    if (Platform.isWindows) {
      downloadsPath = path.join(
        Platform.environment['USERPROFILE'] ?? '.',
        'Downloads',
      );
    } else {
      downloadsPath = path.join(
        Platform.environment['HOME'] ?? '.',
        'Downloads',
      );
    }

    // Create unique filename to avoid conflicts
    final fileName = '${baseName}_converted_$timestamp$extension';
    return path.join(downloadsPath, fileName);
  }

  /// Generate description content with table support
  String _generateDescription(
    Map<String, dynamic> row,
    ColumnMapping columnMapping,
    KmlGenerationOptions options,
  ) {
    if (!options.includeDescription) return '';

    if (options.useDescriptionTable &&
        options.descriptionColumns != null &&
        options.descriptionColumns!.isNotEmpty) {
      return _generateTableDescription(row, options);
    } else if (columnMapping.descriptionColumn != null) {
      return row[columnMapping.descriptionColumn]?.toString() ?? '';
    }

    return '';
  }

  /// Generate table-formatted description
  String _generateTableDescription(
    Map<String, dynamic> row,
    KmlGenerationOptions options,
  ) {
    final style = _getTableStyle(options.descriptionTableStyle ?? 'simple');
    final buffer = StringBuffer();

    buffer.writeln('<div style="$style">');
    buffer.writeln('<table style="width:100%; border-collapse: collapse;">');

    for (final column in options.descriptionColumns!) {
      final value = row[column]?.toString() ?? '';
      if (value.isNotEmpty) {
        buffer.writeln('<tr>');
        buffer.writeln(
          '<td style="font-weight: bold; padding: 4px; vertical-align: top;">$column:</td>',
        );
        buffer.writeln('<td style="padding: 4px;">$value</td>');
        buffer.writeln('</tr>');
      }
    }

    buffer.writeln('</table>');
    buffer.writeln('</div>');

    return buffer.toString();
  }

  /// Get CSS styling for description tables
  String _getTableStyle(String styleType) {
    switch (styleType) {
      case 'bordered':
        return 'font-family: Arial, sans-serif; font-size: 12px; table { border: 1px solid #ddd; } td { border: 1px solid #ddd; }';
      case 'striped':
        return 'font-family: Arial, sans-serif; font-size: 12px; tr:nth-child(even) { background-color: #f2f2f2; }';
      case 'condensed':
        return 'font-family: Arial, sans-serif; font-size: 11px; td { padding: 2px; }';
      default: // simple
        return 'font-family: Arial, sans-serif; font-size: 12px;';
    }
  }
}
