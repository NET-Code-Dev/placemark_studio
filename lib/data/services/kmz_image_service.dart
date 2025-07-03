import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

import '../../core/enums/geometry_type.dart';
import '../models/column_mapping.dart';
import '../models/csv_data.dart';
import '../models/kml_generation_options.dart';

/// Enhanced KML generation service with proper image integration
class KmzImageService {
  /// Generate KMZ with embedded images and proper KML image references
  static Future<File> generateKmzWithImages({
    required CsvData csvData,
    required ColumnMapping columnMapping,
    required KmlGenerationOptions options,
    List<File>? imageFiles,
    String? imageColumnName,
    Map<String, File>? imageAssociations,
  }) async {
    try {
      // Generate KML content with image references
      final kmlContent = _generateKmlWithImageReferences(
        csvData: csvData,
        columnMapping: columnMapping,
        options: options,
        imageColumnName: imageColumnName,
        imageAssociations: imageAssociations,
      );

      // Create KMZ archive
      final archive = Archive();

      // Add KML file to archive
      final kmlBytes = utf8.encode(kmlContent);
      archive.addFile(ArchiveFile('doc.kml', kmlBytes.length, kmlBytes));

      // Add image files to archive
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

      // Compress archive
      final zipData = ZipEncoder().encode(archive);

      if (zipData == null) {
        throw Exception('Failed to create KMZ archive');
      }

      // Write KMZ file
      final outputPath = _determineOutputPath(
        csvData.fileName,
        options,
        isKmz: true,
      );
      final file = File(outputPath);
      await file.writeAsBytes(zipData);

      if (kDebugMode) {
        print('KMZ file generated: $outputPath');
        print(
          'Archive contains ${archive.files.length} files (1 KML + ${addedImages.length} images)',
        );
        print('File size: ${await file.length()} bytes');
      }

      return file;
    } catch (e) {
      if (kDebugMode) {
        print('Error generating KMZ with images: $e');
      }
      rethrow;
    }
  }

  /// Generate KML content with proper image references
  static String _generateKmlWithImageReferences({
    required CsvData csvData,
    required ColumnMapping columnMapping,
    required KmlGenerationOptions options,
    String? imageColumnName,
    Map<String, File>? imageAssociations,
  }) {
    final buffer = StringBuffer();
    int processedCount = 0;

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

    // Get image column index if specified
    int? imageColumnIndex;
    if (imageColumnName != null) {
      imageColumnIndex = csvData.headers.indexOf(imageColumnName);
    }

    // Generate placemarks based on geometry type
    switch (options.geometryType) {
      case GeometryType.point:
        _generatePointPlacemarksWithImages(
          buffer,
          csvData,
          columnMapping,
          options,
          imageColumnIndex,
          imageAssociations,
          (processed, _) => processedCount = processed,
        );
        break;

      case GeometryType.lineString:
        _generateLineStringWithImages(
          buffer,
          csvData,
          columnMapping,
          options,
          imageColumnIndex,
          imageAssociations,
          (processed, _) => processedCount = processed,
        );
        break;

      case GeometryType.polygon:
        _generatePolygonWithImages(
          buffer,
          csvData,
          columnMapping,
          options,
          imageColumnIndex,
          imageAssociations,
          (processed, _) => processedCount = processed,
        );
        break;
    }

    // KML footer
    buffer.writeln('</Document>');
    buffer.writeln('</kml>');

    if (kDebugMode) {
      print('Generated KML with $processedCount placemarks');
      if (imageAssociations != null) {
        print('Image associations available: ${imageAssociations.length}');
      }
    }

    return buffer.toString();
  }

  /// Generate point placemarks with image integration
  static void _generatePointPlacemarksWithImages(
    StringBuffer buffer,
    CsvData csvData,
    ColumnMapping columnMapping,
    KmlGenerationOptions options,
    int? imageColumnIndex,
    Map<String, File>? imageAssociations,
    Function(int, int) onProgress,
  ) {
    int processed = 0;
    int skipped = 0;

    for (int i = 0; i < csvData.rows.length; i++) {
      final row = csvData.rows[i];

      // Validate coordinates
      if (!_hasValidCoordinates(row, columnMapping)) {
        skipped++;
        continue;
      }

      final name = _getValue(row, columnMapping.nameColumn) ?? 'Point ${i + 1}';
      final lat = double.parse(_getValue(row, columnMapping.latitudeColumn)!);
      final lon = double.parse(_getValue(row, columnMapping.longitudeColumn)!);
      final elevation =
          columnMapping.elevationColumn != null
              ? _getValue(row, columnMapping.elevationColumn!)
              : null;

      // Get image reference if available
      String? imageReference;
      if (imageColumnIndex != null &&
          row.length > imageColumnIndex &&
          imageAssociations != null) {
        final imageValue = row[imageColumnIndex].trim();
        if (imageValue.isNotEmpty &&
            imageAssociations.containsKey(imageValue)) {
          imageReference = path.basename(imageAssociations[imageValue]!.path);
        }
      }

      // Generate placemark
      buffer.writeln('<Placemark>');
      buffer.writeln('<name>${_escapeXml(name)}</name>');

      // Enhanced description with image
      final description = _generateEnhancedDescription(
        row: row,
        csvData: csvData,
        columnMapping: columnMapping,
        options: options,
        imageReference: imageReference,
      );
      buffer.writeln('<description><![CDATA[$description]]></description>');

      // Apply styling
      _applyPlacemarkStyling(buffer, options, row, csvData.headers);

      // Coordinates
      buffer.writeln('<Point>');
      if (elevation != null && elevation.isNotEmpty) {
        buffer.writeln('<coordinates>$lon,$lat,${elevation}</coordinates>');
      } else {
        buffer.writeln('<coordinates>$lon,$lat</coordinates>');
      }
      buffer.writeln('</Point>');
      buffer.writeln('</Placemark>');

      processed++;
    }

    onProgress(processed, skipped);
  }

  /// Generate enhanced description with optional image
  static String _generateEnhancedDescription({
    required List<String> row,
    required CsvData csvData,
    required ColumnMapping columnMapping,
    required KmlGenerationOptions options,
    String? imageReference,
  }) {
    final buffer = StringBuffer();

    // Add image if available
    if (imageReference != null) {
      buffer.writeln('<div style="text-align: center; margin-bottom: 10px;">');
      buffer.writeln(
        '<img src="$imageReference" style="max-width: 300px; max-height: 200px; border-radius: 8px;" alt="Location Image"/>',
      );
      buffer.writeln('</div>');
    }

    // Add description from column if specified
    if (columnMapping.descriptionColumn != null) {
      final description = _getValue(row, columnMapping.descriptionColumn!);
      if (description != null && description.isNotEmpty) {
        buffer.writeln(
          '<p><strong>Description:</strong> ${_escapeXml(description)}</p>',
        );
      }
    }

    // Add coordinate information
    final lat = _getValue(row, columnMapping.latitudeColumn);
    final lon = _getValue(row, columnMapping.longitudeColumn);
    if (lat != null && lon != null) {
      buffer.writeln('<p><strong>Coordinates:</strong> $lat, $lon</p>');
    }

    // Add elevation if available
    if (columnMapping.elevationColumn != null) {
      final elevation = _getValue(row, columnMapping.elevationColumn!);
      if (elevation != null && elevation.isNotEmpty) {
        buffer.writeln('<p><strong>Elevation:</strong> ${elevation}m</p>');
      }
    }

    // Add additional data table if enabled
    if (options.includeDescription) {
      buffer.writeln('<hr style="margin: 10px 0;"/>');
      buffer.writeln(
        '<table style="width: 100%; border-collapse: collapse; font-size: 12px;">',
      );

      for (int i = 0; i < csvData.headers.length && i < row.length; i++) {
        final header = csvData.headers[i];
        final value = row[i];

        // Skip empty values and already displayed columns
        if (value.trim().isEmpty ||
            header == columnMapping.nameColumn ||
            header == columnMapping.latitudeColumn ||
            header == columnMapping.longitudeColumn ||
            header == columnMapping.elevationColumn ||
            header == columnMapping.descriptionColumn) {
          continue;
        }

        buffer.writeln('<tr style="border-bottom: 1px solid #ddd;">');
        buffer.writeln(
          '<td style="padding: 4px; font-weight: bold; background-color: #f5f5f5;">${_escapeXml(header)}</td>',
        );
        buffer.writeln('<td style="padding: 4px;">${_escapeXml(value)}</td>');
        buffer.writeln('</tr>');
      }

      buffer.writeln('</table>');
    }

    return buffer.toString();
  }

  /// Generate line string geometry with images (images apply to the overall path)
  static void _generateLineStringWithImages(
    StringBuffer buffer,
    CsvData csvData,
    ColumnMapping columnMapping,
    KmlGenerationOptions options,
    int? imageColumnIndex,
    Map<String, File>? imageAssociations,
    Function(int, int) onProgress,
  ) {
    // For LineString, we create one placemark with multiple coordinates
    // Images would be associated with the overall line, not individual points

    final coordinates = <String>[];
    int validPoints = 0;
    String? lineImageReference;

    // Collect coordinates and find first available image
    for (int i = 0; i < csvData.rows.length; i++) {
      final row = csvData.rows[i];

      if (_hasValidCoordinates(row, columnMapping)) {
        final lat = double.parse(_getValue(row, columnMapping.latitudeColumn)!);
        final lon = double.parse(
          _getValue(row, columnMapping.longitudeColumn)!,
        );
        final elevation =
            columnMapping.elevationColumn != null
                ? _getValue(row, columnMapping.elevationColumn!)
                : null;

        if (elevation != null && elevation.isNotEmpty) {
          coordinates.add('$lon,$lat,$elevation');
        } else {
          coordinates.add('$lon,$lat');
        }
        validPoints++;

        // Get first available image for the line
        if (lineImageReference == null &&
            imageColumnIndex != null &&
            row.length > imageColumnIndex &&
            imageAssociations != null) {
          final imageValue = row[imageColumnIndex].trim();
          if (imageValue.isNotEmpty &&
              imageAssociations.containsKey(imageValue)) {
            lineImageReference = path.basename(
              imageAssociations[imageValue]!.path,
            );
          }
        }
      }
    }

    if (coordinates.isNotEmpty) {
      buffer.writeln('<Placemark>');
      buffer.writeln('<name>${_escapeXml(options.documentName)} Path</name>');

      // Enhanced description for line with image
      final description = _generateLineDescription(
        csvData: csvData,
        pointCount: validPoints,
        imageReference: lineImageReference,
      );
      buffer.writeln('<description><![CDATA[$description]]></description>');

      _applyPlacemarkStyling(buffer, options, null, csvData.headers);

      buffer.writeln('<LineString>');
      buffer.writeln('<coordinates>${coordinates.join(' ')}</coordinates>');
      buffer.writeln('</LineString>');
      buffer.writeln('</Placemark>');
    }

    onProgress(validPoints > 0 ? 1 : 0, csvData.rows.length - validPoints);
  }

  /// Generate polygon geometry with images
  static void _generatePolygonWithImages(
    StringBuffer buffer,
    CsvData csvData,
    ColumnMapping columnMapping,
    KmlGenerationOptions options,
    int? imageColumnIndex,
    Map<String, File>? imageAssociations,
    Function(int, int) onProgress,
  ) {
    // Similar to LineString but creates a closed polygon
    final coordinates = <String>[];
    int validPoints = 0;
    String? polygonImageReference;

    for (int i = 0; i < csvData.rows.length; i++) {
      final row = csvData.rows[i];

      if (_hasValidCoordinates(row, columnMapping)) {
        final lat = double.parse(_getValue(row, columnMapping.latitudeColumn)!);
        final lon = double.parse(
          _getValue(row, columnMapping.longitudeColumn)!,
        );
        final elevation =
            columnMapping.elevationColumn != null
                ? _getValue(row, columnMapping.elevationColumn!)
                : null;

        if (elevation != null && elevation.isNotEmpty) {
          coordinates.add('$lon,$lat,$elevation');
        } else {
          coordinates.add('$lon,$lat');
        }
        validPoints++;

        // Get first available image for the polygon
        if (polygonImageReference == null &&
            imageColumnIndex != null &&
            row.length > imageColumnIndex &&
            imageAssociations != null) {
          final imageValue = row[imageColumnIndex].trim();
          if (imageValue.isNotEmpty &&
              imageAssociations.containsKey(imageValue)) {
            polygonImageReference = path.basename(
              imageAssociations[imageValue]!.path,
            );
          }
        }
      }
    }

    if (coordinates.length >= 3) {
      // Ensure polygon is closed
      if (coordinates.first != coordinates.last) {
        coordinates.add(coordinates.first);
      }

      buffer.writeln('<Placemark>');
      buffer.writeln('<name>${_escapeXml(options.documentName)} Area</name>');

      final description = _generatePolygonDescription(
        csvData: csvData,
        pointCount: validPoints,
        imageReference: polygonImageReference,
      );
      buffer.writeln('<description><![CDATA[$description]]></description>');

      _applyPlacemarkStyling(buffer, options, null, csvData.headers);

      buffer.writeln('<Polygon>');
      buffer.writeln('<outerBoundaryIs>');
      buffer.writeln('<LinearRing>');
      buffer.writeln('<coordinates>${coordinates.join(' ')}</coordinates>');
      buffer.writeln('</LinearRing>');
      buffer.writeln('</outerBoundaryIs>');
      buffer.writeln('</Polygon>');
      buffer.writeln('</Placemark>');
    }

    onProgress(validPoints >= 3 ? 1 : 0, csvData.rows.length - validPoints);
  }

  // Helper methods (same as in original service, but with image support)
  static String _generateLineDescription({
    required CsvData csvData,
    required int pointCount,
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

    buffer.writeln('<p><strong>Path Information:</strong></p>');
    buffer.writeln('<ul>');
    buffer.writeln('<li>Total Points: $pointCount</li>');
    buffer.writeln(
      '<li>Generated: ${DateTime.now().toString().split('.')[0]}</li>',
    );
    buffer.writeln('</ul>');

    return buffer.toString();
  }

  static String _generatePolygonDescription({
    required CsvData csvData,
    required int pointCount,
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

    buffer.writeln('<p><strong>Area Information:</strong></p>');
    buffer.writeln('<ul>');
    buffer.writeln('<li>Boundary Points: $pointCount</li>');
    buffer.writeln(
      '<li>Generated: ${DateTime.now().toString().split('.')[0]}</li>',
    );
    buffer.writeln('</ul>');

    return buffer.toString();
  }

  // Additional helper methods (would need to be implemented or imported from existing service)
  static void _addStyles(StringBuffer buffer, KmlGenerationOptions options) {
    // Implementation for adding KML styles
    // This would be similar to your existing _addStyles method
  }

  static void _applyPlacemarkStyling(
    StringBuffer buffer,
    KmlGenerationOptions options,
    List<String>? row,
    List<String> headers,
  ) {
    // Implementation for applying placemark styling
    // This would be similar to your existing styling logic
  }

  static bool _hasValidCoordinates(
    List<String> row,
    ColumnMapping columnMapping,
  ) {
    // Implementation for coordinate validation
    // This would be similar to your existing validation logic
    return true; // Placeholder
  }

  static String? _getValue(List<String> row, String columnName) {
    // Implementation for getting column value
    // This would be similar to your existing _getValue method
    return null; // Placeholder
  }

  static String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  static String _determineOutputPath(
    String fileName,
    KmlGenerationOptions options, {
    bool isKmz = false,
  }) {
    // Implementation for determining output path
    // This would be similar to your existing path determination logic
    return 'output.kmz'; // Placeholder
  }
}
