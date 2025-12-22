import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

enum GradientDirection {
  vertical,
  horizontal,
  diagonal,
}

class EnhancedGradientPicker extends StatefulWidget {
  final Function(List<Color>?, GradientDirection) onGradientChanged;
  final List<Color>? initialColors;
  final GradientDirection initialDirection;

  const EnhancedGradientPicker({
    super.key,
    required this.onGradientChanged,
    this.initialColors,
    this.initialDirection = GradientDirection.vertical,
  });

  @override
  State<EnhancedGradientPicker> createState() => _EnhancedGradientPickerState();
}

class _EnhancedGradientPickerState extends State<EnhancedGradientPicker> {
  List<Color> _colors = [];
  GradientDirection _direction = GradientDirection.vertical;
  bool _useRandom = true;

  @override
  void initState() {
    super.initState();
    _useRandom = widget.initialColors == null;
    if (widget.initialColors != null) {
      _colors = List.from(widget.initialColors!);
      _useRandom = false;
    }
    _direction = widget.initialDirection;
  }

  void _addColor() {
    setState(() {
      _colors.add(Colors.blue);
      _useRandom = false;
      widget.onGradientChanged(_colors, _direction);
    });
  }

  void _removeColor(int index) {
    setState(() {
      _colors.removeAt(index);
      if (_colors.isEmpty) {
        _useRandom = true;
        widget.onGradientChanged(null, _direction);
      } else {
        widget.onGradientChanged(_colors, _direction);
      }
    });
  }

  void _pickColor(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _colors[index],
            onColorChanged: (color) {
              setState(() {
                _colors[index] = color;
                widget.onGradientChanged(_colors, _direction);
              });
            },
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _changeDirection(GradientDirection direction) {
    setState(() {
      _direction = direction;
      widget.onGradientChanged(_useRandom ? null : _colors, _direction);
    });
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
                    widget.onGradientChanged(null, _direction);
                  } else {
                    if (_colors.isEmpty) {
                      _colors = [Colors.blue, Colors.purple, Colors.pink];
                      widget.onGradientChanged(_colors, _direction);
                    }
                  }
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (!_useRandom) ...[
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
          const SizedBox(height: 16),
          
          // Color Picker Section
          Text(
            'Colors:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ...List.generate(_colors.length, (index) {
                return GestureDetector(
                  onTap: () => _pickColor(index),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _colors[index],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            Icons.color_lens,
                            color: _colors[index].computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white,
                            size: 28,
                          ),
                        ),
                        if (_colors.length > 1)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _removeColor(index),
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
              // Add color button
              GestureDetector(
                onTap: _addColor,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade400, width: 3),
                  ),
                  child: const Icon(Icons.add, color: Colors.grey, size: 28),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tap colors to change, tap + to add more',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
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

