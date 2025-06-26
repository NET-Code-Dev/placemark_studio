import 'package:get_it/get_it.dart';
import '../../data/services/file_picker_service.dart';
import '../../data/services/kml_parser_service.dart';
import '../../data/services/csv_export_service.dart';
import '../../data/services/bounding_box_service.dart';
import '../../presentation/viewmodels/home_viewmodel.dart';
import '../../presentation/viewmodels/extract_viewmodel.dart';
import '../../presentation/viewmodels/create_viewmodel.dart';

final GetIt getIt = GetIt.instance;

class ServiceLocator {
  static Future<void> init() async {
    // Services
    getIt.registerLazySingleton<IFilePickerService>(() => FilePickerService());
    getIt.registerLazySingleton<IKmlParserService>(() => KmlParserService());
    getIt.registerLazySingleton<ICsvExportService>(() => CsvExportService());
    getIt.registerLazySingleton<IBoundingBoxService>(
      () => BoundingBoxService(),
    );

    // ViewModels
    getIt.registerFactory<HomeViewModel>(
      () => HomeViewModel(
        filePickerService: getIt<IFilePickerService>(),
        kmlParserService: getIt<IKmlParserService>(),
        csvExportService: getIt<ICsvExportService>(),
      ),
    );

    getIt.registerFactory<ExtractViewModel>(
      () => ExtractViewModel(boundingBoxService: getIt<IBoundingBoxService>()),
    );

    getIt.registerFactory<CreateViewModel>(() => CreateViewModel());
  }

  static void reset() {
    getIt.reset();
  }
}
