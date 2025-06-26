import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/home_viewmodel.dart';

class StatusMessageCard extends StatelessWidget {
  const StatusMessageCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.hasError) {
          return _MessageCard(
            icon: Icons.error,
            message: viewModel.errorMessage ?? 'An error occurred',
            color: Colors.red,
            backgroundColor: Colors.red.shade50,
            onDismiss: viewModel.clearError,
          );
        }

        if (viewModel.successMessage != null) {
          return _MessageCard(
            icon: Icons.check_circle,
            message: viewModel.successMessage!,
            color: Colors.green,
            backgroundColor: Colors.green.shade50,
            onDismiss: viewModel.clearMessages,
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  final Color backgroundColor;
  final VoidCallback? onDismiss;

  const _MessageCard({
    required this.icon,
    required this.message,
    required this.color,
    required this.backgroundColor,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: TextStyle(color: color))),
            if (onDismiss != null)
              IconButton(
                icon: Icon(Icons.close, color: color),
                onPressed: onDismiss,
                iconSize: 20,
              ),
          ],
        ),
      ),
    );
  }
}
