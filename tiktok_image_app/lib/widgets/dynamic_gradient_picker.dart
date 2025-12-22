import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class DynamicGradientPicker extends StatefulWidget {
  final Function(List<Color>?) onGradientChanged;
  final List<Color>? selectedColors;

  const DynamicGradientPicker({
    super.key,
    required this.onGradientChanged,
    this.selectedColors,
  });

  @override
  State<DynamicGradientPicker> createState() => _DynamicGradientPickerState();
}

class _DynamicGradientPickerState extends State<DynamicGradientPicker> {
  List<Color> _colors = [];
  bool _useRandom = true;

  @override
  void initState() {
    super.initState();
    _useRandom = widget.selectedColors == null;
    if (widget.selectedColors != null) {
      _colors = List.from(widget.selectedColors!);
    }
  }

  void _addColor() {
    setState(() {
      _colors.add(Colors.blue);
      _useRandom = false;
      widget.onGradientChanged(_colors);
    });
  }

  void _removeColor(int index) {
    setState(() {
      _colors.removeAt(index);
      if (_colors.isEmpty) {
        _useRandom = true;
        widget.onGradientChanged(null);
      } else {
        widget.onGradientChanged(_colors);
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
                widget.onGradientChanged(_colors);
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Background Gradient (Optional)',
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
                    widget.onGradientChanged(null);
                  } else {
                    if (_colors.isEmpty) {
                      _colors = [Colors.blue, Colors.purple, Colors.pink];
                      widget.onGradientChanged(_colors);
                    }
                  }
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (!_useRandom) ...[
          // Preview
          Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _colors.isEmpty
                    ? [Colors.grey.shade300, Colors.grey.shade400]
                    : _colors,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Text(
                'Preview',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Color chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...List.generate(_colors.length, (index) {
                return GestureDetector(
                  onTap: () => _pickColor(index),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _colors[index],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
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
                            Icons.color_lens,
                            color: _colors[index].computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white,
                            size: 24,
                          ),
                        ),
                        if (_colors.length > 1)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _removeColor(index),
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
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
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade400, width: 2),
                  ),
                  child: const Icon(Icons.add, color: Colors.grey),
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
}

