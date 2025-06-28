import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class ColumnMapping extends Equatable {
  final String? latitudeColumn;
  final String? longitudeColumn;
  final String? nameColumn;
  final String? descriptionColumn;
  final String? elevationColumn;
  final String? imageColumn;
  final Map<String, String> customColumns;

  const ColumnMapping({
    this.latitudeColumn,
    this.longitudeColumn,
    this.nameColumn,
    this.descriptionColumn,
    this.elevationColumn,
    this.imageColumn,
    this.customColumns = const {},
  });

  factory ColumnMapping.empty() {
    return const ColumnMapping();
  }

  /// Check if mapping has required fields for basic KML generation
  bool get isValid {
    return latitudeColumn != null &&
        longitudeColumn != null &&
        nameColumn != null;
  }

  /// Check if mapping has all coordinate fields
  bool get hasCoordinates {
    return latitudeColumn != null && longitudeColumn != null;
  }

  /// Check if mapping has optional fields
  bool get hasElevation => elevationColumn != null;
  bool get hasDescription => descriptionColumn != null;
  bool get hasImages => imageColumn != null;
  bool get hasCustomColumns => customColumns.isNotEmpty;

  /// Get all mapped columns
  List<String> get allMappedColumns {
    final columns = <String>[];

    if (latitudeColumn != null) columns.add(latitudeColumn!);
    if (longitudeColumn != null) columns.add(longitudeColumn!);
    if (nameColumn != null) columns.add(nameColumn!);
    if (descriptionColumn != null) columns.add(descriptionColumn!);
    if (elevationColumn != null) columns.add(elevationColumn!);
    if (imageColumn != null) columns.add(imageColumn!);

    columns.addAll(customColumns.values);

    return columns;
  }

  /// Get required field mappings
  Map<String, String?> get requiredMappings {
    return {
      'Latitude': latitudeColumn,
      'Longitude': longitudeColumn,
      'Name': nameColumn,
    };
  }

  /// Get optional field mappings
  Map<String, String?> get optionalMappings {
    return {
      'Description': descriptionColumn,
      'Elevation': elevationColumn,
      'Image': imageColumn,
    };
  }

  /// Validate that no column is mapped to multiple fields
  List<String> validateUniqueness() {
    final errors = <String>[];
    final usedColumns = <String>[];

    void checkColumn(String? column, String fieldName) {
      if (column != null) {
        if (usedColumns.contains(column)) {
          errors.add('Column "$column" is mapped to multiple fields');
        } else {
          usedColumns.add(column);
        }
      }
    }

    checkColumn(latitudeColumn, 'Latitude');
    checkColumn(longitudeColumn, 'Longitude');
    checkColumn(nameColumn, 'Name');
    checkColumn(descriptionColumn, 'Description');
    checkColumn(elevationColumn, 'Elevation');
    checkColumn(imageColumn, 'Image');

    for (final customColumn in customColumns.values) {
      checkColumn(customColumn, 'Custom');
    }

    return errors;
  }

  /// Get mapping status for UI display
  MappingStatus get status {
    final validationErrors = validateUniqueness();

    if (validationErrors.isNotEmpty) {
      return MappingStatus.error;
    }

    if (!hasCoordinates) {
      return MappingStatus.incomplete;
    }

    if (!isValid) {
      return MappingStatus.partial;
    }

    return MappingStatus.complete;
  }

  /// Get human-readable status message
  String get statusMessage {
    switch (status) {
      case MappingStatus.incomplete:
        return 'Please map latitude and longitude columns';
      case MappingStatus.partial:
        return 'Please map a name column';
      case MappingStatus.error:
        final errors = validateUniqueness();
        return errors.first;
      case MappingStatus.complete:
        return 'Column mapping is complete';
    }
  }

  /// Create a copy with updated mappings
  ColumnMapping copyWith({
    String? latitudeColumn,
    String? longitudeColumn,
    String? nameColumn,
    String? descriptionColumn,
    String? elevationColumn,
    String? imageColumn,
    Map<String, String>? customColumns,
  }) {
    return ColumnMapping(
      latitudeColumn: latitudeColumn ?? this.latitudeColumn,
      longitudeColumn: longitudeColumn ?? this.longitudeColumn,
      nameColumn: nameColumn ?? this.nameColumn,
      descriptionColumn: descriptionColumn ?? this.descriptionColumn,
      elevationColumn: elevationColumn ?? this.elevationColumn,
      imageColumn: imageColumn ?? this.imageColumn,
      customColumns: customColumns ?? this.customColumns,
    );
  }

  /// Remove a specific column mapping
  ColumnMapping removeMapping(String fieldType) {
    switch (fieldType.toLowerCase()) {
      case 'latitude':
        return copyWith(latitudeColumn: null);
      case 'longitude':
        return copyWith(longitudeColumn: null);
      case 'name':
        return copyWith(nameColumn: null);
      case 'description':
        return copyWith(descriptionColumn: null);
      case 'elevation':
        return copyWith(elevationColumn: null);
      case 'image':
        return copyWith(imageColumn: null);
      default:
        final newCustomColumns = Map<String, String>.from(customColumns);
        newCustomColumns.remove(fieldType);
        return copyWith(customColumns: newCustomColumns);
    }
  }

  /// Add or update a custom column mapping
  ColumnMapping addCustomMapping(String fieldName, String columnName) {
    final newCustomColumns = Map<String, String>.from(customColumns);
    newCustomColumns[fieldName] = columnName;
    return copyWith(customColumns: newCustomColumns);
  }

  @override
  List<Object?> get props => [
    latitudeColumn,
    longitudeColumn,
    nameColumn,
    descriptionColumn,
    elevationColumn,
    imageColumn,
    customColumns,
  ];

  @override
  String toString() {
    return 'ColumnMapping('
        'lat: $latitudeColumn, '
        'lon: $longitudeColumn, '
        'name: $nameColumn, '
        'desc: $descriptionColumn, '
        'elev: $elevationColumn, '
        'image: $imageColumn, '
        'custom: $customColumns)';
  }
}

enum MappingStatus { incomplete, partial, complete, error }

extension MappingStatusExtension on MappingStatus {
  Color get color {
    switch (this) {
      case MappingStatus.incomplete:
        return Colors.red;
      case MappingStatus.partial:
        return Colors.orange;
      case MappingStatus.complete:
        return Colors.green;
      case MappingStatus.error:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case MappingStatus.incomplete:
        return Icons.error;
      case MappingStatus.partial:
        return Icons.warning;
      case MappingStatus.complete:
        return Icons.check_circle;
      case MappingStatus.error:
        return Icons.error;
    }
  }
}
