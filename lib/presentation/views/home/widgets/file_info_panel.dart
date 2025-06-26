import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/home_viewmodel.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../../data/models/kml_data.dart';

class FileInfoPanel extends StatelessWidget {
  const FileInfoPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        if (!viewModel.hasKmlData) {
          return const SizedBox.shrink();
        }

        final kmlData = viewModel.kmlData!;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'File Information',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                _InfoColumn(kmlData: kmlData),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoColumn extends StatelessWidget {
  final KmlData kmlData;

  const _InfoColumn({required this.kmlData});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    final labelStyle = textStyle?.copyWith(
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return Column(
      children: [
        _InfoItem(
          label: 'File Name',
          value: kmlData.fileName,
          labelStyle: labelStyle,
          textStyle: textStyle,
        ),
        const SizedBox(height: 12),
        _InfoItem(
          label: 'File Size',
          value: FileUtils.formatFileSize(kmlData.fileSize),
          labelStyle: labelStyle,
          textStyle: textStyle,
        ),
        const SizedBox(height: 12),
        _InfoItem(
          label: 'Features Count',
          value: '${kmlData.featuresCount}',
          labelStyle: labelStyle,
          textStyle: textStyle,
        ),
        const SizedBox(height: 12),
        _InfoItem(
          label: 'Layers Count',
          value: '${kmlData.layersCount}',
          labelStyle: labelStyle,
          textStyle: textStyle,
        ),
        const SizedBox(height: 12),
        _InfoItem(
          label: 'Coordinate System',
          value: kmlData.coordinateSystem.value,
          labelStyle: labelStyle,
          textStyle: textStyle,
        ),
        const SizedBox(height: 12),
        _InfoItem(
          label: 'Available Fields',
          value: '${kmlData.availableFields.length}',
          labelStyle: labelStyle,
          textStyle: textStyle,
        ),
        if (kmlData.geometryTypeCounts.isNotEmpty) ...[
          const SizedBox(height: 12),
          _GeometryTypesSection(
            geometryTypeCounts: kmlData.geometryTypeCounts,
            labelStyle: labelStyle,
            textStyle: textStyle,
          ),
        ],
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? textStyle;

  const _InfoItem({
    required this.label,
    required this.value,
    this.labelStyle,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 1, child: Text('$label:', style: labelStyle)),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: textStyle,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}

class _GeometryTypesSection extends StatelessWidget {
  final Map<String, int> geometryTypeCounts;
  final TextStyle? labelStyle;
  final TextStyle? textStyle;

  const _GeometryTypesSection({
    required this.geometryTypeCounts,
    this.labelStyle,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    // Create a formatted string of all geometry types
    final geometryTypesText = geometryTypeCounts.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(', ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 1, child: Text('Geometry Types:', style: labelStyle)),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Text(
            geometryTypesText,
            style: textStyle,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}
