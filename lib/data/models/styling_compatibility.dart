import 'package:flutter/material.dart';
import '../../core/enums/geometry_type.dart';
import 'kml_generation_options.dart' as kml_opts;
import 'styling_options.dart';
import 'styling_rule.dart';

/// Compatibility layer to bridge enhanced styling with existing system
class StylingCompatibility {
  /// Create enhanced styling options that work with existing StylingOptions
  static EnhancedStylingOptions createEnhanced({
    required GeometryType geometryType,
    StylingOptions? existingOptions,
  }) {
    final defaultStyle =
        existingOptions?.defaultStyle ??
        StylingOptions.forGeometry(geometryType).defaultStyle;

    if (existingOptions?.useColumnBasedStyling == true) {
      // Convert existing column-based styles to rules
      final rules = <StylingRule>[];
      int priority = 1;

      for (final entry in existingOptions!.columnBasedStyles.entries) {
        final rule = StylingRule(
          id: 'legacy_${DateTime.now().millisecondsSinceEpoch}_$priority',
          columnName: existingOptions.stylingColumn!,
          operator: RuleOperator.equals,
          value: entry.key,
          style: entry.value,
          priority: priority++,
          isEnabled: true,
        );
        rules.add(rule);
      }

      return EnhancedStylingOptions(
        rules: rules,
        defaultStyle: defaultStyle,
        useRuleBasedStyling: true,
        stylingColumn: existingOptions.stylingColumn,
      );
    }

    return EnhancedStylingOptions.forGeometry(
      geometryType,
    ).copyWith(defaultStyle: defaultStyle);
  }

  /// Convert enhanced styling back to legacy format for backward compatibility
  static StylingOptions toLegacy(EnhancedStylingOptions enhanced) {
    final legacyStyles = <String, GeometryStyle>{};

    // Only include equality rules for backward compatibility
    for (final rule in enhanced.rules) {
      if (rule.operator == RuleOperator.equals && rule.isEnabled) {
        legacyStyles[rule.value] = rule.style;
      }
    }

    return StylingOptions(
      defaultStyle: enhanced.defaultStyle,
      useColumnBasedStyling:
          enhanced.useRuleBasedStyling && legacyStyles.isNotEmpty,
      stylingColumn: enhanced.stylingColumn,
      columnBasedStyles: legacyStyles,
    );
  }

  /// Get legacy style rules for KML generation compatibility
  static Map<String, dynamic> toLegacyStyleRules(
    EnhancedStylingOptions enhanced,
  ) {
    final rules = <String, dynamic>{};

    if (enhanced.useRuleBasedStyling && enhanced.stylingColumn != null) {
      for (final rule in enhanced.rules.where((r) => r.isEnabled)) {
        rules['style_${rule.id}'] = {
          'columnName': enhanced.stylingColumn!,
          'columnValue': rule.value,
          'operator': rule.operator.symbol,
          'color': rule.style.color.kmlValue,
          'iconUrl': rule.style.icon?.url ?? KmlIcon.yellowPushpin.url,
          'priority': rule.priority,
        };
      }
    }

    return rules;
  }

  /// Evaluate rules to determine style for a value (for KML generation)
  static GeometryStyle evaluateStyleForValue(
    EnhancedStylingOptions options,
    String? value,
  ) {
    if (!options.useRuleBasedStyling || value == null) {
      return options.defaultStyle;
    }

    // Get matching rules sorted by priority
    final matchingRules =
        options.rules
            .where((rule) => rule.isEnabled && rule.matches(value))
            .toList()
          ..sort((a, b) => b.priority.compareTo(a.priority));

    return matchingRules.isNotEmpty
        ? matchingRules.first.style
        : options.defaultStyle;
  }
}

/// Enhanced styling options that extend the existing StylingOptions
class EnhancedStylingOptionsWrapper extends StylingOptions {
  final EnhancedStylingOptions _enhanced;

  EnhancedStylingOptionsWrapper(this._enhanced)
    : super(
        defaultStyle: _enhanced.defaultStyle,
        useColumnBasedStyling: _enhanced.useRuleBasedStyling,
        stylingColumn: _enhanced.stylingColumn,
        columnBasedStyles: _createLegacyMap(_enhanced),
      );

  static Map<String, GeometryStyle> _createLegacyMap(
    EnhancedStylingOptions enhanced,
  ) {
    final map = <String, GeometryStyle>{};
    for (final rule in enhanced.rules) {
      if (rule.operator == RuleOperator.equals && rule.isEnabled) {
        map[rule.value] = rule.style;
      }
    }
    return map;
  }

  EnhancedStylingOptions get enhanced => _enhanced;

  /// Override getStyleForValue to use enhanced rule evaluation
  @override
  GeometryStyle getStyleForValue(String? value) {
    return StylingCompatibility.evaluateStyleForValue(_enhanced, value);
  }

  /// Override toStyleRules to support enhanced rules
  @override
  Map<String, kml_opts.StyleRule> toStyleRules() {
    // Convert the enhanced styling to legacy StyleRule objects
    final rules = <String, kml_opts.StyleRule>{};

    if (_enhanced.useRuleBasedStyling && _enhanced.stylingColumn != null) {
      for (final rule in _enhanced.rules.where((r) => r.isEnabled)) {
        // Only include equality rules for backward compatibility
        if (rule.operator == RuleOperator.equals) {
          rules['style_${rule.id}'] = kml_opts.StyleRule(
            columnName: _enhanced.stylingColumn!,
            columnValue: rule.value,
            color: rule.style.color.kmlValue,
            iconUrl: rule.style.icon?.url ?? KmlIcon.yellowPushpin.url,
          );
        }
      }
    }

    return rules;
  }
}

/// Quick conversion utilities
extension StylingOptionsEnhanced on StylingOptions {
  /// Convert to enhanced styling options
  EnhancedStylingOptions toEnhanced() {
    return StylingCompatibility.createEnhanced(
      geometryType: _getGeometryTypeFromStyle(),
      existingOptions: this,
    );
  }

  GeometryType _getGeometryTypeFromStyle() {
    // Determine geometry type from style characteristics
    if (defaultStyle.icon != null) return GeometryType.point;
    if (defaultStyle.filled) return GeometryType.polygon;
    return GeometryType.lineString;
  }
}

extension EnhancedStylingOptionsLegacy on EnhancedStylingOptions {
  /// Convert to legacy styling options
  StylingOptions toLegacy() {
    return StylingCompatibility.toLegacy(this);
  }

  /// Create wrapper for backward compatibility
  EnhancedStylingOptionsWrapper toWrapper() {
    return EnhancedStylingOptionsWrapper(this);
  }
}
