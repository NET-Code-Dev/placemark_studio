// lib/data/models/styling_rule.dart

import '../../core/enums/geometry_type.dart';
import 'kml_generation_options.dart' as kml_opts;
import 'styling_options.dart';

enum RuleOperator {
  equals('=', 'equals'),
  greaterThan('>', 'greater than'),
  lessThan('<', 'less than'),
  greaterThanOrEqual('≥', 'greater than or equal'),
  lessThanOrEqual('≤', 'less than or equal'),
  contains('contains', 'contains'),
  startsWith('starts with', 'starts with'),
  endsWith('ends with', 'ends with');

  const RuleOperator(this.symbol, this.description);
  final String symbol;
  final String description;

  String get displayText => '$symbol ($description)';

  bool get isNumeric => [
    greaterThan,
    lessThan,
    greaterThanOrEqual,
    lessThanOrEqual,
  ].contains(this);

  bool get isString => [equals, contains, startsWith, endsWith].contains(this);
}

/// Enhanced styling rule with comparison operators
class StylingRule {
  final String id;
  final String columnName;
  final RuleOperator operator;
  final String value; // The value to compare against
  final GeometryStyle style;
  final int priority; // Higher numbers = higher priority
  final bool isEnabled;

  const StylingRule({
    required this.id,
    required this.columnName,
    required this.operator,
    required this.value,
    required this.style,
    this.priority = 0,
    this.isEnabled = true,
  });

  /// Check if this rule matches a given cell value
  bool matches(String? cellValue) {
    if (!isEnabled || cellValue == null) return false;

    final cleanCellValue = cellValue.toString().trim();
    final cleanRuleValue = value.trim();

    switch (operator) {
      case RuleOperator.equals:
        return cleanCellValue == cleanRuleValue;

      case RuleOperator.contains:
        return cleanCellValue.toLowerCase().contains(
          cleanRuleValue.toLowerCase(),
        );

      case RuleOperator.startsWith:
        return cleanCellValue.toLowerCase().startsWith(
          cleanRuleValue.toLowerCase(),
        );

      case RuleOperator.endsWith:
        return cleanCellValue.toLowerCase().endsWith(
          cleanRuleValue.toLowerCase(),
        );

      case RuleOperator.greaterThan:
      case RuleOperator.lessThan:
      case RuleOperator.greaterThanOrEqual:
      case RuleOperator.lessThanOrEqual:
        return _compareNumeric(cleanCellValue, cleanRuleValue);
    }
  }

  bool _compareNumeric(String cellValue, String ruleValue) {
    final cellNum = double.tryParse(cellValue);
    final ruleNum = double.tryParse(ruleValue);

    if (cellNum == null || ruleNum == null) return false;

    switch (operator) {
      case RuleOperator.greaterThan:
        return cellNum > ruleNum;
      case RuleOperator.lessThan:
        return cellNum < ruleNum;
      case RuleOperator.greaterThanOrEqual:
        return cellNum >= ruleNum;
      case RuleOperator.lessThanOrEqual:
        return cellNum <= ruleNum;
      default:
        return false;
    }
  }

  String get displayDescription {
    final operatorText = operator.symbol;
    return 'When "$columnName" $operatorText "$value"';
  }

  String get ruleId => 'rule_$id';

  StylingRule copyWith({
    String? id,
    String? columnName,
    RuleOperator? operator,
    String? value,
    GeometryStyle? style,
    int? priority,
    bool? isEnabled,
  }) {
    return StylingRule(
      id: id ?? this.id,
      columnName: columnName ?? this.columnName,
      operator: operator ?? this.operator,
      value: value ?? this.value,
      style: style ?? this.style,
      priority: priority ?? this.priority,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  @override
  String toString() {
    return 'StylingRule($displayDescription -> ${style.color.name})';
  }
}

/// Enhanced styling options with rule-based system
class EnhancedStylingOptions {
  final List<StylingRule> rules;
  final GeometryStyle defaultStyle;
  final bool useRuleBasedStyling;
  final String? stylingColumn;

  const EnhancedStylingOptions({
    this.rules = const [],
    required this.defaultStyle,
    this.useRuleBasedStyling = false,
    this.stylingColumn,
  });

  /// Factory for default styling based on geometry type
  factory EnhancedStylingOptions.forGeometry(GeometryType geometryType) {
    switch (geometryType) {
      case GeometryType.point:
        return EnhancedStylingOptions(defaultStyle: GeometryStyle.point());
      case GeometryType.lineString:
        return EnhancedStylingOptions(defaultStyle: GeometryStyle.line());
      case GeometryType.polygon:
        return EnhancedStylingOptions(defaultStyle: GeometryStyle.polygon());
      default:
        return EnhancedStylingOptions(defaultStyle: GeometryStyle.point());
    }
  }

  /// Get style for a specific column value using rule priority
  GeometryStyle getStyleForValue(String? value) {
    if (!useRuleBasedStyling || value == null) {
      return defaultStyle;
    }

    // Find matching rules sorted by priority (highest first)
    final matchingRules =
        rules.where((rule) => rule.matches(value)).toList()
          ..sort((a, b) => b.priority.compareTo(a.priority));

    // Return style from highest priority matching rule
    return matchingRules.isNotEmpty ? matchingRules.first.style : defaultStyle;
  }

  /// Get all rules for the current column
  List<StylingRule> get rulesForColumn {
    if (stylingColumn == null) return [];
    return rules.where((rule) => rule.columnName == stylingColumn).toList();
  }

  /// Get rules sorted by priority
  List<StylingRule> get rulesByPriority {
    final sortedRules = List<StylingRule>.from(rules);
    sortedRules.sort((a, b) => b.priority.compareTo(a.priority));
    return sortedRules;
  }

  /// Add a new rule
  EnhancedStylingOptions addRule(StylingRule rule) {
    final newRules = List<StylingRule>.from(rules);
    newRules.add(rule);
    return copyWith(rules: newRules);
  }

  /// Update an existing rule
  EnhancedStylingOptions updateRule(String ruleId, StylingRule updatedRule) {
    final newRules =
        rules.map((rule) {
          return rule.id == ruleId ? updatedRule : rule;
        }).toList();
    return copyWith(rules: newRules);
  }

  /// Remove a rule
  EnhancedStylingOptions removeRule(String ruleId) {
    final newRules = rules.where((rule) => rule.id != ruleId).toList();
    return copyWith(rules: newRules);
  }

  /// Validate rules against column data
  RuleValidationResult validateRules(List<String> columnValues) {
    final validation = RuleValidationResult();

    for (final rule in rulesForColumn) {
      final matchingValues = columnValues.where(rule.matches).toList();
      validation.addRuleResult(rule, matchingValues);
    }

    final unmatchedValues =
        columnValues.where((value) {
          return !rulesForColumn.any((rule) => rule.matches(value));
        }).toList();

    validation.unmatchedValues = unmatchedValues;
    return validation;
  }

  EnhancedStylingOptions copyWith({
    List<StylingRule>? rules,
    GeometryStyle? defaultStyle,
    bool? useRuleBasedStyling,
    String? stylingColumn,
  }) {
    return EnhancedStylingOptions(
      rules: rules ?? this.rules,
      defaultStyle: defaultStyle ?? this.defaultStyle,
      useRuleBasedStyling: useRuleBasedStyling ?? this.useRuleBasedStyling,
      stylingColumn: stylingColumn ?? this.stylingColumn,
    );
  }

  /// Convert to legacy StyleRule map for backward compatibility
  Map<String, kml_opts.StyleRule> toLegacyStyleRules() {
    final legacyRules = <String, kml_opts.StyleRule>{};

    if (useRuleBasedStyling && stylingColumn != null) {
      for (final rule in rulesForColumn.where(
        (r) => r.operator == RuleOperator.equals,
      )) {
        // Only convert equality rules for backward compatibility
        legacyRules[rule.ruleId] = kml_opts.StyleRule(
          columnName: stylingColumn!,
          columnValue: rule.value,
          color: rule.style.color.kmlValue,
          iconUrl: rule.style.icon?.url ?? KmlIcon.pushpin.url,
        );
      }
    }

    return legacyRules;
  }

  @override
  String toString() {
    return 'EnhancedStylingOptions(ruleCount: ${rules.length}, column: $stylingColumn)';
  }
}

/// Validation result for styling rules
class RuleValidationResult {
  final Map<StylingRule, List<String>> ruleMatches = {};
  List<String> unmatchedValues = [];

  void addRuleResult(StylingRule rule, List<String> matchingValues) {
    ruleMatches[rule] = matchingValues;
  }

  int get totalMatchedValues {
    return ruleMatches.values.fold(0, (sum, matches) => sum + matches.length);
  }

  int get unmatchedCount => unmatchedValues.length;

  bool get hasUnmatchedValues => unmatchedValues.isNotEmpty;

  bool get hasOverlappingRules {
    final allMatches = <String>[];
    for (final matches in ruleMatches.values) {
      for (final match in matches) {
        if (allMatches.contains(match)) return true;
        allMatches.add(match);
      }
    }
    return false;
  }

  List<String> getConflictingValues() {
    final valueRuleCounts = <String, int>{};

    for (final matches in ruleMatches.values) {
      for (final match in matches) {
        valueRuleCounts[match] = (valueRuleCounts[match] ?? 0) + 1;
      }
    }

    return valueRuleCounts.entries
        .where((entry) => entry.value > 1)
        .map((entry) => entry.key)
        .toList();
  }
}
