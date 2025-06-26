import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/di/service_locator.dart';
import '../../viewmodels/home_viewmodel.dart';
import 'widgets/file_selection_card.dart';
import 'widgets/file_info_panel.dart';
import 'widgets/bounding_box_preview.dart';
import 'widgets/export_options_panel.dart';
import 'widgets/status_message_card.dart';
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
            centerTitle: false,
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
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: StatusMessageCard(),
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
    return const Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: FileSelectionCard(),
      ),
    );
  }
}

class _DataLoadedView extends StatelessWidget {
  const _DataLoadedView();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // First row: File info and bounding box
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: FileInfoPanel()),
              const SizedBox(width: 16),
              Expanded(flex: 1, child: BoundingBoxPreview()),
            ],
          ),

          const SizedBox(height: 16),

          // Second row: Preview table (full width)
          const SizedBox(
            height: 400, // Fixed height for better layout control
            child: PreviewTable(),
          ),

          const SizedBox(height: 16),

          // Third row: Export options
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: ExportOptionsPanel()),
              const SizedBox(width: 16),
              // Optional: Add another panel here if needed in the future
              Expanded(
                flex: 1,
                child: Container(), // Empty for now
              ),
            ],
          ),
        ],
      ),
    );
  }
}
