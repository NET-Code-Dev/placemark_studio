import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/home_viewmodel.dart';

class PreviewTable extends StatelessWidget {
  const PreviewTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        if (!viewModel.hasPreviewData) {
          return const SizedBox.shrink();
        }

        final previewData = viewModel.previewData!;
        if (previewData.isEmpty) {
          return const SizedBox.shrink();
        }

        // FIXED: Explicitly constrain the height to prevent unbounded constraints
        return SizedBox(
          height: 400, // Fixed height to prevent unbounded constraint errors
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize:
                    MainAxisSize.min, // IMPORTANT: Prevent infinite expansion
                children: [
                  Text(
                    'Preview (first 5 rows):',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  // FIXED: Use Flexible instead of Expanded to work with bounded height
                  Flexible(child: _BoundedPreviewContent(data: previewData)),
                  const SizedBox(height: 8),
                  Text(
                    'Showing ${previewData.length - 1} of ${viewModel.kmlData?.featuresCount ?? 0} features',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
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

class _BoundedPreviewContent extends StatelessWidget {
  final List<List<String>> data;

  const _BoundedPreviewContent({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text('No preview data available')),
      );
    }

    // Normalize data to ensure consistent column counts
    final normalizedData = _normalizeData(data);
    final headers = normalizedData.first;
    final rows = normalizedData.skip(1).toList();

    return Container(
      height: 300, // Explicit height constraint
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Prevent infinite expansion
        children: [
          // Header - Fixed height
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: _BoundedTableRow(cells: headers, isHeader: true),
          ),
          // Rows - Constrained height with scrolling
          SizedBox(
            height: 260, // Remaining height for rows
            child: ListView.builder(
              itemCount: rows.length,
              itemExtent: 40, // Fixed item height
              itemBuilder: (context, index) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        index.isEven
                            ? Theme.of(context).colorScheme.surface
                            : Theme.of(
                              context,
                            ).colorScheme.surfaceVariant.withOpacity(0.3),
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: _BoundedTableRow(cells: rows[index], isHeader: false),
                );
              },
            ),
          ),
        ],
      ),
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
}

class _BoundedTableRow extends StatelessWidget {
  final List<String> cells;
  final bool isHeader;

  const _BoundedTableRow({required this.cells, required this.isHeader});

  @override
  Widget build(BuildContext context) {
    if (cells.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 24, // Fixed row height
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: cells.length,
        itemBuilder: (context, index) {
          final cell = cells[index];
          return Container(
            width: 120, // Fixed column width
            padding: const EdgeInsets.only(right: 8),
            child: _BoundedTableCell(
              content: cell,
              isHeader: isHeader,
              isLast: index == cells.length - 1,
            ),
          );
        },
      ),
    );
  }
}

class _BoundedTableCell extends StatelessWidget {
  final String content;
  final bool isHeader;
  final bool isLast;

  const _BoundedTableCell({
    required this.content,
    required this.isHeader,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 24, // Fixed cell height
      child: Row(
        children: [
          Expanded(
            child: Tooltip(
              message: content.isNotEmpty ? content : 'Empty',
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
                                  ? theme.colorScheme.onSurfaceVariant
                                      .withOpacity(0.6)
                                  : theme.colorScheme.onSurface,
                        ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
          if (!isLast)
            Container(
              width: 1,
              height: 16,
              color: theme.dividerColor,
              margin: const EdgeInsets.only(left: 4),
            ),
        ],
      ),
    );
  }
}
