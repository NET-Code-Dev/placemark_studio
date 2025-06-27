import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';
import '../../core/errors/app_exception.dart';
import '../models/kml_data.dart';
import '../models/placemark.dart';
import '../models/geometry.dart';
import '../models/coordinate.dart';
import '../models/bounding_box.dart';
import '../models/kml_folder.dart';

abstract class IKmlParserService {
  Future<KmlData> parseKmlFile(File file, {bool preserveHierarchy = true});
  Future<KmlData> parseKmlContent(
    String content,
    String fileName, {
    bool preserveHierarchy = true,
  });
}

class KmlParserService implements IKmlParserService {
  @override
  Future<KmlData> parseKmlFile(
    File file, {
    bool preserveHierarchy = true,
  }) async {
    try {
      final content = await file.readAsString();
      final stat = await file.stat();
      final result = await parseKmlContent(
        content,
        file.path.split('/').last,
        preserveHierarchy: preserveHierarchy,
      );

      // Update with actual file size
      return result.copyWith(fileSize: stat.size);
    } catch (e) {
      if (e is AppException) rethrow;

      throw FileProcessingException(
        'Failed to parse KML file: ${e.toString()}',
        code: 'KML_PARSE_ERROR',
        details: e,
      );
    }
  }

  @override
  Future<KmlData> parseKmlContent(
    String content,
    String fileName, {
    bool preserveHierarchy = true,
  }) async {
    try {
      final document = XmlDocument.parse(content);

      KmlFolder? folderStructure;
      List<Placemark> flatPlacemarks;
      int layersCount;

      if (preserveHierarchy) {
        // Find the correct starting element for folder parsing
        XmlElement documentElement;

        // First try to find Document element, fall back to kml element
        final documentElements = document.findAllElements('Document').toList();
        if (documentElements.isNotEmpty) {
          documentElement = documentElements.first;
        } else {
          documentElement = document.findElements('kml').first;
        }

        folderStructure = await _parseFolder(documentElement, depth: 0);
        flatPlacemarks = folderStructure.getAllPlacemarks();
        layersCount = folderStructure.getTotalFolderCount();
      } else {
        // Parse flat (existing behavior)
        flatPlacemarks = await _parsePlacemarks(document);
        layersCount = _countLayers(document);
      }

      final allCoordinates = _extractAllCoordinates(flatPlacemarks);
      final boundingBox = BoundingBox.fromCoordinates(allCoordinates);
      final availableFields = _extractAvailableFields(flatPlacemarks);
      final geometryTypeCounts = _countGeometryTypes(flatPlacemarks);

      return KmlData(
        fileName: fileName,
        fileSize: content.length, // Approximate size for content
        placemarks: flatPlacemarks,
        boundingBox: boundingBox,
        availableFields: availableFields,
        geometryTypeCounts: geometryTypeCounts,
        layersCount: layersCount,
        folderStructure: folderStructure,
      );
    } catch (e) {
      if (e is AppException) rethrow;

      throw FileProcessingException(
        'Failed to parse KML content: ${e.toString()}',
        code: 'KML_PARSE_ERROR',
        details: e,
      );
    }
  }

  /// Parse a folder and its contents recursively
  Future<KmlFolder> _parseFolder(XmlElement element, {int depth = 0}) async {
    final name = _getElementText(element, 'name');
    final description = _getElementText(element, 'description');
    final extendedData = _parseExtendedData(element);
    final styleUrl = _getElementText(element, 'styleUrl');

    // Parse direct placemarks in this folder
    final placemarks = <Placemark>[];
    final placemarkElements = element.findElements('Placemark').toList();

    for (final placemarkElement in placemarkElements) {
      try {
        final placemark = await _parsePlacemark(placemarkElement);
        placemarks.add(placemark);
      } catch (e) {
        if (kDebugMode) {
          print('Warning: Failed to parse placemark: $e');
        }
      }
    }

    // Parse sub-folders recursively
    final subFolders = <KmlFolder>[];
    final folderElements = element.findElements('Folder').toList();

    for (final folderElement in folderElements) {
      try {
        final subFolder = await _parseFolder(folderElement, depth: depth + 1);
        subFolders.add(subFolder);
      } catch (e) {
        if (kDebugMode) {
          print('Warning: Failed to parse folder: $e');
        }
      }
    }

    return KmlFolder(
      name:
          name.isNotEmpty ? name : (depth == 0 ? 'Document' : 'Unnamed Folder'),
      description: description,
      placemarks: placemarks,
      subFolders: subFolders,
      extendedData: extendedData,
      styleUrl: styleUrl.isNotEmpty ? styleUrl : null,
      depth: depth,
    );
  }

  // Existing methods (keeping backward compatibility)
  Future<List<Placemark>> _parsePlacemarks(XmlDocument document) async {
    final placemarkElements = document.findAllElements('Placemark');

    if (placemarkElements.isEmpty) {
      throw FileProcessingException(
        'No Placemarks found in KML file',
        code: 'NO_PLACEMARKS',
      );
    }

    final placemarks = <Placemark>[];

    for (final element in placemarkElements) {
      try {
        final placemark = await _parsePlacemark(element);
        placemarks.add(placemark);
      } catch (e) {
        // Log warning but continue processing other placemarks
        if (kDebugMode) {
          print('Warning: Failed to parse placemark: $e');
        }
      }
    }

    if (placemarks.isEmpty) {
      throw FileProcessingException(
        'No valid placemarks could be parsed from the KML file',
        code: 'NO_VALID_PLACEMARKS',
      );
    }

    return placemarks;
  }

  Future<Placemark> _parsePlacemark(XmlElement element) async {
    final name = _getElementText(element, 'name');
    final description = _getElementText(element, 'description');
    final geometry = _parseGeometry(element);
    final extendedData = _parseExtendedData(element);
    final styleUrl = _getElementText(element, 'styleUrl');

    return Placemark(
      name: name,
      description: description,
      geometry: geometry,
      extendedData: extendedData,
      styleUrl: styleUrl.isNotEmpty ? styleUrl : null,
    );
  }

  String _getElementText(XmlElement parent, String tagName) {
    final elements = parent.findElements(tagName);
    return elements.isNotEmpty ? elements.first.innerText.trim() : '';
  }

  Geometry _parseGeometry(XmlElement placemark) {
    // Try Point
    final pointElements = placemark.findElements('Point');
    if (pointElements.isNotEmpty) {
      final coordinates = _parseCoordinatesFromElement(pointElements.first);
      if (coordinates.isNotEmpty) {
        return Geometry.point(coordinates.first);
      }
    }

    // Try LineString
    final lineStringElements = placemark.findElements('LineString');
    if (lineStringElements.isNotEmpty) {
      final coordinates = _parseCoordinatesFromElement(
        lineStringElements.first,
      );
      if (coordinates.isNotEmpty) {
        return Geometry.lineString(coordinates);
      }
    }

    // Try Polygon
    final polygonElements = placemark.findElements('Polygon');
    if (polygonElements.isNotEmpty) {
      final outerRing = polygonElements.first.findElements('outerBoundaryIs');
      if (outerRing.isNotEmpty) {
        final linearRing = outerRing.first.findElements('LinearRing');
        if (linearRing.isNotEmpty) {
          final coordinates = _parseCoordinatesFromElement(linearRing.first);
          if (coordinates.isNotEmpty) {
            return Geometry.polygon(coordinates);
          }
        }
      }
    }

    // Default to empty point if no valid geometry found
    return Geometry.point(const Coordinate(longitude: 0, latitude: 0));
  }

  List<Coordinate> _parseCoordinatesFromElement(XmlElement element) {
    final coordinateElements = element.findElements('coordinates');
    if (coordinateElements.isEmpty) return [];

    return _parseCoordinateString(coordinateElements.first.innerText);
  }

  List<Coordinate> _parseCoordinateString(String coordText) {
    return coordText
        .trim()
        .split(RegExp(r'\s+'))
        .where((coord) => coord.isNotEmpty)
        .map((coord) {
          final parts = coord.split(',');
          if (parts.length >= 2) {
            return Coordinate(
              longitude: double.parse(parts[0]),
              latitude: double.parse(parts[1]),
              elevation: parts.length > 2 ? double.parse(parts[2]) : 0.0,
            );
          }
          return null;
        })
        .where((coord) => coord != null)
        .cast<Coordinate>()
        .toList();
  }

  Map<String, dynamic> _parseExtendedData(XmlElement placemark) {
    final extendedData = <String, dynamic>{};

    final extendedDataElements = placemark.findElements('ExtendedData');
    if (extendedDataElements.isNotEmpty) {
      final dataElements = extendedDataElements.first.findElements('Data');
      for (final data in dataElements) {
        final name = data.getAttribute('name');
        final valueElements = data.findElements('value');
        final value =
            valueElements.isNotEmpty ? valueElements.first.innerText : '';

        if (name != null && name.isNotEmpty) {
          extendedData[name] = value;
        }
      }
    }

    return extendedData;
  }

  List<Coordinate> _extractAllCoordinates(List<Placemark> placemarks) {
    final allCoordinates = <Coordinate>[];

    for (final placemark in placemarks) {
      allCoordinates.addAll(placemark.geometry.coordinates);
    }

    return allCoordinates;
  }

  Set<String> _extractAvailableFields(List<Placemark> placemarks) {
    final fields = <String>{
      'name',
      'description',
      'longitude',
      'latitude',
      'elevation',
    };

    for (final placemark in placemarks) {
      // Add extended data fields
      fields.addAll(placemark.extendedData.keys);

      // Extract fields from description tables
      final tableHeaders = _extractTableHeadersFromDescription(
        placemark.description,
      );
      fields.addAll(tableHeaders);
    }

    // Remove geometry_type as it's not needed in the output
    fields.remove('geometry_type');

    return fields;
  }

  List<String> _extractTableHeadersFromDescription(String description) {
    final headers = <String>[];

    if (!description.contains('<table') && !description.contains('<tr')) {
      return headers;
    }

    try {
      // Parse the HTML content to find tables
      final tables = _extractTablesFromHtml(description);

      for (final tableRows in tables) {
        for (final row in tableRows) {
          if (row.length >= 2) {
            // First cell is the header/key
            final key = row[0].trim();
            if (key.isNotEmpty &&
                !key.toLowerCase().contains('field') &&
                !key.toLowerCase().contains('value') &&
                key.isNotEmpty) {
              headers.add(key);
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Warning: Failed to parse table headers in description: $e');
      }
    }

    return headers;
  }

  /// Extract all tables from HTML content, handling nested tables
  List<List<List<String>>> _extractTablesFromHtml(String html) {
    final tables = <List<List<String>>>[];

    try {
      // Find all table elements
      final tableRegex = RegExp(
        r'<table[^>]*>(.*?)</table>',
        caseSensitive: false,
        dotAll: true,
      );

      final tableMatches = tableRegex.allMatches(html);

      for (final tableMatch in tableMatches) {
        final tableContent = tableMatch.group(1) ?? '';
        final rows = _extractRowsFromTable(tableContent);

        if (rows.isNotEmpty) {
          tables.add(rows);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Warning: Failed to extract tables from HTML: $e');
      }
    }

    return tables;
  }

  /// Extract rows from a table, handling bgcolor and other attributes
  List<List<String>> _extractRowsFromTable(String tableContent) {
    final rows = <List<String>>[];

    try {
      // Find all tr elements, including those with attributes like bgcolor
      final rowRegex = RegExp(
        r'<tr[^>]*>(.*?)</tr>',
        caseSensitive: false,
        dotAll: true,
      );

      final rowMatches = rowRegex.allMatches(tableContent);

      for (final rowMatch in rowMatches) {
        final rowContent = rowMatch.group(1) ?? '';
        final cells = _extractCellsFromRow(rowContent);

        // Only add rows that have exactly 2 cells (key-value pairs)
        if (cells.length == 2 && cells[0].trim().isNotEmpty) {
          rows.add(cells);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Warning: Failed to extract rows from table: $e');
      }
    }

    return rows;
  }

  /// Extract cells from a table row
  List<String> _extractCellsFromRow(String rowContent) {
    final cells = <String>[];

    try {
      // Find all td elements, handling nested content
      final cellRegex = RegExp(
        r'<td[^>]*>(.*?)</td>',
        caseSensitive: false,
        dotAll: true,
      );

      final cellMatches = cellRegex.allMatches(rowContent);

      for (final cellMatch in cellMatches) {
        final cellContent = cellMatch.group(1) ?? '';
        final cleanContent = _stripHtmlTags(cellContent).trim();
        cells.add(cleanContent);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Warning: Failed to extract cells from row: $e');
      }
    }

    return cells;
  }

  String _stripHtmlTags(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll('&nbsp;', ' ') // Replace non-breaking spaces
        .replaceAll('&amp;', '&') // Replace HTML entities
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }

  Map<String, int> _countGeometryTypes(List<Placemark> placemarks) {
    final counts = <String, int>{};

    for (final placemark in placemarks) {
      final type = placemark.geometry.type.value;
      counts[type] = (counts[type] ?? 0) + 1;
    }

    return counts;
  }

  int _countLayers(XmlDocument document) {
    // Count the number of Folder elements as a proxy for layers
    final folders = document.findAllElements('Folder');
    return folders.isNotEmpty ? folders.length : 1;
  }
}
