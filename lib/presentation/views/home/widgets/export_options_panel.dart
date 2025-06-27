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
                _LayerSeparationOption(),
                const SizedBox(height: 16),
                // Row for Export Format and Output Location
                Row(
                  children: [
                    Expanded(flex: 1, child: _ExportFormatSelector()),
                    const SizedBox(width: 10),
                    Expanded(flex: 2, child: _OutputPathSelector()),
                  ],
                ),
                if (viewModel.hasDuplicateHeaders) ...[
                  const SizedBox(height: 16),
                  _SimplifiedDuplicateHeadersPanel(),
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
                hintText: 'Select format',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
              items:
                  viewModel.supportedFormats.map((format) {
                    return DropdownMenuItem(
                      value: format,
                      child: Text(
                        format.code,
                        style: const TextStyle(fontWeight: FontWeight.w600),
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
        final kmlData = viewModel.kmlData!;
        final hasHierarchy = kmlData.hasHierarchy;
        final folderCount =
            hasHierarchy ? kmlData.totalFolderCount : kmlData.layersCount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Layer Output',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                if (hasHierarchy) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${kmlData.maxFolderDepth} levels deep',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green[800],
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            // Row layout for radio buttons
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => viewModel.setSeparateLayers(false),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              !viewModel.separateLayers
                                  ? Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.1)
                                  : null,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Radio<bool>(
                              value: false,
                              groupValue: viewModel.separateLayers,
                              onChanged: (value) {
                                if (value != null) {
                                  viewModel.setSeparateLayers(value);
                                }
                              },
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Single file',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    hasHierarchy
                                        ? 'All folders flattened'
                                        : 'All layers combined',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => viewModel.setSeparateLayers(true),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              viewModel.separateLayers
                                  ? Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.1)
                                  : null,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Radio<bool>(
                              value: true,
                              groupValue: viewModel.separateLayers,
                              onChanged: (value) {
                                if (value != null) {
                                  viewModel.setSeparateLayers(value);
                                }
                              },
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Separate files',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    hasHierarchy
                                        ? 'Preserve folder structure'
                                        : 'Each layer in own file',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (viewModel.separateLayers && folderCount > 1) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hasHierarchy ? Colors.green[50] : Colors.blue[50],
                  border: Border.all(
                    color:
                        hasHierarchy ? Colors.green[200]! : Colors.blue[200]!,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasHierarchy ? Icons.account_tree : Icons.info_outline,
                      color:
                          hasHierarchy ? Colors.green[700] : Colors.blue[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hasHierarchy
                            ? 'Will create ${folderCount} files maintaining the original folder structure with up to ${kmlData.maxFolderDepth} nesting levels'
                            : 'Will create ${folderCount} separate files in a new folder',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              hasHierarchy
                                  ? Colors.green[700]
                                  : Colors.blue[700],
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
                              ? viewModel.outputPath?.split('/').last ?? ''
                              : 'Same folder as input file',
                      suffixIcon: const Icon(Icons.folder),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80, // Fixed width for Browse button
                  child: ElevatedButton(
                    onPressed: viewModel.selectOutputPath,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Browse'),
                  ),
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

class _SimplifiedDuplicateHeadersPanel extends StatelessWidget {
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
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Duplicate Headers Found',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: Colors.orange[700]),
                ),
              ],
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
                    'The following headers appear multiple times:',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children:
                        duplicates.entries.map((entry) {
                          return _DuplicateHeaderChip(
                            header: entry.key,
                            sources: entry.value,
                            isEnabled:
                                viewModel.duplicateHandling[entry.key] ?? true,
                            onChanged: (value) {
                              viewModel.setDuplicateHandling(entry.key, value);
                            },
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DuplicateHeaderChip extends StatelessWidget {
  final String header;
  final List<String> sources;
  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  const _DuplicateHeaderChip({
    required this.header,
    required this.sources,
    required this.isEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isEnabled),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isEnabled ? Colors.orange[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEnabled ? Colors.orange[300]! : Colors.grey[400]!,
          ),
        ),
        child: IntrinsicWidth(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isEnabled ? Icons.check_circle : Icons.cancel,
                size: 16,
                color: isEnabled ? Colors.orange[700] : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  header,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isEnabled ? Colors.orange[800] : Colors.grey[700],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _showSourcesDialog(context),
                child: Icon(
                  Icons.info_outline,
                  size: 14,
                  color: isEnabled ? Colors.orange[600] : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSourcesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Header: "$header"'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Found in the following locations:',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                ...sources.map(
                  (source) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            source,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}
