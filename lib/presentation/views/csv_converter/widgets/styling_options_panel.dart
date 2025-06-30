import 'package:flutter/material.dart';
import '../../../../core/enums/geometry_type.dart';
import '../../../../data/models/styling_options.dart';

class StylingOptionsPanel extends StatefulWidget {
  final GeometryType geometryType;
  final StylingOptions stylingOptions;
  final List<String> availableColumns;
  final Function(StylingOptions) onStylingChanged;
  final Function(String)? onPreviewColumn; // For showing column values

  const StylingOptionsPanel({
    super.key,
    required this.geometryType,
    required this.stylingOptions,
    required this.availableColumns,
    required this.onStylingChanged,
    this.onPreviewColumn,
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
              'Customize the appearance of your ${widget.geometryType.displayName.toLowerCase()}s:',
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
              // Color selection
              Row(
                children: [
                  Text(
                    'Color:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildColorSelector(
                      _currentOptions.defaultStyle.color,
                      (color) => _updateDefaultStyle(
                        _currentOptions.defaultStyle.copyWith(color: color),
                      ),
                    ),
                  ),
                ],
              ),

              // Icon selection (for points only)
              if (widget.geometryType == GeometryType.point) ...[
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
                    Expanded(
                      child: _buildIconSelector(
                        _currentOptions.defaultStyle.icon ??
                            KmlIcon.yellowPushpin,
                        (icon) => _updateDefaultStyle(
                          _currentOptions.defaultStyle.copyWith(icon: icon),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Line width (for lines and polygons)
              if (widget.geometryType == GeometryType.lineString ||
                  widget.geometryType == GeometryType.polygon) ...[
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
                    Expanded(
                      child: Slider(
                        value: _currentOptions.defaultStyle.lineWidth,
                        min: 1.0,
                        max: 10.0,
                        divisions: 9,
                        label:
                            '${_currentOptions.defaultStyle.lineWidth.toInt()}px',
                        onChanged:
                            (value) => _updateDefaultStyle(
                              _currentOptions.defaultStyle.copyWith(
                                lineWidth: value,
                              ),
                            ),
                      ),
                    ),
                    Text('${_currentOptions.defaultStyle.lineWidth.toInt()}px'),
                  ],
                ),
              ],

              // Opacity (for polygons)
              if (widget.geometryType == GeometryType.polygon) ...[
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
                    Expanded(
                      child: Slider(
                        value: _currentOptions.defaultStyle.opacity,
                        min: 0.1,
                        max: 1.0,
                        divisions: 9,
                        label:
                            '${(_currentOptions.defaultStyle.opacity * 100).toInt()}%',
                        onChanged:
                            (value) => _updateDefaultStyle(
                              _currentOptions.defaultStyle.copyWith(
                                opacity: value,
                              ),
                            ),
                      ),
                    ),
                    Text(
                      '${(_currentOptions.defaultStyle.opacity * 100).toInt()}%',
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
              value: _currentOptions.useColumnBasedStyling,
              onChanged: (value) => _updateColumnBasedStyling(value),
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

        if (_currentOptions.useColumnBasedStyling) ...[
          const SizedBox(height: 16),

          // Column selection
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
                  value: _currentOptions.stylingColumn,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  items:
                      widget.availableColumns
                          .map(
                            (column) => DropdownMenuItem(
                              value: column,
                              child: Text(column),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => _updateStylingColumn(value),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Style rules
          if (_currentOptions.stylingColumn != null) ...[
            Row(
              children: [
                Text(
                  'Style Rules:',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addStyleRule,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Rule'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Style rules list
            if (_currentOptions.columnBasedStyles.isNotEmpty)
              ..._currentOptions.columnBasedStyles.entries.map(
                (entry) => _buildStyleRuleCard(context, entry.key, entry.value),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'No style rules defined. Add rules to style different values differently.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ),
              ),
          ],
        ],
      ],
    );
  }

  Widget _buildColorSelector(
    KmlColor currentColor,
    Function(KmlColor) onChanged,
  ) {
    return Wrap(
      spacing: 8,
      children:
          KmlColor.predefinedColors.map((color) {
            final isSelected = color.kmlValue == currentColor.kmlValue;
            return GestureDetector(
              onTap: () => onChanged(color),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.color,
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.grey,
                    width: isSelected ? 3 : 1,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child:
                    isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
              ),
            );
          }).toList(),
    );
  }

  Widget _buildIconSelector(KmlIcon currentIcon, Function(KmlIcon) onChanged) {
    return DropdownButtonFormField<KmlIcon>(
      value: currentIcon,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(),
      ),
      items:
          KmlIcon.values.map((icon) {
            return DropdownMenuItem<KmlIcon>(
              value: icon,
              child: Text(icon.displayName),
            );
          }).toList(),
      onChanged: (value) => onChanged(value!),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'When "${_currentOptions.stylingColumn}" = "$value"',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _removeStyleRule(value),
                  icon: const Icon(Icons.delete, size: 18),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Style preview
            Row(
              children: [
                // Color indicator
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: style.color.color,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),

                // Style details
                Expanded(
                  child: Text(
                    _getStyleDescription(style),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),

                // Edit button
                TextButton(
                  onPressed: () => _editStyleRule(value, style),
                  child: const Text('Edit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

  void _addStyleRule() {
    if (_currentOptions.stylingColumn == null) return;

    showDialog(
      context: context,
      builder:
          (context) => StyleRuleDialog(
            geometryType: widget.geometryType,
            columnName: _currentOptions.stylingColumn!,
            onSave: (value, style) {
              setState(() {
                final newStyles = Map<String, GeometryStyle>.from(
                  _currentOptions.columnBasedStyles,
                );
                newStyles[value] = style;
                _currentOptions = _currentOptions.copyWith(
                  columnBasedStyles: newStyles,
                );
              });
              widget.onStylingChanged(_currentOptions);
            },
          ),
    );
  }

  void _editStyleRule(String value, GeometryStyle currentStyle) {
    showDialog(
      context: context,
      builder:
          (context) => StyleRuleDialog(
            geometryType: widget.geometryType,
            columnName: _currentOptions.stylingColumn!,
            initialValue: value,
            initialStyle: currentStyle,
            onSave: (newValue, newStyle) {
              setState(() {
                final newStyles = Map<String, GeometryStyle>.from(
                  _currentOptions.columnBasedStyles,
                );
                if (newValue != value) {
                  newStyles.remove(value); // Remove old key
                }
                newStyles[newValue] = newStyle;
                _currentOptions = _currentOptions.copyWith(
                  columnBasedStyles: newStyles,
                );
              });
              widget.onStylingChanged(_currentOptions);
            },
          ),
    );
  }

  void _removeStyleRule(String value) {
    setState(() {
      final newStyles = Map<String, GeometryStyle>.from(
        _currentOptions.columnBasedStyles,
      );
      newStyles.remove(value);
      _currentOptions = _currentOptions.copyWith(columnBasedStyles: newStyles);
    });
    widget.onStylingChanged(_currentOptions);
  }
}

/// Dialog for creating/editing style rules
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('When "${widget.columnName}" equals:'),
            const SizedBox(height: 8),
            TextField(
              controller: _valueController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter column value',
              ),
            ),
            const SizedBox(height: 16),

            Text('Style:'),
            const SizedBox(height: 8),

            // Color selection
            Text('Color:', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children:
                  KmlColor.predefinedColors.take(8).map((color) {
                    final isSelected =
                        color.kmlValue == _currentStyle.color.kmlValue;
                    return GestureDetector(
                      onTap:
                          () => setState(() {
                            _currentStyle = _currentStyle.copyWith(
                              color: color,
                            );
                          }),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: color.color,
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.grey,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }).toList(),
            ),

            // Icon selection (for points)
            if (widget.geometryType == GeometryType.point) ...[
              const SizedBox(height: 12),
              Text('Icon:', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              DropdownButtonFormField<KmlIcon>(
                value: _currentStyle.icon ?? KmlIcon.yellowPushpin,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  border: OutlineInputBorder(),
                ),
                items:
                    KmlIcon.values.take(10).map((icon) {
                      return DropdownMenuItem<KmlIcon>(
                        value: icon,
                        child: Text(icon.displayName),
                      );
                    }).toList(),
                onChanged:
                    (value) => setState(() {
                      _currentStyle = _currentStyle.copyWith(icon: value);
                    }),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _valueController.text.isNotEmpty ? _save : null,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _save() {
    widget.onSave(_valueController.text.trim(), _currentStyle);
    Navigator.of(context).pop();
  }
}

/// Widget showing a preview of the current styling
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

                  // Column-based styles
                  if (stylingOptions.useColumnBasedStyling &&
                      stylingOptions.columnBasedStyles.isNotEmpty) ...[
                    const Divider(height: 20),
                    ...stylingOptions.columnBasedStyles.entries.map(
                      (entry) => _buildStylePreviewRow(
                        context,
                        entry.key,
                        entry.value,
                      ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
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
      ),
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
