import 'package:flutter/material.dart';
import '../services/image_generator_service.dart';
import '../widgets/spectrum_gradient_picker.dart';
import '../widgets/text_input_section.dart';
import 'preview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _textController = TextEditingController();
  List<Color>? _selectedGradientColors;
  GradientDirection _gradientDirection = GradientDirection.vertical;
  bool _isGenerating = false;
  final ImageGeneratorService _imageService = ImageGeneratorService();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _generateImages() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _showSnackBar('Please enter some text');
      return;
    }

    // Gradient is optional - if not selected, backend will use random gradients

    setState(() {
      _isGenerating = true;
    });

    try {
      // Test connection first
      if (mounted) {
        _showSnackBar('Checking server connection...');
      }
      
      final isConnected = await _imageService.testConnection();
      if (!isConnected) {
        if (mounted) {
          _showSnackBar('Cannot connect to server. Please make sure the backend is running on port 8000');
        }
        return;
      }
      
      // Parse numbered texts
      final texts = _parseNumberedTexts(text);
      
      if (texts.isEmpty) {
        _showSnackBar('No valid texts found');
        return;
      }

      // Generate images (gradient is optional)
      final imagePaths = await _imageService.generateImages(
        texts: texts,
        gradientColors: _selectedGradientColors,
        gradientDirection: _gradientDirection,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PreviewScreen(
              imagePaths: imagePaths,
              texts: texts,
              initialGradientColors: _selectedGradientColors,
              initialGradientDirection: _gradientDirection,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error generating images: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  List<String> _parseNumberedTexts(String input) {
    final texts = <String>[];
    final lines = input.split('\n');
    String? currentText;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        if (currentText != null && currentText.isNotEmpty) {
          texts.add(currentText.trim());
          currentText = null;
        }
        continue;
      }

      // Check if line starts with a number pattern (e.g., "1.", "2.", "10.")
      final match = RegExp(r'^\d+[\.\)]\s*(.*)').firstMatch(trimmed);
      if (match != null) {
        // Save previous text if exists
        if (currentText != null && currentText.isNotEmpty) {
          texts.add(currentText.trim());
        }
        // Start new text
        currentText = match.group(1)?.trim() ?? '';
      } else if (currentText != null) {
        // Continuation of current text (multi-line)
        currentText += '\n$trimmed';
      } else {
        // First line without number - treat as new text
        currentText = trimmed;
      }
    }

    // Don't forget the last text
    if (currentText != null && currentText.isNotEmpty) {
      texts.add(currentText.trim());
    }

    // If no numbered format detected, treat each non-empty line as separate
    if (texts.isEmpty) {
      texts.addAll(lines.where((line) => line.trim().isNotEmpty));
    }

    return texts;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TikTok Image Generator'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Spectrum Gradient Picker Section (Optional)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SpectrumGradientPicker(
                  onGradientChanged: (colors, direction) {
                    setState(() {
                      _selectedGradientColors = colors;
                      _gradientDirection = direction;
                    });
                  },
                  initialColors: _selectedGradientColors,
                  initialDirection: _gradientDirection,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Text Input Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter Your Texts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You can paste numbered texts like:\n1. First text\n2. Second text',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextInputSection(
                      controller: _textController,
                      hintText: 'Paste your texts here...\n\nExample:\n1. Text one\n2. Text two\n3. Text three',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Generate Button
            ElevatedButton(
              onPressed: _isGenerating ? null : _generateImages,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: _isGenerating
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Generating...'),
                      ],
                    )
                  : const Text(
                      'Generate Images',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

