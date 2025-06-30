import 'package:flutter/material.dart';

import '../../core/enums/geometry_type.dart';
import 'kml_generation_options.dart' as kml_opts;

/// Predefined icon options for KML placemarks
enum KmlIcon {
  yellowPushpin(
    'Yellow Pushpin',
    'http://maps.google.com/mapfiles/kml/pushpin/ylw-pushpin.png',
  ),
  redPushpin(
    'Red Pushpin',
    'http://maps.google.com/mapfiles/kml/pushpin/red-pushpin.png',
  ),
  bluePushpin(
    'Blue Pushpin',
    'http://maps.google.com/mapfiles/kml/pushpin/blue-pushpin.png',
  ),
  greenPushpin(
    'Green Pushpin',
    'http://maps.google.com/mapfiles/kml/pushpin/grn-pushpin.png',
  ),
  pinkPushpin(
    'Pink Pushpin',
    'http://maps.google.com/mapfiles/kml/pushpin/pink-pushpin.png',
  ),
  purplePushpin(
    'Purple Pushpin',
    'http://maps.google.com/mapfiles/kml/pushpin/purple-pushpin.png',
  ),
  orangePushpin(
    'Orange Pushpin',
    'http://maps.google.com/mapfiles/kml/pushpin/orange-pushpin.png',
  ),
  whitePushpin(
    'White Pushpin',
    'http://maps.google.com/mapfiles/kml/pushpin/wht-pushpin.png',
  ),

  // Shapes
  yellowCircle(
    'Yellow Circle',
    'http://maps.google.com/mapfiles/kml/shapes/donut.png',
  ),
  redCircle(
    'Red Circle',
    'http://maps.google.com/mapfiles/kml/shapes/target.png',
  ),
  blueSquare(
    'Blue Square',
    'http://maps.google.com/mapfiles/kml/shapes/square.png',
  ),
  greenStar(
    'Green Star',
    'http://maps.google.com/mapfiles/kml/shapes/star.png',
  ),

  // Transportation
  car('Car', 'http://maps.google.com/mapfiles/kml/shapes/cabs.png'),
  plane('Airplane', 'http://maps.google.com/mapfiles/kml/shapes/airports.png'),
  boat('Boat', 'http://maps.google.com/mapfiles/kml/shapes/marina.png'),
  train('Train', 'http://maps.google.com/mapfiles/kml/shapes/rail.png'),

  // Places
  home('Home', 'http://maps.google.com/mapfiles/kml/pal4/icon49.png'),
  office('Office', 'http://maps.google.com/mapfiles/kml/pal4/icon26.png'),
  school('School', 'http://maps.google.com/mapfiles/kml/pal4/icon12.png'),
  hospital('Hospital', 'http://maps.google.com/mapfiles/kml/pal4/icon20.png'),
  restaurant(
    'Restaurant',
    'http://maps.google.com/mapfiles/kml/pal4/icon23.png',
  ),
  hotel('Hotel', 'http://maps.google.com/mapfiles/kml/pal4/icon24.png');

  const KmlIcon(this.displayName, this.url);

  final String displayName;
  final String url;
}

/// Color palette for KML styling
class KmlColor {
  final String name;
  final Color color;
  final String kmlValue; // AABBGGRR format for KML

  const KmlColor(this.name, this.color, this.kmlValue);

  static const List<KmlColor> predefinedColors = [
    KmlColor('Red', Color(0xFFFF0000), 'ff0000ff'),
    KmlColor('Green', Color(0xFF00FF00), 'ff00ff00'),
    KmlColor('Blue', Color(0xFF0000FF), 'ffff0000'),
    KmlColor('Yellow', Color(0xFFFFFF00), 'ff00ffff'),
    KmlColor('Orange', Color(0xFFFF8000), 'ff0080ff'),
    KmlColor('Purple', Color(0xFF8000FF), 'ffff0080'),
    KmlColor('Pink', Color(0xFFFF00FF), 'ffff00ff'),
    KmlColor('Cyan', Color(0xFF00FFFF), 'ffffff00'),
    KmlColor('White', Color(0xFFFFFFFF), 'ffffffff'),
    KmlColor('Black', Color(0xFF000000), 'ff000000'),
    KmlColor('Gray', Color(0xFF808080), 'ff808080'),
    KmlColor('Light Gray', Color(0xFFC0C0C0), 'ffc0c0c0'),
    KmlColor('Dark Gray', Color(0xFF404040), 'ff404040'),
    KmlColor('Brown', Color(0xFF8B4513), 'ff13458b'),
    KmlColor('Lime', Color(0xFF32CD32), 'ff32cd32'),
    KmlColor('Navy', Color(0xFF000080), 'ff800000'),
  ];

  /// Convert Flutter Color to KML color format (AABBGGRR)
  static String colorToKml(Color color) {
    final alpha = color.alpha.toRadixString(16).padLeft(2, '0');
    final blue = color.blue.toRadixString(16).padLeft(2, '0');
    final green = color.green.toRadixString(16).padLeft(2, '0');
    final red = color.red.toRadixString(16).padLeft(2, '0');
    return '$alpha$blue$green$red';
  }

  /// Convert KML color format to Flutter Color
  static Color kmlToColor(String kmlColor) {
    if (kmlColor.length != 8) return Colors.red;

    final alpha = int.parse(kmlColor.substring(0, 2), radix: 16);
    final blue = int.parse(kmlColor.substring(2, 4), radix: 16);
    final green = int.parse(kmlColor.substring(4, 6), radix: 16);
    final red = int.parse(kmlColor.substring(6, 8), radix: 16);

    return Color.fromARGB(alpha, red, green, blue);
  }
}

/// Style configuration for different geometry types
class GeometryStyle {
  final KmlColor color;
  final KmlIcon? icon; // Only for points
  final double lineWidth; // For lines and polygon borders
  final double opacity; // 0.0 to 1.0
  final bool filled; // For polygons
  final bool outlined; // For polygons

  const GeometryStyle({
    required this.color,
    this.icon,
    this.lineWidth = 2.0,
    this.opacity = 1.0,
    this.filled = true,
    this.outlined = true,
  });

  /// Create style for point geometry
  factory GeometryStyle.point({
    KmlColor color = const KmlColor('Red', Color(0xFFFF0000), 'ff0000ff'),
    KmlIcon icon = KmlIcon.yellowPushpin,
  }) {
    return GeometryStyle(color: color, icon: icon);
  }

  /// Create style for line geometry
  factory GeometryStyle.line({
    KmlColor color = const KmlColor('Blue', Color(0xFF0000FF), 'ffff0000'),
    double lineWidth = 3.0,
    double opacity = 1.0,
  }) {
    return GeometryStyle(color: color, lineWidth: lineWidth, opacity: opacity);
  }

  /// Create style for polygon geometry
  factory GeometryStyle.polygon({
    KmlColor color = const KmlColor('Green', Color(0xFF00FF00), 'ff00ff00'),
    double lineWidth = 2.0,
    double opacity = 0.5,
    bool filled = true,
    bool outlined = true,
  }) {
    return GeometryStyle(
      color: color,
      lineWidth: lineWidth,
      opacity: opacity,
      filled: filled,
      outlined: outlined,
    );
  }

  GeometryStyle copyWith({
    KmlColor? color,
    KmlIcon? icon,
    double? lineWidth,
    double? opacity,
    bool? filled,
    bool? outlined,
  }) {
    return GeometryStyle(
      color: color ?? this.color,
      icon: icon ?? this.icon,
      lineWidth: lineWidth ?? this.lineWidth,
      opacity: opacity ?? this.opacity,
      filled: filled ?? this.filled,
      outlined: outlined ?? this.outlined,
    );
  }
}

/// Enhanced styling options for KML generation
class StylingOptions {
  final Map<String, GeometryStyle> columnBasedStyles;
  final GeometryStyle defaultStyle;
  final bool useColumnBasedStyling;
  final String? stylingColumn;

  const StylingOptions({
    this.columnBasedStyles = const {},
    required this.defaultStyle,
    this.useColumnBasedStyling = false,
    this.stylingColumn,
  });

  /// Factory for default styling based on geometry type
  factory StylingOptions.forGeometry(GeometryType geometryType) {
    switch (geometryType) {
      case GeometryType.point:
        return StylingOptions(defaultStyle: GeometryStyle.point());
      case GeometryType.lineString:
        return StylingOptions(defaultStyle: GeometryStyle.line());
      case GeometryType.polygon:
        return StylingOptions(defaultStyle: GeometryStyle.polygon());
      default:
        return StylingOptions(defaultStyle: GeometryStyle.point());
    }
  }

  /// Get style for a specific column value
  GeometryStyle getStyleForValue(String? value) {
    if (!useColumnBasedStyling || value == null) {
      return defaultStyle;
    }

    return columnBasedStyles[value] ?? defaultStyle;
  }

  /// Get all unique values that have custom styles
  List<String> get styledValues => columnBasedStyles.keys.toList();

  StylingOptions copyWith({
    Map<String, GeometryStyle>? columnBasedStyles,
    GeometryStyle? defaultStyle,
    bool? useColumnBasedStyling,
    String? stylingColumn,
  }) {
    return StylingOptions(
      columnBasedStyles: columnBasedStyles ?? this.columnBasedStyles,
      defaultStyle: defaultStyle ?? this.defaultStyle,
      useColumnBasedStyling:
          useColumnBasedStyling ?? this.useColumnBasedStyling,
      stylingColumn: stylingColumn ?? this.stylingColumn,
    );
  }

  /// Convert to StyleRule map for KmlGenerationOptions
  Map<String, kml_opts.StyleRule> toStyleRules() {
    final rules = <String, kml_opts.StyleRule>{};

    if (useColumnBasedStyling && stylingColumn != null) {
      for (final entry in columnBasedStyles.entries) {
        final value = entry.key;
        final style = entry.value;

        // Create StyleRule using the correct class from kml_generation_options.dart
        rules['style_$value'] = kml_opts.StyleRule(
          columnName: stylingColumn!,
          columnValue: value,
          color: style.color.kmlValue,
          iconUrl: style.icon?.url ?? KmlIcon.yellowPushpin.url,
        );
      }
    }

    return rules;
  }

  @override
  String toString() {
    return 'StylingOptions(columnBased: $useColumnBasedStyling, column: $stylingColumn, styles: ${columnBasedStyles.length})';
  }
}
