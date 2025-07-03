import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

/// Panel for configuring image integration in KMZ exports
class ImageIntegrationPanel extends StatefulWidget {
  final List<String> availableColumns;
  final String? selectedImageColumn;
  final Function(String?) onImageColumnChanged;
  final List<File>? detectedImages;
  final Map<String, File>? imageAssociations;
  final Map<String, dynamic>? imageStatistics;
  final bool isLoading;
  final VoidCallback? onRefreshImages;

  const ImageIntegrationPanel({
    super.key,
    required this.availableColumns,
    this.selectedImageColumn,
    required this.onImageColumnChanged,
    this.detectedImages,
    this.imageAssociations,
    this.imageStatistics,
    this.isLoading = false,
    this.onRefreshImages,
  });

  @override
  State<ImageIntegrationPanel> createState() => _ImageIntegrationPanelState();
}

class _ImageIntegrationPanelState extends State<ImageIntegrationPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _buildHeader(),
          if (_expanded) ...[const Divider(height: 1), _buildContent()],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.image,
              color:
                  widget.selectedImageColumn != null
                      ? Colors.green[600]
                      : Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Image Integration',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStatusText(),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (widget.isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.grey[600],
              ),
          ],
        ),
      ),
    );
  }

  String _getStatusText() {
    if (widget.isLoading) {
      return 'Scanning for images...';
    }

    if (widget.selectedImageColumn == null) {
      return 'No image column selected';
    }

    if (widget.imageStatistics != null) {
      final stats = widget.imageStatistics!;
      final matches = stats['successfulMatches'] as int;
      final total = stats['uniqueImageValues'] as int;
      return '$matches of $total images found';
    }

    return 'Image column: ${widget.selectedImageColumn}';
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageColumnSelector(),
          if (widget.selectedImageColumn != null) ...[
            const SizedBox(height: 16),
            _buildImageDetectionSection(),
          ],
          if (widget.imageStatistics != null) ...[
            const SizedBox(height: 16),
            _buildImageStatistics(),
          ],
          if (widget.imageAssociations != null &&
              widget.imageAssociations!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildImagePreview(),
          ],
        ],
      ),
    );
  }

  Widget _buildImageColumnSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Image Column',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: widget.selectedImageColumn,
          decoration: const InputDecoration(
            hintText: 'Select column containing image filenames',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('No images'),
            ),
            ...widget.availableColumns.map(
              (column) =>
                  DropdownMenuItem<String>(value: column, child: Text(column)),
            ),
          ],
          onChanged: widget.onImageColumnChanged,
        ),
        const SizedBox(height: 8),
        Text(
          'Select the CSV column that contains image filenames. Images should be '
          'in the same folder as your CSV file.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildImageDetectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Detected Images',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (widget.onRefreshImages != null)
              TextButton.icon(
                onPressed: widget.isLoading ? null : widget.onRefreshImages,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[50],
          ),
          child:
              widget.isLoading
                  ? const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Scanning for images...'),
                    ],
                  )
                  : widget.detectedImages == null ||
                      widget.detectedImages!.isEmpty
                  ? const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('No images found in CSV folder'),
                    ],
                  )
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.detectedImages!.length} images found',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        children:
                            widget.detectedImages!
                                .take(5)
                                .map(
                                  (file) => Chip(
                                    label: Text(
                                      path.basename(file.path),
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                )
                                .toList(),
                      ),
                      if (widget.detectedImages!.length > 5)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '... and ${widget.detectedImages!.length - 5} more',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ),
                    ],
                  ),
        ),
      ],
    );
  }

  Widget _buildImageStatistics() {
    final stats = widget.imageStatistics!;
    final matchPercentage = stats['matchPercentage'] as double;
    final successfulMatches = stats['successfulMatches'] as int;
    final uniqueImageValues = stats['uniqueImageValues'] as int;
    final missingImages = stats['missingImages'] as int;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Matching Results',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Matched',
                '$successfulMatches',
                Colors.green,
                '${matchPercentage.toStringAsFixed(1)}%',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Missing',
                '$missingImages',
                missingImages > 0 ? Colors.orange : Colors.grey,
                '${(100 - matchPercentage).toStringAsFixed(1)}%',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Total',
                '$uniqueImageValues',
                Colors.blue,
                'unique',
              ),
            ),
          ],
        ),
        if (missingImages > 0) ...[
          const SizedBox(height: 12),
          _buildMissingImagesWarning(
            stats['missingImagesList'] as List<String>,
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.05),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingImagesWarning(List<String> missingImages) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.orange[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, size: 16, color: Colors.orange[700]),
              const SizedBox(width: 8),
              Text(
                'Missing Images',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'The following images referenced in your CSV were not found:',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children:
                missingImages
                    .take(8)
                    .map(
                      (image) => Chip(
                        label: Text(
                          image,
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor: Colors.orange[100],
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
          ),
          if (missingImages.length > 8)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '... and ${missingImages.length - 8} more',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Image Preview',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.imageAssociations!.length.clamp(0, 10),
            itemBuilder: (context, index) {
              final entry = widget.imageAssociations!.entries.elementAt(index);
              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 8),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.file(
                            entry.value,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      path.basename(entry.value.path),
                      style: const TextStyle(fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (widget.imageAssociations!.length > 10)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '... and ${widget.imageAssociations!.length - 10} more images',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ),
      ],
    );
  }
}
