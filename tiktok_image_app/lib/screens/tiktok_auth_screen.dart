import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/tiktok_service.dart';
import 'dart:async';

class TikTokAuthScreen extends StatefulWidget {
  final String authUrl;
  final Function(String userId, Map<String, dynamic> userInfo)? onSuccess;
  final Function(String error)? onError;

  const TikTokAuthScreen({
    super.key,
    required this.authUrl,
    this.onSuccess,
    this.onError,
  });

  @override
  State<TikTokAuthScreen> createState() => _TikTokAuthScreenState();
}

class _TikTokAuthScreenState extends State<TikTokAuthScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // Handle tiktok:// URL scheme - extract the actual URL
            if (request.url.startsWith('tiktok://')) {
              try {
                final uri = Uri.parse(request.url);
                // Extract the actual URL from the tiktok:// scheme
                if (uri.queryParameters.containsKey('url')) {
                  final actualUrl = uri.queryParameters['url']!;
                  // Decode the URL
                  final decodedUrl = Uri.decodeComponent(actualUrl);
                  // Load the actual URL instead
                  _controller.loadRequest(Uri.parse(decodedUrl));
                  return NavigationDecision.prevent;
                }
              } catch (e) {
                debugPrint('Error parsing tiktok:// URL: $e');
              }
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
            
            // Check if this is the callback URL
            if (url.contains('/auth/callback')) {
              _handleCallback(url);
            }
          },
          onUrlChange: (UrlChange change) {
            // Also check URL changes (including hash changes)
            if (change.url != null && change.url!.contains('/auth/callback')) {
              _handleCallback(change.url!);
            }
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            if (!_isProcessing) {
              widget.onError?.call('WebView error: ${error.description}');
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authUrl));
  }

  void _handleCallback(String url) async {
    if (_isProcessing) return;
    
    // Parse the callback URL
    final uri = Uri.parse(url);
    final code = uri.queryParameters['code'];
    final error = uri.queryParameters['error'];
    final hash = uri.fragment;
    
    // Check for hash-based success/error indicators
    if (hash.contains('tiktok_connected') || hash.contains('tiktok_error')) {
      // Wait a moment for page to load, then extract result
      await Future.delayed(const Duration(milliseconds: 500));
      _extractResultFromPage();
      return;
    }
    
    if (error != null) {
      widget.onError?.call('Authorization failed: $error');
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    if (code == null) {
      // Not a valid callback yet, continue loading
      return;
    }

    // Valid callback with code - wait for backend to process
    // The backend will return an HTML page with the result
    _isProcessing = true;
    
    // Wait for page to load and check for result
    await Future.delayed(const Duration(seconds: 2));
    _extractResultFromPage();
  }
  
  Future<void> _extractResultFromPage() async {
    if (_isProcessing && mounted) {
      // Show processing indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Completing authentication...'),
            ],
          ),
        ),
      );
    }

    try {
      final tiktokService = TikTokService();
      
      // Poll for user info (backend processes callback)
      // Try up to 8 times with 1 second delay between attempts
      Map<String, dynamic>? userInfoResult;
      String? userId;
      
      for (int i = 0; i < 8; i++) {
        await Future.delayed(const Duration(seconds: 1));
        
        // Try to get user info
        userInfoResult = await tiktokService.fetchUserInfo();
        
        if (userInfoResult != null && userInfoResult['success'] == true) {
          userId = await tiktokService.getUserId();
          if (userId != null) {
            // Save connection
            await tiktokService.saveConnection(
              userId: userId,
              userInfo: userInfoResult['user_info'],
            );
            break;
          }
        }
      }
      
      if (userInfoResult != null && 
          userInfoResult['success'] == true && 
          userId != null) {
        widget.onSuccess?.call(userId, userInfoResult['user_info']);
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          Navigator.of(context).pop(); // Close auth screen
        }
      } else {
        final errorMsg = userInfoResult?['error'] ?? 
                        'Failed to complete authentication. Please check:\n1. Backend server is running\n2. Redirect URI is set in TikTok Developer Portal\n3. Try again';
        throw Exception(errorMsg);
      }
    } catch (e) {
      _isProcessing = false;
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog if open
        widget.onError?.call('Authentication error: $e');
        Navigator.of(context).pop(); // Close auth screen
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect TikTok Account'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

