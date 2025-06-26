import 'package:equatable/equatable.dart';
import '../../core/enums/coordinate_system.dart';
import '../../core/enums/coordinate_reference_system.dart';
import '../../core/enums/coordinate_units.dart';
import 'coordinate.dart';
import 'placemark.dart';
import 'bounding_box.dart';

class KmlData extends Equatable {
  final String fileName;
  final int fileSize;
  final List<Placemark> placemarks;
  final BoundingBox boundingBox;
  final CoordinateSystem coordinateSystem;
  final CoordinateReferenceSystem coordinateReferenceSystem;
  final CoordinateUnits coordinateUnits;
  final int layersCount;
  final Map<String, int> geometryTypeCounts;
  final Set<String> availableFields;

  const KmlData({
    required this.fileName,
    required this.fileSize,
    required this.placemarks,
    required this.boundingBox,
    this.coordinateSystem = CoordinateSystem.wgs84,
    this.coordinateReferenceSystem = CoordinateReferenceSystem.epsg4326,
    this.coordinateUnits = CoordinateUnits.dd,
    this.layersCount = 1,
    this.geometryTypeCounts = const {},
    this.availableFields = const {},
  });

  factory KmlData.empty() {
    const zero = Coordinate(longitude: 0, latitude: 0);
    return const KmlData(
      fileName: '',
      fileSize: 0,
      placemarks: [],
      boundingBox: BoundingBox(
        northWest: zero,
        northEast: zero,
        southWest: zero,
        southEast: zero,
      ),
    );
  }

  int get featuresCount => placemarks.length;

  bool get hasData => placemarks.isNotEmpty;

  KmlData copyWith({
    String? fileName,
    int? fileSize,
    List<Placemark>? placemarks,
    BoundingBox? boundingBox,
    CoordinateSystem? coordinateSystem,
    CoordinateReferenceSystem? coordinateReferenceSystem,
    CoordinateUnits? coordinateUnits,
    int? layersCount,
    Map<String, int>? geometryTypeCounts,
    Set<String>? availableFields,
  }) {
    return KmlData(
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      placemarks: placemarks ?? this.placemarks,
      boundingBox: boundingBox ?? this.boundingBox,
      coordinateSystem: coordinateSystem ?? this.coordinateSystem,
      coordinateReferenceSystem:
          coordinateReferenceSystem ?? this.coordinateReferenceSystem,
      coordinateUnits: coordinateUnits ?? this.coordinateUnits,
      layersCount: layersCount ?? this.layersCount,
      geometryTypeCounts: geometryTypeCounts ?? this.geometryTypeCounts,
      availableFields: availableFields ?? this.availableFields,
    );
  }

  @override
  List<Object?> get props => [
    fileName,
    fileSize,
    placemarks,
    boundingBox,
    coordinateSystem,
    coordinateReferenceSystem,
    coordinateUnits,
    layersCount,
    geometryTypeCounts,
    availableFields,
  ];
}
