import 'package:equatable/equatable.dart';
import 'coordinate.dart';
import 'geometry.dart';

class Placemark extends Equatable {
  final String name;
  final String description;
  final Geometry geometry;
  final Map<String, dynamic> extendedData;
  final String? styleUrl;

  const Placemark({
    required this.name,
    required this.description,
    required this.geometry,
    this.extendedData = const {},
    this.styleUrl,
  });

  factory Placemark.empty() {
    return Placemark(
      name: '',
      description: '',
      geometry: Geometry.point(const Coordinate(longitude: 0, latitude: 0)),
      extendedData: const {},
    );
  }

  Placemark copyWith({
    String? name,
    String? description,
    Geometry? geometry,
    Map<String, dynamic>? extendedData,
    String? styleUrl,
  }) {
    return Placemark(
      name: name ?? this.name,
      description: description ?? this.description,
      geometry: geometry ?? this.geometry,
      extendedData: extendedData ?? this.extendedData,
      styleUrl: styleUrl ?? this.styleUrl,
    );
  }

  @override
  List<Object?> get props => [
    name,
    description,
    geometry,
    extendedData,
    styleUrl,
  ];
}
