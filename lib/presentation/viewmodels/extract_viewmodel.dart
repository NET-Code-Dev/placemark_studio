import '../../data/models/kml_data.dart';
import '../../data/models/export_options.dart';
import '../../data/services/bounding_box_service.dart';
import '../../core/enums/export_format.dart';
//import '../../core/errors/app_exception.dart';
import 'base_viewmodel.dart';

class ExtractViewModel extends BaseViewModel {
  final IBoundingBoxService _boundingBoxService;

  ExtractViewModel({required IBoundingBoxService boundingBoxService})
    : _boundingBoxService = boundingBoxService;

  KmlData? _kmlData;
  ExportFormat _selectedFormat = ExportFormat.csv;
  List<String> _selectedFields = [];
  List<String> _fieldOrder = [];
  bool _includeHeaders = true;
  bool _flattenNestedData = true;
  String? _customDelimiter;
  Map<String, dynamic>? _boundingBoxInfo;

  // Getters
  KmlData? get kmlData => _kmlData;
  ExportFormat get selectedFormat => _selectedFormat;
  List<String> get selectedFields => List.unmodifiable(_selectedFields);
  List<String> get fieldOrder => List.unmodifiable(_fieldOrder);
  bool get includeHeaders => _includeHeaders;
  bool get flattenNestedData => _flattenNestedData;
  String? get customDelimiter => _customDelimiter;
  Map<String, dynamic>? get boundingBoxInfo => _boundingBoxInfo;

  bool get hasKmlData => _kmlData != null;
  List<String> get availableFields => _kmlData?.availableFields.toList() ?? [];
  List<ExportFormat> get supportedFormats =>
      ExportFormat.values.where((f) => f.isSupported).toList();

  void setKmlData(KmlData kmlData) {
    _kmlData = kmlData;
    _selectedFields = kmlData.availableFields.toList();
    _fieldOrder = List.from(_selectedFields);
    _generateBoundingBoxInfo();
    notifyListeners();
  }

  void setSelectedFormat(ExportFormat format) {
    if (_selectedFormat != format) {
      _selectedFormat = format;
      notifyListeners();
    }
  }

  void toggleFieldSelection(String field) {
    if (_selectedFields.contains(field)) {
      _selectedFields.remove(field);
      _fieldOrder.remove(field);
    } else {
      _selectedFields.add(field);
      _fieldOrder.add(field);
    }
    notifyListeners();
  }

  void setFieldSelection(List<String> fields) {
    _selectedFields = List.from(fields);
    _fieldOrder = List.from(fields);
    notifyListeners();
  }

  void reorderFields(List<String> newOrder) {
    _fieldOrder = List.from(newOrder);
    notifyListeners();
  }

  void moveFieldUp(String field) {
    final index = _fieldOrder.indexOf(field);
    if (index > 0) {
      _fieldOrder.removeAt(index);
      _fieldOrder.insert(index - 1, field);
      notifyListeners();
    }
  }

  void moveFieldDown(String field) {
    final index = _fieldOrder.indexOf(field);
    if (index >= 0 && index < _fieldOrder.length - 1) {
      _fieldOrder.removeAt(index);
      _fieldOrder.insert(index + 1, field);
      notifyListeners();
    }
  }

  void setIncludeHeaders(bool include) {
    if (_includeHeaders != include) {
      _includeHeaders = include;
      notifyListeners();
    }
  }

  void setFlattenNestedData(bool flatten) {
    if (_flattenNestedData != flatten) {
      _flattenNestedData = flatten;
      notifyListeners();
    }
  }

  void setCustomDelimiter(String? delimiter) {
    if (_customDelimiter != delimiter) {
      _customDelimiter = delimiter;
      notifyListeners();
    }
  }

  ExportOptions buildExportOptions() {
    return ExportOptions(
      format: _selectedFormat,
      selectedFields: _selectedFields,
      fieldOrder: _fieldOrder,
      includeHeaders: _includeHeaders,
      flattenNestedData: _flattenNestedData,
      customDelimiter: _customDelimiter,
    );
  }

  void _generateBoundingBoxInfo() {
    if (_kmlData != null) {
      try {
        _boundingBoxInfo = _boundingBoxService.getBoundingBoxInfo(_kmlData!);
      } catch (e) {
        _boundingBoxInfo = null;
      }
    }
  }

  void resetToDefaults() {
    if (_kmlData != null) {
      _selectedFormat = ExportFormat.csv;
      _selectedFields = _kmlData!.availableFields.toList();
      _fieldOrder = List.from(_selectedFields);
      _includeHeaders = true;
      _flattenNestedData = true;
      _customDelimiter = null;
      notifyListeners();
    }
  }

  Map<String, dynamic> getDataSummary() {
    if (_kmlData == null) return {};

    return {
      'fileName': _kmlData!.fileName,
      'fileSize': _kmlData!.fileSize,
      'featuresCount': _kmlData!.featuresCount,
      'layersCount': _kmlData!.layersCount,
      'geometryTypes': _kmlData!.geometryTypeCounts,
      'availableFields': _kmlData!.availableFields.length,
      'coordinateSystem': _kmlData!.coordinateSystem.value,
      'coordinateReferenceSystem': _kmlData!.coordinateReferenceSystem.code,
      'coordinateUnits': _kmlData!.coordinateUnits.code,
    };
  }
}
