import 'package:flutter/material.dart';

class KmlExportPanel extends StatelessWidget {
  const KmlExportPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'KML Export Panel',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Configure export settings and generate KML/KMZ files.\nWill be implemented in Milestone 3.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement export functionality
              },
              child: const Text('Export KML'),
            ),
          ],
        ),
      ),
    );
  }
}
