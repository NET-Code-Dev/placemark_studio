import 'package:flutter/material.dart';
import '../../../../core/enums/geometry_type.dart';
import '../../../../data/models/styling_rule.dart';
import '../../../../data/models/styling_options.dart';
import 'enhanced_rule_dialog.dart';
import 'style_editor_widget.dart';

class StylingOptionsPanel extends StatefulWidget {
  final GeometryType geometryType;
  final List<String> availableColumns;
  final List<String>? previewColumnValues;
  final EnhancedStylingOptions stylingOptions;
  final Function(EnhancedStylingOptions) onStylingChanged;
  final Function(String)? onPreviewColumn;

  const StylingOptionsPanel({
    super.key,
    required this.geometryType,
    required this.availableColumns,
    this.previewColumnValues,
    required this.stylingOptions,
    required this.onStylingChanged,
    this.onPreviewColumn,
  });

  @override
  State<StylingOptionsPanel> createState() => _StylingOptionsPanelState();
}

class _StylingOptionsPanelState extends State<StylingOptionsPanel> {
  late EnhancedStylingOptions _currentOptions;

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
            _buildStylingHeader(context),
            const SizedBox(height: 16),
            _buildDefaultStyleSection(context),
            const SizedBox(height: 20),
            _buildRuleBasedStylingSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStylingHeader(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.palette, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(
          'Styling & Visual Appearance',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        if (_currentOptions.useRuleBasedStyling &&
            _currentOptions.rules.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_currentOptions.rules.length} rules',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDefaultStyleSection(BuildContext context) {
    return Card(
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Default Style',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Applied to features that don\'t match any custom rules',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            StyleEditorWidget(
              geometryType: widget.geometryType,
              initialStyle: _currentOptions.defaultStyle,
              onStyleChanged: _updateDefaultStyle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleBasedStylingSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Criteria-Based Styling',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Switch(
              value: _currentOptions.useRuleBasedStyling,
              onChanged: _toggleRuleBasedStyling,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Apply different styles based on column values using custom criteria',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),

        if (_currentOptions.useRuleBasedStyling) ...[
          const SizedBox(height: 16),
          _buildColumnSelection(context),

          if (_currentOptions.stylingColumn != null) ...[
            const SizedBox(height: 16),
            if (widget.previewColumnValues != null)
              _buildColumnPreview(context),
            const SizedBox(height: 16),
            _buildRulesSection(context),
            const SizedBox(height: 16),
            _buildRuleValidation(context),
          ],
        ],
      ],
    );
  }

  Widget _buildColumnSelection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Column for Styling Rules',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _currentOptions.stylingColumn,
              hint: const Text('Choose a column...'),
              isExpanded: true,
              items:
                  widget.availableColumns.map((column) {
                    return DropdownMenuItem<String>(
                      value: column,
                      child: Text(column),
                    );
                  }).toList(),
              onChanged: _updateStylingColumn,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColumnPreview(BuildContext context) {
    final values = widget.previewColumnValues!;
    final uniqueValues = values.toSet().toList()..sort();

    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Column Values Preview',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Found ${uniqueValues.length} unique values (${values.length} total):',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children:
                  uniqueValues.take(15).map((value) {
                    final isNumeric = double.tryParse(value) != null;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              isNumeric
                                  ? Colors.green[300]!
                                  : Colors.blue[300]!,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isNumeric)
                            Icon(
                              Icons.numbers,
                              size: 12,
                              color: Colors.green[600],
                            ),
                          if (isNumeric) const SizedBox(width: 4),
                          Text(
                            value,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
            if (uniqueValues.length > 15) ...[
              const SizedBox(height: 8),
              Text(
                'and ${uniqueValues.length - 15} more...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRulesSection(BuildContext context) {
    final columnRules = _currentOptions.rulesForColumn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Styling Rules',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            ElevatedButton.icon(
              onPressed: _addNewRule,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Rule'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (columnRules.isEmpty) ...[
          _buildEmptyRulesState(context),
        ] else ...[
          ...columnRules.map((rule) => _buildRuleCard(context, rule)),
        ],
      ],
    );
  }

  Widget _buildEmptyRulesState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.rule, color: Colors.grey[400], size: 48),
            const SizedBox(height: 12),
            Text(
              'No styling rules yet',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add rules to style features based on column criteria',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleCard(BuildContext context, StylingRule rule) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Priority indicator
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '${rule.priority}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Style preview
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: rule.style.color.color,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(
                  widget.geometryType == GeometryType.point ? 16 : 4,
                ),
              ),
              child:
                  widget.geometryType == GeometryType.point &&
                          rule.style.icon != null
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          rule.style.icon!.url,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
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

            // Rule description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rule.displayDescription,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStyleDescription(rule.style),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // Enabled toggle
            Switch(
              value: rule.isEnabled,
              onChanged: (enabled) => _toggleRuleEnabled(rule.id, enabled),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),

            // Actions
            PopupMenuButton<String>(
              onSelected: (action) => _handleRuleAction(rule, action),
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 16),
                          SizedBox(width: 8),
                          Text('Duplicate'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
              child: const Icon(Icons.more_vert),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleValidation(BuildContext context) {
    if (widget.previewColumnValues == null) return const SizedBox.shrink();

    final validation = _currentOptions.validateRules(
      widget.previewColumnValues!,
    );

    return Card(
      color:
          validation.hasUnmatchedValues ? Colors.orange[50] : Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  validation.hasUnmatchedValues
                      ? Icons.warning
                      : Icons.check_circle,
                  color:
                      validation.hasUnmatchedValues
                          ? Colors.orange[600]
                          : Colors.green[600],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Rule Validation',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color:
                        validation.hasUnmatchedValues
                            ? Colors.orange[800]
                            : Colors.green[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Text(
              'Matched: ${validation.totalMatchedValues} values',
              style: Theme.of(context).textTheme.bodySmall,
            ),

            if (validation.hasUnmatchedValues) ...[
              Text(
                'Unmatched: ${validation.unmatchedCount} values (will use default style)',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.orange[700]),
              ),
            ],

            if (validation.hasOverlappingRules) ...[
              const SizedBox(height: 4),
              Text(
                'Warning: Some values match multiple rules. Highest priority rule will be used.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.orange[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
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

  // Event handlers
  void _updateDefaultStyle(GeometryStyle newStyle) {
    setState(() {
      _currentOptions = _currentOptions.copyWith(defaultStyle: newStyle);
    });
    widget.onStylingChanged(_currentOptions);
  }

  void _toggleRuleBasedStyling(bool enabled) {
    setState(() {
      _currentOptions = _currentOptions.copyWith(
        useRuleBasedStyling: enabled,
        stylingColumn: enabled ? _currentOptions.stylingColumn : null,
        rules: enabled ? _currentOptions.rules : [],
      );
    });
    widget.onStylingChanged(_currentOptions);
  }

  void _updateStylingColumn(String? column) {
    setState(() {
      _currentOptions = _currentOptions.copyWith(
        stylingColumn: column,
        rules: [], // Clear existing rules when column changes
      );
    });
    widget.onStylingChanged(_currentOptions);

    // Trigger preview of column values
    if (column != null && widget.onPreviewColumn != null) {
      widget.onPreviewColumn!(column);
    }
  }

  void _addNewRule() {
    if (_currentOptions.stylingColumn == null) return;

    showDialog(
      context: context,
      builder:
          (context) => EnhancedRuleDialog(
            geometryType: widget.geometryType,
            columnName: _currentOptions.stylingColumn!,
            availableValues: widget.previewColumnValues ?? [],
            onSave: (rule) {
              setState(() {
                _currentOptions = _currentOptions.addRule(rule);
              });
              widget.onStylingChanged(_currentOptions);
            },
          ),
    );
  }

  void _toggleRuleEnabled(String ruleId, bool enabled) {
    final rule = _currentOptions.rules.firstWhere((r) => r.id == ruleId);
    final updatedRule = rule.copyWith(isEnabled: enabled);

    setState(() {
      _currentOptions = _currentOptions.updateRule(ruleId, updatedRule);
    });
    widget.onStylingChanged(_currentOptions);
  }

  void _handleRuleAction(StylingRule rule, String action) {
    switch (action) {
      case 'edit':
        _editRule(rule);
        break;
      case 'duplicate':
        _duplicateRule(rule);
        break;
      case 'delete':
        _deleteRule(rule);
        break;
    }
  }

  void _editRule(StylingRule rule) {
    showDialog(
      context: context,
      builder:
          (context) => EnhancedRuleDialog(
            geometryType: widget.geometryType,
            columnName: _currentOptions.stylingColumn!,
            availableValues: widget.previewColumnValues ?? [],
            initialRule: rule,
            onSave: (updatedRule) {
              setState(() {
                _currentOptions = _currentOptions.updateRule(
                  rule.id,
                  updatedRule,
                );
              });
              widget.onStylingChanged(_currentOptions);
            },
          ),
    );
  }

  void _duplicateRule(StylingRule rule) {
    final duplicatedRule = rule.copyWith(
      id: 'rule_${DateTime.now().millisecondsSinceEpoch}',
      priority: rule.priority + 1,
    );

    setState(() {
      _currentOptions = _currentOptions.addRule(duplicatedRule);
    });
    widget.onStylingChanged(_currentOptions);
  }

  void _deleteRule(StylingRule rule) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Rule'),
            content: Text(
              'Are you sure you want to delete this rule?\n\n${rule.displayDescription}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _currentOptions = _currentOptions.removeRule(rule.id);
                  });
                  widget.onStylingChanged(_currentOptions);
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}
