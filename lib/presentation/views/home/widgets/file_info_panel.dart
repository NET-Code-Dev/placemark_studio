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
                      const SizedBox(width: 8),
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
                Expanded(
                  child: SingleChildScrollView(
                    child: _InfoColumn(kmlData: kmlData),
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

        // Folder/Layer information
        if (kmlData.hasHierarchy) ...[
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
          const SizedBox(height: 12),
          _HierarchyPreview(
            kmlData: kmlData,
            textStyle: textStyle,
            labelStyle: labelStyle,
          ),
        ] else ...[
          _InfoItem(
            label: 'Layers Count',
            value: '${kmlData.layersCount}',
            labelStyle: labelStyle,
            textStyle: textStyle,
          ),
        ],

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

class _HierarchyPreview extends StatefulWidget {
  final KmlData kmlData;
  final TextStyle? textStyle;
  final TextStyle? labelStyle;

  const _HierarchyPreview({
    required this.kmlData,
    this.textStyle,
    this.labelStyle,
  });

  @override
  State<_HierarchyPreview> createState() => _HierarchyPreviewState();
}

class _HierarchyPreviewState extends State<_HierarchyPreview> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.kmlData.hasHierarchy) return const SizedBox.shrink();

    final folderPaths = widget.kmlData.folderStructure!.getAllFolderPaths();
    final previewPaths =
        _isExpanded ? folderPaths : folderPaths.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Folder Structure:', style: widget.labelStyle),
            ),
            if (folderPaths.length > 3)
              GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Text(
                  _isExpanded
                      ? 'Show Less'
                      : 'Show All (${folderPaths.length})',
                  style: widget.textStyle?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...previewPaths.map((path) {
                final depth = path.split('/').length - 1;
                final folderName = path.split('/').last;
                final folder = widget.kmlData.findFolderByPath(path);
                final placemarkCount = folder?.placemarks.length ?? 0;

                return Padding(
                  padding: EdgeInsets.only(left: depth * 16.0, bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        depth == 0 ? Icons.folder_open : Icons.folder,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          folderName,
                          style: widget.textStyle?.copyWith(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (placemarkCount > 0)
                        Text(
                          '($placemarkCount)',
                          style: widget.textStyle?.copyWith(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
              if (!_isExpanded && folderPaths.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '... and ${folderPaths.length - 3} more folders',
                    style: widget.textStyle?.copyWith(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
            ],
          ),
        ),
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
