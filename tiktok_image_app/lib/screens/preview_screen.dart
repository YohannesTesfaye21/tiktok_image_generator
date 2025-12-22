import 'dart:async';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import '../widgets/spectrum_gradient_picker.dart';
import '../services/image_generator_service.dart';

class PreviewScreen extends StatefulWidget {
  final List<String> imagePaths;
  final List<String> texts;
  final List<Color>? initialGradientColors;
  final GradientDirection initialGradientDirection;

  const PreviewScreen({
    super.key,
    required this.imagePaths,
    required this.texts,
    this.initialGradientColors,
    this.initialGradientDirection = GradientDirection.vertical,
  });

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _ImageGradientState {
  List<Color>? colors;
  GradientDirection direction;
  bool isRegenerating;

  _ImageGradientState({
    this.colors,
    this.direction = GradientDirection.vertical,
    bool? isRegenerating,
  }) : isRegenerating = isRegenerating ?? false;
}

class _PreviewScreenState extends State<PreviewScreen> {
  bool _isSavingAll = false;
  int _savedCount = 0;
  List<String> _currentImagePaths = [];
  List<int> _imageVersions = []; // Track image versions for cache busting
  List<_ImageGradientState> _imageGradients = [];
  final ImageGeneratorService _imageService = ImageGeneratorService();
  Map<int, Timer?> _regenerateTimers = {}; // Debounce timers for each image
  
  @override
  void initState() {
    super.initState();
    _currentImagePaths = List.from(widget.imagePaths);
    // Initialize image versions for cache busting
    _imageVersions = List.generate(widget.texts.length, (index) => 0);
    // Initialize gradient state for each image - default to Random (null colors)
    _imageGradients = List.generate(
      widget.texts.length,
      (index) => _ImageGradientState(
        colors: null, // Default to random
        direction: widget.initialGradientDirection,
      ),
    );
    // Initialize debounce timers
    _regenerateTimers = {};
  }

  @override
  void dispose() {
    // Cancel all pending timers
    for (var timer in _regenerateTimers.values) {
      timer?.cancel();
    }
    _regenerateTimers.clear();
    super.dispose();
  }
  
  Future<void> _regenerateSingleImage(int index) async {
    if (_imageGradients[index].isRegenerating) {
      debugPrint('Image $index is already regenerating, skipping');
      return;
    }
    
    debugPrint('Regenerating image $index with ${_imageGradients[index].colors?.length ?? 0} colors');
    
    setState(() {
      _imageGradients[index].isRegenerating = true;
    });
    
    try {
      // Generate only this one image
      final newImagePaths = await _imageService.generateImages(
        texts: [widget.texts[index]],
        gradientColors: _imageGradients[index].colors,
        gradientDirection: _imageGradients[index].direction,
      );
      
      debugPrint('Regeneration complete for image $index, got ${newImagePaths.length} paths');
      
      if (newImagePaths.isNotEmpty && mounted) {
        setState(() {
          _currentImagePaths[index] = newImagePaths[0];
          _imageVersions[index] = _imageVersions[index] + 1; // Increment version for cache busting
          _imageGradients[index].isRegenerating = false;
        });
        debugPrint('Image $index updated, version: ${_imageVersions[index]}');
      } else {
        setState(() {
          _imageGradients[index].isRegenerating = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No image generated'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error regenerating image $index: $e');
      setState(() {
        _imageGradients[index].isRegenerating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error regenerating image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _regenerateAllImages() async {
    // Regenerate all images with their current gradient settings
    for (int i = 0; i < widget.texts.length; i++) {
      await _regenerateSingleImage(i);
      // Small delay between regenerations
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  void _onGradientChanged(int index, List<Color>? colors, GradientDirection direction) {
    debugPrint('_onGradientChanged called for image $index with ${colors?.length ?? 0} colors');
    
    // Validate index
    if (index < 0 || index >= _imageGradients.length) {
      debugPrint('Invalid index $index, total images: ${_imageGradients.length}');
      return;
    }
    
    // Capture index in local variable to avoid closure issues
    final imageIndex = index;
    
    // Update state first
    setState(() {
      _imageGradients[imageIndex].colors = colors != null && colors.isNotEmpty ? List.from(colors) : null;
      _imageGradients[imageIndex].direction = direction;
    });
    
    // Cancel any pending regeneration for this image
    _regenerateTimers[imageIndex]?.cancel();
    
    // Debounce regeneration - wait 500ms after last change
    _regenerateTimers[imageIndex] = Timer(const Duration(milliseconds: 500), () {
      if (mounted && imageIndex < _imageGradients.length) {
        debugPrint('Starting regeneration for image $imageIndex (debounced)');
        _regenerateSingleImage(imageIndex);
      }
      _regenerateTimers[imageIndex] = null;
    });
  }

  Future<Widget> _loadImage(String imagePath, {int? version}) async {
    try {
      // Check if it's a local file path
      final file = File(imagePath);
      if (await file.exists()) {
        // Use cacheWidth and cacheHeight to prevent caching issues
        // Add version to key to force reload
        return Image.file(
          file,
          fit: BoxFit.cover,
          height: 400,
          cacheWidth: 1080, // Match TikTok dimensions
          key: version != null ? ValueKey('$imagePath-$version') : null,
        );
      }
      
      // If it's a URL, load from network
      if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
        // Add cache busting parameter if version provided
        final uri = version != null 
            ? Uri.parse(imagePath).replace(queryParameters: {'v': version.toString()})
            : Uri.parse(imagePath);
        final response = await http.get(uri);
        if (response.statusCode == 200) {
          return Image.memory(
            response.bodyBytes,
            fit: BoxFit.cover,
            height: 400,
            cacheWidth: 1080,
            key: version != null ? ValueKey('$imagePath-$version') : null,
          );
        }
      }
      
      throw Exception('Image not found at: $imagePath');
    } catch (e) {
      throw Exception('Failed to load image: $e');
    }
  }

  Future<Uint8List> _loadImageBytes(String imagePath) async {
    // Check if it's a local file
    final file = File(imagePath);
    if (await file.exists()) {
      return await file.readAsBytes();
    } else if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      // Load from URL
      final response = await http.get(Uri.parse(imagePath));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to download image');
      }
    } else {
      throw Exception('Image path not found: $imagePath');
    }
  }

  Future<bool> _saveImageToGallery(Uint8List bytes, String name) async {
    try {
      // Request permission first
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      if (!ps.isAuth) {
        final PermissionState state = await PhotoManager.requestPermissionExtend();
        if (!state.isAuth) {
          debugPrint('Photo permission denied');
          return false;
        }
      }

      // Save to temporary file first
      final tempDir = await Directory.systemTemp.createTemp('tiktok_images');
      final file = File('${tempDir.path}/$name.png');
      await file.writeAsBytes(bytes);
      
      // Save to gallery using photo_manager
      final AssetEntity entity = await PhotoManager.editor.saveImage(
        bytes,
        title: name,
        filename: '$name.png',
      );
      
      // Clean up temp file
      try {
        await file.delete();
        await tempDir.delete();
      } catch (_) {
        // Ignore cleanup errors
      }
      
      return entity.id.isNotEmpty;
    } catch (e) {
      // Log error but don't crash
      debugPrint('Error saving image: $e');
      return false;
    }
  }

  Future<void> _saveImage(BuildContext context, String imagePath, int index) async {
    try {
      final bytes = await _loadImageBytes(imagePath);
      final success = await _saveImageToGallery(bytes, 'tiktok_image_$index');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Image saved to gallery!'
                : 'Failed to save image. Please check permissions.'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveAllImages() async {
    if (_isSavingAll) return;
    
    setState(() {
      _isSavingAll = true;
      _savedCount = 0;
    });

    int successCount = 0;
    int failCount = 0;

    for (int i = 0; i < _currentImagePaths.length; i++) {
      try {
        final bytes = await _loadImageBytes(_currentImagePaths[i]);
        final success = await _saveImageToGallery(bytes, 'tiktok_image_$i');
        
        if (success) {
          successCount++;
        } else {
          failCount++;
        }
        
        setState(() {
          _savedCount = i + 1;
        });
        
        // Small delay to avoid overwhelming the system
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        failCount++;
        debugPrint('Error saving image $i: $e');
      }
    }

    setState(() {
      _isSavingAll = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saved $successCount of ${_currentImagePaths.length} images${failCount > 0 ? ' ($failCount failed)' : ''}',
          ),
          backgroundColor: failCount == 0 ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generated Images'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Regenerate All Button
          if (_imageGradients.any((g) => g.isRegenerating))
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('Regenerating...'),
                  ],
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Regenerate All Images',
              onPressed: _regenerateAllImages,
            ),
          // Save All Button
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _isSavingAll
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('$_savedCount/${_currentImagePaths.length}'),
                        ],
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.download),
                    tooltip: 'Save All to Gallery',
                    onPressed: _saveAllImages,
                  ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _currentImagePaths.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, builderIndex) {
          // Capture index explicitly to avoid closure issues
          final imageIndex = builderIndex;
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image Preview
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: FutureBuilder<Widget>(
                    future: _loadImage(_currentImagePaths[imageIndex], version: _imageVersions[imageIndex]),
                    key: ValueKey('image-$imageIndex-${_imageVersions[imageIndex]}'), // Force rebuild on version change
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          height: 400,
                          color: Colors.grey[200],
                          child: const Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasError) {
                        return Container(
                          height: 400,
                          color: Colors.grey[200],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'Error loading image\n${snapshot.error}',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return snapshot.data ?? Container(height: 400, color: Colors.grey[200]);
                    },
                  ),
                ),
                // Gradient Picker for this image
                Container(
                  color: Colors.grey.shade50,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.palette, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            'Gradient for Image ${imageIndex + 1}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const Spacer(),
                          if (_imageGradients[imageIndex].isRegenerating)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SpectrumGradientPicker(
                        onGradientChanged: (colors, direction) {
                          // Use captured imageIndex to avoid closure issues
                          _onGradientChanged(imageIndex, colors, direction);
                        },
                        initialColors: _imageGradients[imageIndex].colors,
                        initialDirection: _imageGradients[imageIndex].direction,
                      ),
                    ],
                  ),
                ),
                // Text and Save Button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Text ${imageIndex + 1}:',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.texts[imageIndex],
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isSavingAll || _imageGradients[imageIndex].isRegenerating
                            ? null
                            : () => _saveImage(context, _currentImagePaths[imageIndex], imageIndex),
                        icon: const Icon(Icons.download),
                        label: const Text('Save to Gallery'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

