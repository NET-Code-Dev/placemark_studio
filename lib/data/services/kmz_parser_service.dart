import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:archive/archive.dart';
import 'package:placemark_studio/data/models/bounding_box.dart';
import 'package:placemark_studio/data/models/kml_folder.dart';
import 'package:placemark_studio/data/models/placemark.dart';
import '../../core/errors/app_exception.dart';
import '../models/kml_data.dart';
import 'kml_parser_service.dart';

abstract class IKmzParserService {
  Future<KmlData> parseKmzFile(File file, {bool preserveHierarchy = true});
  Future<List<KmlData>> parseKmzFileMultiple(
    File file, {
    bool preserveHierarchy = true,
  });
}

class KmzParserService implements IKmzParserService {
  final IKmlParserService _kmlParserService;

  KmzParserService({required IKmlParserService kmlParserService})
    : _kmlParserService = kmlParserService;

  @override
  Future<KmlData> parseKmzFile(
    File file, {
    bool preserveHierarchy = true,
  }) async {
    try {
      final kmlDataList = await parseKmzFileMultiple(
        file,
        preserveHierarchy: preserveHierarchy,
      );

      if (kmlDataList.isEmpty) {
        throw FileProcessingException(
          'No valid KML files found in KMZ archive',
          code: 'NO_KML_IN_KMZ',
        );
      }

      // If there's only one KML file, return it directly
      if (kmlDataList.length == 1) {
        return kmlDataList.first.copyWith(
          fileName: file.path.split('/').last, // Use original KMZ filename
        );
      }

      // If there are multiple KML files, merge them
      return _mergeKmlData(kmlDataList, file);
    } catch (e) {
      if (e is AppException) rethrow;

      throw FileProcessingException(
        'Failed to parse KMZ file: ${e.toString()}',
        code: 'KMZ_PARSE_ERROR',
        details: e,
      );
    }
  }

  @override
  Future<List<KmlData>> parseKmzFileMultiple(
    File file, {
    bool preserveHierarchy = true,
  }) async {
    try {
      // Read the KMZ file as bytes
      final bytes = await file.readAsBytes();

      // Decode the ZIP archive
      final archive = ZipDecoder().decodeBytes(bytes);

      // Find all KML files in the archive
      final kmlFiles =
          archive.files
              .where(
                (file) =>
                    !file.isFile || // Skip directories
                    file.name.toLowerCase().endsWith('.kml'),
              )
              .where((file) => file.isFile) // Only process actual files
              .toList();

      if (kmlFiles.isEmpty) {
        throw FileProcessingException(
          'No KML files found in KMZ archive',
          code: 'NO_KML_IN_KMZ',
        );
      }

      final kmlDataList = <KmlData>[];

      // Parse each KML file
      for (final kmlFile in kmlFiles) {
        try {
          final kmlContent = _extractKmlContent(kmlFile);
          if (kmlContent.isNotEmpty) {
            final kmlData = await _parseKmlContent(
              kmlContent,
              kmlFile.name,
              preserveHierarchy: preserveHierarchy,
            );
            kmlDataList.add(kmlData);
          }
        } catch (e) {
          if (kDebugMode) {
            print('Warning: Failed to parse KML file ${kmlFile.name}: $e');
          }
          // Continue processing other files
        }
      }

      if (kmlDataList.isEmpty) {
        throw FileProcessingException(
          'No valid KML content could be parsed from KMZ archive',
          code: 'NO_VALID_KML_IN_KMZ',
        );
      }

      return kmlDataList;
    } catch (e) {
      if (e is AppException) rethrow;

      throw FileProcessingException(
        'Failed to extract KMZ archive: ${e.toString()}',
        code: 'KMZ_EXTRACTION_ERROR',
        details: e,
      );
    }
  }

  /// Extract KML content from an archive file
  String _extractKmlContent(ArchiveFile kmlFile) {
    try {
      final content = kmlFile.content as Uint8List;
      return String.fromCharCodes(content);
    } catch (e) {
      throw FileProcessingException(
        'Failed to extract KML content from ${kmlFile.name}',
        code: 'KML_EXTRACTION_ERROR',
        details: e,
      );
    }
  }

  /// Parse KML content string using the existing KML parser
  Future<KmlData> _parseKmlContent(
    String kmlContent,
    String fileName, {
    bool preserveHierarchy = true,
  }) async {
    try {
      // Create a temporary file to use with the existing KML parser
      // This is a workaround since the existing parser expects a File object
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/temp_$fileName');

      try {
        // Write content to temp file
        await tempFile.writeAsString(kmlContent);

        // Parse using existing KML parser
        final kmlData = await _kmlParserService.parseKmlFile(
          tempFile,
          preserveHierarchy: preserveHierarchy,
        );

        // Update filename to reflect original name
        return kmlData.copyWith(fileName: fileName);
      } finally {
        // Clean up temp file
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }
    } catch (e) {
      if (e is AppException) rethrow;

      throw FileProcessingException(
        'Failed to parse KML content from $fileName: ${e.toString()}',
        code: 'KML_CONTENT_PARSE_ERROR',
        details: e,
      );
    }
  }

  /// Merge multiple KML data objects into one
  KmlData _mergeKmlData(List<KmlData> kmlDataList, File originalFile) {
    try {
      final stat = originalFile.statSync();

      // Combine all placemarks
      final allPlacemarks =
          kmlDataList.expand((kml) => kml.allPlacemarks).toList();

      // Combine all available fields
      final allFields =
          kmlDataList.expand((kml) => kml.availableFields).toSet();

      // Combine geometry type counts
      final geometryTypeCounts = <String, int>{};
      for (final kml in kmlDataList) {
        kml.geometryTypeCounts.forEach((type, count) {
          geometryTypeCounts[type] = (geometryTypeCounts[type] ?? 0) + count;
        });
      }

      // Calculate combined bounding box
      final allCoordinates =
          allPlacemarks.expand((p) => p.geometry.coordinates).toList();

      final boundingBox =
          allCoordinates.isNotEmpty
              ? BoundingBox.fromCoordinates(allCoordinates)
              : kmlDataList.first.boundingBox;

      // Merge folder structures if they exist
      final folderStructures =
          kmlDataList
              .where((kml) => kml.hasHierarchy)
              .map((kml) => kml.folderStructure!)
              .toList();

      final mergedFolderStructure =
          folderStructures.isNotEmpty
              ? _mergeFolderStructures(folderStructures)
              : null;

      return KmlData(
        fileName: originalFile.path.split('/').last,
        fileSize: stat.size,
        placemarks: allPlacemarks,
        boundingBox: boundingBox,
        coordinateSystem: kmlDataList.first.coordinateSystem,
        coordinateReferenceSystem: kmlDataList.first.coordinateReferenceSystem,
        coordinateUnits: kmlDataList.first.coordinateUnits,
        layersCount: kmlDataList.length,
        geometryTypeCounts: geometryTypeCounts,
        availableFields: allFields,
        folderStructure: mergedFolderStructure,
      );
    } catch (e) {
      throw FileProcessingException(
        'Failed to merge KML data: ${e.toString()}',
        code: 'KML_MERGE_ERROR',
        details: e,
      );
    }
  }

  /// Merge multiple folder structures into one root folder
  KmlFolder _mergeFolderStructures(List<KmlFolder> folderStructures) {
    final allSubFolders = <KmlFolder>[];
    final allPlacemarks = <Placemark>[];

    for (final folder in folderStructures) {
      allSubFolders.addAll(folder.subFolders);
      allPlacemarks.addAll(folder.placemarks);
    }

    return KmlFolder(
      name: 'Merged KMZ Content',
      description: 'Combined content from ${folderStructures.length} KML files',
      subFolders: allSubFolders,
      placemarks: allPlacemarks,
      depth: 0,
    );
  }
}
