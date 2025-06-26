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
}
