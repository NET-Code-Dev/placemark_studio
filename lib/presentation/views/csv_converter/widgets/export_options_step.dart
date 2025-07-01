import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../../../../core/enums/export_format.dart';
import '../../../../core/enums/geometry_type.dart';
import 'output_path_selector.dart';

class ExportOptionsStep extends StatefulWidget {
  final String? selectedCsvPath;
  final String? currentOutputPath;
  final ExportFormat selectedFormat;
  final GeometryType geometryType;
  final Function(String?) onOutputPathChanged;
  final Function(ExportFormat) onFormatChanged;
  final bool useDefaultLocation;
  final Function(bool) onUseDefaultLocationChanged;

  const ExportOptionsStep({
    super.key,
    this.selectedCsvPath,
    this.currentOutputPath,
    required this.selectedFormat,
    required this.geometryType,
    required this.onOutputPathChanged,
    required this.onFormatChanged,
    this.useDefaultLocation = true,
    required this.onUseDefaultLocationChanged,
  });

  @override
  State<ExportOptionsStep> createState() => _ExportOptionsStepState();
}

class _ExportOptionsStepState extends State<ExportOptionsStep> {
  String get _defaultFileName {
    final baseName =
        widget.selectedCsvPath != null
            ? path.basenameWithoutExtension(widget.selectedCsvPath!)
            : 'converted_data';

    final extension =
        widget.selectedFormat == ExportFormat.kmz ? '.kmz' : '.kml';
    return '$baseName$extension';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step description
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Export Options',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Configure output format and location for your converted file.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Export format selection
          _buildFormatSelector(),

          const SizedBox(height: 24),

          // Output path selection
          OutputPathSelector(
            selectedCsvPath: widget.selectedCsvPath,
            currentOutputPath: widget.currentOutputPath,
            defaultFileName: _defaultFileName,
            onOutputPathChanged: widget.onOutputPathChanged,
            useDefaultLocation: widget.useDefaultLocation,
            onUseDefaultLocationChanged: widget.onUseDefaultLocationChanged,
          ),

          const SizedBox(height: 24),

          // Export summary
          _buildExportSummary(),
        ],
      ),
    );
  }

  Widget _buildFormatSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Output Format',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                // KML option
                Expanded(
                  child: RadioListTile<ExportFormat>(
                    value: ExportFormat.kml,
                    groupValue: widget.selectedFormat,
                    onChanged: (format) {
                      if (format != null) {
                        widget.onFormatChanged(format);
                      }
                    },
                    title: const Text('KML'),
                    subtitle: const Text(
                      'Keyhole Markup Language\nStandard format for Google Earth',
                    ),
                    dense: true,
                  ),
                ),

                // KMZ option
                Expanded(
                  child: RadioListTile<ExportFormat>(
                    value: ExportFormat.kmz,
                    groupValue: widget.selectedFormat,
                    onChanged: (format) {
                      if (format != null) {
                        widget.onFormatChanged(format);
                      }
                    },
                    title: const Text('KMZ'),
                    subtitle: const Text(
                      'Compressed KML\nSmaller file size, supports images',
                    ),
                    dense: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportSummary() {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600]),
                const SizedBox(width: 8),
                Text(
                  'Ready to Export',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildSummaryRow(
              'Format',
              widget.selectedFormat.name.toUpperCase(),
            ),
            _buildSummaryRow('Geometry', widget.geometryType.displayName),
            _buildSummaryRow('Output file', _defaultFileName),

            if (widget.useDefaultLocation && widget.selectedCsvPath != null)
              _buildSummaryRow('Location', 'Same folder as CSV file')
            else if (widget.currentOutputPath != null)
              _buildSummaryRow(
                'Location',
                path.dirname(widget.currentOutputPath!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.green[800]),
            ),
          ),
        ],
      ),
    );
  }
}
