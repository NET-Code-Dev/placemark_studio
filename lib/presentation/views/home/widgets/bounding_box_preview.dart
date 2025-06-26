import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/home_viewmodel.dart';
import '../../../../data/models/bounding_box.dart';
import '../../../../data/models/coordinate.dart';

class BoundingBoxPreview extends StatelessWidget {
  const BoundingBoxPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        if (!viewModel.hasKmlData) {
          return const SizedBox.shrink();
        }

        final boundingBox = viewModel.kmlData!.boundingBox;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Bounding Box Preview',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _BoundingBoxMap(boundingBox: boundingBox),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: _BoundingBoxCoordinates(boundingBox: boundingBox),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BoundingBoxMap extends StatelessWidget {
  final BoundingBox boundingBox;

  const _BoundingBoxMap({required this.boundingBox});

  @override
  Widget build(BuildContext context) {
    const mapHeight = 160.0;

    return Container(
      height: mapHeight,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            _StaticMap(boundingBox: boundingBox),
            CustomPaint(
              painter: _BoundingBoxOverlayPainter(
                boundingBox: boundingBox,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            _CoordinatesOverlay(boundingBox: boundingBox),
          ],
        ),
      ),
    );
  }
}

class _StaticMap extends StatelessWidget {
  final BoundingBox boundingBox;

  const _StaticMap({required this.boundingBox});

  @override
  Widget build(BuildContext context) {
    final center = boundingBox.center;

    final latSpan = boundingBox.height;
    final lonSpan = boundingBox.width;
    final maxSpan = latSpan > lonSpan ? latSpan : lonSpan;

    int zoom = 10;
    if (maxSpan > 10) {
      zoom = 4;
    } else if (maxSpan > 5) {
      zoom = 6;
    } else if (maxSpan > 2) {
      zoom = 8;
    } else if (maxSpan > 1) {
      zoom = 10;
    } else if (maxSpan > 0.5) {
      zoom = 12;
    } else if (maxSpan > 0.1) {
      zoom = 14;
    } else {
      zoom = 16;
    }

    final mapUrl =
        'https://tile.openstreetmap.org/$zoom/${_lonToTileX(center.longitude, zoom)}/${_latToTileY(center.latitude, zoom)}.png';

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            image: const DecorationImage(
              image: NetworkImage(
                'https://via.placeholder.com/400x200/e0e0e0/9e9e9e?text=Loading+Map',
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Image.network(
          mapUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map, size: 24, color: Colors.grey[600]),
                    const SizedBox(height: 4),
                    Text(
                      'Map Preview',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${center.latitude.toStringAsFixed(4)}, ${center.longitude.toStringAsFixed(4)}',
                      style: TextStyle(fontSize: 8, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey[100],
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value:
                        loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  int _lonToTileX(double lon, int zoom) {
    return ((lon + 180.0) / 360.0 * (1 << zoom)).floor();
  }

  int _latToTileY(double lat, int zoom) {
    final latRad = lat * 3.14159265359 / 180.0;
    return ((1.0 -
                (math.log(math.tan(latRad) + (1 / math.cos(latRad))) /
                    3.14159265359)) /
            2.0 *
            (1 << zoom))
        .floor();
  }
}

class _BoundingBoxOverlayPainter extends CustomPainter {
  final BoundingBox boundingBox;
  final Color color;

  _BoundingBoxOverlayPainter({required this.boundingBox, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    final fillPaint =
        Paint()
          ..color = color.withOpacity(0.15)
          ..style = PaintingStyle.fill;

    final padding = 15.0;
    final rect = Rect.fromLTWH(
      padding,
      padding,
      size.width - (padding * 2),
      size.height - (padding * 2),
    );

    canvas.drawRect(rect, fillPaint);
    canvas.drawRect(rect, strokePaint);

    final pointPaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    const pointRadius = 3.0;

    canvas.drawCircle(rect.topLeft, pointRadius, pointPaint);
    canvas.drawCircle(rect.topRight, pointRadius, pointPaint);
    canvas.drawCircle(rect.bottomLeft, pointRadius, pointPaint);
    canvas.drawCircle(rect.bottomRight, pointRadius, pointPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CoordinatesOverlay extends StatelessWidget {
  final BoundingBox boundingBox;

  const _CoordinatesOverlay({required this.boundingBox});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: 4,
            left: 4,
            child: _CoordinateLabel(
              coordinate: boundingBox.northWest,
              label: 'NW',
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: _CoordinateLabel(
              coordinate: boundingBox.northEast,
              label: 'NE',
            ),
          ),
          Positioned(
            bottom: 4,
            left: 4,
            child: _CoordinateLabel(
              coordinate: boundingBox.southWest,
              label: 'SW',
            ),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: _CoordinateLabel(
              coordinate: boundingBox.southEast,
              label: 'SE',
            ),
          ),
        ],
      ),
    );
  }
}

class _CoordinateLabel extends StatelessWidget {
  final Coordinate coordinate;
  final String label;

  const _CoordinateLabel({required this.coordinate, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        '$label\n${coordinate.latitude.toStringAsFixed(2)}\n${coordinate.longitude.toStringAsFixed(2)}',
        style: const TextStyle(color: Colors.white, fontSize: 7, height: 1.1),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _BoundingBoxCoordinates extends StatelessWidget {
  final BoundingBox boundingBox;

  const _BoundingBoxCoordinates({required this.boundingBox});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall;
    final labelStyle = textStyle?.copyWith(fontWeight: FontWeight.w600);

    return SizedBox(
      height: 160,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Coordinates:', style: labelStyle),
            const SizedBox(height: 6),
            _CoordinateItem(
              label: 'North-West',
              coordinate: boundingBox.northWest,
              textStyle: textStyle,
            ),
            _CoordinateItem(
              label: 'North-East',
              coordinate: boundingBox.northEast,
              textStyle: textStyle,
            ),
            _CoordinateItem(
              label: 'South-West',
              coordinate: boundingBox.southWest,
              textStyle: textStyle,
            ),
            _CoordinateItem(
              label: 'South-East',
              coordinate: boundingBox.southEast,
              textStyle: textStyle,
            ),
            const SizedBox(height: 6),
            Text('Dimensions:', style: labelStyle),
            const SizedBox(height: 3),
            Text(
              'Width: ${boundingBox.width.toStringAsFixed(4)}°',
              style: textStyle,
            ),
            Text(
              'Height: ${boundingBox.height.toStringAsFixed(4)}°',
              style: textStyle,
            ),
            const SizedBox(height: 3),
            Text(
              'Center: ${boundingBox.center.longitude.toStringAsFixed(4)}°, ${boundingBox.center.latitude.toStringAsFixed(4)}°',
              style: textStyle,
            ),
            const SizedBox(height: 6),
            Text('Coverage:', style: labelStyle),
            const SizedBox(height: 3),
            Text(
              _getAreaDescription(boundingBox.width, boundingBox.height),
              style: textStyle,
            ),
          ],
        ),
      ),
    );
  }

  String _getAreaDescription(double width, double height) {
    final area = width * height;
    if (area > 100) return 'Large region (${area.toStringAsFixed(1)}° sq)';
    if (area > 10) return 'Medium region (${area.toStringAsFixed(1)}° sq)';
    if (area > 1) return 'Small region (${area.toStringAsFixed(2)}° sq)';
    if (area > 0.01) return 'Local area (${area.toStringAsFixed(3)}° sq)';
    return 'Very local area (${area.toStringAsFixed(4)}° sq)';
  }
}

class _CoordinateItem extends StatelessWidget {
  final String label;
  final Coordinate coordinate;
  final TextStyle? textStyle;

  const _CoordinateItem({
    required this.label,
    required this.coordinate,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Text(
        '$label: ${coordinate.longitude.toStringAsFixed(4)}°, ${coordinate.latitude.toStringAsFixed(4)}°',
        style: textStyle?.copyWith(fontSize: 11),
      ),
    );
  }
}
