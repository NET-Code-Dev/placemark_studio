import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/enums/converter_type.dart';
import '../../../../core/enums/converter_mode.dart';
import '../../../viewmodels/home_viewmodel.dart';

class ConverterGrid extends StatelessWidget {
  const ConverterGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 800),
      child: Column(
        children: [
          // Title section
          Text(
            'Choose Converter',
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the type of conversion you need',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          // Grid of converter cards
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2, // Slightly wider than square
            children: const [
              // KML/KMZ to CSV (existing functionality)
              _ConverterCard(
                type: ConverterType.kmlToCsv,
                title: 'KML/KMZ to CSV',
                description:
                    'Convert KML and KMZ files to CSV format for data analysis',
                icon: Icons.transform,
                iconColor: Colors.blue,
                isAvailable: true,
              ),

              // CSV to KML/KMZ (new functionality)
              _ConverterCard(
                type: ConverterType.csvToKml,
                title: 'CSV to KML/KMZ',
                description:
                    'Create KML/KMZ files from CSV data with custom styling',
                icon: Icons.add_location,
                iconColor: Colors.green,
                isAvailable: true,
              ),

              // Multi-file merge (coming soon)
              _ConverterCard(
                type: ConverterType.multiFileMerge,
                title: 'Multi-File Merge',
                description: 'Combine multiple KML/CSV files into one',
                icon: Icons.merge,
                iconColor: Colors.orange,
                isAvailable: false,
              ),

              // Batch processing (coming soon)
              _ConverterCard(
                type: ConverterType.batchProcessing,
                title: 'Batch Processing',
                description: 'Process multiple files with the same settings',
                icon: Icons.batch_prediction,
                iconColor: Colors.purple,
                isAvailable: false,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Help text
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Need help? Check our documentation for supported file formats and conversion examples.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.blue[700]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConverterCard extends StatefulWidget {
  final ConverterType type;
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final bool isAvailable;

  const _ConverterCard({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.isAvailable,
  });

  @override
  State<_ConverterCard> createState() => _ConverterCardState();
}

class _ConverterCardState extends State<_ConverterCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onHoverChanged(bool hovered) {
    setState(() {
      _isHovered = hovered;
    });
    if (hovered && widget.isAvailable) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _onTap() {
    if (!widget.isAvailable) {
      _showComingSoonDialog();
      return;
    }

    final viewModel = Provider.of<HomeViewModel>(context, listen: false);

    switch (widget.type) {
      case ConverterType.kmlToCsv:
        // Set the converter mode and let the home view show the file selection card
        viewModel.setConverterMode(ConverterMode.kmlToCsv);
        break;
      case ConverterType.csvToKml:
        // Navigate to CSV converter
        _navigateToCsvConverter();
        break;
      case ConverterType.multiFileMerge:
      case ConverterType.batchProcessing:
        _showComingSoonDialog();
        break;
    }
  }

  void _navigateToCsvConverter() {
    Navigator.of(context).pushNamed('/csv-converter');
  }

  void _showComingSoonDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Coming Soon'),
            content: Text(
              'The ${widget.title} feature is currently under development and will be available in a future update.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHoverChanged(true),
      onExit: (_) => _onHoverChanged(false),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTap: _onTap,
              child: Card(
                elevation: _isHovered && widget.isAvailable ? 8 : 4,
                color: _getCardColor(),
                child: Container(
                  decoration: _getCardDecoration(),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon with background circle
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: widget.iconColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.icon,
                            size: 32,
                            color:
                                widget.isAvailable
                                    ? widget.iconColor
                                    : Colors.grey[400],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Title
                        Text(
                          widget.title,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: widget.isAvailable ? null : Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 8),

                        // Description
                        Text(
                          widget.description,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color:
                                widget.isAvailable
                                    ? Colors.grey[600]
                                    : Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),

                        if (!widget.isAvailable) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Coming Soon',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color? _getCardColor() {
    if (!widget.isAvailable) {
      return Colors.grey[50];
    }
    if (_isHovered) {
      return widget.iconColor.withValues(alpha: 0.05);
    }
    return null;
  }

  BoxDecoration? _getCardDecoration() {
    if (_isHovered && widget.isAvailable) {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.iconColor.withValues(alpha: 0.3),
          width: 2,
        ),
      );
    }
    return null;
  }
}
