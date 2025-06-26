import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/home_viewmodel.dart';
import '../../../../core/enums/export_format.dart';
import '../../../../shared/widgets/custom_elevated_button.dart';

class ExportOptionsPanel extends StatelessWidget {
  const ExportOptionsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        if (!viewModel.hasKmlData) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Export Options',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                _ExportFormatSelector(),
                const SizedBox(height: 16),
                _LayerSeparationOption(),
                const SizedBox(height: 16),
                _OutputPathSelector(),
                if (viewModel.hasDuplicateHeaders) ...[
                  const SizedBox(height: 16),
                  _DuplicateHeadersPanel(),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: CustomElevatedButton(
                    onPressed:
                        viewModel.isLoading ? null : viewModel.convertFile,
                    label:
                        viewModel.isLoading ? 'Converting...' : 'Convert File',
                    icon:
                        viewModel.isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Icon(Icons.download),
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

class _ExportFormatSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Format',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<ExportFormat>(
              value: viewModel.selectedExportFormat,
              decoration: const InputDecoration(
                hintText: 'Select export format',
              ),
              items:
                  viewModel.supportedFormats.map((format) {
                    return DropdownMenuItem(
                      value: format,
                      child: Row(
                        children: [
                          Text(
                            format.code,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '- ${format.description}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              onChanged: (format) {
                if (format != null) {
                  viewModel.setSelectedExportFormat(format);
                }
              },
            ),
          ],
        );
      },
    );
  }
}

class _LayerSeparationOption extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Layer Output', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  RadioListTile<bool>(
                    title: const Text('Single file (all layers combined)'),
                    subtitle: Text(
                      'All data in one file',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                    value: false,
                    groupValue: viewModel.separateLayers,
                    onChanged: (value) {
                      if (value != null) {
                        viewModel.setSeparateLayers(value);
                      }
                    },
                    dense: true,
                  ),
                  const Divider(height: 1),
                  RadioListTile<bool>(
                    title: const Text('Separate files by layer'),
                    subtitle: Text(
                      'Each layer in its own file (organized in folder)',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                    value: true,
                    groupValue: viewModel.separateLayers,
                    onChanged: (value) {
                      if (value != null) {
                        viewModel.setSeparateLayers(value);
                      }
                    },
                    dense: true,
                  ),
                ],
              ),
            ),
            if (viewModel.separateLayers &&
                viewModel.kmlData!.layersCount > 1) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border.all(color: Colors.blue[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Will create ${viewModel.kmlData!.layersCount} separate files in a new folder',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _OutputPathSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Output Location',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText:
                          viewModel.hasOutputPath
                              ? viewModel.outputPath
                              : 'Same folder as input file',
                      suffixIcon: const Icon(Icons.folder),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: viewModel.selectOutputPath,
                  child: const Text('Browse'),
                ),
              ],
            ),
            if (viewModel.hasOutputPath) ...[
              const SizedBox(height: 4),
              Text(
                viewModel.separateLayers
                    ? 'Files will be saved in: ${viewModel.outputPath?.split('/').last ?? ''}'
                    : 'File will be saved as: ${viewModel.outputPath?.split('/').last ?? ''}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _DuplicateHeadersPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        final duplicates = viewModel.duplicateHeaders ?? {};

        if (duplicates.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Duplicate Headers Found',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: Colors.orange[700]),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                border: Border.all(color: Colors.orange[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'The following headers appear multiple times in your data:',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  ...duplicates.entries.map((entry) {
                    return _DuplicateHeaderItem(
                      header: entry.key,
                      sources: entry.value,
                      isEnabled: viewModel.duplicateHandling[entry.key] ?? true,
                      onChanged: (value) {
                        viewModel.setDuplicateHandling(entry.key, value);
                      },
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DuplicateHeaderItem extends StatelessWidget {
  final String header;
  final List<String> sources;
  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  const _DuplicateHeaderItem({
    required this.header,
    required this.sources,
    required this.isEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Checkbox(
            value: isEnabled,
            onChanged: (value) => onChanged(value ?? false),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  header,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Found in: ${sources.join(', ')}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
