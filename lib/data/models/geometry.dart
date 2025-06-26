import 'package:equatable/equatable.dart';
import '../../core/enums/geometry_type.dart';
import 'coordinate.dart';

class Geometry extends Equatable {
  final GeometryType type;
  final List<Coordinate> coordinates;

  const Geometry({required this.type, required this.coordinates});

  factory Geometry.point(Coordinate coordinate) {
    return Geometry(type: GeometryType.point, coordinates: [coordinate]);
  }

  factory Geometry.lineString(List<Coordinate> coordinates) {
    return Geometry(type: GeometryType.lineString, coordinates: coordinates);
  }

  factory Geometry.polygon(List<Coordinate> coordinates) {
    return Geometry(type: GeometryType.polygon, coordinates: coordinates);
  }

  Coordinate? get firstCoordinate =>
      coordinates.isNotEmpty ? coordinates.first : null;

  @override
  List<Object?> get props => [type, coordinates];
}
