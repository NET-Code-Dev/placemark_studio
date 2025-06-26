import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'package:path/path.dart' as path;
import '../../../viewmodels/home_viewmodel.dart';
import '../../../../shared/widgets/custom_elevated_button.dart';

class FileSelectionCard extends StatelessWidget {
  const FileSelectionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Icon(Icons.file_upload, size: 64, color: Colors.blue),
                const SizedBox(height: 16),
                Text(
                  'Select KML File',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a KML file to convert to CSV format',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                CustomElevatedButton(
                  onPressed: viewModel.isLoading ? null : viewModel.pickFile,
                  icon: const Icon(Icons.folder_open),
                  label: 'Browse Files',
                ),
                if (viewModel.hasSelectedFile) ...[
                  const SizedBox(height: 16),
                  _SelectedFileInfo(viewModel: viewModel),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SelectedFileInfo extends StatelessWidget {
  final HomeViewModel viewModel;

  const _SelectedFileInfo({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.description, color: Colors.blue),
        title: Text(viewModel.selectedFileName ?? ''),
        subtitle: FutureBuilder(
          future: viewModel.getFileStats(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              final sizeKB = snapshot.data!.size / 1024;
              return Text('Size: ${sizeKB.toStringAsFixed(2)} KB');
            }
            return const Text('Loading...');
          },
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: viewModel.clearSelection,
          tooltip: 'Remove file',
        ),
      ),
    );
  }
}
