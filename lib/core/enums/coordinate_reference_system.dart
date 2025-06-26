enum CoordinateReferenceSystem {
  epsg4326('EPSG:4326', 'WGS 84'),
  epsg3857('EPSG:3857', 'WGS 84 / Pseudo-Mercator'),
  crs84('CRS:84', 'WGS 84 longitude-latitude');

  const CoordinateReferenceSystem(this.code, this.description);
  final String code;
  final String description;

  static CoordinateReferenceSystem fromCode(String code) {
    return CoordinateReferenceSystem.values.firstWhere(
      (crs) => crs.code == code,
      orElse: () => CoordinateReferenceSystem.epsg4326,
    );
  }
}
