import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/csv_converter_viewmodel.dart';
import '../../../../data/models/column_mapping.dart';
import '../../../../core/enums/conversion_step.dart';

class CsvPreviewTable extends StatefulWidget {
  const CsvPreviewTable({super.key});

  @override
  State<CsvPreviewTable> createState() => _CsvPreviewTableState();
}

class _CsvPreviewTableState extends State<CsvPreviewTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CsvConverterViewModel>(
      builder: (context, viewModel, child) {
        if (!viewModel.hasCsvData) {
          return const _EmptyPreviewState();
        }

        return SizedBox(
          height: 600, // Fixed height to prevent layout issues
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _PreviewHeader(
                    csvData: viewModel.csvData!,
                    mapping: viewModel.columnMapping!,
                    onProceed:
                        () => viewModel.proceedToStep(
                          ConversionStep.geometryAndStyling,
                        ),
                  ),

                  const SizedBox(height: 16),

                  // Validation results
                  if (viewModel.columnMapping!.isValid) ...[
                    _ValidationResults(
                      csvData: viewModel.csvData!,
                      mapping: viewModel.columnMapping!,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Data table with fixed height
                  Expanded(
                    child: _DataPreviewTable(
                      csvData: viewModel.csvData!,
                      mapping: viewModel.columnMapping!,
                      horizontalController: _horizontalController,
                      verticalController: _verticalController,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyPreviewState extends StatelessWidget {
  const _EmptyPreviewState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200, // Fixed height for empty state
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.preview, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Data Preview Not Available',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete column mapping to preview your data',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewHeader extends StatelessWidget {
  final dynamic csvData; // CsvData
  final ColumnMapping mapping;
  final VoidCallback onProceed;

  const _PreviewHeader({
    required this.csvData,
    required this.mapping,
    required this.onProceed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Title and stats
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.preview,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Data Preview & Validation',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Showing ${csvData.rows.length} rows • ${csvData.headers.length} columns',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),

        // Action button
        if (mapping.isValid && csvData.hasValidCoordinates)
          ElevatedButton.icon(
            onPressed: onProceed,
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text('Continue to Styling'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }
}

class _ValidationResults extends StatelessWidget {
  final dynamic csvData; // CsvData
  final ColumnMapping mapping;

  const _ValidationResults({required this.csvData, required this.mapping});

  @override
  Widget build(BuildContext context) {
    final hasValidCoordinates = csvData.hasValidCoordinates;
    final validRowCount = csvData.validRowCount;
    final totalRows = csvData.totalRowCount;
    final errorCount = csvData.validationErrors.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasValidCoordinates ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasValidCoordinates ? Colors.green[200]! : Colors.orange[200]!,
        ),
      ),
      child: Column(
        children: [
          // Summary row
          Row(
            children: [
              Icon(
                hasValidCoordinates ? Icons.check_circle : Icons.warning,
                color:
                    hasValidCoordinates
                        ? Colors.green[700]
                        : Colors.orange[700],
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasValidCoordinates
                      ? 'Validation Successful'
                      : 'Validation Issues Found',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color:
                        hasValidCoordinates
                            ? Colors.green[700]
                            : Colors.orange[700],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Statistics
          Row(
            children: [
              _ValidationStat(
                label: 'Valid Rows',
                value: '$validRowCount',
                color: Colors.green,
              ),
              const SizedBox(width: 24),
              _ValidationStat(
                label: 'Total Rows',
                value: '$totalRows',
                color: Colors.blue,
              ),
              if (errorCount > 0) ...[
                const SizedBox(width: 24),
                _ValidationStat(
                  label: 'Errors',
                  value: '$errorCount',
                  color: Colors.red,
                ),
              ],
            ],
          ),

          // Error details
          if (errorCount > 0 && csvData.validationErrors.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            _ErrorDetailsSection(errors: csvData.validationErrors),
          ],
        ],
      ),
    );
  }
}

class _ValidationStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ValidationStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class _ErrorDetailsSection extends StatefulWidget {
  final List<String> errors;

  const _ErrorDetailsSection({required this.errors});

  @override
  State<_ErrorDetailsSection> createState() => _ErrorDetailsSectionState();
}

class _ErrorDetailsSectionState extends State<_ErrorDetailsSection> {
  bool _showAllErrors = false;

  @override
  Widget build(BuildContext context) {
    final displayErrors =
        _showAllErrors ? widget.errors : widget.errors.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Validation Errors:',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.red[700],
          ),
        ),
        const SizedBox(height: 8),

        ...displayErrors.map((error) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline, size: 16, color: Colors.red[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    error,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.red[700]),
                  ),
                ),
              ],
            ),
          );
        }).toList(),

        if (widget.errors.length > 3) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _showAllErrors = !_showAllErrors;
              });
            },
            child: Text(
              _showAllErrors
                  ? 'Show Less'
                  : 'Show ${widget.errors.length - 3} More Errors',
            ),
          ),
        ],
      ],
    );
  }
}

class _DataPreviewTable extends StatelessWidget {
  final dynamic csvData; // CsvData
  final ColumnMapping mapping;
  final ScrollController horizontalController;
  final ScrollController verticalController;

  const _DataPreviewTable({
    required this.csvData,
    required this.mapping,
    required this.horizontalController,
    required this.verticalController,
  });

  @override
  Widget build(BuildContext context) {
    final headers = csvData.headers;
    final rows = csvData.rows.take(20).toList();

    if (headers.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns:
              headers
                  .map<DataColumn>(
                    (header) => DataColumn(
                      label: Text(
                        header,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              _isColumnMapped(header, mapping)
                                  ? Colors.blue
                                  : null,
                        ),
                      ),
                    ),
                  )
                  .toList(),
          rows:
              rows
                  .map<DataRow>(
                    (row) => DataRow(
                      cells:
                          headers
                              .map<DataCell>(
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
    );
  }

  double _getColumnWidth(String header) {
    const baseWidth = 120.0;
    final headerLength = header.length;

    if (headerLength > 20) {
      return 200.0;
    } else if (headerLength > 15) {
      return 160.0;
    } else if (headerLength > 10) {
      return 140.0;
    } else {
      return baseWidth;
    }
  }

  bool _isColumnMapped(String column, ColumnMapping mapping) {
    return mapping.allMappedColumns.contains(column);
  }

  String? _getMappingType(String column, ColumnMapping mapping) {
    if (column == mapping.latitudeColumn) return 'Latitude';
    if (column == mapping.longitudeColumn) return 'Longitude';
    if (column == mapping.nameColumn) return 'Name';
    if (column == mapping.descriptionColumn) return 'Description';
    if (column == mapping.elevationColumn) return 'Elevation';
    return null;
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String content;
  final bool isMapped;
  final String? mappingType;
  final double width;
  final bool isLast;

  const _TableHeaderCell({
    required this.content,
    required this.isMapped,
    required this.mappingType,
    required this.width,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          right:
              isLast
                  ? BorderSide.none
                  : BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 0.5,
                  ),
        ),
        color: isMapped ? _getMappingColor(mappingType).withOpacity(0.1) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Column name
          Text(
            content,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color:
                  isMapped
                      ? _getMappingColor(mappingType)
                      : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),

          // Mapping indicator
          if (isMapped && mappingType != null) ...[
            const SizedBox(height: 2),
            Text(
              mappingType!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: _getMappingColor(mappingType),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ],
      ),
    );
  }

  Color _getMappingColor(String? mappingType) {
    switch (mappingType) {
      case 'Latitude':
      case 'Longitude':
        return Colors.red;
      case 'Name':
        return Colors.blue;
      case 'Description':
        return Colors.green;
      case 'Elevation':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

class _TableDataCell extends StatelessWidget {
  final String content;
  final String header;
  final ColumnMapping mapping;
  final double width;
  final bool isLast;

  const _TableDataCell({
    required this.content,
    required this.header,
    required this.mapping,
    required this.width,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final isMapped = mapping.allMappedColumns.contains(header);
    final mappingType = _getMappingType();
    final hasValidationIssue = _hasValidationIssue();

    return Container(
      width: width,
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          right:
              isLast
                  ? BorderSide.none
                  : BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 0.5,
                  ),
        ),
        color:
            hasValidationIssue
                ? Colors.red.withOpacity(0.1)
                : isMapped
                ? _getMappingColor(mappingType).withOpacity(0.05)
                : null,
      ),
      child: Row(
        children: [
          // Content
          Expanded(
            child: Text(
              content.isNotEmpty ? content : '—',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color:
                    content.isEmpty
                        ? Colors.grey[500]
                        : hasValidationIssue
                        ? Colors.red[700]
                        : null,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),

          // Validation indicator
          if (hasValidationIssue)
            Icon(Icons.error_outline, size: 14, color: Colors.red[600]),
        ],
      ),
    );
  }

  String? _getMappingType() {
    if (header == mapping.latitudeColumn) return 'Latitude';
    if (header == mapping.longitudeColumn) return 'Longitude';
    if (header == mapping.nameColumn) return 'Name';
    if (header == mapping.descriptionColumn) return 'Description';
    if (header == mapping.elevationColumn) return 'Elevation';
    return null;
  }

  bool _hasValidationIssue() {
    if (!mapping.allMappedColumns.contains(header)) return false;

    // Check for coordinate validation issues
    if (header == mapping.latitudeColumn || header == mapping.longitudeColumn) {
      if (content.isEmpty) return true;
      final value = double.tryParse(content);
      if (value == null) return true;

      if (header == mapping.latitudeColumn) {
        return value < -90 || value > 90;
      } else {
        return value < -180 || value > 180;
      }
    }

    // Check for required field issues
    if (header == mapping.nameColumn && content.isEmpty) {
      return true;
    }

    return false;
  }

  Color _getMappingColor(String? mappingType) {
    switch (mappingType) {
      case 'Latitude':
      case 'Longitude':
        return Colors.red;
      case 'Name':
        return Colors.blue;
      case 'Description':
        return Colors.green;
      case 'Elevation':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
