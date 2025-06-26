// lib/presentation/views/home/home_view.dart
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Placemark Studio'),
        centerTitle: true,
        actions: [
          Consumer<HomeViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.hasKmlData) {
                return IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Clear and start over',
                  onPressed: viewModel.clearSelection,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: const Column(
        children: [
          // Fixed header area
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                FileSelectionCard(),
                SizedBox(height: 16),
                StatusMessageCard(),
              ],
            ),
          ),

          // Scrollable content area
          Expanded(child: _MainContentArea()),
        ],
      ),
    );
  }
}

class _MainContentArea extends StatelessWidget {
  const _MainContentArea();

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        if (!viewModel.hasKmlData) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.file_upload, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Select a KML file to get started',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left panel - File info and options
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    FileInfoPanel(),
                    const SizedBox(height: 16),
                    BoundingBoxPreview(),
                    const SizedBox(height: 16),
                    ExportOptionsPanel(),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Right panel - Preview table
              Expanded(flex: 3, child: PreviewTable()),
            ],
          ),
        );
      },
    );
  }
}
