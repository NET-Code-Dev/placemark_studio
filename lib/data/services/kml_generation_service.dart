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

    // Add default styles
    _addDefaultStyles(buffer, options);

    // Process each row
    for (int i = 0; i < csvData.rows.length; i++) {
      final row = csvData.rows[i];

      try {
        final placemark = _createPlacemark(row, columnMapping, options, i);
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
        // Continue processing other rows
      }
    }

    // KML footer
    buffer.writeln('</Document>');
    buffer.writeln('</kml>');

    if (kDebugMode) {
      print('KML generation completed:');
      print('  Processed: $processedCount placemarks');
      print('  Skipped: $skippedCount rows');
      print(
        '  Success rate: ${(processedCount / csvData.rows.length * 100).toStringAsFixed(1)}%',
      );
    }

    return buffer.toString();
  }

  /// Add default styles to KML document
  void _addDefaultStyles(StringBuffer buffer, KmlGenerationOptions options) {
    // Default point style
    buffer.writeln('<Style id="defaultStyle">');
    buffer.writeln('  <IconStyle>');
    buffer.writeln('    <color>ff0000ff</color>'); // Red color
    buffer.writeln('    <scale>1.0</scale>');
    buffer.writeln('    <Icon>');
    buffer.writeln(
      '      <href>http://maps.google.com/mapfiles/kml/pushpin/ylw-pushpin.png</href>',
    );
    buffer.writeln('    </Icon>');
    buffer.writeln('  </IconStyle>');
    buffer.writeln('  <LabelStyle>');
    buffer.writeln('    <color>ff000000</color>'); // Black labels
    buffer.writeln('    <scale>0.9</scale>');
    buffer.writeln('  </LabelStyle>');
    buffer.writeln('</Style>');

    // Add custom styles from options
    if (options.useCustomIcons && options.styleRules.isNotEmpty) {
      for (final entry in options.styleRules.entries) {
        final styleId = entry.key;
        final rule = entry.value;

        buffer.writeln('<Style id="$styleId">');
        buffer.writeln('  <IconStyle>');
        buffer.writeln('    <color>${rule.color}</color>');
        buffer.writeln('    <scale>1.0</scale>');
        buffer.writeln('    <Icon>');
        buffer.writeln('      <href>${rule.iconUrl}</href>');
        buffer.writeln('    </Icon>');
        buffer.writeln('  </IconStyle>');
        buffer.writeln('</Style>');
      }
    }
  }

  /// Create a placemark from a CSV row
  String? _createPlacemark(
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
    if (options.includeDescription && columnMapping.descriptionColumn != null) {
      final description =
          row[columnMapping.descriptionColumn]?.toString() ?? '';
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

    // Geometry
    final geometry = _createGeometry(
      latitude: latitude,
      longitude: longitude,
      elevation: _extractElevation(row, columnMapping, options),
      geometryType: options.geometryType,
    );
    buffer.write(geometry); // Note: geometry includes its own indentation

    buffer.writeln('  </Placemark>');
    return buffer.toString();
  }

  /// Create geometry element based on geometry type
  String _createGeometry({
    required double latitude,
    required double longitude,
    double? elevation,
    required GeometryType geometryType,
  }) {
    final coords =
        elevation != null && elevation != 0.0
            ? '$longitude,$latitude,$elevation'
            : '$longitude,$latitude';

    switch (geometryType) {
      case GeometryType.point:
        return '''    <Point>
      <coordinates>$coords</coordinates>
    </Point>
''';

      case GeometryType.lineString:
        // For single point data, we'll create a point instead
        return '''    <Point>
      <coordinates>$coords</coordinates>
    </Point>
''';

      case GeometryType.polygon:
        // For single point data, we'll create a point instead
        return '''    <Point>
      <coordinates>$coords</coordinates>
    </Point>
''';

      case GeometryType.linearRing:
        // For single point data, we'll create a point instead
        return '''    <Point>
      <coordinates>$coords</coordinates>
    </Point>
''';

      case GeometryType.multiGeometry:
        // For single point data, we'll create a point instead
        return '''    <Point>
      <coordinates>$coords</coordinates>
    </Point>
''';

      case GeometryType.model:
        // For single point data, we'll create a point instead
        return '''    <Point>
      <coordinates>$coords</coordinates>
    </Point>
''';
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
}
