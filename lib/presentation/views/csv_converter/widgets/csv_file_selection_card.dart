import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:cross_file/cross_file.dart';
import '../../../viewmodels/csv_converter_viewmodel.dart';
import '../../../../shared/widgets/custom_elevated_button.dart';

class CsvFileSelectionCard extends StatefulWidget {
  const CsvFileSelectionCard({super.key});

  @override
  State<CsvFileSelectionCard> createState() => _CsvFileSelectionCardState();
}

class _CsvFileSelectionCardState extends State<CsvFileSelectionCard>
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
      end: Colors.green[50],
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
    CsvConverterViewModel viewModel,
  ) async {
    if (files.isEmpty) return;

    final file = files.first;

    // Validate file extension
    if (!file.name.toLowerCase().endsWith('.csv')) {
      _showErrorSnackBar('Please select a CSV file (.csv extension required)');
      return;
    }

    try {
      final fileObject = File(file.path);

      // Basic file validation
      if (!await fileObject.exists()) {
        _showErrorSnackBar('File does not exist');
        return;
      }

      final stat = await fileObject.stat();
      const maxFileSize = 50 * 1024 * 1024; // 50MB limit

      if (stat.size > maxFileSize) {
        _showErrorSnackBar('File too large. Maximum size is 50MB.');
        return;
      }

      // Process the file through the view model using the correct method
      await viewModel.processCsvFile(fileObject);
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
    return Consumer<CsvConverterViewModel>(
      builder: (context, viewModel, child) {
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
                                  color: Colors.green,
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
                                        ? Colors.green
                                        : Colors.green[600],
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
                                    color: _isDragOver ? Colors.green : null,
                                  ) ??
                                  const TextStyle(),
                              child: Text(
                                _isDragOver
                                    ? 'Drop CSV File Here'
                                    : 'Select CSV File',
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _isDragOver
                                  ? 'Release to upload your CSV file'
                                  : 'Choose a CSV file to convert to KML/KMZ format.\nYour data should include latitude, longitude, and name columns.',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.copyWith(
                                color:
                                    _isDragOver
                                        ? Colors.green
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
                                        : viewModel.pickCsvFile,
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
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[600],
                                ),
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
                                            ? Colors.green
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
                                    const Icon(
                                      Icons.mouse,
                                      size: 16,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    _isDragOver
                                        ? 'Drop your file now!'
                                        : 'Or drag and drop a CSV file here',
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
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  'Supported: CSV files up to 50MB',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color: Colors.green,
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
