import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _requesting = false;

  Future<void> _requestPermission() async {
    // Non-mobile platforms skip straight to home
    if (!Platform.isAndroid && !Platform.isIOS) {
      _goHome();
      return;
    }

    setState(() => _requesting = true);

    try {
      final status = await Permission.photos.request();

      if (!mounted) return;

      if (status.isGranted || status.isLimited) {
        HapticFeedback.lightImpact();
        _goHome();
      } else if (status.isPermanentlyDenied) {
        await openAppSettings();
        setState(() => _requesting = false);
      } else {
        // Denied but not permanent — still let them continue
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Gallery access denied. Some features won\'t work.',
            ),
            backgroundColor: const Color(0xFF2C2C2E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        _goHome();
      }
    } catch (_) {
      if (mounted) _goHome();
    }
  }

  void _goHome() =>
      Navigator.pushReplacementNamed(context, '/home');

  @override
  Widget build(BuildContext context) {
    // Auto-skip on non-mobile
    if (!Platform.isAndroid && !Platform.isIOS) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _goHome());
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D0D),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF6B4EFF).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.photo_library_rounded,
                  size: 56,
                  color: Color(0xFF6B4EFF),
                ),
              ),
              const SizedBox(height: 40),

              const Text(
                'Access Your\nPhoto Library',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Photo Swiper needs access to your gallery\nto help you review and clean up your photos.\n\nYour media never leaves your device.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 56),

              // Grant button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _requesting ? null : _requestPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B4EFF),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        const Color(0xFF6B4EFF).withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _requesting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          'Allow Access',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Skip
              TextButton(
                onPressed: _requesting ? null : _goHome,
                child: const Text(
                  'Not now',
                  style: TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
