import '../models/bounding_box.dart';
import '../models/coordinate.dart';
import '../models/kml_data.dart';

abstract class IBoundingBoxService {
  BoundingBox calculateBoundingBox(List<Coordinate> coordinates);
  Map<String, dynamic> getBoundingBoxInfo(KmlData kmlData);
}

class BoundingBoxService implements IBoundingBoxService {
  @override
  BoundingBox calculateBoundingBox(List<Coordinate> coordinates) {
    return BoundingBox.fromCoordinates(coordinates);
  }

  @override
  Map<String, dynamic> getBoundingBoxInfo(KmlData kmlData) {
    final bbox = kmlData.boundingBox;

    return {
      'northWest': {
        'longitude': bbox.northWest.longitude,
        'latitude': bbox.northWest.latitude,
      },
      'northEast': {
        'longitude': bbox.northEast.longitude,
        'latitude': bbox.northEast.latitude,
      },
      'southWest': {
        'longitude': bbox.southWest.longitude,
        'latitude': bbox.southWest.latitude,
      },
      'southEast': {
        'longitude': bbox.southEast.longitude,
        'latitude': bbox.southEast.latitude,
      },
      'center': {
        'longitude': bbox.center.longitude,
        'latitude': bbox.center.latitude,
      },
      'width': bbox.width,
      'height': bbox.height,
    };
  }
}
