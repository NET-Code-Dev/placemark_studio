import '../../data/models/placemark.dart';
import '../../data/models/geometry.dart';
import '../../data/models/coordinate.dart';
import '../../core/enums/geometry_type.dart';
//import '../../core/errors/app_exception.dart';
import 'base_viewmodel.dart';

class CreateViewModel extends BaseViewModel {
  final List<Placemark> _placemarks = [];
  Placemark? _currentPlacemark;
  GeometryType _selectedGeometryType = GeometryType.point;

  // Getters
  List<Placemark> get placemarks => List.unmodifiable(_placemarks);
  Placemark? get currentPlacemark => _currentPlacemark;
  GeometryType get selectedGeometryType => _selectedGeometryType;

  bool get hasPlacemarks => _placemarks.isNotEmpty;
  bool get isEditingPlacemark => _currentPlacemark != null;
  int get placemarkCount => _placemarks.length;

  void addPlacemark(Placemark placemark) {
    _placemarks.add(placemark);
    notifyListeners();
  }

  void updatePlacemark(int index, Placemark placemark) {
    if (index >= 0 && index < _placemarks.length) {
      _placemarks[index] = placemark;
      notifyListeners();
    }
  }

  void removePlacemark(int index) {
    if (index >= 0 && index < _placemarks.length) {
      _placemarks.removeAt(index);
      notifyListeners();
    }
  }

  void clearPlacemarks() {
    _placemarks.clear();
    _currentPlacemark = null;
    notifyListeners();
  }

  void startEditingPlacemark(Placemark? placemark) {
    _currentPlacemark = placemark;
    notifyListeners();
  }

  void cancelEditingPlacemark() {
    _currentPlacemark = null;
    notifyListeners();
  }

  void setSelectedGeometryType(GeometryType type) {
    if (_selectedGeometryType != type) {
      _selectedGeometryType = type;
      notifyListeners();
    }
  }

  Placemark createPlacemark({
    required String name,
    required String description,
    required List<Coordinate> coordinates,
    Map<String, dynamic>? extendedData,
  }) {
    Geometry geometry;

    switch (_selectedGeometryType) {
      case GeometryType.point:
        geometry = Geometry.point(
          coordinates.isNotEmpty
              ? coordinates.first
              : const Coordinate(longitude: 0, latitude: 0),
        );
        break;
      case GeometryType.lineString:
        geometry = Geometry.lineString(coordinates);
        break;
      case GeometryType.polygon:
        geometry = Geometry.polygon(coordinates);
        break;
      default:
        geometry = Geometry.point(
          coordinates.isNotEmpty
              ? coordinates.first
              : const Coordinate(longitude: 0, latitude: 0),
        );
    }

    return Placemark(
      name: name,
      description: description,
      geometry: geometry,
      extendedData: extendedData ?? {},
    );
  }

  void savePlacemark({
    required String name,
    required String description,
    required List<Coordinate> coordinates,
    Map<String, dynamic>? extendedData,
  }) {
    try {
      final placemark = createPlacemark(
        name: name,
        description: description,
        coordinates: coordinates,
        extendedData: extendedData,
      );

      if (_currentPlacemark != null) {
        // Update existing placemark
        final index = _placemarks.indexOf(_currentPlacemark!);
        if (index >= 0) {
          updatePlacemark(index, placemark);
        }
      } else {
        // Add new placemark
        addPlacemark(placemark);
      }

      _currentPlacemark = null;
      setSuccess();
    } catch (e) {
      setError('Failed to save placemark: ${e.toString()}');
    }
  }

  Future<String> generateKmlContent() async {
    try {
      setLoading();

      final buffer = StringBuffer();
      buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
      buffer.writeln('<kml xmlns="http://www.opengis.net/kml/2.2">');
      buffer.writeln('  <Document>');
      buffer.writeln('    <name>Created with Placemark Studio</name>');

      for (final placemark in _placemarks) {
        buffer.writeln('    <Placemark>');
        buffer.writeln('      <name>${_escapeXml(placemark.name)}</name>');
        buffer.writeln(
          '      <description>${_escapeXml(placemark.description)}</description>',
        );

        // Add geometry
        _writeGeometry(buffer, placemark.geometry);

        // Add extended data if present
        if (placemark.extendedData.isNotEmpty) {
          buffer.writeln('      <ExtendedData>');
          for (final entry in placemark.extendedData.entries) {
            buffer.writeln('        <Data name="${_escapeXml(entry.key)}">');
            buffer.writeln(
              '          <value>${_escapeXml(entry.value.toString())}</value>',
            );
            buffer.writeln('        </Data>');
          }
          buffer.writeln('      </ExtendedData>');
        }

        buffer.writeln('    </Placemark>');
      }

      buffer.writeln('  </Document>');
      buffer.writeln('</kml>');

      setSuccess();
      return buffer.toString();
    } catch (e) {
      setError('Failed to generate KML content: ${e.toString()}');
      rethrow;
    }
  }

  void _writeGeometry(StringBuffer buffer, Geometry geometry) {
    switch (geometry.type) {
      case GeometryType.point:
        buffer.writeln('      <Point>');
        buffer.writeln(
          '        <coordinates>${_formatCoordinates(geometry.coordinates)}</coordinates>',
        );
        buffer.writeln('      </Point>');
        break;
      case GeometryType.lineString:
        buffer.writeln('      <LineString>');
        buffer.writeln(
          '        <coordinates>${_formatCoordinates(geometry.coordinates)}</coordinates>',
        );
        buffer.writeln('      </LineString>');
        break;
      case GeometryType.polygon:
        buffer.writeln('      <Polygon>');
        buffer.writeln('        <outerBoundaryIs>');
        buffer.writeln('          <LinearRing>');
        buffer.writeln(
          '            <coordinates>${_formatCoordinates(geometry.coordinates)}</coordinates>',
        );
        buffer.writeln('          </LinearRing>');
        buffer.writeln('        </outerBoundaryIs>');
        buffer.writeln('      </Polygon>');
        break;
      default:
        // Default to point
        buffer.writeln('      <Point>');
        buffer.writeln('        <coordinates>0,0,0</coordinates>');
        buffer.writeln('      </Point>');
    }
  }

  String _formatCoordinates(List<Coordinate> coordinates) {
    return coordinates
        .map(
          (coord) => '${coord.longitude},${coord.latitude},${coord.elevation}',
        )
        .join(' ');
  }

  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
