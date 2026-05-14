import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/analytics_service.dart';
import '../services/preferences_service.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  static const _pages = [
    _SlideData(
      icon: Icons.auto_delete_rounded,
      iconColor: Color(0xFF6B4EFF),
      title: 'Clean Your\nGallery',
      subtitle:
          'Stop scrolling through thousands of photos.\nSwipe to keep or delete — effortlessly.',
    ),
    _SlideData(
      icon: Icons.swipe_rounded,
      iconColor: Color(0xFF30D158),
      title: 'Swipe to\nDecide',
      subtitle:
          'Swipe right to keep.\nSwipe left to delete.\nNot sure? Tap the center button to review later.',
    ),
    _SlideData(
      icon: Icons.storage_rounded,
      iconColor: Color(0xFFFFD60A),
      title: 'Free Up\nSpace',
      subtitle:
          'Review your picks before anything is deleted.\nSee exactly how much storage you\'ll reclaim.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    unawaited(AnalyticsService.instance.screen('intro_screen'));
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      );
    } else {
      _goToPermission();
    }
  }

  void _goToPermission() {
    HapticFeedback.lightImpact();
    PreferencesService.instance.setHasSeenOnboarding(true);
    Navigator.pushReplacementNamed(context, '/permission');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _goToPermission,
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            // Slides
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _SlidePage(data: _pages[i]),
              ),
            ),

            // Dots + button
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
              child: Column(
                children: [
                  // Page indicator dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _currentPage ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _currentPage
                              ? const Color(0xFF6B4EFF)
                              : const Color(0xFF3A3A3C),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // CTA button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B4EFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage < _pages.length - 1
                            ? 'Continue'
                            : 'Get Started',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Slide data model ─────────────────────────────────────────────────────────

class _SlideData {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _SlideData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });
}

// ─── Individual slide page ────────────────────────────────────────────────────

class _SlidePage extends StatelessWidget {
  final _SlideData data;
  const _SlidePage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon blob
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: data.iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.icon,
              size: 68,
              color: data.iconColor,
            ),
          ),
          const SizedBox(height: 48),

          // Title
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w700,
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),

          // Subtitle
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 17,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
