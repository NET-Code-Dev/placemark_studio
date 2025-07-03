import 'dart:io';
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import '../../core/errors/app_exception.dart';
import '../models/csv_data.dart';

abstract class ICsvParserService {
  Future<File?> pickCsvFile();
  Future<CsvData> parseCsvFile(File file);
  Future<CsvData> parseCsvContent(String content, String fileName);
}

class CsvParserService implements ICsvParserService {
  static const int maxFileSize = 50 * 1024 * 1024; // 50MB
  static const int maxRows = 100000; // Reasonable limit for performance

  @override
  Future<File?> pickCsvFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result?.files.single.path != null) {
        final file = File(result!.files.single.path!);
        await _validateFile(file);
        return file;
      }
      return null;
    } catch (e) {
      throw FileProcessingException(
        'Failed to pick CSV file: ${e.toString()}',
        code: 'CSV_PICKER_ERROR',
        details: e,
      );
    }
  }

  @override
  Future<CsvData> parseCsvFile(File file) async {
    try {
      await _validateFile(file);

      final content = await file.readAsString();
      final fileName = file.path.split('/').last;

      return await parseCsvContent(content, fileName);
    } catch (e) {
      if (e is AppException) rethrow;

      throw FileProcessingException(
        'Failed to parse CSV file: ${e.toString()}',
        code: 'CSV_PARSE_ERROR',
        details: e,
      );
    }
  }

  @override
  Future<CsvData> parseCsvContent(String content, String fileName) async {
    try {
      if (content.trim().isEmpty) {
        throw FileProcessingException(
          'CSV file is empty',
          code: 'EMPTY_CSV_FILE',
        );
      }

      // Try different delimiter options
      final detectedDelimiter = _detectDelimiter(content);

      if (kDebugMode) {
        print('Detected CSV delimiter: "$detectedDelimiter"');
      }

      // Parse CSV content
      final csvConverter = CsvToListConverter(
        fieldDelimiter: detectedDelimiter,
        textDelimiter: '"',
        eol: '\n',
        shouldParseNumbers: false, // Keep everything as strings initially
      );

      final List<List<dynamic>> csvData = csvConverter.convert(content);

      if (csvData.isEmpty) {
        throw FileProcessingException(
          'No data found in CSV file',
          code: 'NO_CSV_DATA',
        );
      }

      // Extract headers from first row
      final rawHeaders = csvData.first.map((e) => e.toString().trim()).toList();

      if (rawHeaders.isEmpty) {
        throw FileProcessingException(
          'No headers found in CSV file',
          code: 'NO_CSV_HEADERS',
        );
      }

      // FIXED: Clean headers and handle duplicates instead of throwing error
      final headers = _cleanHeaders(rawHeaders);

      if (kDebugMode) {
        // Show what headers were cleaned
        final changedHeaders = <String>[];
        for (int i = 0; i < rawHeaders.length && i < headers.length; i++) {
          if (rawHeaders[i] != headers[i]) {
            changedHeaders.add('${rawHeaders[i]} → ${headers[i]}');
          }
        }

        if (changedHeaders.isNotEmpty) {
          print('Header cleaning applied:');
          for (final change in changedHeaders) {
            print('  $change');
          }
        }
      }

      // Process data rows
      final dataRows = csvData.skip(1).toList();

      if (dataRows.length > maxRows) {
        throw FileProcessingException(
          'CSV file contains too many rows. Maximum allowed: $maxRows',
          code: 'TOO_MANY_ROWS',
        );
      }

      // Convert rows to maps using cleaned headers
      final rows = <Map<String, dynamic>>[];

      for (int i = 0; i < dataRows.length; i++) {
        final row = dataRows[i];
        final rowMap = <String, dynamic>{};

        // Ensure row has the correct number of columns
        for (int j = 0; j < headers.length; j++) {
          final value = j < row.length ? row[j] : '';
          rowMap[headers[j]] = _processValue(value);
        }

        rows.add(rowMap);
      }

      if (kDebugMode) {
        print('CSV parsed successfully:');
        print('  File: $fileName');
        print(
          '  Headers: ${headers.length} (${headers.take(5).join(', ')}${headers.length > 5 ? '...' : ''})',
        );
        print('  Rows: ${rows.length}');
      }

      return CsvData(fileName: fileName, headers: headers, rows: rows);
    } catch (e) {
      if (e is AppException) rethrow;

      throw FileProcessingException(
        'Failed to parse CSV content: ${e.toString()}',
        code: 'CSV_CONTENT_PARSE_ERROR',
        details: e,
      );
    }
  }

  /// Validate CSV file before processing
  Future<void> _validateFile(File file) async {
    // Check if file exists
    if (!await file.exists()) {
      throw FileProcessingException(
        'CSV file does not exist',
        code: 'FILE_NOT_FOUND',
      );
    }

    // Check file size
    final stat = await file.stat();
    if (stat.size > maxFileSize) {
      throw FileProcessingException(
        'CSV file is too large. Maximum size: ${maxFileSize / (1024 * 1024)}MB',
        code: 'FILE_TOO_LARGE',
      );
    }

    if (stat.size == 0) {
      throw FileProcessingException('CSV file is empty', code: 'EMPTY_FILE');
    }

    // Check file extension
    if (!file.path.toLowerCase().endsWith('.csv')) {
      throw FileProcessingException(
        'File must have .csv extension',
        code: 'INVALID_EXTENSION',
      );
    }
  }

  /// Detect the most likely delimiter used in the CSV
  String _detectDelimiter(String content) {
    // Take first few lines for analysis
    final lines = content.split('\n').take(5).toList();
    final sampleContent = lines.join('\n');

    // Test common delimiters - COMMA FIRST (preferred)
    final delimiters = [',', ';', '\t', '|'];
    final scores = <String, Map<String, dynamic>>{};

    if (kDebugMode) {
      print('=== CSV DELIMITER DETECTION ===');
      print(
        'Sample content (first 200 chars): ${sampleContent.substring(0, math.min(200, sampleContent.length))}',
      );
    }

    for (final delimiter in delimiters) {
      try {
        final converter = CsvToListConverter(
          fieldDelimiter: delimiter,
          textDelimiter: '"',
          shouldParseNumbers: false,
          allowInvalid: true,
        );

        final parsed = converter.convert(sampleContent);

        if (parsed.isNotEmpty) {
          final columnCounts = parsed.map((row) => row.length).toList();
          final firstRowCount = columnCounts.first;

          // Count how many rows have the same column count as the first row
          final consistentRows =
              columnCounts.where((count) => count == firstRowCount).length;
          final consistencyScore =
              (consistentRows * 100) ~/ columnCounts.length;

          // IMPROVED SCORING: Heavily favor reasonable column counts (2-100)
          int columnScore = 0;
          if (firstRowCount >= 2 && firstRowCount <= 100) {
            columnScore = firstRowCount; // Direct scoring based on column count
          } else if (firstRowCount > 100) {
            // Penalize excessive columns (likely parsing error)
            columnScore = math.max(0, 100 - (firstRowCount - 100));
          }

          // COMMA BONUS: Give comma delimiter a bonus since it's most common
          int delimiterBonus = 0;
          if (delimiter == ',') {
            delimiterBonus = 50; // Significant bonus for comma
          } else if (delimiter == ';') {
            delimiterBonus = 20; // Smaller bonus for semicolon
          }

          final totalScore = consistencyScore + columnScore + delimiterBonus;

          scores[delimiter] = {
            'columns': firstRowCount,
            'consistency': consistencyScore,
            'columnScore': columnScore,
            'delimiterBonus': delimiterBonus,
            'totalScore': totalScore,
          };

          if (kDebugMode) {
            final delimiterName = delimiter == '\t' ? 'TAB' : delimiter;
            print(
              'Delimiter "$delimiterName": $firstRowCount columns, consistency: $consistencyScore%, columnScore: $columnScore, bonus: $delimiterBonus, total: $totalScore',
            );
          }
        }
      } catch (e) {
        scores[delimiter] = {
          'columns': 0,
          'totalScore': 0,
          'error': e.toString(),
        };
        if (kDebugMode) {
          final delimiterName = delimiter == '\t' ? 'TAB' : delimiter;
          print('Delimiter "$delimiterName" failed: $e');
        }
      }
    }

    // Return delimiter with highest score, defaulting to comma
    if (scores.isEmpty ||
        scores.values.every((score) => score['totalScore'] == 0)) {
      if (kDebugMode) {
        print('No valid delimiter found, defaulting to comma');
      }
      return ',';
    }

    // Find delimiter with highest total score
    String bestDelimiter = ',';
    int bestScore = 0;

    scores.forEach((delimiter, scoreData) {
      final totalScore = scoreData['totalScore'] as int;
      if (totalScore > bestScore) {
        bestScore = totalScore;
        bestDelimiter = delimiter;
      }
    });

    if (kDebugMode) {
      final delimiterName = bestDelimiter == '\t' ? 'TAB' : bestDelimiter;
      final scoreData = scores[bestDelimiter]!;
      print(
        'Selected delimiter: "$delimiterName" with score: $bestScore (${scoreData['columns']} columns)',
      );
    }

    return bestDelimiter;
  }

  /// Process individual cell values
  dynamic _processValue(dynamic value) {
    if (value == null) return '';

    final stringValue = value.toString().trim();

    // Return empty string for null/empty values
    if (stringValue.isEmpty || stringValue.toLowerCase() == 'null') {
      return '';
    }

    // Try to parse as number for coordinate fields
    final numValue = double.tryParse(stringValue);
    if (numValue != null) {
      return numValue;
    }

    return stringValue;
  }

  /// Clean and make headers unique to handle duplicates
  List<String> _cleanHeaders(List<String> rawHeaders) {
    final cleanHeaders = <String>[];
    final headerCounts = <String, int>{};

    for (final header in rawHeaders) {
      // Clean the header by removing special characters and trimming
      var cleanHeader = header
          .trim()
          .replaceAll(RegExp(r'::+'), '_') // Replace :: with _
          .replaceAll(RegExp(r'[(),]'), '') // Remove parentheses and commas
          .replaceAll(RegExp(r'\s+'), '_') // Replace spaces with _
          .replaceAll(RegExp(r'_+'), '_') // Replace multiple _ with single _
          .replaceAll(RegExp(r'^_|_$'), ''); // Remove leading/trailing _

      // Handle empty headers
      if (cleanHeader.isEmpty) {
        cleanHeader = 'Column';
      }

      // Handle duplicates by adding a suffix
      if (headerCounts.containsKey(cleanHeader)) {
        headerCounts[cleanHeader] = headerCounts[cleanHeader]! + 1;
        cleanHeader = '${cleanHeader}_${headerCounts[cleanHeader]}';
      } else {
        headerCounts[cleanHeader] = 1;
      }

      cleanHeaders.add(cleanHeader);
    }

    return cleanHeaders;
  }
}
