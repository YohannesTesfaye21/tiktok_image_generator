import 'package:flutter/material.dart';

class GradientPreset {
  final String name;
  final List<Color> colors;
  final GradientDirection direction;

  GradientPreset({
    required this.name,
    required this.colors,
    this.direction = GradientDirection.vertical,
  });
}

enum GradientDirection {
  vertical,
  horizontal,
  diagonal,
}

// Predefined gradient presets
class GradientPresets {
  static final List<GradientPreset> presets = [
    GradientPreset(
      name: 'Sunset',
      colors: [
        const Color(0xFFFF6B6B),
        const Color(0xFFFF9F40),
        const Color(0xFFFFD93D),
      ],
    ),
    GradientPreset(
      name: 'Ocean',
      colors: [
        const Color(0xFF48DBFB),
        const Color(0xFFA3E635),
        const Color(0xFF12B76A),
      ],
    ),
    GradientPreset(
      name: 'Vibrant',
      colors: [
        const Color(0xFFFF4D4D),
        const Color(0xFFFFB800),
        const Color(0xFFFFFF00),
      ],
    ),
    GradientPreset(
      name: 'Purple Pink',
      colors: [
        const Color(0xFF8A2BE2),
        const Color(0xFFFF1493),
        const Color(0xFFFF69B4),
      ],
    ),
    GradientPreset(
      name: 'Sky Blue',
      colors: [
        const Color(0xFF00BFFF),
        const Color(0xFF00FA9A),
        const Color(0xFF32CD32),
      ],
    ),
    GradientPreset(
      name: 'Pastel Pink',
      colors: [
        const Color(0xFFFFB6C1),
        const Color(0xFFFFDAB9),
        const Color(0xFFFFEFD5),
      ],
    ),
    GradientPreset(
      name: 'Pastel Blue',
      colors: [
        const Color(0xFFADD8E6),
        const Color(0xFFB0E0E6),
        const Color(0xFFAFEEEE),
      ],
    ),
    GradientPreset(
      name: 'Dark Purple',
      colors: [
        const Color(0xFF191970),
        const Color(0xFF483D8B),
        const Color(0xFF7B68EE),
      ],
    ),
    GradientPreset(
      name: 'Red Gradient',
      colors: [
        const Color(0xFF8B0000),
        const Color(0xFFB22222),
        const Color(0xFFDC143C),
      ],
    ),
    GradientPreset(
      name: 'Orange Energy',
      colors: [
        const Color(0xFFFF4500),
        const Color(0xFFFF8C00),
        const Color(0xFFFFD700),
      ],
    ),
  ];
}

