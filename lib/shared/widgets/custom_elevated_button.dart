import 'package:flutter/material.dart';

class CustomElevatedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget? icon;
  final String label;
  final ButtonStyle? style;

  const CustomElevatedButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon!,
        label: Text(label),
        style:
            style ??
            ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style:
          style ??
          ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
      child: Text(label),
    );
  }
}
