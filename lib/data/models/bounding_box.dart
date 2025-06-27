import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'coordinate.dart';

class BoundingBox extends Equatable {
  final Coordinate northWest;
  final Coordinate northEast;
  final Coordinate southWest;
  final Coordinate southEast;

  const BoundingBox({
    required this.northWest,
    required this.northEast,
    required this.southWest,
    required this.southEast,
  });

  factory BoundingBox.fromCoordinates(List<Coordinate> coordinates) {
    if (coordinates.isEmpty) {
      const zero = Coordinate(longitude: 0, latitude: 0);
      return const BoundingBox(
        northWest: zero,
        northEast: zero,
        southWest: zero,
        southEast: zero,
      );
    }

    // Filter out invalid coordinates including 0.0 values (which are often placeholders)
    final validCoordinates =
        coordinates.where((coord) {
          return !coord.longitude.isNaN &&
              !coord.latitude.isNaN &&
              coord.longitude >= -180 &&
              coord.longitude <= 180 &&
              coord.latitude >= -90 &&
              coord.latitude <= 90 &&
              !(coord.longitude == 0.0 &&
                  coord.latitude ==
                      0.0); // Filter out (0,0) which is often invalid
        }).toList();

    if (validCoordinates.isEmpty) {
      print('WARNING: No valid coordinates found after filtering');
      const zero = Coordinate(longitude: 0, latitude: 0);
      return const BoundingBox(
        northWest: zero,
        northEast: zero,
        southWest: zero,
        southEast: zero,
      );
    }

    // Initialize with the first valid coordinate
    double minLon = validCoordinates.first.longitude;
    double maxLon = validCoordinates.first.longitude;
    double minLat = validCoordinates.first.latitude;
    double maxLat = validCoordinates.first.latitude;

    // Find the actual min/max values from valid coordinates only
    for (final coord in validCoordinates) {
      if (coord.longitude < minLon) minLon = coord.longitude;
      if (coord.longitude > maxLon) maxLon = coord.longitude;
      if (coord.latitude < minLat) minLat = coord.latitude;
      if (coord.latitude > maxLat) maxLat = coord.latitude;
    }

    // Debug output
    if (kDebugMode) {
      print('=== BOUNDING BOX CALCULATION DEBUG ===');

      print('Total coordinates: ${coordinates.length}');
      print('Valid coordinates after filtering: ${validCoordinates.length}');
      print(
        'Filtered out: ${coordinates.length - validCoordinates.length} invalid coordinates',
      );
      print('Min Longitude: $minLon, Max Longitude: $maxLon');
      print('Min Latitude: $minLat, Max Latitude: $maxLat');
      print('Calculated corners:');
      print('  NW: $maxLat, $minLon');
      print('  NE: $maxLat, $maxLon');
      print('  SW: $minLat, $minLon');
      print('  SE: $minLat, $maxLon');
      print('=====================================');
    }
    return BoundingBox(
      northWest: Coordinate(longitude: minLon, latitude: maxLat),
      northEast: Coordinate(longitude: maxLon, latitude: maxLat),
      southWest: Coordinate(longitude: minLon, latitude: minLat),
      southEast: Coordinate(longitude: maxLon, latitude: minLat),
    );
  }

  double get width => northEast.longitude - northWest.longitude;
  double get height => northWest.latitude - southWest.latitude;

  Coordinate get center => Coordinate(
    longitude: (northWest.longitude + northEast.longitude) / 2,
    latitude: (northWest.latitude + southWest.latitude) / 2,
  );

  @override
  List<Object?> get props => [northWest, northEast, southWest, southEast];
}
