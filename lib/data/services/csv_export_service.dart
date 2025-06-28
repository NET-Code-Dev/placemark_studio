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
    final duplicates = <String, List<String>>{};

    for (int i = 0; i < kmlData.placemarks.length; i++) {
      final placemark = kmlData.placemarks[i];
      final placemarkName =
          placemark.name.isNotEmpty ? placemark.name : 'Placemark ${i + 1}';

      // Extract all headers from this placemark's description table
      final tableHeaders = _extractAllTableHeaders(placemark.description);

      // Find duplicates within this single table
      final headerCounts = <String, int>{};
      for (final header in tableHeaders) {
        headerCounts[header] = (headerCounts[header] ?? 0) + 1;
      }

      // Add headers that appear more than once in this table
      headerCounts.forEach((header, count) {
        if (count > 1) {
          duplicates.putIfAbsent(header, () => []).add(placemarkName);
        }
      });
    }

    return duplicates;
  }

  @override
  List<String> buildHeadersWithDuplicates(
    KmlData kmlData,
    Map<String, bool> duplicateHandling,
  ) {
    final allHeaders = <String>{
      'name',
      'description',
      'longitude',
      'latitude',
      'elevation',
    };

    // Process each placemark to build headers, handling duplicates
    for (final placemark in kmlData.placemarks) {
      final tableHeaders = _extractAllTableHeaders(placemark.description);
      final processedHeaders = _processDuplicateHeaders(
        tableHeaders,
        duplicateHandling,
      );
      allHeaders.addAll(processedHeaders);

      // Add extended data headers
      for (final key in placemark.extendedData.keys) {
        final shouldKeep = duplicateHandling[key] ?? true;
        if (shouldKeep) {
          allHeaders.add(key);
        }
      }
    }

    return allHeaders.toList();
  }

  /// Extract ALL headers from a description table, including duplicates
  List<String> _extractAllTableHeaders(String description) {
    final headers = <String>[];

    if (!description.contains('<table') && !description.contains('<tr')) {
      return headers;
    }

    try {
      // Parse the HTML content to find tables
      final tables = _extractTablesFromHtml(description);

      for (final tableRows in tables) {
        for (final row in tableRows) {
          if (row.length >= 2) {
            // First cell is the header/key
            final key = row[0].trim();
            if (key.isNotEmpty &&
                !key.toLowerCase().contains('field') &&
                !key.toLowerCase().contains('value')) {
              headers.add(key);
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Warning: Failed to parse table headers in description: $e');
      }
    }

    return headers;
  }

  /// Extract all tables from HTML content, handling nested tables
  List<List<List<String>>> _extractTablesFromHtml(String html) {
    final tables = <List<List<String>>>[];

    try {
      // Find all table elements
      final tableRegex = RegExp(
        r'<table[^>]*>(.*?)</table>',
        caseSensitive: false,
        dotAll: true,
      );

      final tableMatches = tableRegex.allMatches(html);

      for (final tableMatch in tableMatches) {
        final tableContent = tableMatch.group(1) ?? '';
        final rows = _extractRowsFromTable(tableContent);

        if (rows.isNotEmpty) {
          tables.add(rows);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Warning: Failed to extract tables from HTML: $e');
      }
    }

    return tables;
  }

  /// Extract rows from a table, handling bgcolor and other attributes
  List<List<String>> _extractRowsFromTable(String tableContent) {
    final rows = <List<String>>[];

    try {
      // Find all tr elements, including those with attributes like bgcolor
      final rowRegex = RegExp(
        r'<tr[^>]*>(.*?)</tr>',
        caseSensitive: false,
        dotAll: true,
      );

      final rowMatches = rowRegex.allMatches(tableContent);

      for (final rowMatch in rowMatches) {
        final rowContent = rowMatch.group(1) ?? '';
        final cells = _extractCellsFromRow(rowContent);

        // Only add rows that have exactly 2 cells (key-value pairs)
        if (cells.length == 2 && cells[0].trim().isNotEmpty) {
          rows.add(cells);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Warning: Failed to extract rows from table: $e');
      }
    }

    return rows;
  }

  /// Extract cells from a table row
  List<String> _extractCellsFromRow(String rowContent) {
    final cells = <String>[];

    try {
      // Find all td elements, handling nested content
      final cellRegex = RegExp(
        r'<td[^>]*>(.*?)</td>',
        caseSensitive: false,
        dotAll: true,
      );

      final cellMatches = cellRegex.allMatches(rowContent);

      for (final cellMatch in cellMatches) {
        final cellContent = cellMatch.group(1) ?? '';
        final cleanContent = _stripHtmlTags(cellContent).trim();
        cells.add(cleanContent);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Warning: Failed to extract cells from row: $e');
      }
    }

    return cells;
  }

  /// Process duplicate headers within a single table
  List<String> _processDuplicateHeaders(
    List<String> tableHeaders,
    Map<String, bool> duplicateHandling,
  ) {
    final processedHeaders = <String>[];
    final headerCounts = <String, int>{};

    for (final header in tableHeaders) {
      final shouldKeep = duplicateHandling[header] ?? true;

      if (shouldKeep) {
        if (headerCounts.containsKey(header)) {
          // This is a duplicate - add with suffix
          headerCounts[header] = headerCounts[header]! + 1;
          processedHeaders.add('${header}_${headerCounts[header]}');
        } else {
          // First occurrence
          headerCounts[header] = 1;
          processedHeaders.add(header);
        }
      }
    }

    return processedHeaders;
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

    // Add headers from description tables (unique set)
    for (final placemark in kmlData.placemarks) {
      final tableHeaders = _extractUniqueTableHeaders(placemark.description);
      allHeaders.addAll(tableHeaders);
    }

    // Add extended data headers
    allHeaders.addAll(kmlData.availableFields);

    // Remove geometry_type from headers
    allHeaders.remove('geometry_type');

    return allHeaders.toList();
  }

  /// Extract unique headers from a description table (for building the header set)
  List<String> _extractUniqueTableHeaders(String description) {
    final allHeaders = _extractAllTableHeaders(description);
    return allHeaders.toSet().toList(); // Remove duplicates for header building
  }

  List<List<String>> _buildRows(
    KmlData kmlData,
    List<String> headers,
    ExportOptions options,
  ) {
    final rows = <List<String>>[];

    for (final placemark in kmlData.placemarks) {
      final row = <String>[];
      final tableData = _extractTableDataWithDuplicates(placemark.description);

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

  /// Extract table data handling duplicate headers with suffixes
  Map<String, String> _extractTableDataWithDuplicates(String description) {
    final tableData = <String, String>{};

    if (!description.contains('<table') && !description.contains('<tr')) {
      return tableData;
    }

    try {
      // Use the improved table parsing logic
      final tables = _extractTablesFromHtml(description);
      final headerCounts = <String, int>{};

      for (final tableRows in tables) {
        for (final row in tableRows) {
          if (row.length >= 2) {
            final originalKey = row[0].trim();
            final value = row[1].trim();

            if (originalKey.isNotEmpty) {
              String key;
              if (headerCounts.containsKey(originalKey)) {
                // This is a duplicate - add with suffix
                headerCounts[originalKey] = headerCounts[originalKey]! + 1;
                key = '${originalKey}_${headerCounts[originalKey]}';
              } else {
                // First occurrence
                headerCounts[originalKey] = 1;
                key = originalKey;
              }

              tableData[key] = value;
            }
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

  /*
  Map<String, String> _extractTableData(String description) {
    // Use the new method that handles duplicates
    return _extractTableDataWithDuplicates(description);
  }

  List<String> _extractTableHeaders(String description) {
    return _extractUniqueTableHeaders(description);
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
*/
  String _stripHtmlTags(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll('&nbsp;', ' ') // Replace non-breaking spaces
        .replaceAll('&amp;', '&') // Replace HTML entities
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        // FIXED: Normalize line breaks to single spaces for CSV compatibility
        .replaceAll(RegExp(r'\r?\n'), ' ') // Replace newlines with spaces
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        ) // Collapse multiple spaces to single space
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
    // FIXED: Enhanced CSV cell escaping for better multi-line content handling
    String cleanedCell = cell;

    // Normalize whitespace and line breaks for CSV
    cleanedCell =
        cleanedCell
            .replaceAll(RegExp(r'\r?\n'), ' ') // Convert newlines to spaces
            .replaceAll(RegExp(r'\s+'), ' ') // Collapse multiple spaces
            .trim();

    // Escape quotes and wrap in quotes if contains delimiter, quote, or newline
    if (cleanedCell.contains(delimiter) ||
        cleanedCell.contains('"') ||
        cleanedCell.contains('\n') ||
        cleanedCell.contains('\r')) {
      return '"${cleanedCell.replaceAll('"', '""')}"';
    }

    return cleanedCell;
  }
}
