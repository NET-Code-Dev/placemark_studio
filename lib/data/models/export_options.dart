import 'package:equatable/equatable.dart';
import '../../core/enums/export_format.dart';

class ExportOptions extends Equatable {
  final ExportFormat format;
  final List<String> selectedFields;
  final List<String> fieldOrder;
  final bool includeHeaders;
  final bool flattenNestedData;
  final String? customDelimiter;
  final String? outputPath;

  const ExportOptions({
    required this.format,
    this.selectedFields = const [],
    this.fieldOrder = const [],
    this.includeHeaders = true,
    this.flattenNestedData = true,
    this.customDelimiter,
    this.outputPath,
  });

  factory ExportOptions.csv({
    List<String> selectedFields = const [],
    List<String> fieldOrder = const [],
    bool includeHeaders = true,
    bool flattenNestedData = true,
    String? customDelimiter,
    String? outputPath,
  }) {
    return ExportOptions(
      format: ExportFormat.csv,
      selectedFields: selectedFields,
      fieldOrder: fieldOrder,
      includeHeaders: includeHeaders,
      flattenNestedData: flattenNestedData,
      customDelimiter: customDelimiter,
      outputPath: outputPath,
    );
  }

  ExportOptions copyWith({
    ExportFormat? format,
    List<String>? selectedFields,
    List<String>? fieldOrder,
    bool? includeHeaders,
    bool? flattenNestedData,
    String? customDelimiter,
    String? outputPath,
  }) {
    return ExportOptions(
      format: format ?? this.format,
      selectedFields: selectedFields ?? this.selectedFields,
      fieldOrder: fieldOrder ?? this.fieldOrder,
      includeHeaders: includeHeaders ?? this.includeHeaders,
      flattenNestedData: flattenNestedData ?? this.flattenNestedData,
      customDelimiter: customDelimiter ?? this.customDelimiter,
      outputPath: outputPath ?? this.outputPath,
    );
  }

  @override
  List<Object?> get props => [
    format,
    selectedFields,
    fieldOrder,
    includeHeaders,
    flattenNestedData,
    customDelimiter,
    outputPath,
  ];
}
