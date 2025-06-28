import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/enums/converter_mode.dart';
import '../../viewmodels/home_viewmodel.dart';
import 'widgets/kml_file_selection_card.dart';
import 'widgets/converter_grid.dart';
import 'widgets/file_info_panel.dart';
import 'widgets/bounding_box_preview.dart';
import 'widgets/export_options_panel.dart';
import '../../../shared/widgets/status_message_card.dart';
import 'widgets/preview_table.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => getIt<HomeViewModel>(),
      child: const _HomeViewContent(),
    );
  }
}

class _HomeViewContent extends StatelessWidget {
  const _HomeViewContent();

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 50.0,
            title: Row(
              children: [
                const Text('Placemark Studio'),
                if (viewModel.hasKmlData) ...[
                  const SizedBox(width: 16),
                  const Text('•', style: TextStyle(color: Colors.grey)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      viewModel.selectedFileName ?? '',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            centerTitle: true,
            actions: [
              if (viewModel.hasKmlData)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Clear and start over',
                  onPressed: viewModel.clearSelection,
                )
              else
                const SizedBox(width: 48), // Maintain consistent spacing
            ],
          ),
          body: Column(
            children: [
              // Status messages (always at top)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: StatusMessageCard(
                  hasError: viewModel.hasError,
                  errorMessage: viewModel.errorMessage,
                  successMessage: viewModel.successMessage,
                  onDismissError: viewModel.clearError,
                  onDismissSuccess: viewModel.clearMessages,
                ),
              ),

              // Main content area
              Expanded(
                child:
                    viewModel.hasKmlData
                        ? const _DataLoadedView()
                        : const _NoDataView(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NoDataView extends StatelessWidget {
  const _NoDataView();

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        // Show file selection card if a converter mode is selected
        if (viewModel.isInFileSelectionMode) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Back button
                  Row(
                    children: [
                      IconButton(
                        onPressed:
                            () =>
                                viewModel.setConverterMode(ConverterMode.none),
                        icon: const Icon(Icons.arrow_back),
                        tooltip: 'Back to converter selection',
                      ),
                      Expanded(
                        child: Text(
                          viewModel.converterMode.displayName,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Show appropriate file selection card
                  if (viewModel.converterMode == ConverterMode.kmlToCsv)
                    const KmlFileSelectionCard()
                  else
                    const SizedBox.shrink(), // Placeholder for future converters
                ],
              ),
            ),
          );
        }

        // Show converter grid if no mode is selected
        return const Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: ConverterGrid(),
          ),
        );
      },
    );
  }
}

class _DataLoadedView extends StatelessWidget {
  const _DataLoadedView();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 600,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 2, // 2/3 width for bounding box
                  child: BoundingBoxPreview(),
                ),
                Expanded(flex: 1, child: FileInfoPanel()),
                Expanded(flex: 1, child: ExportOptionsPanel()),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Second row: Preview table (full width)
          const SizedBox(
            height: 270, // Fixed height for better layout control
            child: PreviewTable(),
          ),
        ],
      ),
    );
  }
}
