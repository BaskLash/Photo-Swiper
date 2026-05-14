import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import '../services/analytics_events.dart';
import '../services/analytics_service.dart';
import '../services/preferences_service.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

// WidgetsBindingObserver lets us detect the app resuming after the user
// returns from the iOS Settings app so we can re-check without a tap.
class _PermissionScreenState extends State<PermissionScreen>
    with WidgetsBindingObserver {
  bool _requesting = false;
  bool _silentChecking = false;

  // True once the user has explicitly denied and we've shown the fallback.
  // Used to gate the Settings-return re-check so we don't fire it on every
  // unrelated app-resume event.
  bool _showDeniedFallback = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(AnalyticsService.instance.screen('permission_screen'));
    // On return launches, silently check permission to skip straight to home.
    if (PreferencesService.instance.hasSeenOnboarding) {
      _silentChecking = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _silentCheck());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ─── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the user comes back from the Settings app, silently re-check.
    // If they granted access → proceed automatically (no tap needed).
    // If still denied  → stay on the fallback screen; never auto-redirect again.
    if (state == AppLifecycleState.resumed && _showDeniedFallback) {
      _recheckAfterSettings();
    }
  }

  Future<void> _silentCheck() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      _goHome();
      return;
    }
    final ps = await PhotoManager.requestPermissionExtend();
    if (!mounted) return;
    if (ps.isAuth || ps.hasAccess) {
      _goHome();
    } else {
      setState(() {
        _silentChecking = false;
        _showDeniedFallback = true;
      });
    }
  }

  Future<void> _recheckAfterSettings() async {
    // photo_manager returns immediately if status is already determined —
    // no dialog is shown on this call.
    final ps = await PhotoManager.requestPermissionExtend();
    if (!mounted) return;
    if (ps.isAuth || ps.hasAccess) {
      unawaited(AnalyticsService.instance.track(
        AnalyticsEvents.photoPermissionGranted,
        properties: const {'source': 'settings_return'},
      ));
      _goHome();
    }
    // Still denied → do nothing; the user stays on the fallback screen.
    // This is what breaks the app ↔ Settings loop.
  }

  // ─── Permission request ───────────────────────────────────────────────────────

  Future<void> _requestPermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      _goHome();
      return;
    }

    setState(() {
      _requesting = true;
      _showDeniedFallback = false;
    });

    unawaited(AnalyticsService.instance.track(
      AnalyticsEvents.photoPermissionRequested,
    ));

    try {
      // photo_manager is already used throughout the app and correctly maps to
      // the native iOS PHPhotoLibrary API:
      //   • notDetermined → shows the native iOS permission dialog (once)
      //   • authorized / limited → returns immediately, no dialog shown
      //   • denied / restricted   → returns immediately, no dialog shown
      //
      // permission_handler incorrectly maps iOS "denied" to "permanentlyDenied"
      // after the very first denial, causing it to call openAppSettings()
      // automatically, which creates the app ↔ Settings loop.
      final ps = await PhotoManager.requestPermissionExtend();

      if (!mounted) return;

      if (ps.isAuth || ps.hasAccess) {
        unawaited(AnalyticsService.instance.track(
          AnalyticsEvents.photoPermissionGranted,
          properties: const {'source': 'prompt'},
        ));
        HapticFeedback.lightImpact();
        _goHome();
      } else {
        // Denied or restricted.
        // We NEVER auto-open Settings here — that is what caused the loop.
        // Instead, switch to the fallback view which has an explicit button.
        unawaited(AnalyticsService.instance.track(
          AnalyticsEvents.photoPermissionDenied,
        ));
        setState(() {
          _requesting = false;
          _showDeniedFallback = true;
        });
      }
    } catch (e) {
      unawaited(AnalyticsService.instance.track(
        AnalyticsEvents.errorOccurred,
        properties: {
          'error_type': e.runtimeType.toString(),
          'context': 'permission_request',
        },
      ));
      if (mounted) _goHome();
    }
  }

  void _openSettings() {
    // The WidgetsBindingObserver above will detect the return and re-check
    // automatically, so the user doesn't have to tap anything else.
    PhotoManager.openSetting();
  }

  void _goHome() => Navigator.pushReplacementNamed(context, '/home');

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_silentChecking) {
      return const Scaffold(backgroundColor: Color(0xFF0D0D0D));
    }

    if (!Platform.isAndroid && !Platform.isIOS) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goHome());
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
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _showDeniedFallback
                ? _DeniedView(
                    key: const ValueKey('denied'),
                    onOpenSettings: _openSettings,
                    onSkip: _goHome,
                  )
                : _RequestView(
                    key: const ValueKey('request'),
                    requesting: _requesting,
                    onContinue: _requestPermission,
                    onSkip: _goHome,
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Default view: explain + trigger native dialog ────────────────────────────

class _RequestView extends StatelessWidget {
  final bool requesting;
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  const _RequestView({
    super.key,
    required this.requesting,
    required this.onContinue,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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
          'Photo Library',
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
          'Photo Swiper uses your photo library\n'
          'to help you review and clean up your photos.\n\n'
          'Your media never leaves your device.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF8E8E93),
            fontSize: 16,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 56),

        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: requesting ? null : onContinue,
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
            child: requesting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),

        TextButton(
          onPressed: requesting ? null : onSkip,
          child: const Text(
            'Not now',
            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 16),
          ),
        ),
      ],
    );
  }
}

// ─── Fallback view: shown only after an explicit denial ──────────────────────
// Never triggered automatically — always requires the user to have tapped
// "Continue" first and received a denial from the iOS permission dialog.

class _DeniedView extends StatelessWidget {
  final VoidCallback onOpenSettings;
  final VoidCallback onSkip;

  const _DeniedView({
    super.key,
    required this.onOpenSettings,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFFFF453A).withOpacity(0.10),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.no_photography_rounded,
            size: 52,
            color: Color(0xFFFF453A),
          ),
        ),
        const SizedBox(height: 40),

        const Text(
          'Access Needed',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'To review and clean up your photos,\n'
          'Photo Swiper needs access to your library.\n\n'
          'In Settings → Privacy → Photos,\n'
          'set Photo Swiper to "All Photos".',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF8E8E93),
            fontSize: 15,
            height: 1.65,
          ),
        ),
        const SizedBox(height: 52),

        // Explicit user action — never called automatically
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: onOpenSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B4EFF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Open Settings',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 16),

        TextButton(
          onPressed: onSkip,
          child: const Text(
            'Continue without photos',
            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 15),
          ),
        ),
      ],
    );
  }
}
