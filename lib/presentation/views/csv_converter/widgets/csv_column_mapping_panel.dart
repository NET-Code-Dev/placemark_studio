import 'package:flutter/material.dart';

class CsvColumnMappingPanel extends StatelessWidget {
  const CsvColumnMappingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Column Mapping Panel',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'This panel will allow users to map CSV columns to KML fields.\nWill be implemented in Milestone 2.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement column mapping functionality
              },
              child: const Text('Configure Mapping'),
            ),
          ],
        ),
      ),
    );
  }
}
