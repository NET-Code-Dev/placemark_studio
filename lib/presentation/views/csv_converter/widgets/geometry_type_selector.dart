import 'package:flutter/material.dart';

class GeometryTypeSelector extends StatelessWidget {
  const GeometryTypeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Geometry Type Selector',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Choose between Point, LineString, or Polygon geometry.\nWill be implemented in Milestone 4.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
