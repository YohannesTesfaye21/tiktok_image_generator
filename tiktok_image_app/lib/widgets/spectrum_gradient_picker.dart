import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

enum GradientDirection {
  vertical,
  horizontal,
  diagonal,
}

class SpectrumGradientPicker extends StatefulWidget {
  final Function(List<Color>?, GradientDirection) onGradientChanged;
  final List<Color>? initialColors;
  final GradientDirection initialDirection;

  const SpectrumGradientPicker({
    super.key,
    required this.onGradientChanged,
    this.initialColors,
    this.initialDirection = GradientDirection.vertical,
  });

  @override
  State<SpectrumGradientPicker> createState() => _SpectrumGradientPickerState();
}

class _SpectrumGradientPickerState extends State<SpectrumGradientPicker> {
  List<Color> _colors = [];
  GradientDirection _direction = GradientDirection.vertical;
  bool _useRandom = true;

  @override
  void initState() {
    super.initState();
    // Default to Random mode (off)
    _useRandom = true;
    // Only use custom if explicitly provided
    if (widget.initialColors != null && widget.initialColors!.isNotEmpty) {
      _colors = List.from(widget.initialColors!);
      _useRandom = false;
    }
    _direction = widget.initialDirection;
  }

  Color _getColorFromPosition(double position) {
    // Create a spectrum from red to blue through the rainbow
    final hue = position * 360.0;
    return HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();
  }

  void _onSpectrumTap(TapDownDetails details, double width) {
    final position = (details.localPosition.dx / width).clamp(0.0, 1.0);
    final selectedColor = _getColorFromPosition(position);
    
    setState(() {
      _colors.add(selectedColor);
      _useRandom = false;
    });
    // Call callback after state update
    widget.onGradientChanged(List.from(_colors), _direction);
  }

  void _editColor(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _colors[index],
            onColorChanged: (color) {
              setState(() {
                _colors[index] = color;
              });
            },
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Call callback when dialog closes with final color
              widget.onGradientChanged(List.from(_colors), _direction);
              Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _removeColor(int index) {
    setState(() {
      _colors.removeAt(index);
      if (_colors.isEmpty) {
        _useRandom = true;
      }
    });
    // Call callback after state update
    if (_colors.isEmpty) {
      widget.onGradientChanged(null, _direction);
    } else {
      widget.onGradientChanged(List.from(_colors), _direction);
    }
  }

  void _changeDirection(GradientDirection direction) {
    setState(() {
      _direction = direction;
    });
    // Call callback after state update
    widget.onGradientChanged(_useRandom ? null : (_colors.isNotEmpty ? List.from(_colors) : null), _direction);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with toggle
        Row(
          children: [
            Expanded(
              child: Text(
                'Background Gradient',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _useRandom ? 'Random' : 'Custom',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(width: 4),
            Switch(
              value: !_useRandom,
              onChanged: (value) {
                setState(() {
                  _useRandom = !value;
                  if (_useRandom) {
                    _colors.clear();
                  } else {
                    if (_colors.isEmpty) {
                      // Add default colors when switching to custom
                      _colors = [Colors.blue, Colors.purple, Colors.pink];
                    }
                  }
                });
                // Call callback after state update
                if (_useRandom) {
                  widget.onGradientChanged(null, _direction);
                } else {
                  widget.onGradientChanged(List.from(_colors), _direction);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (!_useRandom) ...[
          // Color Spectrum Bar
          Container(
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300, width: 2),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return GestureDetector(
                  onTapDown: (details) => _onSpectrumTap(details, width),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: LinearGradient(
                        colors: List.generate(
                          360,
                          (i) => HSVColor.fromAHSV(1.0, i.toDouble(), 1.0, 1.0).toColor(),
                        ),
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Show selected color stops
                        ...List.generate(_colors.length, (index) {
                          // Calculate position based on color hue
                          final hue = HSVColor.fromColor(_colors[index]).hue;
                          final position = (hue / 360.0) * width;
                          
                          return Positioned(
                            left: position.clamp(0.0, width - 20),
                            top: 0,
                            child: GestureDetector(
                              onLongPress: () => _removeColor(index),
                              onTap: () => _editColor(index),
                              child: Container(
                                width: 20,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: _colors[index],
                                  border: Border.all(color: Colors.white, width: 2),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Icon(
                                        Icons.circle,
                                        size: 8,
                                        color: _colors[index].computeLuminance() > 0.5
                                            ? Colors.black
                                            : Colors.white,
                                      ),
                                    ),
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: GestureDetector(
                                        onTap: () => _removeColor(index),
                                        child: Container(
                                          width: 14,
                                          height: 14,
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 10,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap bar to add • Tap color to edit • Long press or X to remove',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          
          // Gradient Preview
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: _getGradient(),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Gradient Preview',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Direction Selector
          Text(
            'Direction:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DirectionButton(
                  label: 'Vertical',
                  icon: Icons.arrow_downward,
                  isSelected: _direction == GradientDirection.vertical,
                  onTap: () => _changeDirection(GradientDirection.vertical),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DirectionButton(
                  label: 'Horizontal',
                  icon: Icons.arrow_forward,
                  isSelected: _direction == GradientDirection.horizontal,
                  onTap: () => _changeDirection(GradientDirection.horizontal),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DirectionButton(
                  label: 'Diagonal',
                  icon: Icons.trending_up,
                  isSelected: _direction == GradientDirection.diagonal,
                  onTap: () => _changeDirection(GradientDirection.diagonal),
                ),
              ),
            ],
          ),
        ] else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Random beautiful gradients will be used',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  LinearGradient _getGradient() {
    if (_colors.isEmpty) {
      return LinearGradient(
        begin: _getBeginAlignment(),
        end: _getEndAlignment(),
        colors: [Colors.grey.shade300, Colors.grey.shade400],
      );
    }
    return LinearGradient(
      begin: _getBeginAlignment(),
      end: _getEndAlignment(),
      colors: _colors,
    );
  }

  Alignment _getBeginAlignment() {
    switch (_direction) {
      case GradientDirection.vertical:
        return Alignment.topCenter;
      case GradientDirection.horizontal:
        return Alignment.centerLeft;
      case GradientDirection.diagonal:
        return Alignment.topLeft;
    }
  }

  Alignment _getEndAlignment() {
    switch (_direction) {
      case GradientDirection.vertical:
        return Alignment.bottomCenter;
      case GradientDirection.horizontal:
        return Alignment.centerRight;
      case GradientDirection.diagonal:
        return Alignment.bottomRight;
    }
  }
}

class _DirectionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _DirectionButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[600],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

