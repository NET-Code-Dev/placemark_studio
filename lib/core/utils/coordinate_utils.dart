import 'dart:math' as math;
import '../enums/coordinate_units.dart';
import '../../data/models/coordinate.dart';

class CoordinateUtils {
  static String formatCoordinate(double value, CoordinateUnits units) {
    switch (units) {
      case CoordinateUnits.dd:
        return value.toStringAsFixed(6);
      case CoordinateUnits.dms:
        return _formatDMS(value);
      case CoordinateUnits.dmm:
        return _formatDMM(value);
    }
  }

  static String _formatDMS(double decimal) {
    final degrees = decimal.floor();
    final minutesDecimal = (decimal - degrees) * 60;
    final minutes = minutesDecimal.floor();
    final seconds = (minutesDecimal - minutes) * 60;

    return '$degrees°$minutes\'${seconds.toStringAsFixed(2)}"';
  }

  static String _formatDMM(double decimal) {
    final degrees = decimal.floor();
    final minutesDecimal = (decimal - degrees) * 60;

    return '$degrees°${minutesDecimal.toStringAsFixed(4)}\'';
  }

  static double distanceKm(Coordinate point1, Coordinate point2) {
    const double earthRadius = 6371; // km

    final lat1Rad = point1.latitude * (3.14159 / 180);
    final lat2Rad = point2.latitude * (3.14159 / 180);
    final deltaLatRad = (point2.latitude - point1.latitude) * (3.14159 / 180);
    final deltaLonRad = (point2.longitude - point1.longitude) * (3.14159 / 180);

    final a =
        math.pow(math.sin(deltaLatRad / 2), 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.pow(math.sin(deltaLonRad / 2), 2);
    final c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  static bool isValidLatitude(double latitude) {
    return latitude >= -90 && latitude <= 90;
  }

  static bool isValidLongitude(double longitude) {
    return longitude >= -180 && longitude <= 180;
  }

  static Coordinate clampCoordinate(Coordinate coord) {
    return Coordinate(
      longitude: coord.longitude.clamp(-180.0, 180.0),
      latitude: coord.latitude.clamp(-90.0, 90.0),
      elevation: coord.elevation,
    );
  }
}
