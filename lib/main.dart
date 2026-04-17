import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/intro_screen.dart';
import 'screens/permission_screen.dart';
import 'screens/home_screen.dart';
import 'services/preferences_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load persisted preferences before the first frame
  await PreferencesService.instance.init();
  // Lock to portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // Force light status-bar icons on dark background
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));
  runApp(const PhotoSwiperApp());
}

class PhotoSwiperApp extends StatelessWidget {
  const PhotoSwiperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Swiper',
      debugShowCheckedModeBanner: false,

      // ── Pure dark theme ──────────────────────────────────────────────────────
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF6B4EFF),
          secondary: const Color(0xFF30D158),
          surface: const Color(0xFF1C1C1E),
          error: const Color(0xFFFF453A),
          onPrimary: Colors.white,
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D0D0D),
          surfaceTintColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),

      // ── Routes ───────────────────────────────────────────────────────────────
      initialRoute: '/intro',
      routes: {
        '/intro': (_) => const IntroScreen(),
        '/permission': (_) => const PermissionScreen(),
        '/home': (_) => const HomeScreen(),
      },
    );
  }
}
