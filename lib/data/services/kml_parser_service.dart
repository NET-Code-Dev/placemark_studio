import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';
import '../../core/errors/app_exception.dart';
//import '../../core/enums/geometry_type.dart';
import '../models/kml_data.dart';
import '../models/placemark.dart';
import '../models/geometry.dart';
import '../models/coordinate.dart';
import '../models/bounding_box.dart';

abstract class IKmlParserService {
  Future<KmlData> parseKmlFile(File file);
}

class KmlParserService implements IKmlParserService {
  @override
  Future<KmlData> parseKmlFile(File file) async {
    try {
      final content = await file.readAsString();
      final document = XmlDocument.parse(content);
      final stat = await file.stat();

      final placemarks = await _parsePlacemarks(document);
      final allCoordinates = _extractAllCoordinates(placemarks);
      final boundingBox = BoundingBox.fromCoordinates(allCoordinates);
      final availableFields = _extractAvailableFields(placemarks);
      final geometryTypeCounts = _countGeometryTypes(placemarks);

      return KmlData(
        fileName: file.path.split('/').last,
        fileSize: stat.size,
        placemarks: placemarks,
        boundingBox: boundingBox,
        availableFields: availableFields,
        geometryTypeCounts: geometryTypeCounts,
        layersCount: _countLayers(document),
      );
    } catch (e) {
      if (e is AppException) rethrow;

      throw FileProcessingException(
        'Failed to parse KML file: ${e.toString()}',
        code: 'KML_PARSE_ERROR',
        details: e,
      );
    }
  }

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
      // Simple HTML table parsing - look for table row patterns
      final rows = description.split('<tr');

      for (final row in rows) {
        if (!row.contains('<td') && !row.contains('<th')) continue;

        final cells = _extractTableCellsFromRow(row);
        if (cells.length >= 2) {
          // Assume first cell is header/key
          final key = cells[0].trim();
          if (key.isNotEmpty &&
              !key.toLowerCase().contains('field') &&
              !key.toLowerCase().contains('value')) {
            headers.add(key);
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

  List<String> _extractTableCellsFromRow(String row) {
    final cells = <String>[];

    // Extract content between <td> or <th> tags
    final cellRegex = RegExp(
      r'<t[dh][^>]*>(.*?)</t[dh]>',
      caseSensitive: false,
      dotAll: true,
    );
    final matches = cellRegex.allMatches(row);

    for (final match in matches) {
      final cellContent = match.group(1) ?? '';
      final cleanContent = _stripHtmlTags(cellContent).trim();
      cells.add(cleanContent);
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
