import 'package:flutter/material.dart';
import '../../../../core/enums/geometry_type.dart';
import '../../../../data/models/styling_options.dart';

class StylingOptionsPanel extends StatelessWidget {
  final GeometryType geometryType;
  final StylingOptions stylingOptions;
  final List<String> availableColumns;
  final Function(StylingOptions) onStylingChanged;
  final Function(String)? onPreviewColumn;

  const StylingOptionsPanel({
    super.key,
    required this.geometryType,
    required this.stylingOptions,
    required this.availableColumns,
    required this.onStylingChanged,
    this.onPreviewColumn,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Styling Options',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Customize the appearance of your ${geometryType.displayName.toLowerCase()}s:',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            // Default style section
            _buildDefaultStyleSection(context),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),

            // Column-based styling section
            _buildColumnBasedStylingSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultStyleSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Default Style',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              // Color preview
              Row(
                children: [
                  Text(
                    'Color:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: stylingOptions.defaultStyle.color.color,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(stylingOptions.defaultStyle.color.name),
                ],
              ),

              // Icon display (for points only)
              if (geometryType == GeometryType.point) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Icon:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      stylingOptions.defaultStyle.icon?.displayName ??
                          'Default',
                    ),
                  ],
                ),
              ],

              // Line width (for lines and polygons)
              if (geometryType == GeometryType.lineString ||
                  geometryType == GeometryType.polygon) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Line Width:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('${stylingOptions.defaultStyle.lineWidth.toInt()}px'),
                  ],
                ),
              ],

              // Opacity (for polygons)
              if (geometryType == GeometryType.polygon) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Opacity:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${(stylingOptions.defaultStyle.opacity * 100).toInt()}%',
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColumnBasedStylingSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Column-Based Styling',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            Switch(
              value: stylingOptions.useColumnBasedStyling,
              onChanged: (value) {
                final newOptions = stylingOptions.copyWith(
                  useColumnBasedStyling: value,
                );
                onStylingChanged(newOptions);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Style features differently based on column values',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),

        if (stylingOptions.useColumnBasedStyling) ...[
          const SizedBox(height: 16),

          // Column selection
          if (availableColumns.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  'Style by column:',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: stylingOptions.stylingColumn,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    items:
                        availableColumns
                            .map(
                              (column) => DropdownMenuItem(
                                value: column,
                                child: Text(column),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      final newOptions = stylingOptions.copyWith(
                        stylingColumn: value,
                      );
                      onStylingChanged(newOptions);
                      if (value != null && onPreviewColumn != null) {
                        onPreviewColumn!(value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Status message
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        stylingOptions.stylingColumn != null
                            ? 'Column-based styling active for "${stylingOptions.stylingColumn}"'
                            : 'Select a column to enable custom styling rules',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
                if (stylingOptions.columnBasedStyles.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${stylingOptions.columnBasedStyles.length} custom style rules defined',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blue[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Simple style preview widget
class StylePreview extends StatelessWidget {
  final GeometryType geometryType;
  final StylingOptions stylingOptions;

  const StylePreview({
    super.key,
    required this.geometryType,
    required this.stylingOptions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Style Preview',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  // Default style preview
                  _buildStylePreviewRow(
                    context,
                    'Default Style',
                    stylingOptions.defaultStyle,
                  ),

                  // Column-based styles summary
                  if (stylingOptions.useColumnBasedStyling) ...[
                    const Divider(height: 20),
                    Row(
                      children: [
                        Icon(Icons.palette, color: Colors.blue[600], size: 16),
                        const SizedBox(width: 8),
                        Text(
                          stylingOptions.columnBasedStyles.isEmpty
                              ? 'No custom rules defined yet'
                              : '${stylingOptions.columnBasedStyles.length} custom rules active',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.blue[600]),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStylePreviewRow(
    BuildContext context,
    String label,
    GeometryStyle style,
  ) {
    return Row(
      children: [
        // Visual indicator
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: style.color.color,
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(
              geometryType == GeometryType.point ? 10 : 2,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Label
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),

        // Style details
        Text(
          _getStyleSummary(style),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  String _getStyleSummary(GeometryStyle style) {
    switch (geometryType) {
      case GeometryType.point:
        return style.icon?.displayName ?? 'Default Icon';
      case GeometryType.lineString:
        return '${style.lineWidth.toInt()}px line';
      case GeometryType.polygon:
        return '${style.lineWidth.toInt()}px, ${(style.opacity * 100).toInt()}% fill';
      default:
        return style.color.name;
    }
  }
}
