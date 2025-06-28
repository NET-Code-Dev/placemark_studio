import 'dart:math' as math;
import 'package:flutter/foundation.dart';
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
              children: [
                Text(
                  'Bounding Box Preview',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _InteractiveBoundingBoxMap(
                          boundingBox: boundingBox,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: _BoundingBoxCoordinates(
                          boundingBox: boundingBox,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InteractiveBoundingBoxMap extends StatefulWidget {
  final BoundingBox boundingBox;

  const _InteractiveBoundingBoxMap({required this.boundingBox});

  @override
  State<_InteractiveBoundingBoxMap> createState() =>
      _InteractiveBoundingBoxMapState();
}

class _InteractiveBoundingBoxMapState
    extends State<_InteractiveBoundingBoxMap> {
  late int _currentZoom;
  late Coordinate _center;
  bool _isLoading = false;
  MapType _currentMapType = MapType.streets;

  @override
  void initState() {
    super.initState();
    // Debug: Print the bounding box values
    if (kDebugMode) {
      print('=== BOUNDING BOX DEBUG ===');

      print(
        'North-West: ${widget.boundingBox.northWest.latitude}, ${widget.boundingBox.northWest.longitude}',
      );
      print(
        'North-East: ${widget.boundingBox.northEast.latitude}, ${widget.boundingBox.northEast.longitude}',
      );
      print(
        'South-West: ${widget.boundingBox.southWest.latitude}, ${widget.boundingBox.southWest.longitude}',
      );
      print(
        'South-East: ${widget.boundingBox.southEast.latitude}, ${widget.boundingBox.southEast.longitude}',
      );
      print(
        'Center: ${widget.boundingBox.center.latitude}, ${widget.boundingBox.center.longitude}',
      );
      print(
        'Width: ${widget.boundingBox.width}°, Height: ${widget.boundingBox.height}°',
      );
      print('========================');
    }
    // Calculate center more reliably
    final centerLat =
        (widget.boundingBox.northWest.latitude +
            widget.boundingBox.southEast.latitude) /
        2;
    final centerLon =
        (widget.boundingBox.northWest.longitude +
            widget.boundingBox.southEast.longitude) /
        2;

    // Validate coordinates
    if (centerLat.isNaN ||
        centerLon.isNaN ||
        centerLat < -90 ||
        centerLat > 90 ||
        centerLon < -180 ||
        centerLon > 180) {
      if (kDebugMode) {
        print('WARNING: Invalid center coordinates, using fallback');
      }
      _center = const Coordinate(longitude: 0, latitude: 0);
    } else {
      _center = Coordinate(longitude: centerLon, latitude: centerLat);
    }

    _currentZoom = _calculateOptimalZoom();
  }

  int _calculateOptimalZoom() {
    final latSpan = widget.boundingBox.height;
    final lonSpan = widget.boundingBox.width;
    final maxSpan = math.max(latSpan, lonSpan);

    // Calculate zoom to fit the bounding box with some padding
    if (maxSpan > 20) return 3;
    if (maxSpan > 10) return 4;
    if (maxSpan > 5) return 5;
    if (maxSpan > 2) return 6;
    if (maxSpan > 1) return 7;
    if (maxSpan > 0.5) return 8;
    if (maxSpan > 0.25) return 9;
    if (maxSpan > 0.1) return 10;
    if (maxSpan > 0.05) return 11;
    return 12;
  }

  void _zoomIn() {
    if (_currentZoom < 18) {
      setState(() {
        _currentZoom++;
        _isLoading = true;
      });
      _finishLoading();
    }
  }

  void _zoomOut() {
    if (_currentZoom > 1) {
      setState(() {
        _currentZoom--;
        _isLoading = true;
      });
      _finishLoading();
    }
  }

  void _resetView() {
    // Calculate center more robustly for reset
    final centerLat =
        (widget.boundingBox.northWest.latitude +
            widget.boundingBox.southEast.latitude) /
        2;
    final centerLon =
        (widget.boundingBox.northWest.longitude +
            widget.boundingBox.southEast.longitude) /
        2;

    setState(() {
      _center = Coordinate(longitude: centerLon, latitude: centerLat);
      _currentZoom = _calculateOptimalZoom();
      _isLoading = true;
    });
    _finishLoading();
  }

  void _centerOnBoundingBox() {
    // Calculate center more robustly
    final centerLat =
        (widget.boundingBox.northWest.latitude +
            widget.boundingBox.southEast.latitude) /
        2;
    final centerLon =
        (widget.boundingBox.northWest.longitude +
            widget.boundingBox.southEast.longitude) /
        2;

    if (kDebugMode) {
      print('=== CENTER CALCULATION ===');

      print(
        'NW: ${widget.boundingBox.northWest.latitude}, ${widget.boundingBox.northWest.longitude}',
      );
      print(
        'SE: ${widget.boundingBox.southEast.latitude}, ${widget.boundingBox.southEast.longitude}',
      );
      print('Calculated Center: $centerLat, $centerLon');
      print(
        'BoundingBox Center: ${widget.boundingBox.center.latitude}, ${widget.boundingBox.center.longitude}',
      );
      print('========================');
    }
    setState(() {
      _center = Coordinate(longitude: centerLon, latitude: centerLat);
      _isLoading = true;
    });
    _finishLoading();
  }

  void _changeMapType(MapType mapType) {
    setState(() {
      _currentMapType = mapType;
      _isLoading = true;
    });
    _finishLoading();
  }

  void _finishLoading() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Multi-tile map
            Positioned.fill(
              child: _MultiTileMap(
                center: _center,
                zoom: _currentZoom,
                isLoading: _isLoading,
                mapType: _currentMapType,
              ),
            ),

            // Bounding box overlay
            Positioned.fill(
              child: CustomPaint(
                painter: _BoundingBoxOverlayPainter(
                  boundingBox: widget.boundingBox,
                  mapCenter: _center,
                  zoom: _currentZoom,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),

            // Map type selector (top left)
            Positioned(
              top: 8,
              left: 8,
              child: _MapTypeSelector(
                currentMapType: _currentMapType,
                onMapTypeChanged: _changeMapType,
              ),
            ),

            // Zoom controls
            Positioned(
              top: 8,
              right: 8,
              child: _ZoomControls(
                onZoomIn: _zoomIn,
                onZoomOut: _zoomOut,
                onReset: _resetView,
                onCenter: _centerOnBoundingBox,
                canZoomIn: _currentZoom < 18,
                canZoomOut: _currentZoom > 1,
                currentZoom: _currentZoom,
              ),
            ),

            // Loading overlay
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),

            // Info overlay
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: _MapInfoOverlay(
                boundingBox: widget.boundingBox,
                currentZoom: _currentZoom,
                center: _center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Add these enums and classes before the _MultiTileMap class

enum MapType { streets, satellite, hybrid }

class MapTileProvider {
  static String getTileUrl(MapType mapType, int x, int y, int z) {
    switch (mapType) {
      case MapType.streets:
        return 'https://tile.openstreetmap.org/$z/$x/$y.png';
      case MapType.satellite:
        // Using Esri World Imagery for satellite view
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/$z/$y/$x';
      case MapType.hybrid:
        // We'll layer satellite + labels by using satellite as base
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/$z/$y/$x';
    }
  }

  static String getOverlayUrl(MapType mapType, int x, int y, int z) {
    if (mapType == MapType.hybrid) {
      // For hybrid, we overlay labels on top of satellite
      return 'https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/$z/$y/$x';
    }
    return '';
  }

  static String getDisplayName(MapType mapType) {
    switch (mapType) {
      case MapType.streets:
        return 'Streets';
      case MapType.satellite:
        return 'Satellite';
      case MapType.hybrid:
        return 'Hybrid';
    }
  }

  static IconData getIcon(MapType mapType) {
    switch (mapType) {
      case MapType.streets:
        return Icons.map;
      case MapType.satellite:
        return Icons.satellite_alt;
      case MapType.hybrid:
        return Icons.layers;
    }
  }
}

class _MultiTileMap extends StatelessWidget {
  final Coordinate center;
  final int zoom;
  final bool isLoading;
  final MapType mapType;

  const _MultiTileMap({
    required this.center,
    required this.zoom,
    required this.isLoading,
    required this.mapType,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        // Calculate how many tiles we need to fill the view
        const tileSize = 256.0;
        final tilesX = (width / tileSize).ceil() + 2; // Add padding
        final tilesY = (height / tileSize).ceil() + 2; // Add padding

        // Calculate center tile
        final centerTileX = _lonToTileX(center.longitude, zoom);
        final centerTileY = _latToTileY(center.latitude, zoom);

        // Calculate offset to center the tiles properly
        final centerPixelX = _lonToPixelX(center.longitude, zoom);
        final centerPixelY = _latToPixelY(center.latitude, zoom);

        final offsetX = (width / 2) - (centerPixelX % tileSize);
        final offsetY = (height / 2) - (centerPixelY % tileSize);

        final tiles = <Widget>[];

        // Generate tiles around the center
        for (int dx = -tilesX ~/ 2; dx <= tilesX ~/ 2; dx++) {
          for (int dy = -tilesY ~/ 2; dy <= tilesY ~/ 2; dy++) {
            final tileX = centerTileX + dx;
            final tileY = centerTileY + dy;

            // Skip invalid tiles
            if (tileX < 0 ||
                tileY < 0 ||
                tileX >= (1 << zoom) ||
                tileY >= (1 << zoom)) {
              continue;
            }

            final left = offsetX + (dx * tileSize);
            final top = offsetY + (dy * tileSize);

            tiles.add(
              Positioned(
                left: left,
                top: top,
                width: tileSize,
                height: tileSize,
                child: _MapTile(x: tileX, y: tileY, z: zoom, mapType: mapType),
              ),
            );
          }
        }

        return Stack(
          children: [
            // Background
            Container(width: width, height: height, color: Colors.grey[100]),
            // Tiles
            ...tiles,
          ],
        );
      },
    );
  }

  int _lonToTileX(double lon, int zoom) {
    return ((lon + 180.0) / 360.0 * (1 << zoom)).floor();
  }

  int _latToTileY(double lat, int zoom) {
    final latRad = lat * math.pi / 180.0;
    return ((1.0 -
                (math.log(math.tan(latRad) + (1 / math.cos(latRad))) /
                    math.pi)) /
            2.0 *
            (1 << zoom))
        .floor();
  }

  double _lonToPixelX(double lon, int zoom) {
    return (lon + 180.0) / 360.0 * (1 << zoom) * 256.0;
  }

  double _latToPixelY(double lat, int zoom) {
    final latRad = lat * math.pi / 180.0;
    return (1.0 -
            (math.log(math.tan(latRad) + (1 / math.cos(latRad))) / math.pi)) /
        2.0 *
        (1 << zoom) *
        256.0;
  }
}

class _MapTile extends StatelessWidget {
  final int x;
  final int y;
  final int z;
  final MapType mapType;

  const _MapTile({
    required this.x,
    required this.y,
    required this.z,
    required this.mapType,
  });

  @override
  Widget build(BuildContext context) {
    final baseUrl = MapTileProvider.getTileUrl(mapType, x, y, z);
    final overlayUrl = MapTileProvider.getOverlayUrl(mapType, x, y, z);

    return Container(
      width: 256,
      height: 256,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 0.5),
      ),
      child: Stack(
        children: [
          // Base tile
          Image.network(
            baseUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                child: Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.grey[400],
                    size: 32,
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

          // Overlay tile (for hybrid mode)
          if (overlayUrl.isNotEmpty)
            Image.network(
              overlayUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox(); // Don't show error for overlay
              },
            ),
        ],
      ),
    );
  }
}

class _BoundingBoxOverlayPainter extends CustomPainter {
  final BoundingBox boundingBox;
  final Coordinate mapCenter;
  final int zoom;
  final Color color;

  _BoundingBoxOverlayPainter({
    required this.boundingBox,
    required this.mapCenter,
    required this.zoom,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Convert coordinates to pixel positions
    //  final centerPixelX = size.width / 2;
    //  final centerPixelY = size.height / 2;

    // Calculate pixel positions for bounding box corners
    final nwPixel = _coordinateToPixel(boundingBox.northWest, size);
    final nePixel = _coordinateToPixel(boundingBox.northEast, size);
    final swPixel = _coordinateToPixel(boundingBox.southWest, size);
    final sePixel = _coordinateToPixel(boundingBox.southEast, size);

    // Find bounding rectangle
    final left = math.min(
      math.min(nwPixel.dx, nePixel.dx),
      math.min(swPixel.dx, sePixel.dx),
    );
    final right = math.max(
      math.max(nwPixel.dx, nePixel.dx),
      math.max(swPixel.dx, sePixel.dx),
    );
    final top = math.min(
      math.min(nwPixel.dy, nePixel.dy),
      math.min(swPixel.dy, sePixel.dy),
    );
    final bottom = math.max(
      math.max(nwPixel.dy, nePixel.dy),
      math.max(swPixel.dy, sePixel.dy),
    );

    // Only draw if visible
    if (right >= 0 && left <= size.width && bottom >= 0 && top <= size.height) {
      final rect = Rect.fromLTRB(
        math.max(0, left),
        math.max(0, top),
        math.min(size.width, right),
        math.min(size.height, bottom),
      );

      // Draw fill
      final fillPaint =
          Paint()
            ..color = color.withOpacity(0.2)
            ..style = PaintingStyle.fill;
      canvas.drawRect(rect, fillPaint);

      // Draw border
      final strokePaint =
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2;
      canvas.drawRect(rect, strokePaint);

      // Draw corner dots
      final dotPaint =
          Paint()
            ..color = color
            ..style = PaintingStyle.fill;

      const dotRadius = 4.0;
      if (_isPointVisible(nwPixel, size))
        canvas.drawCircle(nwPixel, dotRadius, dotPaint);
      if (_isPointVisible(nePixel, size))
        canvas.drawCircle(nePixel, dotRadius, dotPaint);
      if (_isPointVisible(swPixel, size))
        canvas.drawCircle(swPixel, dotRadius, dotPaint);
      if (_isPointVisible(sePixel, size))
        canvas.drawCircle(sePixel, dotRadius, dotPaint);
    }
  }

  Offset _coordinateToPixel(Coordinate coord, Size size) {
    // Convert lat/lon to pixel coordinates relative to the map center
    final scale = math.pow(2, zoom) * 256.0;

    // Calculate pixel positions for map center
    final centerX = _lonToPixel(mapCenter.longitude) * scale;
    final centerY = _latToPixel(mapCenter.latitude) * scale;

    // Calculate pixel positions for the coordinate
    final coordX = _lonToPixel(coord.longitude) * scale;
    final coordY = _latToPixel(coord.latitude) * scale;

    // Calculate offset from center and convert to screen coordinates
    final screenX = size.width / 2 + (coordX - centerX);
    final screenY = size.height / 2 + (coordY - centerY);

    return Offset(screenX, screenY);
  }

  double _lonToPixel(double lon) {
    return (lon + 180.0) / 360.0;
  }

  double _latToPixel(double lat) {
    final latRad = lat * math.pi / 180.0;
    return (1.0 -
            (math.log(math.tan(latRad) + (1 / math.cos(latRad))) / math.pi)) /
        2.0;
  }

  bool _isPointVisible(Offset point, Size size) {
    return point.dx >= -10 &&
        point.dx <= size.width + 10 &&
        point.dy >= -10 &&
        point.dy <= size.height + 10;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _MapTypeSelector extends StatefulWidget {
  final MapType currentMapType;
  final ValueChanged<MapType> onMapTypeChanged;

  const _MapTypeSelector({
    required this.currentMapType,
    required this.onMapTypeChanged,
  });

  @override
  State<_MapTypeSelector> createState() => _MapTypeSelectorState();
}

class _MapTypeSelectorState extends State<_MapTypeSelector> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _selectMapType(MapType mapType) {
    widget.onMapTypeChanged(mapType);
    setState(() {
      _isExpanded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header/Current selection button
          InkWell(
            onTap: _toggleExpanded,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    MapTileProvider.getIcon(widget.currentMapType),
                    size: 16,
                    color: Colors.black87,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    MapTileProvider.getDisplayName(widget.currentMapType),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: Colors.black87,
                  ),
                ],
              ),
            ),
          ),

          // Dropdown options (only show when expanded)
          if (_isExpanded) ...[
            const Divider(height: 1),
            ...MapType.values
                .where((mapType) => mapType != widget.currentMapType)
                .map(
                  (mapType) => _MapTypeButton(
                    mapType: mapType,
                    onPressed: () => _selectMapType(mapType),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _MapTypeButton extends StatelessWidget {
  final MapType mapType;
  final VoidCallback onPressed;

  const _MapTypeButton({required this.mapType, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              MapTileProvider.getIcon(mapType),
              size: 16,
              color: Colors.black87,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                MapTileProvider.getDisplayName(mapType),
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;
  final VoidCallback onCenter;
  final bool canZoomIn;
  final bool canZoomOut;
  final int currentZoom;

  const _ZoomControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
    required this.onCenter,
    required this.canZoomIn,
    required this.canZoomOut,
    required this.currentZoom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom level
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              'Z$currentZoom',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          const Divider(height: 1),

          // Zoom in
          _ZoomButton(
            icon: Icons.add,
            onPressed: canZoomIn ? onZoomIn : null,
            tooltip: 'Zoom In',
          ),

          const Divider(height: 1),

          // Zoom out
          _ZoomButton(
            icon: Icons.remove,
            onPressed: canZoomOut ? onZoomOut : null,
            tooltip: 'Zoom Out',
          ),

          const Divider(height: 1),

          // Center
          _ZoomButton(
            icon: Icons.my_location,
            onPressed: onCenter,
            tooltip: 'Center on Data',
          ),

          const Divider(height: 1),

          // Reset
          _ZoomButton(
            icon: Icons.refresh,
            onPressed: onReset,
            tooltip: 'Reset View',
          ),
        ],
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;

  const _ZoomButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 18,
            color: onPressed != null ? Colors.black87 : Colors.grey[400],
          ),
        ),
      ),
    );
  }
}

class _MapInfoOverlay extends StatelessWidget {
  final BoundingBox boundingBox;
  final int currentZoom;
  final Coordinate center;

  const _MapInfoOverlay({
    required this.boundingBox,
    required this.currentZoom,
    required this.center,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Zoom: $currentZoom | Center: ${center.latitude.toStringAsFixed(4)}, ${center.longitude.toStringAsFixed(4)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Data Bounds: ${boundingBox.width.toStringAsFixed(4)}° × ${boundingBox.height.toStringAsFixed(4)}°',
            style: const TextStyle(color: Colors.white70, fontSize: 9),
          ),
        ],
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
    final labelStyle = textStyle?.copyWith(
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Coordinates:', style: labelStyle),
          const SizedBox(height: 8),
          _CoordinateItem(
            label: 'North-West',
            coordinate: boundingBox.northWest,
            textStyle: textStyle,
          ),
          const SizedBox(height: 4),
          _CoordinateItem(
            label: 'North-East',
            coordinate: boundingBox.northEast,
            textStyle: textStyle,
          ),
          const SizedBox(height: 4),
          _CoordinateItem(
            label: 'South-West',
            coordinate: boundingBox.southWest,
            textStyle: textStyle,
          ),
          const SizedBox(height: 4),
          _CoordinateItem(
            label: 'South-East',
            coordinate: boundingBox.southEast,
            textStyle: textStyle,
          ),
          const SizedBox(height: 16),
          Text('Dimensions:', style: labelStyle),
          const SizedBox(height: 6),
          Text(
            'Width: ${boundingBox.width.toStringAsFixed(4)}°',
            style: textStyle,
          ),
          const SizedBox(height: 3),
          Text(
            'Height: ${boundingBox.height.toStringAsFixed(4)}°',
            style: textStyle,
          ),
          const SizedBox(height: 3),
          Text(
            'Center: ${boundingBox.center.longitude.toStringAsFixed(4)}°, ${boundingBox.center.latitude.toStringAsFixed(4)}°',
            style: textStyle,
          ),
          const SizedBox(height: 16),
          Text('Coverage:', style: labelStyle),
          const SizedBox(height: 6),
          Text(
            _getAreaDescription(boundingBox.width, boundingBox.height),
            style: textStyle,
          ),
        ],
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
    return Text(
      '$label: ${coordinate.longitude.toStringAsFixed(4)}°, ${coordinate.latitude.toStringAsFixed(4)}°',
      style: textStyle?.copyWith(fontSize: 12),
    );
  }
}


/*
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
              children: [
                Text(
                  'Bounding Box Preview',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _InteractiveBoundingBoxMap(
                          boundingBox: boundingBox,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: _BoundingBoxCoordinates(
                          boundingBox: boundingBox,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InteractiveBoundingBoxMap extends StatefulWidget {
  final BoundingBox boundingBox;

  const _InteractiveBoundingBoxMap({required this.boundingBox});

  @override
  State<_InteractiveBoundingBoxMap> createState() =>
      _InteractiveBoundingBoxMapState();
}

class _InteractiveBoundingBoxMapState
    extends State<_InteractiveBoundingBoxMap> {
  late int _currentZoom;
  late Coordinate _center;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Debug: Print the bounding box values
    print('=== BOUNDING BOX DEBUG ===');
    print(
      'North-West: ${widget.boundingBox.northWest.latitude}, ${widget.boundingBox.northWest.longitude}',
    );
    print(
      'North-East: ${widget.boundingBox.northEast.latitude}, ${widget.boundingBox.northEast.longitude}',
    );
    print(
      'South-West: ${widget.boundingBox.southWest.latitude}, ${widget.boundingBox.southWest.longitude}',
    );
    print(
      'South-East: ${widget.boundingBox.southEast.latitude}, ${widget.boundingBox.southEast.longitude}',
    );
    print(
      'Center: ${widget.boundingBox.center.latitude}, ${widget.boundingBox.center.longitude}',
    );
    print(
      'Width: ${widget.boundingBox.width}°, Height: ${widget.boundingBox.height}°',
    );
    print('========================');

    // Calculate center more reliably
    final centerLat =
        (widget.boundingBox.northWest.latitude +
            widget.boundingBox.southEast.latitude) /
        2;
    final centerLon =
        (widget.boundingBox.northWest.longitude +
            widget.boundingBox.southEast.longitude) /
        2;

    // Validate coordinates
    if (centerLat.isNaN ||
        centerLon.isNaN ||
        centerLat < -90 ||
        centerLat > 90 ||
        centerLon < -180 ||
        centerLon > 180) {
      print('WARNING: Invalid center coordinates, using fallback');
      _center = const Coordinate(longitude: 0, latitude: 0);
    } else {
      _center = Coordinate(longitude: centerLon, latitude: centerLat);
    }

    _currentZoom = _calculateOptimalZoom();
  }

  int _calculateOptimalZoom() {
    final latSpan = widget.boundingBox.height;
    final lonSpan = widget.boundingBox.width;
    final maxSpan = math.max(latSpan, lonSpan);

    // Calculate zoom to fit the bounding box with some padding
    if (maxSpan > 20) return 3;
    if (maxSpan > 10) return 4;
    if (maxSpan > 5) return 5;
    if (maxSpan > 2) return 6;
    if (maxSpan > 1) return 7;
    if (maxSpan > 0.5) return 8;
    if (maxSpan > 0.25) return 9;
    if (maxSpan > 0.1) return 10;
    if (maxSpan > 0.05) return 11;
    return 12;
  }

  void _zoomIn() {
    if (_currentZoom < 18) {
      setState(() {
        _currentZoom++;
        _isLoading = true;
      });
      _finishLoading();
    }
  }

  void _zoomOut() {
    if (_currentZoom > 1) {
      setState(() {
        _currentZoom--;
        _isLoading = true;
      });
      _finishLoading();
    }
  }

  void _resetView() {
    // Calculate center more robustly for reset
    final centerLat =
        (widget.boundingBox.northWest.latitude +
            widget.boundingBox.southEast.latitude) /
        2;
    final centerLon =
        (widget.boundingBox.northWest.longitude +
            widget.boundingBox.southEast.longitude) /
        2;

    setState(() {
      _center = Coordinate(longitude: centerLon, latitude: centerLat);
      _currentZoom = _calculateOptimalZoom();
      _isLoading = true;
    });
    _finishLoading();
  }

  void _centerOnBoundingBox() {
    // Calculate center more robustly
    final centerLat =
        (widget.boundingBox.northWest.latitude +
            widget.boundingBox.southEast.latitude) /
        2;
    final centerLon =
        (widget.boundingBox.northWest.longitude +
            widget.boundingBox.southEast.longitude) /
        2;

    print('=== CENTER CALCULATION ===');
    print(
      'NW: ${widget.boundingBox.northWest.latitude}, ${widget.boundingBox.northWest.longitude}',
    );
    print(
      'SE: ${widget.boundingBox.southEast.latitude}, ${widget.boundingBox.southEast.longitude}',
    );
    print('Calculated Center: $centerLat, $centerLon');
    print(
      'BoundingBox Center: ${widget.boundingBox.center.latitude}, ${widget.boundingBox.center.longitude}',
    );
    print('========================');

    setState(() {
      _center = Coordinate(longitude: centerLon, latitude: centerLat);
      _isLoading = true;
    });
    _finishLoading();
  }

  void _finishLoading() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Multi-tile map
            Positioned.fill(
              child: _MultiTileMap(
                center: _center,
                zoom: _currentZoom,
                isLoading: _isLoading,
              ),
            ),

            // Bounding box overlay
            Positioned.fill(
              child: CustomPaint(
                painter: _BoundingBoxOverlayPainter(
                  boundingBox: widget.boundingBox,
                  mapCenter: _center,
                  zoom: _currentZoom,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),

            // Zoom controls
            Positioned(
              top: 8,
              right: 8,
              child: _ZoomControls(
                onZoomIn: _zoomIn,
                onZoomOut: _zoomOut,
                onReset: _resetView,
                onCenter: _centerOnBoundingBox,
                canZoomIn: _currentZoom < 18,
                canZoomOut: _currentZoom > 1,
                currentZoom: _currentZoom,
              ),
            ),

            // Loading overlay
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),

            // Info overlay
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: _MapInfoOverlay(
                boundingBox: widget.boundingBox,
                currentZoom: _currentZoom,
                center: _center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MultiTileMap extends StatelessWidget {
  final Coordinate center;
  final int zoom;
  final bool isLoading;

  const _MultiTileMap({
    required this.center,
    required this.zoom,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        // Calculate how many tiles we need to fill the view
        const tileSize = 256.0;
        final tilesX = (width / tileSize).ceil() + 2; // Add padding
        final tilesY = (height / tileSize).ceil() + 2; // Add padding

        // Calculate center tile
        final centerTileX = _lonToTileX(center.longitude, zoom);
        final centerTileY = _latToTileY(center.latitude, zoom);

        // Calculate offset to center the tiles properly
        final centerPixelX = _lonToPixelX(center.longitude, zoom);
        final centerPixelY = _latToPixelY(center.latitude, zoom);

        final offsetX = (width / 2) - (centerPixelX % tileSize);
        final offsetY = (height / 2) - (centerPixelY % tileSize);

        final tiles = <Widget>[];

        // Generate tiles around the center
        for (int dx = -tilesX ~/ 2; dx <= tilesX ~/ 2; dx++) {
          for (int dy = -tilesY ~/ 2; dy <= tilesY ~/ 2; dy++) {
            final tileX = centerTileX + dx;
            final tileY = centerTileY + dy;

            // Skip invalid tiles
            if (tileX < 0 ||
                tileY < 0 ||
                tileX >= (1 << zoom) ||
                tileY >= (1 << zoom)) {
              continue;
            }

            final left = offsetX + (dx * tileSize);
            final top = offsetY + (dy * tileSize);

            tiles.add(
              Positioned(
                left: left,
                top: top,
                width: tileSize,
                height: tileSize,
                child: _MapTile(x: tileX, y: tileY, z: zoom),
              ),
            );
          }
        }

        return Stack(
          children: [
            // Background
            Container(width: width, height: height, color: Colors.grey[100]),
            // Tiles
            ...tiles,
          ],
        );
      },
    );
  }

  int _lonToTileX(double lon, int zoom) {
    return ((lon + 180.0) / 360.0 * (1 << zoom)).floor();
  }

  int _latToTileY(double lat, int zoom) {
    final latRad = lat * math.pi / 180.0;
    return ((1.0 -
                (math.log(math.tan(latRad) + (1 / math.cos(latRad))) /
                    math.pi)) /
            2.0 *
            (1 << zoom))
        .floor();
  }

  double _lonToPixelX(double lon, int zoom) {
    return (lon + 180.0) / 360.0 * (1 << zoom) * 256.0;
  }

  double _latToPixelY(double lat, int zoom) {
    final latRad = lat * math.pi / 180.0;
    return (1.0 -
            (math.log(math.tan(latRad) + (1 / math.cos(latRad))) / math.pi)) /
        2.0 *
        (1 << zoom) *
        256.0;
  }
}

class _MapTile extends StatelessWidget {
  final int x;
  final int y;
  final int z;

  const _MapTile({required this.x, required this.y, required this.z});

  @override
  Widget build(BuildContext context) {
    final url = 'https://tile.openstreetmap.org/$z/$x/$y.png';

    return Container(
      width: 256,
      height: 256,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 0.5),
      ),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: Center(
              child: Icon(
                Icons.broken_image,
                color: Colors.grey[400],
                size: 32,
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
    );
  }
}

class _BoundingBoxOverlayPainter extends CustomPainter {
  final BoundingBox boundingBox;
  final Coordinate mapCenter;
  final int zoom;
  final Color color;

  _BoundingBoxOverlayPainter({
    required this.boundingBox,
    required this.mapCenter,
    required this.zoom,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Convert coordinates to pixel positions
    final centerPixelX = size.width / 2;
    final centerPixelY = size.height / 2;

    // Calculate pixel positions for bounding box corners
    final nwPixel = _coordinateToPixel(boundingBox.northWest, size);
    final nePixel = _coordinateToPixel(boundingBox.northEast, size);
    final swPixel = _coordinateToPixel(boundingBox.southWest, size);
    final sePixel = _coordinateToPixel(boundingBox.southEast, size);

    // Find bounding rectangle
    final left = math.min(
      math.min(nwPixel.dx, nePixel.dx),
      math.min(swPixel.dx, sePixel.dx),
    );
    final right = math.max(
      math.max(nwPixel.dx, nePixel.dx),
      math.max(swPixel.dx, sePixel.dx),
    );
    final top = math.min(
      math.min(nwPixel.dy, nePixel.dy),
      math.min(swPixel.dy, sePixel.dy),
    );
    final bottom = math.max(
      math.max(nwPixel.dy, nePixel.dy),
      math.max(swPixel.dy, sePixel.dy),
    );

    // Only draw if visible
    if (right >= 0 && left <= size.width && bottom >= 0 && top <= size.height) {
      final rect = Rect.fromLTRB(
        math.max(0, left),
        math.max(0, top),
        math.min(size.width, right),
        math.min(size.height, bottom),
      );

      // Draw fill
      final fillPaint =
          Paint()
            ..color = color.withOpacity(0.2)
            ..style = PaintingStyle.fill;
      canvas.drawRect(rect, fillPaint);

      // Draw border
      final strokePaint =
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2;
      canvas.drawRect(rect, strokePaint);

      // Draw corner dots
      final dotPaint =
          Paint()
            ..color = color
            ..style = PaintingStyle.fill;

      const dotRadius = 4.0;
      if (_isPointVisible(nwPixel, size))
        canvas.drawCircle(nwPixel, dotRadius, dotPaint);
      if (_isPointVisible(nePixel, size))
        canvas.drawCircle(nePixel, dotRadius, dotPaint);
      if (_isPointVisible(swPixel, size))
        canvas.drawCircle(swPixel, dotRadius, dotPaint);
      if (_isPointVisible(sePixel, size))
        canvas.drawCircle(sePixel, dotRadius, dotPaint);
    }
  }

  Offset _coordinateToPixel(Coordinate coord, Size size) {
    // Convert lat/lon to pixel coordinates relative to the map center
    final scale = math.pow(2, zoom) * 256.0;

    // Calculate pixel positions for map center
    final centerX = _lonToPixel(mapCenter.longitude) * scale;
    final centerY = _latToPixel(mapCenter.latitude) * scale;

    // Calculate pixel positions for the coordinate
    final coordX = _lonToPixel(coord.longitude) * scale;
    final coordY = _latToPixel(coord.latitude) * scale;

    // Calculate offset from center and convert to screen coordinates
    final screenX = size.width / 2 + (coordX - centerX);
    final screenY = size.height / 2 + (coordY - centerY);

    return Offset(screenX, screenY);
  }

  double _lonToPixel(double lon) {
    return (lon + 180.0) / 360.0;
  }

  double _latToPixel(double lat) {
    final latRad = lat * math.pi / 180.0;
    return (1.0 -
            (math.log(math.tan(latRad) + (1 / math.cos(latRad))) / math.pi)) /
        2.0;
  }

  bool _isPointVisible(Offset point, Size size) {
    return point.dx >= -10 &&
        point.dx <= size.width + 10 &&
        point.dy >= -10 &&
        point.dy <= size.height + 10;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ZoomControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;
  final VoidCallback onCenter;
  final bool canZoomIn;
  final bool canZoomOut;
  final int currentZoom;

  const _ZoomControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
    required this.onCenter,
    required this.canZoomIn,
    required this.canZoomOut,
    required this.currentZoom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom level
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              'Z$currentZoom',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          const Divider(height: 1),

          // Zoom in
          _ZoomButton(
            icon: Icons.add,
            onPressed: canZoomIn ? onZoomIn : null,
            tooltip: 'Zoom In',
          ),

          const Divider(height: 1),

          // Zoom out
          _ZoomButton(
            icon: Icons.remove,
            onPressed: canZoomOut ? onZoomOut : null,
            tooltip: 'Zoom Out',
          ),

          const Divider(height: 1),

          // Center
          _ZoomButton(
            icon: Icons.my_location,
            onPressed: onCenter,
            tooltip: 'Center on Data',
          ),

          const Divider(height: 1),

          // Reset
          _ZoomButton(
            icon: Icons.refresh,
            onPressed: onReset,
            tooltip: 'Reset View',
          ),
        ],
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;

  const _ZoomButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 18,
            color: onPressed != null ? Colors.black87 : Colors.grey[400],
          ),
        ),
      ),
    );
  }
}

class _MapInfoOverlay extends StatelessWidget {
  final BoundingBox boundingBox;
  final int currentZoom;
  final Coordinate center;

  const _MapInfoOverlay({
    required this.boundingBox,
    required this.currentZoom,
    required this.center,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Zoom: $currentZoom | Center: ${center.latitude.toStringAsFixed(4)}, ${center.longitude.toStringAsFixed(4)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Data Bounds: ${boundingBox.width.toStringAsFixed(4)}° × ${boundingBox.height.toStringAsFixed(4)}°',
            style: const TextStyle(color: Colors.white70, fontSize: 9),
          ),
        ],
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
    final labelStyle = textStyle?.copyWith(
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Coordinates:', style: labelStyle),
          const SizedBox(height: 8),
          _CoordinateItem(
            label: 'North-West',
            coordinate: boundingBox.northWest,
            textStyle: textStyle,
          ),
          const SizedBox(height: 4),
          _CoordinateItem(
            label: 'North-East',
            coordinate: boundingBox.northEast,
            textStyle: textStyle,
          ),
          const SizedBox(height: 4),
          _CoordinateItem(
            label: 'South-West',
            coordinate: boundingBox.southWest,
            textStyle: textStyle,
          ),
          const SizedBox(height: 4),
          _CoordinateItem(
            label: 'South-East',
            coordinate: boundingBox.southEast,
            textStyle: textStyle,
          ),
          const SizedBox(height: 16),
          Text('Dimensions:', style: labelStyle),
          const SizedBox(height: 6),
          Text(
            'Width: ${boundingBox.width.toStringAsFixed(4)}°',
            style: textStyle,
          ),
          const SizedBox(height: 3),
          Text(
            'Height: ${boundingBox.height.toStringAsFixed(4)}°',
            style: textStyle,
          ),
          const SizedBox(height: 3),
          Text(
            'Center: ${boundingBox.center.longitude.toStringAsFixed(4)}°, ${boundingBox.center.latitude.toStringAsFixed(4)}°',
            style: textStyle,
          ),
          const SizedBox(height: 16),
          Text('Coverage:', style: labelStyle),
          const SizedBox(height: 6),
          Text(
            _getAreaDescription(boundingBox.width, boundingBox.height),
            style: textStyle,
          ),
        ],
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
    return Text(
      '$label: ${coordinate.longitude.toStringAsFixed(4)}°, ${coordinate.latitude.toStringAsFixed(4)}°',
      style: textStyle?.copyWith(fontSize: 12),
    );
  }
}
*/