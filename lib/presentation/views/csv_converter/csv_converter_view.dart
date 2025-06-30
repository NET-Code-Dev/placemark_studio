import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/enums/conversion_step.dart';
import '../../viewmodels/csv_converter_viewmodel.dart';
import 'widgets/csv_file_selection_card.dart';
import 'widgets/csv_column_mapping_panel.dart';
import 'widgets/csv_preview_table.dart';
import 'widgets/geometry_type_selector.dart';
import 'widgets/styling_options_panel.dart';
import 'widgets/kml_export_panel.dart';
import '../../../shared/widgets/status_message_card.dart';

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
    return Consumer<CsvConverterViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('CSV to KML/KMZ Converter'),
            actions: [
              if (viewModel.hasCsvData)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Start over',
                  onPressed: viewModel.reset,
                ),
            ],
          ),
          body: Column(
            children: [
              // Status messages
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Consumer<CsvConverterViewModel>(
                  builder: (context, viewModel, child) {
                    return StatusMessageCard(
                      hasError: viewModel.hasError,
                      errorMessage: viewModel.errorMessage,
                      successMessage: viewModel.successMessage,
                      onDismissError: viewModel.clearError,
                      onDismissSuccess: viewModel.clearMessages,
                    );
                  },
                ),
              ),

              // Main content
              Expanded(child: _buildMainContent(viewModel)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainContent(CsvConverterViewModel viewModel) {
    if (!viewModel.hasCsvData) {
      return const _FileSelectionView();
    }

    return const _ConversionWorkflowView();
  }
}

class _FileSelectionView extends StatelessWidget {
  const _FileSelectionView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            CsvFileSelectionCard(),
            SizedBox(height: 24),
            _CsvFormatGuide(),
          ],
        ),
      ),
    );
  }
}

class _ConversionWorkflowView extends StatelessWidget {
  const _ConversionWorkflowView();

  @override
  Widget build(BuildContext context) {
    return Consumer<CsvConverterViewModel>(
      builder: (context, viewModel, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step 1: Column Mapping
              _WorkflowStep(
                stepNumber: 1,
                title: 'Map Columns',
                subtitle:
                    'Specify which CSV columns contain coordinate and label data',
                isActive: viewModel.currentStep >= ConversionStep.columnMapping,
                isCompleted:
                    viewModel.currentStep > ConversionStep.columnMapping,
                child:
                    viewModel.currentStep >= ConversionStep.columnMapping
                        ? const CsvColumnMappingPanel()
                        : null,
              ),

              const SizedBox(height: 16),

              // Step 2: Preview Data - REPLACE existing step
              _WorkflowStep(
                stepNumber: 2,
                title: 'Preview & Validate Data',
                subtitle: 'Review your data and validate coordinates',
                isActive: viewModel.currentStep >= ConversionStep.dataPreview,
                isCompleted: viewModel.currentStep > ConversionStep.dataPreview,
                canActivate: viewModel.columnMapping?.hasCoordinates ?? false,
                inactiveReason:
                    viewModel.columnMapping?.hasCoordinates == false
                        ? 'Complete column mapping first'
                        : null,
                child:
                    viewModel.currentStep >= ConversionStep.dataPreview
                        ? const CsvPreviewTable()
                        : null,
              ),

              const SizedBox(height: 16),

              // Step 3: Geometry & Styling - REPLACE existing step
              _WorkflowStep(
                stepNumber: 3,
                title: 'Geometry & Styling',
                subtitle: 'Choose geometry type and customize appearance',
                isActive:
                    viewModel.currentStep >= ConversionStep.geometryAndStyling,
                isCompleted:
                    viewModel.currentStep > ConversionStep.geometryAndStyling,
                canActivate: viewModel.canProceedToStyling,
                inactiveReason:
                    !viewModel.canProceedToStyling
                        ? 'Validate coordinate data first'
                        : null,
                child:
                    viewModel.currentStep >= ConversionStep.geometryAndStyling
                        ? const Row(
                          children: [
                            Expanded(child: GeometryTypeSelector()),
                            SizedBox(width: 16),
                            Expanded(child: StylingOptionsPanel()),
                          ],
                        )
                        : null,
              ),

              const SizedBox(height: 16),

              // Step 4: Export Options - REPLACE existing step
              _WorkflowStep(
                stepNumber: 4,
                title: 'Export Options',
                subtitle: 'Configure output format and generate files',
                isActive: viewModel.currentStep >= ConversionStep.exportOptions,
                isCompleted: false,
                canActivate: viewModel.canExport,
                inactiveReason:
                    !viewModel.canExport
                        ? 'Complete previous steps first'
                        : null, // Never completed
                child:
                    viewModel.currentStep >= ConversionStep.exportOptions
                        ? const KmlExportPanel()
                        : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WorkflowStep extends StatelessWidget {
  final int stepNumber;
  final String title;
  final String subtitle;
  final bool isActive;
  final bool isCompleted;
  final Widget? child;
  final bool canActivate;
  final String? inactiveReason;

  const _WorkflowStep({
    required this.stepNumber,
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.isCompleted,
    this.child,
    this.canActivate = true,
    this.inactiveReason,
  });

  @override
  Widget build(BuildContext context) {
    final effectivelyActive = isActive && canActivate;

    return Card(
      elevation: effectivelyActive ? 4 : 2,
      color:
          isCompleted
              ? Colors.green[50]
              : effectivelyActive
              ? null
              : Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step header
            Row(
              children: [
                // Step number indicator
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color:
                        isCompleted
                            ? Colors.green
                            : effectivelyActive
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[400],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCompleted
                        ? Icons.check
                        : !canActivate
                        ? Icons.lock
                        : _getStepIcon(stepNumber),
                    color: Colors.white,
                    size: 18,
                  ),
                ),

                const SizedBox(width: 12),

                // Step title and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Step $stepNumber: $title',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color:
                              effectivelyActive || isCompleted
                                  ? null
                                  : Colors.grey[600],
                        ),
                      ),
                      Text(
                        inactiveReason ?? subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              effectivelyActive || isCompleted
                                  ? Colors.grey[600]
                                  : Colors.grey[500],
                          fontStyle:
                              inactiveReason != null
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status indicator
                if (isCompleted)
                  Icon(Icons.check_circle, color: Colors.green, size: 24)
                else if (effectivelyActive)
                  Icon(
                    Icons.play_circle_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  )
                else if (!canActivate)
                  Icon(Icons.lock, color: Colors.grey[400], size: 24),
              ],
            ),

            // Step content
            if (child != null && effectivelyActive) ...[
              const SizedBox(height: 16),
              child!,
            ],
          ],
        ),
      ),
    );
  }

  IconData _getStepIcon(int stepNumber) {
    switch (stepNumber) {
      case 1:
        return Icons.map;
      case 2:
        return Icons.preview;
      case 3:
        return Icons.palette;
      case 4:
        return Icons.download;
      default:
        return Icons.circle;
    }
  }
}

class _CsvFormatGuide extends StatelessWidget {
  const _CsvFormatGuide();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'CSV Format Requirements',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              'Your CSV file should contain the following columns:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 8),

            // Required columns
            _FormatRequirement(
              icon: Icons.location_on,
              title: 'Latitude & Longitude',
              description: 'Decimal degrees format (e.g., 40.7128, -74.0060)',
              isRequired: true,
            ),

            _FormatRequirement(
              icon: Icons.label,
              title: 'Name/Title',
              description: 'Text label for each placemark',
              isRequired: true,
            ),

            // Optional columns
            _FormatRequirement(
              icon: Icons.height,
              title: 'Elevation',
              description: 'Height in meters (optional)',
              isRequired: false,
            ),

            _FormatRequirement(
              icon: Icons.description,
              title: 'Description',
              description: 'Additional details for each placemark (optional)',
              isRequired: false,
            ),

            _FormatRequirement(
              icon: Icons.image,
              title: 'Images',
              description: 'Image filenames for KMZ export (optional)',
              isRequired: false,
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Example: name,latitude,longitude,elevation,description\n'
                'Central Park,40.7829,-73.9654,30,Famous park in NYC',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormatRequirement extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isRequired;

  const _FormatRequirement({
    required this.icon,
    required this.title,
    required this.description,
    required this.isRequired,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isRequired ? Colors.red[100] : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 14,
              color: isRequired ? Colors.red[700] : Colors.grey[600],
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isRequired) ...[
                      const SizedBox(width: 4),
                      Text(
                        '*',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  description,
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
