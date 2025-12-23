import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TikTokService {
  // Production backend URL on Render
  static const String baseUrl = 'https://tiktok-image-generator.onrender.com';
  
  // Legacy: Keep for local development if needed
  // static String get baseUrl {
  //   if (Platform.isAndroid) {
  //     return 'http://10.0.2.2:8000';
  //   }
  //   return 'http://localhost:8000';
  // }
  
  static String? customServerUrl;
  String get serverUrl => customServerUrl ?? baseUrl;
  
  // SharedPreferences keys
  static const String _keyUserId = 'tiktok_user_id';
  static const String _keyConnected = 'tiktok_connected';
  static const String _keyUserInfo = 'tiktok_user_info';
  
  /// Get authorization URL for OAuth flow
  Future<Map<String, dynamic>> getAuthorizationUrl() async {
    try {
      final response = await http.get(
        Uri.parse('$serverUrl/api/tiktok/auth/authorize'),
      );
      
      // Check if response is HTML (error page)
      final contentType = response.headers['content-type'] ?? '';
      if (contentType.contains('text/html')) {
        return {
          'success': false,
          'error': 'Server returned HTML instead of JSON. Check if TikTok API is configured correctly.',
        };
      }
      
      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          return {
            'success': true,
            'auth_url': data['auth_url'],
            'state': data['state'],
          };
        } catch (e) {
          // Response is not valid JSON
          return {
            'success': false,
            'error': 'Invalid JSON response: ${response.body.substring(0, 100)}',
          };
        }
      } else {
        try {
          final error = json.decode(response.body);
          return {
            'success': false,
            'error': error['error'] ?? 'Failed to get authorization URL',
          };
        } catch (e) {
          return {
            'success': false,
            'error': 'Server error (${response.statusCode}): ${response.body.substring(0, 100)}',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection error: $e',
      };
    }
  }
  
  /// Check if user is connected to TikTok
  Future<bool> isConnected() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyConnected) ?? false;
  }
  
  /// Get stored user ID
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }
  
  /// Get stored user info
  Future<Map<String, dynamic>?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userInfoStr = prefs.getString(_keyUserInfo);
    if (userInfoStr != null) {
      return json.decode(userInfoStr);
    }
    return null;
  }
  
  /// Save connection status and user info
  Future<void> saveConnection({
    required String userId,
    required Map<String, dynamic> userInfo,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyConnected, true);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyUserInfo, json.encode(userInfo));
  }
  
  /// Disconnect TikTok account
  Future<void> disconnect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyConnected);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserInfo);
  }
  
  /// Get fresh user info from API
  Future<Map<String, dynamic>> fetchUserInfo() async {
    try {
      final userId = await getUserId();
      if (userId == null) {
        return {
          'success': false,
          'error': 'User not connected',
        };
      }
      
      final response = await http.get(
        Uri.parse('$serverUrl/api/tiktok/user/info?user_id=$userId'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Update stored user info
          await saveConnection(
            userId: userId,
            userInfo: data['user_info'],
          );
          return {
            'success': true,
            'user_info': data['user_info'],
          };
        }
      }
      
      return {
        'success': false,
        'error': 'Failed to fetch user info',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection error: $e',
      };
    }
  }
  
  /// Post a single image to TikTok
  Future<Map<String, dynamic>> postVideo({
    required String imagePath,
    String caption = '',
    String privacyLevel = 'PUBLIC_TO_EVERYONE',
    int duration = 5,
  }) async {
    try {
      final userId = await getUserId();
      if (userId == null) {
        return {
          'success': false,
          'error': 'TikTok account not connected. Please connect your account first.',
        };
      }
      
      // Extract filename from path for backend
      final filename = imagePath.split('/').last;
      final backendPath = imagePath; // Backend expects full path
      
      final response = await http.post(
        Uri.parse('$serverUrl/api/tiktok/post/video'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'image_path': backendPath,
          'user_id': userId,
          'caption': caption,
          'privacy_level': privacyLevel,
          'duration': duration,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Video uploaded successfully',
          'upload_id': data['upload_id'],
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Failed to post video',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection error: $e',
      };
    }
  }
  
  /// Post multiple images as slideshow to TikTok
  Future<Map<String, dynamic>> postMultipleVideos({
    required List<String> imagePaths,
    String caption = '',
    String privacyLevel = 'PUBLIC_TO_EVERYONE',
    int durationPerImage = 3,
  }) async {
    try {
      final userId = await getUserId();
      if (userId == null) {
        return {
          'success': false,
          'error': 'TikTok account not connected. Please connect your account first.',
        };
      }
      
      final response = await http.post(
        Uri.parse('$serverUrl/api/tiktok/post/multiple'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'image_paths': imagePaths,
          'user_id': userId,
          'caption': caption,
          'privacy_level': privacyLevel,
          'duration_per_image': durationPerImage,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Slideshow uploaded successfully',
          'upload_id': data['upload_id'],
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Failed to post slideshow',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection error: $e',
      };
    }
  }
}


