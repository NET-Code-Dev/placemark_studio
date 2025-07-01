import 'package:flutter/material.dart';
import '../../../../core/enums/geometry_type.dart';
import '../../../../data/models/styling_options.dart';

class StyleEditorWidget extends StatefulWidget {
  final GeometryType geometryType;
  final GeometryStyle initialStyle;
  final Function(GeometryStyle) onStyleChanged;
  final bool showAdvanced;

  const StyleEditorWidget({
    super.key,
    required this.geometryType,
    required this.initialStyle,
    required this.onStyleChanged,
    this.showAdvanced = false,
  });

  @override
  State<StyleEditorWidget> createState() => _StyleEditorWidgetState();
}

class _StyleEditorWidgetState extends State<StyleEditorWidget> {
  late GeometryStyle _currentStyle;
  bool _showAdvancedOptions = false;

  @override
  void initState() {
    super.initState();
    _currentStyle = widget.initialStyle;
    _showAdvancedOptions = widget.showAdvanced;
  }

  @override
  void didUpdateWidget(StyleEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialStyle != widget.initialStyle) {
      _currentStyle = widget.initialStyle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Color selection
        _buildColorSelection(),

        const SizedBox(height: 16),

        // Icon selection (for points only)
        if (widget.geometryType == GeometryType.point) ...[
          _buildIconSelection(),
          const SizedBox(height: 16),
        ],

        // Line width (for lines and polygons)
        if (widget.geometryType == GeometryType.lineString ||
            widget.geometryType == GeometryType.polygon) ...[
          _buildLineWidthSelection(),
          const SizedBox(height: 16),
        ],

        // Opacity (for polygons)
        if (widget.geometryType == GeometryType.polygon) ...[
          _buildOpacitySelection(),
          const SizedBox(height: 16),
        ],

        // Advanced options toggle
        if (widget.geometryType == GeometryType.polygon &&
            !widget.showAdvanced) ...[
          _buildAdvancedToggle(),
          if (_showAdvancedOptions) ...[
            const SizedBox(height: 16),
            _buildAdvancedOptions(),
          ],
        ],

        // Style preview
        const SizedBox(height: 16),
        _buildStylePreview(),
      ],
    );
  }

  Widget _buildColorSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Color',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: KmlColor.predefinedColors.length,
            itemBuilder: (context, index) {
              final color = KmlColor.predefinedColors[index];
              final isSelected = _currentStyle.color == color;

              return GestureDetector(
                onTap: () => _updateColor(color),
                child: Container(
                  width: 50,
                  height: 50,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: color.color,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.grey[300]!,
                      width: isSelected ? 3 : 1,
                    ),
                    boxShadow:
                        isSelected
                            ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                            : null,
                  ),
                  child:
                      isSelected
                          ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          )
                          : null,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _currentStyle.color.name,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildIconSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Icon',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: KmlIcon.values.length,
            itemBuilder: (context, index) {
              final icon = KmlIcon.values[index];
              final isSelected = _currentStyle.icon == icon;

              return GestureDetector(
                onTap: () => _updateIcon(icon),
                child: Container(
                  width: 60,
                  height: 60,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.network(
                      icon.url,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.place, color: Colors.grey[400]);
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _currentStyle.icon?.displayName ?? 'No icon selected',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildLineWidthSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Line Width',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              '${_currentStyle.lineWidth.toInt()}px',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: _currentStyle.lineWidth,
            min: 1.0,
            max: 10.0,
            divisions: 9,
            onChanged: _updateLineWidth,
          ),
        ),
      ],
    );
  }

  Widget _buildOpacitySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Fill Opacity',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              '${(_currentStyle.opacity * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: _currentStyle.opacity,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            onChanged: _updateOpacity,
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedToggle() {
    return InkWell(
      onTap: () {
        setState(() {
          _showAdvancedOptions = !_showAdvancedOptions;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              _showAdvancedOptions ? Icons.expand_less : Icons.expand_more,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              'Advanced Options',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fill option
        Row(
          children: [
            Text(
              'Fill Interior',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Switch(value: _currentStyle.filled, onChanged: _updateFilled),
          ],
        ),

        const SizedBox(height: 16),

        // Outline option
        Row(
          children: [
            Text(
              'Show Outline',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Switch(value: _currentStyle.outlined, onChanged: _updateOutlined),
          ],
        ),
      ],
    );
  }

  Widget _buildStylePreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Style Preview',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Visual preview
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _currentStyle.color.color.withOpacity(
                    widget.geometryType == GeometryType.polygon
                        ? _currentStyle.opacity
                        : 1.0,
                  ),
                  border: Border.all(
                    color:
                        _currentStyle.outlined
                            ? Colors.grey[800]!
                            : Colors.transparent,
                    width: _currentStyle.lineWidth,
                  ),
                  borderRadius: BorderRadius.circular(
                    widget.geometryType == GeometryType.point ? 20 : 4,
                  ),
                ),
                child:
                    widget.geometryType == GeometryType.point &&
                            _currentStyle.icon != null
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            _currentStyle.icon!.url,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.place,
                                color: Colors.white,
                              );
                            },
                          ),
                        )
                        : null,
              ),
              const SizedBox(width: 16),

              // Style details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGeometryTypeLabel(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStyleSummary(),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getGeometryTypeLabel() {
    switch (widget.geometryType) {
      case GeometryType.point:
        return 'Point/Placemark';
      case GeometryType.lineString:
        return 'Line/Path';
      case GeometryType.polygon:
        return 'Polygon/Area';
      default:
        return 'Feature';
    }
  }

  String _getStyleSummary() {
    final parts = <String>[];

    parts.add(_currentStyle.color.name);

    if (widget.geometryType == GeometryType.point &&
        _currentStyle.icon != null) {
      parts.add(_currentStyle.icon!.displayName);
    }

    if (widget.geometryType == GeometryType.lineString ||
        widget.geometryType == GeometryType.polygon) {
      parts.add('${_currentStyle.lineWidth.toInt()}px line');
    }

    if (widget.geometryType == GeometryType.polygon) {
      parts.add('${(_currentStyle.opacity * 100).toInt()}% opacity');
      if (!_currentStyle.filled) parts.add('no fill');
      if (!_currentStyle.outlined) parts.add('no outline');
    }

    return parts.join(' • ');
  }

  // Event handlers
  void _updateColor(KmlColor color) {
    setState(() {
      _currentStyle = _currentStyle.copyWith(color: color);
    });
    widget.onStyleChanged(_currentStyle);
  }

  void _updateIcon(KmlIcon icon) {
    setState(() {
      _currentStyle = _currentStyle.copyWith(icon: icon);
    });
    widget.onStyleChanged(_currentStyle);
  }

  void _updateLineWidth(double width) {
    setState(() {
      _currentStyle = _currentStyle.copyWith(lineWidth: width);
    });
    widget.onStyleChanged(_currentStyle);
  }

  void _updateOpacity(double opacity) {
    setState(() {
      _currentStyle = _currentStyle.copyWith(opacity: opacity);
    });
    widget.onStyleChanged(_currentStyle);
  }

  void _updateFilled(bool filled) {
    setState(() {
      _currentStyle = _currentStyle.copyWith(filled: filled);
    });
    widget.onStyleChanged(_currentStyle);
  }

  void _updateOutlined(bool outlined) {
    setState(() {
      _currentStyle = _currentStyle.copyWith(outlined: outlined);
    });
    widget.onStyleChanged(_currentStyle);
  }
}
