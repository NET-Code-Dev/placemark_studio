import 'package:flutter/material.dart';

class StatusMessageCard extends StatelessWidget {
  final bool hasError;
  final String? errorMessage;
  final String? successMessage;
  final VoidCallback? onDismissError;
  final VoidCallback? onDismissSuccess;

  const StatusMessageCard({
    super.key,
    this.hasError = false,
    this.errorMessage,
    this.successMessage,
    this.onDismissError,
    this.onDismissSuccess,
  });

  @override
  Widget build(BuildContext context) {
    if (hasError && errorMessage != null) {
      return _MessageCard(
        icon: Icons.error,
        message: errorMessage!,
        color: Colors.red,
        backgroundColor: Colors.red.shade50,
        onDismiss: onDismissError,
      );
    }

    if (successMessage != null && successMessage!.isNotEmpty) {
      return _MessageCard(
        icon: Icons.check_circle,
        message: successMessage!,
        color: Colors.green,
        backgroundColor: Colors.green.shade50,
        onDismiss: onDismissSuccess,
      );
    }

    return const SizedBox.shrink();
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
