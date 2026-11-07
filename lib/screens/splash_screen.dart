import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:openlist_mobile/api/native_upload.dart';
import 'package:openlist_mobile/api/session.dart';
import 'package:openlist_mobile/design/theme.dart';
import 'package:openlist_mobile/utils/service_manager.dart';

/// Splash screen shown during app initialization
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _statusMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    _initialize();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      // Restore session
      _updateStatus('Restoring session...');
      await OpenListSession.instance.restore();
      await Future.delayed(const Duration(milliseconds: 300));

      // Restore native uploads
      _updateStatus('Restoring uploads...');
      await NativeUploader.instance.restore();
      await Future.delayed(const Duration(milliseconds: 300));

      // Check server status
      _updateStatus('Checking server...');
      await ServiceManager.instance.checkServiceStatus();
      await Future.delayed(const Duration(milliseconds: 300));

      _updateStatus('Ready!');
      await Future.delayed(const Duration(milliseconds: 500));

      // Navigate to main screen
      if (mounted) {
        Get.offAllNamed('/');
      }
    } catch (e) {
      debugPrint('Initialization error: $e');
      // Even if there's an error, navigate to main screen
      if (mounted) {
        Get.offAllNamed('/');
      }
    }
  }

  void _updateStatus(String message) {
    if (mounted) {
      setState(() {
        _statusMessage = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // OpenList Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppDesign.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.folder_open,
                  size: 60,
                  color: AppDesign.primaryBlue,
                ),
              ),
              const SizedBox(height: 32),

              // App Name
              Text(
                'OpenList',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'File Management',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : Colors.black54,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 48),

              // Loading indicator
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppDesign.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Status message
              Text(
                _statusMessage,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
