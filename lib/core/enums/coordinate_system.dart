enum CoordinateSystem {
  wgs84('WGS84'),
  nad83('NAD83'),
  nad27('NAD27');

  const CoordinateSystem(this.value);
  final String value;

  static CoordinateSystem fromString(String value) {
    return CoordinateSystem.values.firstWhere(
      (system) => system.value == value,
      orElse: () => CoordinateSystem.wgs84,
    );
  }
}
