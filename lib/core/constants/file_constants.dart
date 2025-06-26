class FileConstants {
  static const Map<String, String> mimeTypes = {
    'kml': 'application/vnd.google-earth.kml+xml',
    'csv': 'text/csv',
    'json': 'application/json',
    'geojson': 'application/geo+json',
    'gpx': 'application/gpx+xml',
    'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  };

  static const Map<String, String> fileDescriptions = {
    'kml': 'Keyhole Markup Language',
    'csv': 'Comma Separated Values',
    'json': 'JavaScript Object Notation',
    'geojson': 'Geographic JavaScript Object Notation',
    'gpx': 'GPS Exchange Format',
    'xlsx': 'Microsoft Excel Spreadsheet',
  };
}
