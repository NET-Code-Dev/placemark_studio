import 'package:equatable/equatable.dart';
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

    double minLon = coordinates.first.longitude;
    double maxLon = coordinates.first.longitude;
    double minLat = coordinates.first.latitude;
    double maxLat = coordinates.first.latitude;

    for (final coord in coordinates) {
      minLon = coord.longitude < minLon ? coord.longitude : minLon;
      maxLon = coord.longitude > maxLon ? coord.longitude : maxLon;
      minLat = coord.latitude < minLat ? coord.latitude : minLat;
      maxLat = coord.latitude > maxLat ? coord.latitude : maxLat;
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
