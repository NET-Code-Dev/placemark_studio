import 'package:flutter/material.dart';
import '../../core/errors/app_exception.dart';

class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final AppException? exception;
  final VoidCallback? onRetry;

  const ErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.exception,
    this.onRetry,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    AppException? exception,
    VoidCallback? onRetry,
  }) {
    return showDialog(
      context: context,
      builder:
          (context) => ErrorDialog(
            title: title,
            message: message,
            exception: exception,
            onRetry: onRetry,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.error_outline, color: Colors.red, size: 32),
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          if (exception != null && exception!.code != null) ...[
            const SizedBox(height: 8),
            Text(
              'Error Code: ${exception!.code}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ],
      ),
      actions: [
        if (onRetry != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry!();
            },
            child: const Text('Retry'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
