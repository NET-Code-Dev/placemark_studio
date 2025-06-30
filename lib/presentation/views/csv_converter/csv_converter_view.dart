import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/csv_converter_viewmodel.dart';
import '../../../core/enums/conversion_step.dart';
import '../../../core/enums/export_format.dart';
import '../../../core/enums/geometry_type.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/models/column_mapping.dart';

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
              _buildProgressIndicator(context, viewModel),

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
      color: Theme.of(context).primaryColor.withOpacity(0.1),
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
              viewModel.error ?? 'An unknown error occurred',
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
            scrollDirection: Axis.both,
            child: DataTable(
              columns:
                  csvData.headers
                      .map(
                        (header) => DataColumn(
                          label: Text(
                            header,
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
      ],
    );
  }

  Widget _buildGeometryAndStylingStep(
    BuildContext context,
    CsvConverterViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Geometry & Styling',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),

        // Geometry type selection
        Text(
          'Geometry Type',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...GeometryType.values
            .where((type) => type.isSupportedForCsvConversion)
            .map(
              (type) => RadioListTile<GeometryType>(
                title: Text(type.displayName),
                subtitle: Text(type.description),
                value: type,
                groupValue: viewModel.selectedGeometryType,
                onChanged: (value) => viewModel.setGeometryType(value!),
              ),
            ),
      ],
    );
  }

  Widget _buildExportOptionsStep(
    BuildContext context,
    CsvConverterViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Export Options',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),

        // Export format selection
        Text(
          'Export Format',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...ExportFormat.values.map(
          (format) => RadioListTile<ExportFormat>(
            title: Text(format.displayName),
            subtitle: Text(format.description),
            value: format,
            groupValue: viewModel.selectedExportFormat,
            onChanged: (value) => viewModel.setExportFormat(value!),
          ),
        ),

        const SizedBox(height: 32),

        // Export summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Export Summary',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...viewModel.exportInfo.entries.map(
                (entry) => Text('${entry.key}: ${entry.value}'),
              ),
            ],
          ),
        ),
      ],
    );
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
    }
  }
}
