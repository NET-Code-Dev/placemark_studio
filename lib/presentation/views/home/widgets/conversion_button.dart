import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/home_viewmodel.dart';

class ConversionButton extends StatelessWidget {
  const ConversionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        return ElevatedButton(
          onPressed:
              viewModel.hasSelectedFile && !viewModel.isLoading
                  ? viewModel.convertToCSV
                  : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child:
              viewModel.isLoading
                  ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Converting...'),
                    ],
                  )
                  : const Text(
                    'Convert to CSV',
                    style: TextStyle(fontSize: 16),
                  ),
        );
      },
    );
  }
}
