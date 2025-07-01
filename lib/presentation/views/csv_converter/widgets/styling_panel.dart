import 'package:flutter/material.dart';
import '../../../../core/enums/geometry_type.dart';
import '../../../../data/models/styling_options.dart';

class StylingOptionsPanel extends StatefulWidget {
  final GeometryType geometryType;
  final StylingOptions stylingOptions;
  final List<String> availableColumns;
  final Function(StylingOptions) onStylingChanged;
  final Function(String)? onPreviewColumn;
  final List<String>? previewColumnValues;

  const StylingOptionsPanel({
    super.key,
    required this.geometryType,
    required this.stylingOptions,
    required this.availableColumns,
    required this.onStylingChanged,
    this.onPreviewColumn,
    this.previewColumnValues,
  });

  @override
  State<StylingOptionsPanel> createState() => _StylingOptionsPanelState();
}

class _StylingOptionsPanelState extends State<StylingOptionsPanel> {
  late StylingOptions _currentOptions;

  @override
  void initState() {
    super.initState();
    _currentOptions = widget.stylingOptions;
  }

  @override
  void didUpdateWidget(StylingOptionsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stylingOptions != widget.stylingOptions) {
      _currentOptions = widget.stylingOptions;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Geometry visual options
        // _buildGeometryOptionsSection(context),

        // const SizedBox(height: 24),

        // Default styling configuration
        _buildDefaultStylingSection(context),

        const SizedBox(height: 24),

        // Column-based styling
        _buildColumnBasedStylingSection(context),

        const SizedBox(height: 24),

        // Style preview
        _buildStylePreviewSection(context),
      ],
    );
  }

  /*
  Widget _buildGeometryOptionsSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getGeometryIcon(widget.geometryType),
                const SizedBox(width: 12),
                Text(
                  'Visual Geometry Options',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.geometryType.displayName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getGeometryDescription(widget.geometryType),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.blue[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getGeometryHelpText(widget.geometryType),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.blue[600]),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
*/
  Widget _buildDefaultStylingSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Default Styling Configuration',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Configure the default appearance for all ${widget.geometryType.displayName.toLowerCase()}s',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  // Color selection
                  _buildColorSelection(context, _currentOptions.defaultStyle),

                  const SizedBox(height: 16),

                  // Icon selection (for points only)
                  if (widget.geometryType == GeometryType.point) ...[
                    _buildIconSelection(context, _currentOptions.defaultStyle),
                    const SizedBox(height: 16),
                  ],

                  // Line width (for lines and polygons)
                  if (widget.geometryType == GeometryType.lineString ||
                      widget.geometryType == GeometryType.polygon) ...[
                    _buildLineWidthSelection(
                      context,
                      _currentOptions.defaultStyle,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Opacity (for polygons)
                  if (widget.geometryType == GeometryType.polygon) ...[
                    _buildOpacitySelection(
                      context,
                      _currentOptions.defaultStyle,
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

  Widget _buildColumnBasedStylingSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Column-Based Styling',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: _currentOptions.useColumnBasedStyling,
                  onChanged: _updateColumnBasedStyling,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Style features based on values in a specific column',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),

            if (_currentOptions.useColumnBasedStyling) ...[
              const SizedBox(height: 16),

              // Column selection dropdown
              Row(
                children: [
                  Text(
                    'Styling Column:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _currentOptions.stylingColumn,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      hint: const Text('Select column for styling'),
                      items:
                          widget.availableColumns.map((column) {
                            return DropdownMenuItem(
                              value: column,
                              child: Text(column),
                            );
                          }).toList(),
                      onChanged: _updateStylingColumn,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Column values preview
              if (_currentOptions.stylingColumn != null &&
                  widget.previewColumnValues != null) ...[
                _buildColumnValuesPreview(context),
                const SizedBox(height: 16),
              ],

              // Style rules
              if (_currentOptions.stylingColumn != null) ...[
                _buildStyleRulesSection(context),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStylePreviewSection(BuildContext context) {
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
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Preview how your styling will appear in the final KML',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  // Default style preview
                  _buildStylePreviewRow(
                    context,
                    'Default Style',
                    _currentOptions.defaultStyle,
                    isDefault: true,
                  ),

                  // Column-based styles preview
                  if (_currentOptions.useColumnBasedStyling &&
                      _currentOptions.columnBasedStyles.isNotEmpty) ...[
                    const Divider(height: 20),
                    Text(
                      'Custom Styles',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._currentOptions.columnBasedStyles.entries.map(
                      (entry) => _buildStylePreviewRow(
                        context,
                        '${_currentOptions.stylingColumn}: ${entry.key}',
                        entry.value,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Validation info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Styling configuration is valid and ready for export',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widgets

  Widget _buildColorSelection(BuildContext context, GeometryStyle style) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Color',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              KmlColor.predefinedColors.map((color) {
                final isSelected = color.kmlValue == style.color.kmlValue;
                return GestureDetector(
                  onTap:
                      () => _updateDefaultStyle(style.copyWith(color: color)),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.color,
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.grey[300]!,
                        width: isSelected ? 3 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        isSelected
                            ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                            : null,
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          'Selected: ${style.color.name}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildIconSelection(BuildContext context, GeometryStyle style) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Icon',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: KmlIcon.values.length,
            itemBuilder: (context, index) {
              final icon = KmlIcon.values[index];
              final isSelected = icon == style.icon;

              return GestureDetector(
                onTap: () => _updateDefaultStyle(style.copyWith(icon: icon)),
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected ? Colors.blue[50] : null,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Image.network(
                          icon.url,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.place,
                              color: Colors.grey[400],
                              size: 32,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        icon.displayName,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Selected: ${style.icon?.displayName ?? 'Default Icon'}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildLineWidthSelection(BuildContext context, GeometryStyle style) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Line Width',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: style.lineWidth,
                min: 1.0,
                max: 10.0,
                divisions: 9,
                label: '${style.lineWidth.toInt()}px',
                onChanged:
                    (value) =>
                        _updateDefaultStyle(style.copyWith(lineWidth: value)),
              ),
            ),
            const SizedBox(width: 8),
            Text('${style.lineWidth.toInt()}px'),
          ],
        ),
      ],
    );
  }

  Widget _buildOpacitySelection(BuildContext context, GeometryStyle style) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fill Opacity',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: style.opacity,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                label: '${(style.opacity * 100).toInt()}%',
                onChanged:
                    (value) =>
                        _updateDefaultStyle(style.copyWith(opacity: value)),
              ),
            ),
            const SizedBox(width: 8),
            Text('${(style.opacity * 100).toInt()}%'),
          ],
        ),
      ],
    );
  }

  Widget _buildColumnValuesPreview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Column Values Preview',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Found ${widget.previewColumnValues!.length} unique values:',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children:
                    widget.previewColumnValues!.take(10).map((value) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue[300]!),
                        ),
                        child: Text(
                          value,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    }).toList(),
              ),
              if (widget.previewColumnValues!.length > 10) ...[
                const SizedBox(height: 8),
                Text(
                  'and ${widget.previewColumnValues!.length - 10} more...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStyleRulesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Style Rules',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            TextButton.icon(
              onPressed: _addNewStyleRule,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Rule'),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (_currentOptions.columnBasedStyles.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Icon(Icons.palette, color: Colors.grey[400], size: 48),
                const SizedBox(height: 8),
                Text(
                  'No custom style rules yet',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add rules to style features based on column values',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ] else ...[
          ..._currentOptions.columnBasedStyles.entries.map((entry) {
            return _buildStyleRuleCard(context, entry.key, entry.value);
          }),
        ],
      ],
    );
  }

  Widget _buildStyleRuleCard(
    BuildContext context,
    String value,
    GeometryStyle style,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Visual indicator
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: style.color.color,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(
                  widget.geometryType == GeometryType.point ? 16 : 4,
                ),
              ),
              child:
                  widget.geometryType == GeometryType.point &&
                          style.icon != null
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          style.icon!.url,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.place,
                              color: Colors.white,
                              size: 16,
                            );
                          },
                        ),
                      )
                      : null,
            ),
            const SizedBox(width: 12),

            // Rule details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'When "${_currentOptions.stylingColumn}" = "$value"',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStyleDescription(style),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _editStyleRule(value, style),
                  icon: const Icon(Icons.edit, size: 16),
                  tooltip: 'Edit rule',
                ),
                IconButton(
                  onPressed: () => _deleteStyleRule(value),
                  icon: const Icon(Icons.delete, size: 16),
                  tooltip: 'Delete rule',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStylePreviewRow(
    BuildContext context,
    String label,
    GeometryStyle style, {
    bool isDefault = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Visual indicator
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: style.color.color,
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(
                widget.geometryType == GeometryType.point ? 12 : 3,
              ),
            ),
            child:
                widget.geometryType == GeometryType.point && style.icon != null
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        style.icon!.url,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.place,
                            color: Colors.white,
                            size: 12,
                          );
                        },
                      ),
                    )
                    : null,
          ),
          const SizedBox(width: 12),

          // Label
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isDefault ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),

          // Style details
          Text(
            _getStyleSummary(style),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // Helper methods
  /*
  Widget _getGeometryIcon(GeometryType type) {
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
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }

  String _getGeometryDescription(GeometryType type) {
    switch (type) {
      case GeometryType.point:
        return 'Individual points representing specific locations with coordinates';
      case GeometryType.lineString:
        return 'Connected lines showing paths, routes, or linear features';
      case GeometryType.polygon:
        return 'Closed shapes representing areas, boundaries, or regions';
      default:
        return 'Geographic features for mapping applications';
    }
  }

  String _getGeometryHelpText(GeometryType type) {
    switch (type) {
      case GeometryType.point:
        return 'Each row in your CSV will create a single point placemark';
      case GeometryType.lineString:
        return 'Coordinates will be connected in sequence to form continuous lines';
      case GeometryType.polygon:
        return 'Coordinates will form closed shapes with fill and border styling';
      default:
        return 'Configure how your CSV data will be visualized';
    }
  }
*/
  String _getStyleSummary(GeometryStyle style) {
    switch (widget.geometryType) {
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

  String _getStyleDescription(GeometryStyle style) {
    final parts = <String>[];
    parts.add(style.color.name);

    if (style.icon != null) {
      parts.add(style.icon!.displayName);
    }

    if (widget.geometryType == GeometryType.lineString ||
        widget.geometryType == GeometryType.polygon) {
      parts.add('${style.lineWidth.toInt()}px line');
    }

    if (widget.geometryType == GeometryType.polygon) {
      parts.add('${(style.opacity * 100).toInt()}% opacity');
    }

    return parts.join(', ');
  }

  // Event handlers

  void _updateDefaultStyle(GeometryStyle newStyle) {
    setState(() {
      _currentOptions = _currentOptions.copyWith(defaultStyle: newStyle);
    });
    widget.onStylingChanged(_currentOptions);
  }

  void _updateColumnBasedStyling(bool enabled) {
    setState(() {
      _currentOptions = _currentOptions.copyWith(
        useColumnBasedStyling: enabled,
        stylingColumn: enabled ? _currentOptions.stylingColumn : null,
        columnBasedStyles: enabled ? _currentOptions.columnBasedStyles : {},
      );
    });
    widget.onStylingChanged(_currentOptions);
  }

  void _updateStylingColumn(String? column) {
    setState(() {
      _currentOptions = _currentOptions.copyWith(
        stylingColumn: column,
        columnBasedStyles: {}, // Clear existing rules when column changes
      );
    });
    widget.onStylingChanged(_currentOptions);

    // Trigger preview of column values
    if (column != null && widget.onPreviewColumn != null) {
      widget.onPreviewColumn!(column);
    }
  }

  void _addNewStyleRule() {
    if (_currentOptions.stylingColumn == null) return;

    showDialog(
      context: context,
      builder:
          (context) => StyleRuleDialog(
            geometryType: widget.geometryType,
            columnName: _currentOptions.stylingColumn!,
            onSave: (value, style) {
              setState(() {
                final newRules = Map<String, GeometryStyle>.from(
                  _currentOptions.columnBasedStyles,
                );
                newRules[value] = style;
                _currentOptions = _currentOptions.copyWith(
                  columnBasedStyles: newRules,
                );
              });
              widget.onStylingChanged(_currentOptions);
            },
          ),
    );
  }

  void _editStyleRule(String value, GeometryStyle style) {
    showDialog(
      context: context,
      builder:
          (context) => StyleRuleDialog(
            geometryType: widget.geometryType,
            columnName: _currentOptions.stylingColumn!,
            initialValue: value,
            initialStyle: style,
            onSave: (newValue, newStyle) {
              setState(() {
                final newRules = Map<String, GeometryStyle>.from(
                  _currentOptions.columnBasedStyles,
                );
                if (newValue != value) {
                  newRules.remove(value);
                }
                newRules[newValue] = newStyle;
                _currentOptions = _currentOptions.copyWith(
                  columnBasedStyles: newRules,
                );
              });
              widget.onStylingChanged(_currentOptions);
            },
          ),
    );
  }

  void _deleteStyleRule(String value) {
    setState(() {
      final newRules = Map<String, GeometryStyle>.from(
        _currentOptions.columnBasedStyles,
      );
      newRules.remove(value);
      _currentOptions = _currentOptions.copyWith(columnBasedStyles: newRules);
    });
    widget.onStylingChanged(_currentOptions);
  }
}

// Style Rule Dialog for adding/editing column-based styles
class StyleRuleDialog extends StatefulWidget {
  final GeometryType geometryType;
  final String columnName;
  final String? initialValue;
  final GeometryStyle? initialStyle;
  final Function(String value, GeometryStyle style) onSave;

  const StyleRuleDialog({
    super.key,
    required this.geometryType,
    required this.columnName,
    this.initialValue,
    this.initialStyle,
    required this.onSave,
  });

  @override
  State<StyleRuleDialog> createState() => _StyleRuleDialogState();
}

class _StyleRuleDialogState extends State<StyleRuleDialog> {
  late TextEditingController _valueController;
  late GeometryStyle _currentStyle;

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController(text: widget.initialValue ?? '');
    _currentStyle =
        widget.initialStyle ??
        StylingOptions.forGeometry(widget.geometryType).defaultStyle;
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.initialValue != null ? 'Edit' : 'Add'} Style Rule'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column value input
              Text(
                'When "${widget.columnName}" equals:',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _valueController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter column value',
                ),
              ),
              const SizedBox(height: 24),

              // Style configuration
              Text(
                'Apply this style:',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              // Color selection
              _buildDialogColorSelection(),

              const SizedBox(height: 16),

              // Icon selection (for points)
              if (widget.geometryType == GeometryType.point) ...[
                _buildDialogIconSelection(),
                const SizedBox(height: 16),
              ],

              // Line width (for lines and polygons)
              if (widget.geometryType == GeometryType.lineString ||
                  widget.geometryType == GeometryType.polygon) ...[
                _buildDialogLineWidthSelection(),
                const SizedBox(height: 16),
              ],

              // Opacity (for polygons)
              if (widget.geometryType == GeometryType.polygon) ...[
                _buildDialogOpacitySelection(),
                const SizedBox(height: 16),
              ],

              // Style preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Text(
                      'Preview:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _currentStyle.color.color,
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(
                          widget.geometryType == GeometryType.point ? 12 : 3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getStyleDescription(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _canSave() ? _saveRule : null,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildDialogColorSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Color:',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children:
              KmlColor.predefinedColors.take(12).map((color) {
                final isSelected =
                    color.kmlValue == _currentStyle.color.kmlValue;
                return GestureDetector(
                  onTap:
                      () => setState(() {
                        _currentStyle = _currentStyle.copyWith(color: color);
                      }),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.color,
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child:
                        isSelected
                            ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            )
                            : null,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildDialogIconSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Icon:',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: KmlIcon.values.length,
            itemBuilder: (context, index) {
              final icon = KmlIcon.values[index];
              final isSelected = icon == _currentStyle.icon;

              return GestureDetector(
                onTap:
                    () => setState(() {
                      _currentStyle = _currentStyle.copyWith(icon: icon);
                    }),
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    color: isSelected ? Colors.blue[50] : null,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Image.network(
                          icon.url,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.place,
                              color: Colors.grey[400],
                              size: 20,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        icon.displayName,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(fontSize: 8),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDialogLineWidthSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Line Width:',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _currentStyle.lineWidth,
                min: 1.0,
                max: 10.0,
                divisions: 9,
                label: '${_currentStyle.lineWidth.toInt()}px',
                onChanged:
                    (value) => setState(() {
                      _currentStyle = _currentStyle.copyWith(lineWidth: value);
                    }),
              ),
            ),
            Text('${_currentStyle.lineWidth.toInt()}px'),
          ],
        ),
      ],
    );
  }

  Widget _buildDialogOpacitySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fill Opacity:',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _currentStyle.opacity,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                label: '${(_currentStyle.opacity * 100).toInt()}%',
                onChanged:
                    (value) => setState(() {
                      _currentStyle = _currentStyle.copyWith(opacity: value);
                    }),
              ),
            ),
            Text('${(_currentStyle.opacity * 100).toInt()}%'),
          ],
        ),
      ],
    );
  }

  String _getStyleDescription() {
    final parts = <String>[];
    parts.add(_currentStyle.color.name);

    if (_currentStyle.icon != null) {
      parts.add(_currentStyle.icon!.displayName);
    }

    if (widget.geometryType == GeometryType.lineString ||
        widget.geometryType == GeometryType.polygon) {
      parts.add('${_currentStyle.lineWidth.toInt()}px line');
    }

    if (widget.geometryType == GeometryType.polygon) {
      parts.add('${(_currentStyle.opacity * 100).toInt()}% opacity');
    }

    return parts.join(', ');
  }

  bool _canSave() {
    return _valueController.text.trim().isNotEmpty;
  }

  void _saveRule() {
    final value = _valueController.text.trim();
    if (value.isNotEmpty) {
      widget.onSave(value, _currentStyle);
      Navigator.of(context).pop();
    }
  }
}
