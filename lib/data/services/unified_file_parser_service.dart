import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:archive/archive.dart';
import '../../core/errors/app_exception.dart';
import '../models/kml_data.dart';
import '../models/bounding_box.dart';
import '../models/coordinate.dart';
import 'kml_parser_service.dart';

abstract class IUnifiedFileParserService {
  Future<KmlData> parseFile(File file, {bool preserveHierarchy = true});
}

class UnifiedFileParserService implements IUnifiedFileParserService {
  final IKmlParserService _kmlParserService;

  UnifiedFileParserService({required IKmlParserService kmlParserService})
    : _kmlParserService = kmlParserService;

  @override
  Future<KmlData> parseFile(File file, {bool preserveHierarchy = true}) async {
    final extension = file.path.split('.').last.toLowerCase();

    try {
      if (extension == 'kmz') {
        return await _parseKmzFile(file, preserveHierarchy: preserveHierarchy);
      } else if (extension == 'kml') {
        return await _kmlParserService.parseKmlFile(
          file,
          preserveHierarchy: preserveHierarchy,
        );
      } else {
        throw FileProcessingException(
          'Unsupported file format: $extension',
          code: 'UNSUPPORTED_FORMAT',
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;

      throw FileProcessingException(
        'Failed to parse file: ${e.toString()}',
        code: 'FILE_PARSE_ERROR',
        details: e,
      );
    }
  }

  Future<KmlData> _parseKmzFile(
    File file, {
    bool preserveHierarchy = true,
  }) async {
    try {
      if (kDebugMode) {
        print('Parsing KMZ file: ${file.path}');
      }

      // Read the KMZ file as bytes
      final bytes = await file.readAsBytes();

      if (kDebugMode) {
        print('KMZ file size: ${bytes.length} bytes');
      }

      // Decode the ZIP archive
      final archive = ZipDecoder().decodeBytes(bytes);

      if (kDebugMode) {
        print('Found ${archive.files.length} files in KMZ archive');
      }

      // Find all KML files in the archive
      final kmlFiles =
          archive.files
              .where(
                (file) =>
                    file.isFile && // Only process actual files
                    file.name.toLowerCase().endsWith('.kml'),
              )
              .toList();

      if (kDebugMode) {
        print(
          'Found ${kmlFiles.length} KML files: ${kmlFiles.map((f) => f.name).join(', ')}',
        );
      }

      if (kmlFiles.isEmpty) {
        throw FileProcessingException(
          'No KML files found in KMZ archive',
          code: 'NO_KML_IN_KMZ',
        );
      }

      // Parse the first (or main) KML file
      final mainKmlFile = kmlFiles.first;
      final kmlContent = _extractKmlContent(mainKmlFile);

      if (kDebugMode) {
        print('Extracted KML content length: ${kmlContent.length}');
        print(
          'KML content preview: ${kmlContent.substring(0, math.min(200, kmlContent.length))}...',
        );
      }

      // Parse the KML content
      final kmlData = await _kmlParserService.parseKmlContent(
        kmlContent,
        file.path.split('/').last, // Use original KMZ filename
        preserveHierarchy: preserveHierarchy,
      );

      // Update the file size to the actual KMZ file size
      final stat = await file.stat();
      return kmlData.copyWith(fileSize: stat.size);
    } catch (e) {
      if (e is AppException) rethrow;

      if (kDebugMode) {
        print('Error parsing KMZ file: $e');
      }

      throw FileProcessingException(
        'Failed to parse KMZ file: ${e.toString()}',
        code: 'KMZ_PARSE_ERROR',
        details: e,
      );
    }
  }

  String _extractKmlContent(ArchiveFile kmlFile) {
    try {
      final content = kmlFile.content;
      if (content is List<int>) {
        return String.fromCharCodes(content);
      } else {
        throw FileProcessingException(
          'Invalid KML file content format',
          code: 'INVALID_KML_CONTENT',
        );
      }
    } catch (e) {
      throw FileProcessingException(
        'Failed to extract KML content from ${kmlFile.name}: ${e.toString()}',
        code: 'KML_EXTRACTION_ERROR',
        details: e,
      );
    }
  }
}
