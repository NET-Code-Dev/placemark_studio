import 'package:get_it/get_it.dart';
import 'package:placemark_studio/data/services/unified_file_parser_service.dart';
import '../../data/services/file_picker_service.dart';
import '../../data/services/kml_parser_service.dart';
import '../../data/services/csv_export_service.dart';
import '../../data/services/csv_parser_service.dart';
import '../../data/services/kml_generation_service.dart';
import '../../data/services/enhanced_kml_generation_service.dart';
import '../../data/services/bounding_box_service.dart';
import '../../presentation/viewmodels/home_viewmodel.dart';
import '../../presentation/viewmodels/extract_viewmodel.dart';
import '../../presentation/viewmodels/create_viewmodel.dart';
import '../../presentation/viewmodels/csv_converter_viewmodel.dart';

final GetIt getIt = GetIt.instance;

class ServiceLocator {
  static Future<void> init() async {
    // Core Services
    getIt.registerLazySingleton<IFilePickerService>(() => FilePickerService());
    getIt.registerLazySingleton<IKmlParserService>(() => KmlParserService());
    getIt.registerLazySingleton<IUnifiedFileParserService>(
      () => UnifiedFileParserService(
        kmlParserService: getIt<IKmlParserService>(),
      ),
    );
    getIt.registerLazySingleton<ICsvExportService>(() => CsvExportService());
    getIt.registerLazySingleton<IBoundingBoxService>(
      () => BoundingBoxService(),
    );

    // CSV Services (both legacy and enhanced)
    getIt.registerLazySingleton<ICsvParserService>(() => CsvParserService());
    getIt.registerLazySingleton<IKmlGenerationService>(
      () => KmlGenerationService(),
    );

    // NEW: Enhanced KML Generation Service
    getIt.registerLazySingleton<IEnhancedKmlGenerationService>(
      () => EnhancedKmlGenerationService(),
    );

    // Existing ViewModels
    getIt.registerFactory<HomeViewModel>(
      () => HomeViewModel(
        filePickerService: getIt<IFilePickerService>(),
        kmlParserService: getIt<IUnifiedFileParserService>(),
        csvExportService: getIt<ICsvExportService>(),
      ),
    );

    getIt.registerFactory<ExtractViewModel>(
      () => ExtractViewModel(boundingBoxService: getIt<IBoundingBoxService>()),
    );

    getIt.registerFactory<CreateViewModel>(() => CreateViewModel());

    // UPDATED: CSV Converter ViewModel with enhanced service
    getIt.registerFactory<CsvConverterViewModel>(
      () => CsvConverterViewModel(
        csvParserService: getIt<ICsvParserService>(),
        kmlGenerationService: getIt<IKmlGenerationService>(),
        enhancedKmlGenerationService:
            getIt<IEnhancedKmlGenerationService>(), // Add this line
      ),
    );
  }

  static void reset() {
    getIt.reset();
  }
}
