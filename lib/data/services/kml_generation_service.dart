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

    // LineString style
    buffer.writeln('<Style id="lineStringStyle">');
    buffer.writeln('  <LineStyle>');
    buffer.writeln(
      '    <color>ff0000ff</color>',
    ); // Red color (AABBGGRR format)
    buffer.writeln('    <width>3</width>');
    buffer.writeln('  </LineStyle>');
    buffer.writeln('  <LabelStyle>');
    buffer.writeln('    <color>ff000000</color>');
    buffer.writeln('    <scale>0.9</scale>');
    buffer.writeln('  </LabelStyle>');
    buffer.writeln('</Style>');

    // Polygon style
    buffer.writeln('<Style id="polygonStyle">');
    buffer.writeln('  <LineStyle>');
    buffer.writeln('    <color>ff0000ff</color>'); // Red border
    buffer.writeln('    <width>2</width>');
    buffer.writeln('  </LineStyle>');
    buffer.writeln('  <PolyStyle>');
    buffer.writeln('    <color>7f0000ff</color>'); // Semi-transparent red fill
    buffer.writeln('    <fill>1</fill>');
    buffer.writeln('    <outline>1</outline>');
    buffer.writeln('  </PolyStyle>');
    buffer.writeln('  <LabelStyle>');
    buffer.writeln('    <color>ff000000</color>');
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
