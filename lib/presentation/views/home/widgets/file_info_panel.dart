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
                const SizedBox(height: 12),
                _InfoGrid(kmlData: kmlData),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final KmlData kmlData;

  const _InfoGrid({required this.kmlData});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    final labelStyle = textStyle?.copyWith(fontWeight: FontWeight.w600);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _InfoItem(
                label: 'File Name',
                value: kmlData.fileName,
                labelStyle: labelStyle,
                textStyle: textStyle,
              ),
            ),
            Expanded(
              child: _InfoItem(
                label: 'File Size',
                value: FileUtils.formatFileSize(kmlData.fileSize),
                labelStyle: labelStyle,
                textStyle: textStyle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _InfoItem(
                label: 'Features Count',
                value: '${kmlData.featuresCount}',
                labelStyle: labelStyle,
                textStyle: textStyle,
              ),
            ),
            Expanded(
              child: _InfoItem(
                label: 'Layers Count',
                value: '${kmlData.layersCount}',
                labelStyle: labelStyle,
                textStyle: textStyle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _InfoItem(
                label: 'Coordinate System',
                value: kmlData.coordinateSystem.value,
                labelStyle: labelStyle,
                textStyle: textStyle,
              ),
            ),
            Expanded(
              child: _InfoItem(
                label: 'Available Fields',
                value: '${kmlData.availableFields.length}',
                labelStyle: labelStyle,
                textStyle: textStyle,
              ),
            ),
          ],
        ),
        if (kmlData.geometryTypeCounts.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Geometry Types:', style: labelStyle),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children:
                kmlData.geometryTypeCounts.entries.map<Widget>((entry) {
                  return Chip(
                    label: Text('${entry.key}: ${entry.value}'),
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceVariant,
                  );
                }).toList(),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 2),
        Text(value, style: textStyle),
      ],
    );
  }
}
