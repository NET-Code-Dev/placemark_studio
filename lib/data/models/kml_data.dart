import 'package:equatable/equatable.dart';
import '../../core/enums/coordinate_system.dart';
import '../../core/enums/coordinate_reference_system.dart';
import '../../core/enums/coordinate_units.dart';
import 'coordinate.dart';
import 'placemark.dart';
import 'bounding_box.dart';
import 'kml_folder.dart'; // Add this import

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
  final KmlFolder? folderStructure; // Add optional folder structure

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
    this.folderStructure, // Add this parameter
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

  // Enhanced getters that consider folder structure
  int get featuresCount =>
      hasHierarchy
          ? folderStructure!.getTotalPlacemarkCount()
          : placemarks.length;

  bool get hasData =>
      hasHierarchy ? folderStructure!.hasPlacemarks : placemarks.isNotEmpty;

  // New hierarchy-related getters
  bool get hasHierarchy => folderStructure != null;

  List<Placemark> get allPlacemarks =>
      hasHierarchy ? folderStructure!.getAllPlacemarks() : placemarks;

  int get maxFolderDepth => hasHierarchy ? folderStructure!.getMaxDepth() : 0;

  int get totalFolderCount =>
      hasHierarchy ? folderStructure!.getTotalFolderCount() : layersCount;

  /// Get a summary of the folder structure
  Map<String, dynamic> get folderSummary =>
      hasHierarchy
          ? {
            'hasHierarchy': true,
            'maxDepth': maxFolderDepth,
            'totalFolders': totalFolderCount,
            'folderPaths': folderStructure!.getAllFolderPaths(),
            'rootFolder': folderStructure!.getSummary(),
          }
          : {
            'hasHierarchy': false,
            'maxDepth': 0,
            'totalFolders': layersCount,
            'folderPaths': <String>[],
          };

  /// Get folders at a specific depth level
  List<KmlFolder> getFoldersAtDepth(int depth) {
    return hasHierarchy ? folderStructure!.getFoldersAtDepth(depth) : [];
  }

  /// Find a folder by its path
  KmlFolder? findFolderByPath(String path) {
    return hasHierarchy ? folderStructure!.findFolderByPath(path) : null;
  }

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
    KmlFolder? folderStructure, // Add this parameter
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
      folderStructure: folderStructure ?? this.folderStructure, // Add this
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
    folderStructure, // Add this to props
  ];
}
