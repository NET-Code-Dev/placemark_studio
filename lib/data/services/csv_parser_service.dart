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
      final headers = csvData.first.map((e) => e.toString().trim()).toList();

      if (headers.isEmpty) {
        throw FileProcessingException(
          'No headers found in CSV file',
          code: 'NO_CSV_HEADERS',
        );
      }

      // Validate headers for duplicates
      final uniqueHeaders = <String>{};
      final duplicateHeaders = <String>[];

      for (final header in headers) {
        if (header.isEmpty) {
          throw FileProcessingException(
            'Empty column header found in CSV file',
            code: 'EMPTY_HEADER',
          );
        }

        if (uniqueHeaders.contains(header)) {
          duplicateHeaders.add(header);
        } else {
          uniqueHeaders.add(header);
        }
      }

      if (duplicateHeaders.isNotEmpty) {
        throw FileProcessingException(
          'Duplicate column headers found: ${duplicateHeaders.join(', ')}',
          code: 'DUPLICATE_HEADERS',
        );
      }

      // Process data rows
      final dataRows = csvData.skip(1).toList();

      if (dataRows.length > maxRows) {
        throw FileProcessingException(
          'CSV file contains too many rows. Maximum allowed: $maxRows',
          code: 'TOO_MANY_ROWS',
        );
      }

      // Convert rows to maps
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
        print('  Headers: ${headers.length} (${headers.join(', ')})');
        print('  Rows: ${rows.length}');
        print('  Sample row: ${rows.isNotEmpty ? rows.first : 'none'}');
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

    // Test common delimiters
    final delimiters = [',', ';', '\t', '|'];
    final scores = <String, int>{};

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
          allowInvalid: true, // Allow invalid CSV to continue parsing
        );

        final parsed = converter.convert(sampleContent);

        if (parsed.isNotEmpty) {
          // Score based on consistency of column counts and reasonable column numbers
          final columnCounts = parsed.map((row) => row.length).toList();
          final firstRowCount = columnCounts.first;

          // Count how many rows have the same column count as the first row
          final consistentRows =
              columnCounts.where((count) => count == firstRowCount).length;
          final consistencyScore =
              (consistentRows * 100) ~/ columnCounts.length;

          // Prefer delimiters that result in reasonable number of columns (2-200)
          int columnScore = 0;
          if (firstRowCount >= 2 && firstRowCount <= 200) {
            columnScore = math.min(firstRowCount, 50); // Cap bonus at 50
          }

          final totalScore = consistencyScore + columnScore;
          scores[delimiter] = totalScore;

          if (kDebugMode) {
            print(
              'Delimiter "$delimiter": ${firstRowCount} columns, consistency: $consistencyScore%, score: $totalScore',
            );
          }
        }
      } catch (e) {
        scores[delimiter] = 0;
        if (kDebugMode) {
          print('Delimiter "$delimiter" failed: $e');
        }
      }
    }

    // Return delimiter with highest score, defaulting to comma
    if (scores.isEmpty || scores.values.every((score) => score == 0)) {
      if (kDebugMode) {
        print('No valid delimiter found, defaulting to comma');
      }
      return ',';
    }

    final bestEntry = scores.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    final bestDelimiter = bestEntry.key;

    if (kDebugMode) {
      print(
        'Selected delimiter: "$bestDelimiter" with score: ${bestEntry.value}',
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
}
