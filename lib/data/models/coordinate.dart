import 'package:equatable/equatable.dart';

class Coordinate extends Equatable {
  final double longitude;
  final double latitude;
  final double elevation;

  const Coordinate({
    required this.longitude,
    required this.latitude,
    this.elevation = 0.0,
  });

  factory Coordinate.fromList(List<double> coords) {
    return Coordinate(
      longitude: coords[0],
      latitude: coords[1],
      elevation: coords.length > 2 ? coords[2] : 0.0,
    );
  }

  Coordinate copyWith({
    double? longitude,
    double? latitude,
    double? elevation,
  }) {
    return Coordinate(
      longitude: longitude ?? this.longitude,
      latitude: latitude ?? this.latitude,
      elevation: elevation ?? this.elevation,
    );
  }

  @override
  List<Object?> get props => [longitude, latitude, elevation];

  @override
  String toString() => '($longitude, $latitude, $elevation)';
}
