import 'package:flutter/material.dart';
import '../../../../core/enums/geometry_type.dart';

class GeometryTypeSelector extends StatelessWidget {
  final GeometryType selectedType;
  final Function(GeometryType) onTypeChanged;
  final int? totalRows;

  const GeometryTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
    this.totalRows,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Geometry Type',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose how your CSV coordinates should be interpreted:',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            // Geometry type options
            ...GeometryType.values
                .where((type) => type.isSupportedForCsvConversion)
                .map((type) => _buildGeometryOption(context, type)),
          ],
        ),
      ),
    );
  }

  Widget _buildGeometryOption(BuildContext context, GeometryType type) {
    final isSelected = selectedType == type;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color:
              isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color:
            isSelected
                ? Theme.of(context).primaryColor.withValues(alpha: 0.05)
                : null,
      ),
      child: RadioListTile<GeometryType>(
        value: type,
        groupValue: selectedType,
        onChanged: (value) => onTypeChanged(value!),
        title: Row(
          children: [
            _getGeometryIcon(type),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.displayName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Theme.of(context).primaryColor : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type.description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  if (totalRows != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _getExpectedOutput(type),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  Widget _getGeometryIcon(GeometryType type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case GeometryType.point:
        iconData = Icons.place;
        iconColor = Colors.red;
        break;
      case GeometryType.lineString:
        iconData = Icons.timeline;
        iconColor = Colors.blue;
        break;
      case GeometryType.polygon:
        iconData = Icons.crop_free;
        iconColor = Colors.green;
        break;
      default:
        iconData = Icons.location_on;
        iconColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }

  String _getExpectedOutput(GeometryType type) {
    if (totalRows == null) return '';

    switch (type) {
      case GeometryType.point:
        return 'Creates $totalRows individual placemarks';
      case GeometryType.lineString:
        return 'Creates 1 connected path from $totalRows points';
      case GeometryType.polygon:
        return 'Creates 1 closed area from $totalRows points';
      default:
        return '';
    }
  }
}

/// Preview widget showing what the selected geometry type will produce
class GeometryPreview extends StatelessWidget {
  final GeometryType geometryType;
  final int coordinateCount;

  const GeometryPreview({
    super.key,
    required this.geometryType,
    required this.coordinateCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.preview,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Preview',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPreviewContent(context),
        ],
      ),
    );
  }

  Widget _buildPreviewContent(BuildContext context) {
    switch (geometryType) {
      case GeometryType.point:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Individual Points',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              '• Creates $coordinateCount separate placemarks\n'
              '• Each row becomes one point on the map\n'
              '• Best for: Locations, markers, POIs',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );

      case GeometryType.lineString:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connected Path',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              '• Creates 1 continuous line through all points\n'
              '• Points are connected in CSV row order\n'
              '• Best for: Routes, tracks, boundaries\n'
              '• Requires at least 2 coordinates',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );

      case GeometryType.polygon:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Closed Area', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              '• Creates 1 filled polygon area\n'
              '• Automatically closes the shape\n'
              '• Best for: Zones, regions, boundaries\n'
              '• Requires at least 3 coordinates',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );

      default:
        return const SizedBox();
    }
  }
}

/// Widget showing geometry requirements and validation
class GeometryRequirements extends StatelessWidget {
  final GeometryType geometryType;
  final int availableCoordinates;

  const GeometryRequirements({
    super.key,
    required this.geometryType,
    required this.availableCoordinates,
  });

  @override
  Widget build(BuildContext context) {
    final requirements = _getRequirements();
    final isValid = availableCoordinates >= requirements.minimum;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isValid ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isValid ? Colors.green[200]! : Colors.orange[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.warning,
            color: isValid ? Colors.green[700] : Colors.orange[700],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isValid ? 'Requirements Met' : 'Insufficient Coordinates',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isValid ? Colors.green[700] : Colors.orange[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Need ${requirements.minimum}+, have $availableCoordinates',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isValid ? Colors.green[600] : Colors.orange[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ({int minimum, String description}) _getRequirements() {
    switch (geometryType) {
      case GeometryType.point:
        return (minimum: 1, description: 'At least 1 coordinate');
      case GeometryType.lineString:
        return (minimum: 2, description: 'At least 2 coordinates');
      case GeometryType.polygon:
        return (minimum: 3, description: 'At least 3 coordinates');
      default:
        return (minimum: 1, description: 'At least 1 coordinate');
    }
  }
}
