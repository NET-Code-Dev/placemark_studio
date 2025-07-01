import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class OutputPathSelector extends StatefulWidget {
  final String? selectedCsvPath;
  final String? currentOutputPath;
  final String defaultFileName;
  final Function(String?) onOutputPathChanged;
  final bool useDefaultLocation;
  final Function(bool) onUseDefaultLocationChanged;

  const OutputPathSelector({
    super.key,
    this.selectedCsvPath,
    this.currentOutputPath,
    required this.defaultFileName,
    required this.onOutputPathChanged,
    this.useDefaultLocation = true,
    required this.onUseDefaultLocationChanged,
  });

  @override
  State<OutputPathSelector> createState() => _OutputPathSelectorState();
}

class _OutputPathSelectorState extends State<OutputPathSelector> {
  bool _isSelectingPath = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Output Location',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Location options
            _buildLocationOptions(),

            const SizedBox(height: 16),

            // Path selector (only shown when custom location is selected)
            if (!widget.useDefaultLocation) ...[
              _buildPathSelector(),
              const SizedBox(height: 12),
            ],

            // Preview of final output path
            _buildPathPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationOptions() {
    return Column(
      children: [
        // Same directory as CSV option
        RadioListTile<bool>(
          value: true,
          groupValue: widget.useDefaultLocation,
          onChanged: (value) {
            if (value != null) {
              widget.onUseDefaultLocationChanged(value);
              if (value) {
                widget.onOutputPathChanged(null); // Clear custom path
              }
            }
          },
          title: const Text('Same folder as CSV file'),
          subtitle: Text(
            widget.selectedCsvPath != null
                ? 'Save in: ${path.dirname(widget.selectedCsvPath!)}'
                : 'Save in the same folder as your CSV file',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
          dense: true,
        ),

        // Custom location option
        RadioListTile<bool>(
          value: false,
          groupValue: widget.useDefaultLocation,
          onChanged: (value) {
            if (value != null) {
              widget.onUseDefaultLocationChanged(value);
              if (!value && widget.currentOutputPath == null) {
                _selectCustomPath(); // Auto-open selector when switching to custom
              }
            }
          },
          title: const Text('Choose custom location'),
          subtitle: const Text('Select a different folder for the output file'),
          dense: true,
        ),
      ],
    );
  }

  Widget _buildPathSelector() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            readOnly: true,
            decoration: InputDecoration(
              hintText:
                  widget.currentOutputPath != null
                      ? path.basename(widget.currentOutputPath!)
                      : 'Click Browse to select location',
              prefixIcon: const Icon(Icons.folder_outlined),
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            controller: TextEditingController(
              text:
                  widget.currentOutputPath != null
                      ? path.basename(widget.currentOutputPath!)
                      : '',
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 100,
          child: ElevatedButton(
            onPressed: _isSelectingPath ? null : _selectCustomPath,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child:
                _isSelectingPath
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Browse'),
          ),
        ),
      ],
    );
  }

  Widget _buildPathPreview() {
    final String finalPath = _getFinalOutputPath();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Output Preview',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            finalPath,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  String _getFinalOutputPath() {
    if (widget.useDefaultLocation && widget.selectedCsvPath != null) {
      final csvDir = path.dirname(widget.selectedCsvPath!);
      return path.join(csvDir, widget.defaultFileName);
    } else if (widget.currentOutputPath != null) {
      return widget.currentOutputPath!;
    } else {
      return 'No location selected';
    }
  }

  Future<void> _selectCustomPath() async {
    setState(() {
      _isSelectingPath = true;
    });

    try {
      // Get the default directory for file picker
      String? initialDirectory;
      if (widget.selectedCsvPath != null) {
        initialDirectory = path.dirname(widget.selectedCsvPath!);
      }

      // Use file picker to save file (this allows user to choose both location and filename)
      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Choose output location',
        fileName: widget.defaultFileName,
        initialDirectory: initialDirectory,
        type: FileType.custom,
        allowedExtensions: ['kml', 'kmz'],
      );

      if (outputPath != null) {
        widget.onOutputPathChanged(outputPath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select output path: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSelectingPath = false;
        });
      }
    }
  }
}
