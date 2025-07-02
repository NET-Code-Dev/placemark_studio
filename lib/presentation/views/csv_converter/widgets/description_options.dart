import 'package:flutter/material.dart';

class DescriptionOptionsWidget extends StatefulWidget {
  final List<String> availableColumns;
  final List<String> selectedColumns;
  final bool useTableFormat;
  final String tableStyle;
  final Function(List<String>) onColumnsChanged;
  final Function(bool) onTableFormatChanged;
  final Function(String) onTableStyleChanged;

  const DescriptionOptionsWidget({
    super.key,
    required this.availableColumns,
    required this.selectedColumns,
    required this.useTableFormat,
    required this.tableStyle,
    required this.onColumnsChanged,
    required this.onTableFormatChanged,
    required this.onTableStyleChanged,
  });

  @override
  State<DescriptionOptionsWidget> createState() =>
      _DescriptionOptionsWidgetState();
}

class _DescriptionOptionsWidgetState extends State<DescriptionOptionsWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description Options',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Table format toggle
            Row(
              children: [
                Text(
                  'Use table format',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                Switch(
                  value: widget.useTableFormat,
                  onChanged: widget.onTableFormatChanged,
                ),
              ],
            ),

            if (widget.useTableFormat) ...[
              const SizedBox(height: 16),

              // Column selection
              Text(
                'Select columns to include:',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                runSpacing: 4,
                children:
                    widget.availableColumns.map((column) {
                      final isSelected = widget.selectedColumns.contains(
                        column,
                      );
                      return FilterChip(
                        label: Text(column),
                        selected: isSelected,
                        onSelected: (selected) {
                          final newSelection = List<String>.from(
                            widget.selectedColumns,
                          );
                          if (selected) {
                            newSelection.add(column);
                          } else {
                            newSelection.remove(column);
                          }
                          widget.onColumnsChanged(newSelection);
                        },
                      );
                    }).toList(),
              ),

              const SizedBox(height: 16),

              // Table style selection
              Text(
                'Table Style:',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              DropdownButton<String>(
                value: widget.tableStyle,
                isExpanded: true,
                items: [
                  DropdownMenuItem(value: 'simple', child: Text('Simple')),
                  DropdownMenuItem(value: 'bordered', child: Text('Bordered')),
                  DropdownMenuItem(value: 'striped', child: Text('Striped')),
                  DropdownMenuItem(
                    value: 'condensed',
                    child: Text('Condensed'),
                  ),
                ],
                onChanged:
                    (value) => widget.onTableStyleChanged(value ?? 'simple'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
