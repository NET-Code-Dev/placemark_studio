import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/csv_converter_viewmodel.dart';
import '../../../core/enums/conversion_step.dart';
import '../../../core/enums/export_format.dart';
import '../../../core/enums/geometry_type.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/models/column_mapping.dart';
import '../../../data/models/styling_compatibility.dart';
import 'widgets/styling_integration.dart'; // Updated import
import 'widgets/export_options_step.dart';

class CsvConverterView extends StatelessWidget {
  const CsvConverterView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => getIt<CsvConverterViewModel>(),
      child: const _CsvConverterContent(),
    );
  }
}

class _CsvConverterContent extends StatelessWidget {
  const _CsvConverterContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CSV to KML/KMZ Converter'),
        centerTitle: true,
      ),
      body: Consumer<CsvConverterViewModel>(
        builder: (context, viewModel, child) {
          return Column(
            children: [
              // Progress indicator
              //  _buildProgressIndicator(context, viewModel),

              // Main content area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildCurrentStepContent(context, viewModel),
                ),
              ),

              // Action buttons
              _buildActionButtons(context, viewModel),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgressIndicator(
    BuildContext context,
    CsvConverterViewModel viewModel,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      child: Column(
        children: [
          Text(
            viewModel.currentStep.displayName,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            viewModel.currentStep.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: viewModel.currentStep.progressPercentage / 100,
            backgroundColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepContent(
    BuildContext context,
    CsvConverterViewModel viewModel,
  ) {
    if (viewModel.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Processing...'),
          ],
        ),
      );
    }

    if (viewModel.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              viewModel.errorMessage ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => viewModel.resetConverter(),
              child: const Text('Start Over'),
            ),
          ],
        ),
      );
    }

    switch (viewModel.currentStep) {
      case ConversionStep.fileSelection:
        return _buildFileSelectionStep(context, viewModel);
      case ConversionStep.columnMapping:
        return _buildColumnMappingStep(context, viewModel);
      case ConversionStep.dataPreview:
        return _buildDataPreviewStep(context, viewModel);
      case ConversionStep.geometryAndStyling:
        return _buildGeometryAndStylingStep(context, viewModel);
      // ADD THIS CASE - this is what's missing!
      case ConversionStep.exportOptions:
        return _buildExportOptionsStep(context, viewModel);
      case ConversionStep.exportComplete:
        return _buildExportCompleteStep(context, viewModel);
    }
  }

  Widget _buildFileSelectionStep(
    BuildContext context,
    CsvConverterViewModel viewModel,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.upload_file, size: 96, color: Colors.blue[400]),
          const SizedBox(height: 24),
          Text(
            'Select CSV File',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Choose a CSV file containing location data to convert to KML/KMZ format.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => viewModel.pickCsvFile(),
            icon: const Icon(Icons.file_open),
            label: const Text('Choose CSV File'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnMappingStep(
    BuildContext context,
    CsvConverterViewModel viewModel,
  ) {
    final csvData = viewModel.csvData;
    if (csvData == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Map CSV Columns',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Tell us which columns contain the required data for your placemarks.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),

        Expanded(
          child: ListView(
            children: [
              _buildColumnDropdown(
                context,
                'Name/Title Column *',
                viewModel.columnMapping?.nameColumn,
                csvData.headers,
                (value) => viewModel.updateColumnMapping(
                  viewModel.columnMapping?.copyWith(nameColumn: value) ??
                      ColumnMapping(nameColumn: value),
                ),
              ),
              _buildColumnDropdown(
                context,
                'Latitude Column *',
                viewModel.columnMapping?.latitudeColumn,
                csvData.headers,
                (value) => viewModel.updateColumnMapping(
                  viewModel.columnMapping?.copyWith(latitudeColumn: value) ??
                      ColumnMapping(latitudeColumn: value),
                ),
              ),
              _buildColumnDropdown(
                context,
                'Longitude Column *',
                viewModel.columnMapping?.longitudeColumn,
                csvData.headers,
                (value) => viewModel.updateColumnMapping(
                  viewModel.columnMapping?.copyWith(longitudeColumn: value) ??
                      ColumnMapping(longitudeColumn: value),
                ),
              ),
              _buildColumnDropdown(
                context,
                'Elevation Column (Optional)',
                viewModel.columnMapping?.elevationColumn,
                csvData.headers,
                (value) => viewModel.updateColumnMapping(
                  viewModel.columnMapping?.copyWith(elevationColumn: value) ??
                      ColumnMapping(elevationColumn: value),
                ),
                allowNull: true,
              ),
              _buildColumnDropdown(
                context,
                'Description Column (Optional)',
                viewModel.columnMapping?.descriptionColumn,
                csvData.headers,
                (value) => viewModel.updateColumnMapping(
                  viewModel.columnMapping?.copyWith(descriptionColumn: value) ??
                      ColumnMapping(descriptionColumn: value),
                ),
                allowNull: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataPreviewStep(
    BuildContext context,
    CsvConverterViewModel viewModel,
  ) {
    final csvData = viewModel.csvData;
    if (csvData == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data Preview',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Validation results
        if (csvData.hasValidCoordinates) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    csvData.getValidationSummary(),
                    style: TextStyle(color: Colors.green[700]),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No valid coordinate data found. Please check your column mapping.',
                    style: TextStyle(color: Colors.orange[700]),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Data table preview
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                columns:
                    csvData.headers
                        .map(
                          (header) => DataColumn(
                            label: Text(
                              header,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                rows:
                    csvData.rows
                        .take(10)
                        .map(
                          (row) => DataRow(
                            cells:
                                csvData.headers
                                    .map(
                                      (header) => DataCell(
                                        Text(row[header]?.toString() ?? ''),
                                      ),
                                    )
                                    .toList(),
                          ),
                        )
                        .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGeometryAndStylingStep(
    BuildContext context,
    CsvConverterViewModel viewModel,
  ) {
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
                    'Geometry & Styling Configuration',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose the geometry type and configure styling rules for your KML output.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Geometry type selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Geometry Type',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children:
                        GeometryType.values
                            .where((type) => type.isSupportedForCsvConversion)
                            .map((type) {
                              final isSelected =
                                  viewModel.selectedGeometryType == type;
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: InkWell(
                                    onTap:
                                        () => viewModel.setGeometryType(type),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color:
                                            isSelected
                                                ? Theme.of(context).primaryColor
                                                    .withValues(alpha: 0.1)
                                                : Colors.grey[100],
                                        border: Border.all(
                                          color:
                                              isSelected
                                                  ? Theme.of(
                                                    context,
                                                  ).primaryColor
                                                  : Colors.grey[300]!,
                                          width: isSelected ? 2 : 1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        children: [
                                          _getGeometryIcon(type, isSelected),
                                          const SizedBox(height: 8),
                                          Text(
                                            type.displayName,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.copyWith(
                                              fontWeight:
                                                  isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                              color:
                                                  isSelected
                                                      ? Theme.of(
                                                        context,
                                                      ).primaryColor
                                                      : null,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            type.description,
                                            style:
                                                Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            })
                            .toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // UPDATED: Enhanced styling integration
          StylingIntegration(
            geometryType: viewModel.selectedGeometryType,
            csvData: viewModel.csvData,
            availableColumns: viewModel.availableColumns,
            onStylingChanged: (enhancedOptions) {
              // Use the new enhanced styling method
              viewModel.updateEnhancedStylingOptions(enhancedOptions);
            },
            initialOptions: viewModel.enhancedStylingOptions,
          ),

          const SizedBox(height: 24),

          // Real-time validation section
          _buildValidationSection(context, viewModel),
        ],
      ),
    );
  }

  // Add debug information panel
  Widget _buildValidationSection(
    BuildContext context,
    CsvConverterViewModel viewModel,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Configuration Summary',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (viewModel.csvData != null) ...[
              _buildInfoRow('Total rows', '${viewModel.csvData!.rows.length}'),
              _buildInfoRow(
                'Valid coordinates',
                '${viewModel.csvData!.validRowCount}',
              ),
              _buildInfoRow(
                'Geometry type',
                viewModel.selectedGeometryType.displayName,
              ),

              // Enhanced styling information
              if (viewModel.useEnhancedStyling &&
                  viewModel.enhancedStylingOptions.useRuleBasedStyling) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green[600],
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Enhanced Styling Active',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        'Styling column',
                        viewModel.enhancedStylingOptions.stylingColumn ??
                            'None',
                      ),
                      _buildInfoRow(
                        'Active rules',
                        '${viewModel.enhancedStylingOptions.rules.where((r) => r.isEnabled).length}',
                      ),
                      _buildInfoRow(
                        'Total rules',
                        '${viewModel.enhancedStylingOptions.rules.length}',
                      ),
                    ],
                  ),
                ),
              ] else ...[
                _buildInfoRow('Styling', 'Default styling will be applied'),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _getGeometryIcon(GeometryType type, bool isSelected) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case GeometryType.point:
        iconData = Icons.place;
        iconColor = Colors.red;
        break;
      case GeometryType.lineString:
        iconData = Icons.timeline;
        iconColor = Colors.blue;
        break;
      case GeometryType.polygon:
        iconData = Icons.crop_free;
        iconColor = Colors.green;
        break;
      default:
        iconData = Icons.location_on;
        iconColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color:
            isSelected
                ? iconColor.withValues(alpha: 0.2)
                : iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: isSelected ? iconColor : iconColor.withValues(alpha: 0.7),
        size: 24,
      ),
    );
  }

  Widget _buildValidationItem(
    BuildContext context,
    String label,
    String value,
    bool isValid,
  ) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check : Icons.warning,
          size: 16,
          color: isValid ? Colors.green[600] : Colors.orange[600],
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }

  Widget _buildExportOptionsStep(
    BuildContext context,
    CsvConverterViewModel viewModel,
  ) {
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
          _buildFormatSelector(context, viewModel),

          const SizedBox(height: 24),

          // Output path selection
          _buildOutputPathSelector(context, viewModel),

          const SizedBox(height: 24),

          // Export summary
          _buildExportSummary(context, viewModel),
        ],
      ),
    );
  }

  // Add these helper methods to your csv_converter_view.dart:

  Widget _buildFormatSelector(
    BuildContext context,
    CsvConverterViewModel viewModel,
  ) {
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
                    groupValue: viewModel.selectedExportFormat,
                    onChanged: (format) {
                      if (format != null) {
                        viewModel.setExportFormat(format);
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
                    groupValue: viewModel.selectedExportFormat,
                    onChanged: (format) {
                      if (format != null) {
                        viewModel.setExportFormat(format);
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

  Widget _buildOutputPathSelector(
    BuildContext context,
    CsvConverterViewModel viewModel,
  ) {
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
            Column(
              children: [
                // Same directory as CSV option
                RadioListTile<bool>(
                  value: true,
                  groupValue: viewModel.useDefaultLocation,
                  onChanged: (value) {
                    if (value != null) {
                      viewModel.setUseDefaultLocation(value);
                    }
                  },
                  title: const Text('Same folder as CSV file'),
                  subtitle: Text(
                    viewModel.csvFilePath != null
                        ? 'Save in: ${viewModel.csvFilePath!.split('/').last.split('\\').last.replaceAll(RegExp(r'\.[^.]*$'), '')}'
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
                  groupValue: viewModel.useDefaultLocation,
                  onChanged: (value) {
                    if (value != null) {
                      viewModel.setUseDefaultLocation(value);
                      if (!value) {
                        _selectCustomPath(context, viewModel);
                      }
                    }
                  },
                  title: const Text('Choose custom location'),
                  subtitle: const Text(
                    'Select a different folder for the output file',
                  ),
                  dense: true,
                ),
              ],
            ),

            // Custom path selector (only shown when custom location is selected)
            if (!viewModel.useDefaultLocation) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText:
                            viewModel.customOutputPath != null
                                ? viewModel.customOutputPath!
                                    .split('/')
                                    .last
                                    .split('\\')
                                    .last
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
                            viewModel.customOutputPath != null
                                ? viewModel.customOutputPath!
                                    .split('/')
                                    .last
                                    .split('\\')
                                    .last
                                : '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 100,
                    child: ElevatedButton(
                      onPressed: () => _selectCustomPath(context, viewModel),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Browse'),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Preview of final output path
            _buildPathPreview(context, viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildPathPreview(
    BuildContext context,
    CsvConverterViewModel viewModel,
  ) {
    final String finalPath = viewModel.finalOutputPath;

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

  Widget _buildExportSummary(
    BuildContext context,
    CsvConverterViewModel viewModel,
  ) {
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
              viewModel.selectedExportFormat.name.toUpperCase(),
            ),
            _buildSummaryRow(
              'Geometry',
              viewModel.selectedGeometryType.displayName,
            ),
            _buildSummaryRow('Output file', viewModel.defaultFileName),

            if (viewModel.useDefaultLocation && viewModel.csvFilePath != null)
              _buildSummaryRow('Location', 'Same folder as CSV file')
            else if (viewModel.customOutputPath != null)
              _buildSummaryRow(
                'Location',
                viewModel.customOutputPath!.split('/').last.split('\\').first,
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
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  Future<void> _selectCustomPath(
    BuildContext context,
    CsvConverterViewModel viewModel,
  ) async {
    try {
      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Choose output location',
        fileName: viewModel.defaultFileName,
        type: FileType.custom,
        allowedExtensions: ['kml', 'kmz'],
      );

      if (outputPath != null) {
        viewModel.setCustomOutputPath(outputPath);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select output path: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildExportCompleteStep(
    BuildContext context,
    CsvConverterViewModel viewModel,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 96, color: Colors.green[400]),
          const SizedBox(height: 24),
          Text(
            'Export Complete!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 16),
          if (viewModel.successMessage != null) ...[
            Text(
              viewModel.successMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => viewModel.openOutputFolder(),
                icon: const Icon(Icons.folder_open),
                label: const Text('Open Folder'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => viewModel.resetConverter(),
                icon: const Icon(Icons.refresh),
                label: const Text('Convert Another'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColumnDropdown(
    BuildContext context,
    String label,
    String? currentValue,
    List<String> options,
    Function(String?) onChanged, {
    bool allowNull = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            value: currentValue,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              hintText:
                  allowNull ? 'Select column (optional)' : 'Select column',
            ),
            items: [
              if (allowNull)
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('(None)'),
                ),
              ...options.map(
                (option) => DropdownMenuItem<String?>(
                  value: option,
                  child: Text(option),
                ),
              ),
            ],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    CsvConverterViewModel viewModel,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          // Back button
          if (viewModel.currentStep != ConversionStep.fileSelection &&
              viewModel.currentStep != ConversionStep.exportComplete)
            Expanded(
              child: OutlinedButton(
                onPressed: () => _goToPreviousStep(viewModel),
                child: const Text('Back'),
              ),
            ),

          if (viewModel.currentStep != ConversionStep.fileSelection &&
              viewModel.currentStep != ConversionStep.exportComplete)
            const SizedBox(width: 16),

          // Next/Action button
          Expanded(
            flex: 2,
            child: _buildPrimaryActionButton(context, viewModel),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryActionButton(
    BuildContext context,
    CsvConverterViewModel viewModel,
  ) {
    switch (viewModel.currentStep) {
      case ConversionStep.fileSelection:
        return const SizedBox(); // File selection handled in main content

      case ConversionStep.columnMapping:
        return ElevatedButton(
          onPressed:
              viewModel.hasValidMapping
                  ? () => _validateAndProceed(viewModel)
                  : null,
          child: const Text('Validate Data'),
        );

      case ConversionStep.dataPreview:
        return ElevatedButton(
          onPressed:
              viewModel.canProceedToStyling
                  ? () =>
                      viewModel.proceedToStep(ConversionStep.geometryAndStyling)
                  : null,
          child: const Text('Continue to Styling'),
        );

      case ConversionStep.geometryAndStyling:
        return ElevatedButton(
          onPressed:
              () => viewModel.proceedToStep(ConversionStep.exportOptions),
          child: const Text('Continue to Export'),
        );

      case ConversionStep.exportOptions:
        return ElevatedButton(
          onPressed:
              viewModel.canExport ? () => _performExport(viewModel) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Export File'),
        );

      case ConversionStep.exportComplete:
        return ElevatedButton(
          onPressed: () => viewModel.resetConverter(),
          child: const Text('Convert Another File'),
        );
    }
  }

  void _goToPreviousStep(CsvConverterViewModel viewModel) {
    final previousStep = viewModel.currentStep.previous;
    if (previousStep != null) {
      viewModel.proceedToStep(previousStep);
    }
  }

  void _validateAndProceed(CsvConverterViewModel viewModel) {
    viewModel.validateData();
    // The validation will automatically proceed to preview if successful
    if (viewModel.csvData?.hasValidCoordinates == true) {
      viewModel.proceedToStep(ConversionStep.dataPreview);
    }
  }

  void _performExport(CsvConverterViewModel viewModel) {
    switch (viewModel.selectedExportFormat) {
      case ExportFormat.kml:
        viewModel.exportToKml();
        break;
      case ExportFormat.kmz:
        viewModel.exportToKmz();
        break;
      case ExportFormat.csv:
      case ExportFormat.dgn:
      case ExportFormat.dxf:
      case ExportFormat.esriFileGdb:
      case ExportFormat.shapefile:
      case ExportFormat.flatGeobuf:
      case ExportFormat.gml:
      case ExportFormat.geoPackage:
      case ExportFormat.gpx:
      case ExportFormat.geoJson:
      case ExportFormat.geoJsonSeq:
      case ExportFormat.mbTiles:
      case ExportFormat.mvt:
      case ExportFormat.mapInfoTab:
      case ExportFormat.ods:
      case ExportFormat.pdf:
      case ExportFormat.parquet:
      case ExportFormat.sqlite:
      case ExportFormat.svg:
      case ExportFormat.topoJson:
      case ExportFormat.wkt:
      case ExportFormat.xlsx:
        // These formats are not supported for CSV conversion
        // Default to KML export
        viewModel.exportToKml();
        break;
    }
  }
}
