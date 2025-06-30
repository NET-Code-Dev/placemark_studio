import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/csv_converter_viewmodel.dart';
import '../../../../data/models/column_mapping.dart';
import '../../../../core/enums/conversion_step.dart';

class CsvColumnMappingPanel extends StatelessWidget {
  const CsvColumnMappingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CsvConverterViewModel>(
      builder: (context, viewModel, child) {
        if (!viewModel.hasCsvData) {
          return const _EmptyState();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.swap_horiz,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Map CSV Columns to KML Fields',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Tell us which columns contain your coordinate and label data',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Status indicator
                _MappingStatusIndicator(mapping: viewModel.columnMapping!),

                const SizedBox(height: 20),

                // Column mappings
                _ColumnMappingsSection(
                  availableColumns: viewModel.availableColumns,
                  currentMapping: viewModel.columnMapping!,
                  onMappingChanged: viewModel.updateColumnMapping,
                ),

                const SizedBox(height: 24),

                // Preview samples and actions
                Row(
                  children: [
                    Expanded(
                      child: _ColumnPreviewSection(
                        csvData: viewModel.csvData!,
                        mapping: viewModel.columnMapping!,
                      ),
                    ),
                    const SizedBox(width: 16),
                    _ActionButtons(
                      mapping: viewModel.columnMapping!,
                      onValidate: () => _validateAndProceed(context, viewModel),
                      onReset: () => _resetMappings(viewModel),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _validateAndProceed(
    BuildContext context,
    CsvConverterViewModel viewModel,
  ) {
    if (viewModel.columnMapping!.isValid) {
      viewModel.proceedToStep(ConversionStep.dataPreview);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Column mapping validated successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.columnMapping!.statusMessage),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _resetMappings(CsvConverterViewModel viewModel) {
    viewModel.updateColumnMapping(ColumnMapping.empty());
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.table_chart, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No CSV Data Available',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Please select a CSV file first',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

class _MappingStatusIndicator extends StatelessWidget {
  final ColumnMapping mapping;

  const _MappingStatusIndicator({required this.mapping});

  @override
  Widget build(BuildContext context) {
    final status = mapping.status;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: status.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(status.icon, color: status.color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mapping Status: ${status.name.toUpperCase()}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: status.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  mapping.statusMessage,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: status.color.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColumnMappingsSection extends StatelessWidget {
  final List<String> availableColumns;
  final ColumnMapping currentMapping;
  final Function(ColumnMapping) onMappingChanged;

  const _ColumnMappingsSection({
    required this.availableColumns,
    required this.currentMapping,
    required this.onMappingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Required mappings
        _SectionHeader('Required Fields', Icons.star, Colors.red),
        const SizedBox(height: 12),

        _MappingField(
          label: 'Latitude',
          description: 'Column containing latitude coordinates',
          icon: Icons.place,
          isRequired: true,
          currentValue: currentMapping.latitudeColumn,
          availableColumns: availableColumns,
          onChanged:
              (value) => onMappingChanged(
                currentMapping.copyWith(latitudeColumn: value),
              ),
        ),

        _MappingField(
          label: 'Longitude',
          description: 'Column containing longitude coordinates',
          icon: Icons.place,
          isRequired: true,
          currentValue: currentMapping.longitudeColumn,
          availableColumns: availableColumns,
          onChanged:
              (value) => onMappingChanged(
                currentMapping.copyWith(longitudeColumn: value),
              ),
        ),

        _MappingField(
          label: 'Name/Title',
          description: 'Column containing placemark names',
          icon: Icons.label,
          isRequired: true,
          currentValue: currentMapping.nameColumn,
          availableColumns: availableColumns,
          onChanged:
              (value) =>
                  onMappingChanged(currentMapping.copyWith(nameColumn: value)),
        ),

        const SizedBox(height: 20),

        // Optional mappings
        _SectionHeader('Optional Fields', Icons.tune, Colors.blue),
        const SizedBox(height: 12),

        _MappingField(
          label: 'Description',
          description: 'Column containing additional details',
          icon: Icons.description,
          isRequired: false,
          currentValue: currentMapping.descriptionColumn,
          availableColumns: availableColumns,
          onChanged:
              (value) => onMappingChanged(
                currentMapping.copyWith(descriptionColumn: value),
              ),
        ),

        _MappingField(
          label: 'Elevation',
          description: 'Column containing elevation/altitude data',
          icon: Icons.height,
          isRequired: false,
          currentValue: currentMapping.elevationColumn,
          availableColumns: availableColumns,
          onChanged:
              (value) => onMappingChanged(
                currentMapping.copyWith(elevationColumn: value),
              ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader(this.title, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _MappingField extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final bool isRequired;
  final String? currentValue;
  final List<String> availableColumns;
  final Function(String?) onChanged;

  const _MappingField({
    required this.label,
    required this.description,
    required this.icon,
    required this.isRequired,
    required this.currentValue,
    required this.availableColumns,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Field info
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isRequired) ...[
                      const SizedBox(width: 4),
                      Text(
                        '*',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Dropdown
          Expanded(
            flex: 1,
            child: DropdownButtonFormField<String>(
              value: currentValue,
              decoration: InputDecoration(
                hintText: 'Select column...',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                errorBorder:
                    isRequired && currentValue == null
                        ? OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red[400]!),
                        )
                        : null,
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('(none)', style: TextStyle(color: Colors.grey)),
                ),
                ...availableColumns.map((column) {
                  return DropdownMenuItem<String>(
                    value: column,
                    child: Text(column),
                  );
                }),
              ],
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _ColumnPreviewSection extends StatelessWidget {
  final dynamic csvData; // CsvData from the model
  final ColumnMapping mapping;

  const _ColumnPreviewSection({required this.csvData, required this.mapping});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sample Data Preview',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: SingleChildScrollView(child: _buildPreviewTable()),
        ),
      ],
    );
  }

  Widget _buildPreviewTable() {
    // Show sample data for mapped columns
    final mappedColumns = [
      if (mapping.latitudeColumn != null) mapping.latitudeColumn!,
      if (mapping.longitudeColumn != null) mapping.longitudeColumn!,
      if (mapping.nameColumn != null) mapping.nameColumn!,
      if (mapping.descriptionColumn != null) mapping.descriptionColumn!,
      if (mapping.elevationColumn != null) mapping.elevationColumn!,
    ];

    if (mappedColumns.isEmpty) {
      return const Center(
        child: Text(
          'Map columns to see preview',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Get sample data (first 3 rows)
    final sampleRows = csvData.rows.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children:
              mappedColumns.map((column) {
                return Expanded(
                  child: Text(
                    column,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
        ),
        const Divider(height: 8),

        // Sample rows
        ...sampleRows.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children:
                  mappedColumns.map((column) {
                    final value = row[column]?.toString() ?? '';
                    return Expanded(
                      child: Text(
                        value.isEmpty ? '—' : value,
                        style: TextStyle(
                          fontSize: 11,
                          color: value.isEmpty ? Colors.grey : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
            ),
          );
        }).toList(),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final ColumnMapping mapping;
  final VoidCallback onValidate;
  final VoidCallback onReset;

  const _ActionButtons({
    required this.mapping,
    required this.onValidate,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Validate button
        ElevatedButton.icon(
          onPressed: onValidate,
          icon: Icon(
            mapping.isValid ? Icons.check_circle : Icons.warning,
            size: 18,
          ),
          label: const Text('Validate & Continue'),
          style: ElevatedButton.styleFrom(
            backgroundColor: mapping.isValid ? Colors.green : Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),

        const SizedBox(height: 8),

        // Reset button
        TextButton.icon(
          onPressed: onReset,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Reset Mapping'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[700],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
        ),
      ],
    );
  }
}
