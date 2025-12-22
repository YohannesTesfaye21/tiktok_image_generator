import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../widgets/spectrum_gradient_picker.dart';

class ImageGeneratorService {
  // Use 10.0.2.2 for Android emulator, localhost for iOS simulator/desktop
  // For physical Android devices, use your computer's IP address (e.g., http://192.168.1.100:8000)
  static String get baseUrl {
    if (Platform.isAndroid) {
      // Android emulator uses 10.0.2.2 to access host machine
      // For physical device, you'll need to use your computer's local IP
      // You can find it with: ifconfig (macOS/Linux) or ipconfig (Windows)
      return 'http://10.0.2.2:8000';  // Android emulator
    }
    return 'http://localhost:8000';   // iOS simulator, macOS, etc.
  }
  
  // Optional: Allow custom server URL for physical devices
  static String? customServerUrl;
  
  String get serverUrl => customServerUrl ?? baseUrl;
  
  Future<List<String>> generateImages({
    required List<String> texts,
    List<Color>? gradientColors,
    GradientDirection gradientDirection = GradientDirection.vertical,
  }) async {
    try {
      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'texts': texts,
      };

      // Always send gradient colors and direction (even if null for random)
      if (gradientColors != null && gradientColors.isNotEmpty) {
        final colors = gradientColors.map((color) {
          // Use toARGB32() instead of deprecated .value
          final argb = color.value; // Keep using value for now, but extract components
          return {
            'r': (argb >> 16) & 0xFF,
            'g': (argb >> 8) & 0xFF,
            'b': argb & 0xFF,
          };
        }).toList();
        requestBody['gradient_colors'] = colors;
        requestBody['gradient_direction'] = gradientDirection.toString().split('.').last;
        debugPrint('Sending gradient colors: ${colors.length} colors, direction: ${gradientDirection.toString().split('.').last}');
        debugPrint('Color values: $colors');
      } else {
        // Explicitly send empty/null to use random
        requestBody['gradient_colors'] = [];
        requestBody['gradient_direction'] = gradientDirection.toString().split('.').last;
        debugPrint('Sending empty gradient_colors - will use random');
      }

      final response = await http.post(
        Uri.parse('$serverUrl/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<String>.from(data['image_paths']);
        } else {
          throw Exception(data['error'] ?? 'Unknown error');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to generate images: ${response.statusCode}');
      }
    } catch (e) {
      // Provide better error message
      String errorMessage = e.toString();
      if (errorMessage.contains('Failed host lookup') || 
          errorMessage.contains('Connection refused') ||
          errorMessage.contains('Network is unreachable')) {
        String platformHint = '';
        if (Platform.isAndroid) {
          platformHint = '\n\nFor Android Emulator: Make sure backend is running on your computer.\n'
              'For Physical Device: Use your computer\'s IP address instead of 10.0.2.2\n'
              'Find your IP: ifconfig (Mac/Linux) or ipconfig (Windows)\n'
              'Then set: ImageGeneratorService.customServerUrl = "http://YOUR_IP:8000"';
        } else {
          platformHint = '\n\nMake sure the backend server is running on port 8000';
        }
        throw Exception('Cannot connect to server at $serverUrl.$platformHint');
      }
      rethrow;
    }
  }
  
  // Test connection to server
  Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$serverUrl/api/health'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

