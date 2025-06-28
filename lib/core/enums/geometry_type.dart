enum GeometryType {
  point('Point'),
  lineString('LineString'),
  linearRing('LinearRing'),
  polygon('Polygon'),
  multiGeometry('MultiGeometry'),
  model('Model');

  const GeometryType(this.value);
  final String value;

  static GeometryType fromString(String value) {
    return GeometryType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => GeometryType.point,
    );
  }

  // NEW: Additional properties for CSV converter
  String get displayName {
    switch (this) {
      case GeometryType.point:
        return 'Point';
      case GeometryType.lineString:
        return 'LineString';
      case GeometryType.linearRing:
        return 'LinearRing';
      case GeometryType.polygon:
        return 'Polygon';
      case GeometryType.multiGeometry:
        return 'MultiGeometry';
      case GeometryType.model:
        return 'Model';
    }
  }

  String get description {
    switch (this) {
      case GeometryType.point:
        return 'Individual points/placemarks';
      case GeometryType.lineString:
        return 'Connected paths/routes';
      case GeometryType.linearRing:
        return 'Closed linear rings';
      case GeometryType.polygon:
        return 'Closed areas/regions';
      case GeometryType.multiGeometry:
        return 'Multiple geometry collection';
      case GeometryType.model:
        return '3D models';
    }
  }

  // NEW: Check if geometry type is supported for CSV conversion
  bool get isSupportedForCsvConversion {
    switch (this) {
      case GeometryType.point:
      case GeometryType.lineString:
      case GeometryType.polygon:
        return true;
      case GeometryType.linearRing:
      case GeometryType.multiGeometry:
      case GeometryType.model:
        return false;
    }
  }

  // NEW: Get the KML element name for generation
  String get kmlElementName => value;
}
