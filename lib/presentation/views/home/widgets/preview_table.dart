import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/home_viewmodel.dart';

class PreviewTable extends StatefulWidget {
  const PreviewTable({super.key});

  @override
  State<PreviewTable> createState() => _PreviewTableState();
}

class _PreviewTableState extends State<PreviewTable> {
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
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        if (!viewModel.hasPreviewData) {
          return const Card(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.table_chart, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No preview data available',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final previewData = viewModel.previewData!;
        if (previewData.isEmpty) {
          return const Card(child: Center(child: Text('No data to preview')));
        }

        // Normalize data to ensure consistent column counts
        final normalizedData = _normalizeData(previewData);
        final headers = normalizedData.first;
        final rows = normalizedData.skip(1).toList();

        return Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Data Preview',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      'Showing ${rows.length} of ${viewModel.kmlData?.featuresCount ?? 0} features • ${headers.length} columns',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Scrollable table with both horizontal and vertical scrollbars
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Scrollbar(
                      controller: _horizontalController,
                      thumbVisibility: true,
                      child: Scrollbar(
                        controller: _verticalController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _horizontalController,
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: _calculateTotalWidth(headers),
                            child: Column(
                              children: [
                                // Header row
                                Container(
                                  height: 35,
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(
                                          context,
                                          //  ).colorScheme.surfaceVariant,
                                        ).colorScheme.surfaceContainerHighest,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      topRight: Radius.circular(8),
                                    ),
                                  ),
                                  child: Row(
                                    children:
                                        headers.asMap().entries.map((entry) {
                                          return _TableCell(
                                            content: entry.value,
                                            isHeader: true,
                                            width: _getColumnWidth(entry.value),
                                            isLast:
                                                entry.key == headers.length - 1,
                                          );
                                        }).toList(),
                                  ),
                                ),

                                // Data rows
                                Expanded(
                                  child: ListView.builder(
                                    controller: _verticalController,
                                    itemCount: rows.length,
                                    itemExtent: 30,
                                    itemBuilder: (context, rowIndex) {
                                      final row = rows[rowIndex];
                                      return Container(
                                        decoration: BoxDecoration(
                                          color:
                                              rowIndex.isEven
                                                  ? Theme.of(
                                                    context,
                                                  ).colorScheme.surface
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      //  .surfaceVariant
                                                      .surfaceContainerHighest
                                                      .withValues(alpha: 0.3),
                                          border: Border(
                                            bottom: BorderSide(
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).dividerColor,
                                              width: 0.5,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children:
                                              row.asMap().entries.map((entry) {
                                                return _TableCell(
                                                  content: entry.value,
                                                  isHeader: false,
                                                  width: _getColumnWidth(
                                                    headers[entry.key],
                                                  ),
                                                  isLast:
                                                      entry.key ==
                                                      row.length - 1,
                                                );
                                              }).toList(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 1),
                /*
                // Desktop-friendly instructions
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Use scrollbars or mouse wheel to navigate • Click and drag columns to resize',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
*/
              ],
            ),
          ),
        );
      },
    );
  }

  List<List<String>> _normalizeData(List<List<String>> data) {
    if (data.isEmpty) return data;

    // Find the maximum number of columns
    final maxColumns = data
        .map((row) => row.length)
        .reduce((a, b) => a > b ? a : b);

    // Normalize all rows to have the same number of columns
    return data.map((row) {
      final normalizedRow = List<String>.from(row);
      while (normalizedRow.length < maxColumns) {
        normalizedRow.add('');
      }
      return normalizedRow.take(maxColumns).toList();
    }).toList();
  }

  double _getColumnWidth(String header) {
    // Dynamic column width based on header length
    const baseWidth = 140.0;
    final headerLength = header.length;

    if (headerLength > 25) {
      return 250.0;
    } else if (headerLength > 20) {
      return 220.0;
    } else if (headerLength > 15) {
      return 180.0;
    } else if (headerLength > 10) {
      return 160.0;
    } else {
      return baseWidth;
    }
  }

  double _calculateTotalWidth(List<String> headers) {
    return headers
        .map((header) => _getColumnWidth(header))
        .reduce((a, b) => a + b);
  }
}

class _TableCell extends StatelessWidget {
  final String content;
  final bool isHeader;
  final double width;
  final bool isLast;

  const _TableCell({
    required this.content,
    required this.isHeader,
    required this.width,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: width,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          right:
              isLast
                  ? BorderSide.none
                  : BorderSide(color: theme.dividerColor, width: 0.5),
        ),
      ),
      child: Tooltip(
        message: content.isNotEmpty ? content : 'Empty',
        waitDuration: const Duration(milliseconds: 500),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            content.isNotEmpty ? content : '—',
            style:
                isHeader
                    ? theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                    )
                    : theme.textTheme.bodySmall?.copyWith(
                      color:
                          content.isEmpty
                              ? theme.colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.6,
                              )
                              : theme.colorScheme.onSurface,
                    ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}
