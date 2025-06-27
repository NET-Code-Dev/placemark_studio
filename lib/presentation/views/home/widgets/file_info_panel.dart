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
                Row(
                  children: [
                    Text(
                      'File Information',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (kmlData.hasHierarchy) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Nested',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: Colors.blue[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(child: _InfoColumn(kmlData: kmlData)),
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column - Basic File Information
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /*
                _InfoItem(
                  label: 'File Name',
                  value: kmlData.fileName,
                  labelStyle: labelStyle,
                  textStyle: textStyle,
                ),
                const SizedBox(height: 12),
*/
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
                // Add folder count info for hierarchy files
                if (kmlData.hasHierarchy) ...[
                  const SizedBox(height: 12),
                  _InfoItem(
                    label: 'Total Folders',
                    value: '${kmlData.totalFolderCount}',
                    labelStyle: labelStyle,
                    textStyle: textStyle,
                  ),
                  const SizedBox(height: 12),
                  _InfoItem(
                    label: 'Max Nesting Depth',
                    value: '${kmlData.maxFolderDepth} levels',
                    labelStyle: labelStyle,
                    textStyle: textStyle,
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  _InfoItem(
                    label: 'Layers Count',
                    value: '${kmlData.layersCount}',
                    labelStyle: labelStyle,
                    textStyle: textStyle,
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(width: 16), // Spacing between columns
        // Right Column - Folder Structure (only show if hierarchy exists)
        if (kmlData.hasHierarchy)
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Folder Structure:',
                  style:
                      labelStyle ??
                      Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _HierarchyPreview(
                    kmlData: kmlData,
                    textStyle:
                        textStyle ?? Theme.of(context).textTheme.bodyMedium,
                    labelStyle:
                        labelStyle ??
                        Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
          )
        else
          // If no hierarchy, show a placeholder
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Structure:',
                  style:
                      labelStyle ??
                      Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.description,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Flat structure - no folders',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _HierarchyPreview extends StatelessWidget {
  final KmlData kmlData;
  final TextStyle? textStyle;
  final TextStyle? labelStyle;

  const _HierarchyPreview({
    required this.kmlData,
    this.textStyle,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (!kmlData.hasHierarchy) return const SizedBox.shrink();

    final folderPaths = kmlData.folderStructure!.getAllFolderPaths();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...folderPaths.map((path) {
              final depth = path.split('/').length - 1;
              final folderName = path.split('/').last;
              final folder = kmlData.findFolderByPath(path);
              final placemarkCount = folder?.placemarks.length ?? 0;

              return Padding(
                padding: EdgeInsets.only(left: depth * 12.0, bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      depth == 0 ? Icons.folder_open : Icons.folder,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        folderName,
                        style: textStyle?.copyWith(
                          fontSize: 12,
                          fontWeight:
                              depth == 0 ? FontWeight.w600 : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                    if (placemarkCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$placemarkCount',
                          style: textStyle?.copyWith(
                            fontSize: 10,
                            color: Colors.blue[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
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
        Text('$label:', style: labelStyle),
        const SizedBox(height: 2),
        Text(
          value,
          style: textStyle,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Geometry Types:', style: labelStyle),
        const SizedBox(height: 2),
        Text(
          geometryTypesText,
          style: textStyle,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      ],
    );
  }
}
