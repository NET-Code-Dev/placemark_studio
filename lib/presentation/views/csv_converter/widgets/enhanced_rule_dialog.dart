import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/enums/geometry_type.dart';
import '../../../../data/models/styling_rule.dart';
import '../../../../data/models/styling_options.dart';
import 'style_editor_widget.dart';

class EnhancedRuleDialog extends StatefulWidget {
  final GeometryType geometryType;
  final String columnName;
  final List<String> availableValues;
  final StylingRule? initialRule;
  final Function(StylingRule) onSave;

  const EnhancedRuleDialog({
    super.key,
    required this.geometryType,
    required this.columnName,
    required this.availableValues,
    this.initialRule,
    required this.onSave,
  });

  @override
  State<EnhancedRuleDialog> createState() => _EnhancedRuleDialogState();
}

class _EnhancedRuleDialogState extends State<EnhancedRuleDialog> {
  late TextEditingController _valueController;
  late TextEditingController _priorityController;
  late RuleOperator _selectedOperator;
  late GeometryStyle _currentStyle;
  late bool _isEnabled;

  bool _isNumericColumn = false;
  List<String> _suggestedValues = [];

  @override
  void initState() {
    super.initState();

    // Initialize controllers and values
    _valueController = TextEditingController(
      text: widget.initialRule?.value ?? '',
    );
    _priorityController = TextEditingController(
      text: widget.initialRule?.priority.toString() ?? '1',
    );
    _selectedOperator = widget.initialRule?.operator ?? RuleOperator.equals;
    _currentStyle =
        widget.initialRule?.style ??
        EnhancedStylingOptions.forGeometry(widget.geometryType).defaultStyle;
    _isEnabled = widget.initialRule?.isEnabled ?? true;

    // Analyze column data
    _analyzeColumnData();
  }

  @override
  void dispose() {
    _valueController.dispose();
    _priorityController.dispose();
    super.dispose();
  }

  void _analyzeColumnData() {
    final values = widget.availableValues;

    // Check if column contains mostly numeric values
    final numericCount = values.where((v) => double.tryParse(v) != null).length;
    _isNumericColumn = numericCount > (values.length * 0.7); // 70% threshold

    // Get unique values for suggestions
    _suggestedValues = values.toSet().toList()..sort();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        '${widget.initialRule != null ? 'Edit' : 'Add'} Styling Rule',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      content: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRuleConfiguration(),
              const SizedBox(height: 24),
              _buildStyleConfiguration(),
              const SizedBox(height: 24),
              _buildRuleSettings(),
              const SizedBox(height: 16),
              _buildRulePreview(),
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
          onPressed: _isValidRule() ? _saveRule : null,
          child: const Text('Save Rule'),
        ),
      ],
    );
  }

  Widget _buildRuleConfiguration() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rule Criteria',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 16),

            // Rule description
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  const TextSpan(text: 'When column '),
                  TextSpan(
                    text: '"${widget.columnName}"',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: ' is:'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Operator selection
            _buildOperatorSelection(),
            const SizedBox(height: 16),

            // Value input
            _buildValueInput(),

            // Value suggestions
            if (_suggestedValues.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildValueSuggestions(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOperatorSelection() {
    final availableOperators =
        _isNumericColumn
            ? RuleOperator.values
            : RuleOperator.values.where((op) => op.isString).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comparison Operator',
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
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<RuleOperator>(
              value: _selectedOperator,
              isExpanded: true,
              items:
                  availableOperators.map((operator) {
                    return DropdownMenuItem<RuleOperator>(
                      value: operator,
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 24,
                            decoration: BoxDecoration(
                              color:
                                  operator.isNumeric
                                      ? Colors.green[100]
                                      : Colors.blue[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Text(
                                operator.symbol,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color:
                                      operator.isNumeric
                                          ? Colors.green[700]
                                          : Colors.blue[700],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(operator.description),
                        ],
                      ),
                    );
                  }).toList(),
              onChanged: (operator) {
                if (operator != null) {
                  setState(() {
                    _selectedOperator = operator;
                  });
                }
              },
            ),
          ),
        ),
        if (_selectedOperator.isNumeric && !_isNumericColumn) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, size: 16, color: Colors.orange[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This column contains mostly non-numeric values. Numeric comparison may not work as expected.',
                    style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildValueInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comparison Value',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _valueController,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: _getValueHint(),
            suffixIcon:
                _selectedOperator.isNumeric
                    ? const Icon(Icons.numbers)
                    : const Icon(Icons.text_fields),
          ),
          keyboardType:
              _selectedOperator.isNumeric
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
          inputFormatters:
              _selectedOperator.isNumeric
                  ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.-]'))]
                  : null,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildValueSuggestions() {
    // Show only first 10 suggestions to avoid overwhelming UI
    final suggestions = _suggestedValues.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Common Values (tap to use)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children:
              suggestions.map((value) {
                final isSelected = _valueController.text == value;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _valueController.text = value;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[100] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected ? Colors.blue[300]! : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.blue[700] : Colors.grey[700],
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
        if (_suggestedValues.length > 10) ...[
          const SizedBox(height: 4),
          Text(
            'and ${_suggestedValues.length - 10} more values...',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStyleConfiguration() {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Style Configuration',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose how features matching this rule should be styled',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.green[700]),
            ),
            const SizedBox(height: 16),
            StyleEditorWidget(
              geometryType: widget.geometryType,
              initialStyle: _currentStyle,
              onStyleChanged: (style) {
                setState(() {
                  _currentStyle = style;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleSettings() {
    return Card(
      color: Colors.purple[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rule Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.purple[800],
              ),
            ),
            const SizedBox(height: 16),

            // Priority setting
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Priority Level',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Higher numbers have priority when rules overlap',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _priorityController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Enabled toggle
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rule Enabled',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Disabled rules are ignored during styling',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isEnabled,
                  onChanged: (enabled) {
                    setState(() {
                      _isEnabled = enabled;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRulePreview() {
    if (!_isValidRule()) {
      return const SizedBox.shrink();
    }

    // Count potential matches
    final testRule = _createRuleFromInputs();
    final matchCount = widget.availableValues.where(testRule.matches).length;
    final totalValues = widget.availableValues.length;
    final percentage = totalValues > 0 ? (matchCount / totalValues * 100) : 0;

    return Card(
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.preview, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Rule Preview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Rule description
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  // Style preview
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
                    child:
                        widget.geometryType == GeometryType.point &&
                                _currentStyle.icon != null
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _currentStyle.icon!.url,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
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
                  Expanded(
                    child: Text(
                      testRule.displayDescription,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Match statistics
            Row(
              children: [
                Icon(Icons.analytics, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Matches $matchCount of $totalValues values (${percentage.toStringAsFixed(1)}%)',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                ),
              ],
            ),

            if (matchCount == 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, size: 16, color: Colors.orange[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This rule doesn\'t match any current values in the column.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getValueHint() {
    switch (_selectedOperator) {
      case RuleOperator.equals:
        return 'Enter exact value to match';
      case RuleOperator.greaterThan:
        return 'Enter number (column > this value)';
      case RuleOperator.lessThan:
        return 'Enter number (column < this value)';
      case RuleOperator.greaterThanOrEqual:
        return 'Enter number (column ≥ this value)';
      case RuleOperator.lessThanOrEqual:
        return 'Enter number (column ≤ this value)';
      case RuleOperator.contains:
        return 'Enter text to search for';
      case RuleOperator.startsWith:
        return 'Enter starting text';
      case RuleOperator.endsWith:
        return 'Enter ending text';
    }
  }

  bool _isValidRule() {
    if (_valueController.text.trim().isEmpty) return false;
    if (_priorityController.text.trim().isEmpty) return false;

    final priority = int.tryParse(_priorityController.text);
    if (priority == null || priority < 0) return false;

    // For numeric operators, ensure the value is numeric
    if (_selectedOperator.isNumeric) {
      return double.tryParse(_valueController.text.trim()) != null;
    }

    return true;
  }

  StylingRule _createRuleFromInputs() {
    final ruleId =
        widget.initialRule?.id ??
        'rule_${DateTime.now().millisecondsSinceEpoch}';

    return StylingRule(
      id: ruleId,
      columnName: widget.columnName,
      operator: _selectedOperator,
      value: _valueController.text.trim(),
      style: _currentStyle,
      priority: int.tryParse(_priorityController.text) ?? 1,
      isEnabled: _isEnabled,
    );
  }

  void _saveRule() {
    if (!_isValidRule()) return;

    final rule = _createRuleFromInputs();
    widget.onSave(rule);
    Navigator.of(context).pop();
  }
}
