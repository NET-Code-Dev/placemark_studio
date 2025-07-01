import 'package:flutter/material.dart';
import '../../../../core/enums/geometry_type.dart';
import '../../../../data/models/csv_data.dart';
import '../../../../data/models/styling_rule.dart';
import '../../../../data/models/styling_options.dart';
import 'enhanced_styling_panel.dart';

/// Integration widget that handles the migration from old to new styling system
class StylingIntegration extends StatefulWidget {
  final GeometryType geometryType;
  final CsvData? csvData;
  final List<String> availableColumns;
  final Function(EnhancedStylingOptions) onStylingChanged;
  final EnhancedStylingOptions? initialOptions;

  const StylingIntegration({
    super.key,
    required this.geometryType,
    this.csvData,
    required this.availableColumns,
    required this.onStylingChanged,
    this.initialOptions,
  });

  @override
  State<StylingIntegration> createState() => _StylingIntegrationState();
}

class _StylingIntegrationState extends State<StylingIntegration> {
  late EnhancedStylingOptions _currentOptions;
  List<String>? _previewColumnValues;
  String? _currentPreviewColumn;

  @override
  void initState() {
    super.initState();
    _currentOptions =
        widget.initialOptions ??
        EnhancedStylingOptions.forGeometry(widget.geometryType);
  }

  @override
  void didUpdateWidget(StylingIntegration oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update options if CSV data changed
    if (oldWidget.csvData != widget.csvData) {
      _previewColumnValues = null;
      _currentPreviewColumn = null;

      // Reset styling column if it's no longer available
      if (_currentOptions.stylingColumn != null &&
          !widget.availableColumns.contains(_currentOptions.stylingColumn)) {
        _currentOptions = _currentOptions.copyWith(
          stylingColumn: null,
          rules: [],
          useRuleBasedStyling: false,
        );
        widget.onStylingChanged(_currentOptions);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Migration notice (if needed)
        if (_showMigrationNotice()) ...[
          _buildMigrationNotice(),
          const SizedBox(height: 16),
        ],

        // Enhanced styling panel
        EnhancedStylingPanel(
          geometryType: widget.geometryType,
          availableColumns: widget.availableColumns,
          previewColumnValues: _previewColumnValues,
          stylingOptions: _currentOptions,
          onStylingChanged: _handleStylingChanged,
          onPreviewColumn: _handlePreviewColumn,
        ),

        // Validation summary
        if (widget.csvData != null && _currentOptions.useRuleBasedStyling) ...[
          const SizedBox(height: 16),
          _buildValidationSummary(),
        ],
      ],
    );
  }

  bool _showMigrationNotice() {
    // Show migration notice if user had old-style column-based styling
    return false; // For now, we'll assume clean implementation
  }

  Widget _buildMigrationNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.upgrade, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Text(
                'Enhanced Styling Available!',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your styling configuration has been upgraded to support advanced criteria-based rules with comparison operators (>, <, ≥, ≤) and text matching.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.blue[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationSummary() {
    final validation = _currentOptions.validateAgainstData(widget.csvData!);

    return Card(
      color:
          validation.isValid
              ? (validation.hasWarnings ? Colors.orange[50] : Colors.green[50])
              : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  validation.isValid
                      ? (validation.hasWarnings
                          ? Icons.warning
                          : Icons.check_circle)
                      : Icons.error,
                  color:
                      validation.isValid
                          ? (validation.hasWarnings
                              ? Colors.orange[600]
                              : Colors.green[600])
                          : Colors.red[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'Styling Validation',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color:
                        validation.isValid
                            ? (validation.hasWarnings
                                ? Colors.orange[800]
                                : Colors.green[800])
                            : Colors.red[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Text(
              validation.summary,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),

            if (validation.message.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                validation.message,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],

            if (validation.hasWarnings) ...[
              const SizedBox(height: 8),
              ...validation.warnings.map(
                (warning) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning, size: 16, color: Colors.orange[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          warning,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.orange[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleStylingChanged(EnhancedStylingOptions newOptions) {
    setState(() {
      _currentOptions = newOptions;
    });
    widget.onStylingChanged(newOptions);
  }

  void _handlePreviewColumn(String columnName) {
    if (widget.csvData == null || columnName == _currentPreviewColumn) return;

    setState(() {
      _currentPreviewColumn = columnName;
      _previewColumnValues =
          widget.csvData!.rows
              .map((row) => row[columnName]?.toString())
              .where((value) => value != null && value.isNotEmpty)
              .cast<String>()
              .toList();
    });
  }
}

/// Helper class to migrate from old StylingOptions to EnhancedStylingOptions
class StylingMigration {
  /// Migrate old column-based styling to enhanced rule-based styling
  static EnhancedStylingOptions migrateFromLegacy(
    StylingOptions oldOptions,
    GeometryType geometryType,
  ) {
    final enhancedOptions = EnhancedStylingOptions.forGeometry(
      geometryType,
    ).copyWith(
      defaultStyle: oldOptions.defaultStyle,
      useRuleBasedStyling: oldOptions.useColumnBasedStyling,
      stylingColumn: oldOptions.stylingColumn,
    );

    // Convert old column-based styles to equality rules
    if (oldOptions.useColumnBasedStyling && oldOptions.stylingColumn != null) {
      final rules = <StylingRule>[];
      int priority = 1;

      for (final entry in oldOptions.columnBasedStyles.entries) {
        final rule = StylingRule(
          id: 'migrated_rule_${DateTime.now().millisecondsSinceEpoch}_$priority',
          columnName: oldOptions.stylingColumn!,
          operator: RuleOperator.equals,
          value: entry.key,
          style: entry.value,
          priority: priority++,
          isEnabled: true,
        );
        rules.add(rule);
      }

      return enhancedOptions.copyWith(rules: rules);
    }

    return enhancedOptions;
  }

  /// Convert enhanced styling back to legacy format for backward compatibility
  static StylingOptions convertToLegacy(
    EnhancedStylingOptions enhancedOptions,
  ) {
    final legacyStyles = <String, GeometryStyle>{};

    // Only include equality rules for backward compatibility
    for (final rule in enhancedOptions.rules) {
      if (rule.operator == RuleOperator.equals && rule.isEnabled) {
        legacyStyles[rule.value] = rule.style;
      }
    }

    return StylingOptions(
      defaultStyle: enhancedOptions.defaultStyle,
      useColumnBasedStyling: enhancedOptions.useRuleBasedStyling,
      stylingColumn: enhancedOptions.stylingColumn,
      columnBasedStyles: legacyStyles,
    );
  }
}

/// Quick actions widget for common styling scenarios
class StylingQuickActions extends StatelessWidget {
  final GeometryType geometryType;
  final List<String> availableColumns;
  final List<String>? columnValues;
  final Function(List<StylingRule>) onApplyRules;

  const StylingQuickActions({
    super.key,
    required this.geometryType,
    required this.availableColumns,
    this.columnValues,
    required this.onApplyRules,
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
              'Quick Styling Templates',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickActionChip(
                  context,
                  'Color by Value',
                  Icons.palette,
                  () => _applyColorByValue(context),
                ),
                _buildQuickActionChip(
                  context,
                  'Size by Number',
                  Icons.straighten,
                  columnValues != null && _hasNumericValues()
                      ? () => _applySizeByNumber(context)
                      : null,
                ),
                _buildQuickActionChip(
                  context,
                  'Category Groups',
                  Icons.category,
                  () => _applyCategoryGroups(context),
                ),
                _buildQuickActionChip(
                  context,
                  'Range Styling',
                  Icons.bar_chart,
                  columnValues != null && _hasNumericValues()
                      ? () => _applyRangeStyling(context)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionChip(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: onTap != null ? null : Colors.grey[200],
    );
  }

  bool _hasNumericValues() {
    if (columnValues == null) return false;
    return columnValues!.any((value) => double.tryParse(value) != null);
  }

  void _applyColorByValue(BuildContext context) {
    // Implementation for color by value quick action
    // This would create rules that assign different colors to different values
  }

  void _applySizeByNumber(BuildContext context) {
    // Implementation for size by number (for points, varying icon sizes)
  }

  void _applyCategoryGroups(BuildContext context) {
    // Implementation for category-based grouping
  }

  void _applyRangeStyling(BuildContext context) {
    // Implementation for numeric range-based styling
  }
}
