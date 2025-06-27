import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:cross_file/cross_file.dart';
import '../../../viewmodels/home_viewmodel.dart';
import '../../../../shared/widgets/custom_elevated_button.dart';
import '../../../../core/constants/app_constants.dart';

class FileSelectionCard extends StatefulWidget {
  const FileSelectionCard({super.key});

  @override
  State<FileSelectionCard> createState() => _FileSelectionCardState();
}

class _FileSelectionCardState extends State<FileSelectionCard>
    with TickerProviderStateMixin {
  bool _isDragOver = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _colorAnimation = ColorTween(
      begin: Colors.grey[100],
      end: Colors.blue[50],
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleDroppedFiles(
    List<XFile> files,
    HomeViewModel viewModel,
  ) async {
    if (files.isEmpty) return;

    final file = files.first;

    // Get file extension
    final extension = file.name.split('.').last.toLowerCase();

    // Validate file extension against supported types
    if (!AppConstants.supportedFileExtensions.contains(extension)) {
      _showErrorSnackBar(
        'Invalid file type. Supported formats: ${AppConstants.supportedFileExtensions.join(', ').toUpperCase()}',
      );
      return;
    }

    // Check file size (rough estimate from file path/name)
    try {
      final fileObject = File(file.path);
      final stat = await fileObject.stat();

      if (stat.size > AppConstants.maxFileSizeBytes) {
        _showErrorSnackBar(
          'File too large. Maximum size is ${AppConstants.maxFileSizeBytes / (1024 * 1024)}MB.',
        );
        return;
      }

      // Set the file in the view model and trigger processing
      await viewModel.handleDroppedFile(fileObject);
    } catch (e) {
      _showErrorSnackBar('Error processing dropped file: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onDragEntered() {
    setState(() {
      _isDragOver = true;
    });
    _animationController.forward();
  }

  void _onDragExited() {
    setState(() {
      _isDragOver = false;
    });
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        // If file is already selected, don't show this card
        if (viewModel.hasKmlData) {
          return const SizedBox.shrink();
        }

        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: DropTarget(
            onDragDone: (details) async {
              _onDragExited();
              await _handleDroppedFiles(details.files, viewModel);
            },
            onDragEntered: (details) => _onDragEntered(),
            onDragExited: (details) => _onDragExited(),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Card(
                    elevation: _isDragOver ? 8 : 4,
                    color: _colorAnimation.value,
                    child: Container(
                      decoration:
                          _isDragOver
                              ? BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                              )
                              : null,
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                _isDragOver
                                    ? Icons.cloud_upload
                                    : Icons.upload_file,
                                key: ValueKey(_isDragOver),
                                size: 80,
                                color:
                                    _isDragOver
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style:
                                  Theme.of(
                                    context,
                                  ).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        _isDragOver
                                            ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                            : null,
                                  ) ??
                                  const TextStyle(),
                              child: Text(
                                _isDragOver
                                    ? 'Drop File Here'
                                    : 'Select KML/KMZ File',
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _isDragOver
                                  ? 'Release to upload your file'
                                  : 'Choose a KML or KMZ file to convert and analyze.\nSupported formats: ${AppConstants.supportedFileExtensions.join(', ').toUpperCase()}',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.copyWith(
                                color:
                                    _isDragOver
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              child: CustomElevatedButton(
                                onPressed:
                                    viewModel.isLoading
                                        ? null
                                        : viewModel.pickFile,
                                icon:
                                    viewModel.isLoading
                                        ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                        : const Icon(Icons.folder_open),
                                label:
                                    viewModel.isLoading
                                        ? 'Loading...'
                                        : 'Browse Files',
                              ),
                            ),
                            const SizedBox(height: 16),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style:
                                  Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color:
                                        _isDragOver
                                            ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                            : Colors.grey[500],
                                    fontStyle: FontStyle.italic,
                                    fontWeight:
                                        _isDragOver
                                            ? FontWeight.w500
                                            : FontWeight.normal,
                                  ) ??
                                  const TextStyle(),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isDragOver) ...[
                                    Icon(
                                      Icons.mouse,
                                      size: 16,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    _isDragOver
                                        ? 'Drop your file now!'
                                        : 'Or drag and drop a KML/KMZ file here',
                                  ),
                                ],
                              ),
                            ),
                            if (_isDragOver) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  'Max file size: ${AppConstants.maxFileSizeBytes ~/ (1024 * 1024)}MB | Formats: ${AppConstants.supportedFileExtensions.join(', ').toUpperCase()}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
