import 'dart:io';
import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import '../../core/constants/app_constants.dart';
import '../models/kml_data.dart';
import '../models/export_options.dart';

abstract class ICsvExportService {
  Future<String> exportToCsv(KmlData kmlData, ExportOptions options);
  Future<void> saveCsvFile(String csvContent, String filePath);
  Map<String, List<String>> detectDuplicateHeaders(KmlData kmlData);
  List<String> buildHeadersWithDuplicates(
    KmlData kmlData,
    Map<String, bool> duplicateHandling,
  );
}

class CsvExportService implements ICsvExportService {
  @override
  Future<String> exportToCsv(KmlData kmlData, ExportOptions options) async {
    try {
      final headers = _buildHeaders(kmlData, options);
      final rows = _buildRows(kmlData, headers, options);

      return _formatCsv(headers, rows, options);
    } catch (e) {
      throw ConversionException(
        'Failed to export to CSV: ${e.toString()}',
        code: 'CSV_EXPORT_ERROR',
        details: e,
      );
    }
  }

  @override
  Future<void> saveCsvFile(String csvContent, String filePath) async {
    try {
      final file = File(filePath);
      await file.writeAsString(csvContent);
    } catch (e) {
      throw FileProcessingException(
        'Failed to save CSV file: ${e.toString()}',
        code: 'CSV_SAVE_ERROR',
        details: e,
      );
    }
  }

  @override
  Map<String, List<String>> detectDuplicateHeaders(KmlData kmlData) {
    final headerCounts = <String, int>{};
    final headerSources = <String, List<String>>{};

    // Track all header occurrences and their sources
    for (int i = 0; i < kmlData.placemarks.length; i++) {
      final placemark = kmlData.placemarks[i];

      // From table data
      final tableHeaders = _extractTableHeaders(placemark.description);
      for (final header in tableHeaders) {
        headerCounts[header] = (headerCounts[header] ?? 0) + 1;
        headerSources
            .putIfAbsent(header, () => [])
            .add('Table in placemark ${i + 1}');
      }

      // From extended data
      for (final key in placemark.extendedData.keys) {
        headerCounts[key] = (headerCounts[key] ?? 0) + 1;
        headerSources
            .putIfAbsent(key, () => [])
            .add('Extended data in placemark ${i + 1}');
      }
    }

    // Return only duplicates
    final duplicates = <String, List<String>>{};
    headerCounts.forEach((header, count) {
      if (count > 1) {
        duplicates[header] = headerSources[header] ?? [];
      }
    });

    return duplicates;
  }

  @override
  List<String> buildHeadersWithDuplicates(
    KmlData kmlData,
    Map<String, bool> duplicateHandling,
  ) {
    final allHeadersWithSource = <String>[];
    final seenHeaders = <String, int>{};

    // Base headers
    allHeadersWithSource.addAll([
      'name',
      'description',
      'longitude',
      'latitude',
      'elevation',
    ]);

    // Process each placemark to build headers in order
    for (final placemark in kmlData.placemarks) {
      // From table data
      final tableHeaders = _extractTableHeaders(placemark.description);
      for (final header in tableHeaders) {
        final shouldKeep = duplicateHandling[header] ?? true;
        if (shouldKeep) {
          if (seenHeaders.containsKey(header)) {
            seenHeaders[header] = seenHeaders[header]! + 1;
            allHeadersWithSource.add('${header}_${seenHeaders[header]}');
          } else {
            seenHeaders[header] = 1;
            allHeadersWithSource.add(header);
          }
        }
      }

      // From extended data
      for (final key in placemark.extendedData.keys) {
        final shouldKeep = duplicateHandling[key] ?? true;
        if (shouldKeep && !allHeadersWithSource.contains(key)) {
          if (seenHeaders.containsKey(key)) {
            seenHeaders[key] = seenHeaders[key]! + 1;
            allHeadersWithSource.add('${key}_${seenHeaders[key]}');
          } else {
            seenHeaders[key] = 1;
            allHeadersWithSource.add(key);
          }
        }
      }
    }

    return allHeadersWithSource.toSet().toList(); // Remove final duplicates
  }

  List<String> _buildHeaders(KmlData kmlData, ExportOptions options) {
    if (options.selectedFields.isNotEmpty) {
      return options.fieldOrder.isNotEmpty
          ? options.fieldOrder
          : options.selectedFields;
    }

    // Extract headers from description tables and extended data
    final allHeaders = <String>{
      'name',
      'description',
      'longitude',
      'latitude',
      'elevation',
    };

    // Add headers from description tables
    for (final placemark in kmlData.placemarks) {
      final tableHeaders = _extractTableHeaders(placemark.description);
      allHeaders.addAll(tableHeaders);
    }

    // Add extended data headers
    allHeaders.addAll(kmlData.availableFields);

    // Remove geometry_type from headers
    allHeaders.remove('geometry_type');

    return allHeaders.toList();
  }

  List<List<String>> _buildRows(
    KmlData kmlData,
    List<String> headers,
    ExportOptions options,
  ) {
    final rows = <List<String>>[];

    for (final placemark in kmlData.placemarks) {
      final row = <String>[];
      final tableData = _extractTableData(placemark.description);

      for (final header in headers) {
        String value = '';

        switch (header) {
          case 'name':
            value = placemark.name;
            break;
          case 'description':
            // Use cleaned description without table content
            value = _cleanDescription(placemark.description);
            break;
          case 'longitude':
            value =
                placemark.geometry.firstCoordinate?.longitude.toString() ?? '';
            break;
          case 'latitude':
            value =
                placemark.geometry.firstCoordinate?.latitude.toString() ?? '';
            break;
          case 'elevation':
            value =
                placemark.geometry.firstCoordinate?.elevation.toString() ?? '';
            break;
          default:
            // Check table data first, then extended data
            if (tableData.containsKey(header)) {
              value = tableData[header] ?? '';
            } else {
              value = placemark.extendedData[header]?.toString() ?? '';
            }
        }

        row.add(value);
      }

      rows.add(row);
    }

    return rows;
  }

  Map<String, String> _extractTableData(String description) {
    final tableData = <String, String>{};

    if (!description.contains('<table') && !description.contains('<tr')) {
      return tableData;
    }

    try {
      // Simple HTML table parsing - look for table row patterns
      final rows = description.split('<tr');

      for (final row in rows) {
        if (!row.contains('<td') && !row.contains('<th')) continue;

        final cells = _extractTableCells(row);
        if (cells.length >= 2) {
          // Assume first cell is header/key, second is value
          final key = cells[0].trim();
          final value = cells[1].trim();
          if (key.isNotEmpty) {
            tableData[key] = value;
          }
        }
      }
    } catch (e) {
      // If parsing fails, return empty map
      if (kDebugMode) {
        print('Warning: Failed to parse table in description: $e');
      }
    }

    return tableData;
  }

  List<String> _extractTableHeaders(String description) {
    final headers = <String>[];
    final tableData = _extractTableData(description);
    headers.addAll(tableData.keys);
    return headers;
  }

  List<String> _extractTableCells(String row) {
    final cells = <String>[];

    // Extract content between <td> or <th> tags
    final cellRegex = RegExp(
      r'<t[dh][^>]*>(.*?)</t[dh]>',
      caseSensitive: false,
      dotAll: true,
    );
    final matches = cellRegex.allMatches(row);

    for (final match in matches) {
      final cellContent = match.group(1) ?? '';
      final cleanContent = _stripHtmlTags(cellContent).trim();
      cells.add(cleanContent);
    }

    return cells;
  }

  String _stripHtmlTags(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll('&nbsp;', ' ') // Replace non-breaking spaces
        .replaceAll('&amp;', '&') // Replace HTML entities
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }

  String _cleanDescription(String description) {
    // Remove table content from description to avoid duplication
    return description
        .replaceAll(
          RegExp(
            r'<table[^>]*>.*?</table>',
            caseSensitive: false,
            dotAll: true,
          ),
          '',
        )
        .trim();
  }

  String _formatCsv(
    List<String> headers,
    List<List<String>> rows,
    ExportOptions options,
  ) {
    final delimiter =
        options.customDelimiter ?? AppConstants.defaultCsvDelimiter;
    final lines = <String>[];

    // Add headers if requested
    if (options.includeHeaders) {
      lines.add(_formatCsvRow(headers, delimiter));
    }

    // Add data rows
    for (final row in rows) {
      lines.add(_formatCsvRow(row, delimiter));
    }

    return lines.join('\n');
  }

  String _formatCsvRow(List<String> row, String delimiter) {
    return row.map((cell) => _escapeCsvCell(cell, delimiter)).join(delimiter);
  }

  String _escapeCsvCell(String cell, String delimiter) {
    // Escape quotes and wrap in quotes if contains delimiter, quote, or newline
    if (cell.contains(delimiter) || cell.contains('"') || cell.contains('\n')) {
      return '"${cell.replaceAll('"', '""')}"';
    }
    return cell;
  }
}
