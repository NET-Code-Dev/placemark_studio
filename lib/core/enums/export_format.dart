enum ExportFormat {
  csv('CSV', 'Comma Separated Values', '.csv'),
  dgn('DGN', 'Microstation DGN V7', '.dgn'),
  dxf('DXF', 'AutoCAD Drawing Interchange Format', '.dxf'),
  esriFileGdb(
    'ESRI File Geodatabase',
    'ESRI File Geodatabase vector (OpenFileGDB)',
    '.gdb',
  ),
  shapefile('Shapefile', 'ESRI Shapefile', '.shp'),
  flatGeobuf('FlatGeobuf', 'FlatGeobuf', '.fgb'),
  gml('GML', 'Geography Markup Language', '.gml'),
  geoPackage('GPKG', 'GeoPackage', '.gpkg'),
  gpx('GPX', 'GPS Exchange Format', '.gpx'),
  geoJson('GeoJSON', 'GeoJSON', '.geojson'),
  geoJsonSeq('GeoJSONSeq', 'GeoJSON Sequence', '.geojsonl'),
  mbTiles('MBTiles', 'MBTiles (MVT - Mapbox Vector Tiles)', '.mbtiles'),
  mvt('MVT', 'Mapbox Vector Tiles (directory based)', ''),
  mapInfoTab('MapInfo TAB', 'MapInfo TAB (binary)', '.tab'),
  ods('ODS', 'Open Document / LibreOffice spreadsheet', '.ods'),
  pdf('PDF', 'Geospatial PDF (GeoPDF)', '.pdf'),
  parquet('Parquet', '(Geo)Parquet', '.parquet'),
  sqlite('SQLite', 'SQLite / SpatiaLite', '.sqlite'),
  svg('SVG', 'Scalable Vector Graphics', '.svg'),
  topoJson('TopoJSON', 'TopoJSON', '.topojson'),
  wkt('WKT', 'Well-Known text (.csv + WKT column)', '.csv'),
  xlsx('XLSX', 'MS Office Open XML spreadsheet', '.xlsx'),
  kml('KML', 'Keyhole Markup Language', '.kml'),
  kmz('KMZ', 'Compressed KML Archive', '.kmz');

  const ExportFormat(this.code, this.description, this.extension);
  final String code;
  final String description;
  final String extension;

  static ExportFormat fromCode(String code) {
    return ExportFormat.values.firstWhere(
      (format) => format.code == code,
      orElse: () => ExportFormat.csv,
    );
  }

  bool get isSupported {
    // For now, only CSV, KML, and KMZ are fully implemented
    return this == ExportFormat.csv ||
        this == ExportFormat.kml ||
        this == ExportFormat.kmz;
  }

  bool get isSupportedForCsvConversion {
    return this == ExportFormat.kml || this == ExportFormat.kmz;
  }

  String get displayName => code;
}
