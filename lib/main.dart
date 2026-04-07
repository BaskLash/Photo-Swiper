import 'package:flutter/material.dart';
import 'package:intro_slider/intro_slider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'second_page.dart';           // falls du sie noch brauchst

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PhotoSwiper',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/intro',
      routes: {
        '/intro': (context) => const IntroScreen(),
        '/permission': (context) => const PermissionScreen(),
        '/home': (context) => const HomeScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

// ====================== INTRO & PERMISSION (unverändert) ======================
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});
  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final List<ContentConfig> listContentConfig = [];

  @override
  void initState() {
    super.initState();
    listContentConfig.addAll([
      ContentConfig(
        title: "Willkommen bei PhotoSwiper",
        description: "Entdecke eine neue Art, durch deine Fotos zu swipen.",
        pathImage: "assets/images/intro1.png",
        backgroundColor: const Color(0xFF1E88E5),
        styleTitle: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
        styleDescription: const TextStyle(color: Colors.white70, fontSize: 17),
      ),
      ContentConfig(
        title: "Flüssig swipen",
        description: "Wische einfach nach links oder rechts – intuitiv und schön.",
        pathImage: "assets/images/intro2.png",
        backgroundColor: const Color(0xFF43A047),
        styleTitle: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
        styleDescription: const TextStyle(color: Colors.white70, fontSize: 17),
      ),
      ContentConfig(
        title: "Los geht's!",
        description: "Bereit für dein neues Foto-Erlebnis?",
        pathImage: "assets/images/intro3.png",
        backgroundColor: const Color(0xFF8E24AA),
        styleTitle: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
        styleDescription: const TextStyle(color: Colors.white70, fontSize: 17),
      ),
    ]);
  }

  void onDonePress() => Navigator.pushReplacementNamed(context, '/permission');
  void onSkipPress() => Navigator.pushReplacementNamed(context, '/permission');

  @override
  Widget build(BuildContext context) {
    return IntroSlider(
      listContentConfig: listContentConfig,
      onDonePress: onDonePress,
      onSkipPress: onSkipPress,
      isShowSkipBtn: true,
      renderSkipBtn: const Text("Überspringen", style: TextStyle(color: Colors.white)),
      renderNextBtn: const Icon(Icons.arrow_forward, color: Colors.white, size: 30),
      renderDoneBtn: const Icon(Icons.check, color: Colors.white, size: 30),
    );
  }
}

class PermissionScreen extends StatelessWidget {
  const PermissionScreen({super.key});

  Future<void> _requestPhotoPermission(BuildContext context) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      if (context.mounted) Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    try {
      final status = await Permission.photos.request();
      if (status.isGranted || status.isLimited) {
        if (context.mounted) Navigator.pushReplacementNamed(context, '/home');
      } else if (status.isPermanentlyDenied) {
        if (context.mounted) openAppSettings();
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Du kannst die Berechtigung später ändern.')),
          );
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (_) {
      if (context.mounted) Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid && !Platform.isIOS) {
      WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.pushReplacementNamed(context, '/home'));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.photo_library_outlined, size: 100, color: Colors.deepPurple),
              const SizedBox(height: 40),
              const Text("Deine Fotos einlesen?", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              const Text(
                "Damit du durch deine Bilder swipen kannst, benötigt PhotoSwiper Zugriff auf deine Foto-Bibliothek.\n\n"
                "Du kannst das jederzeit in den Geräte-Einstellungen ändern.",
                style: TextStyle(fontSize: 17, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: () => _requestPhotoPermission(context),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56), backgroundColor: Colors.deepPurple),
                child: const Text("Ja, alle Fotos einlesen", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                child: const Text("Nein, später entscheiden"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ====================== NEUE HAUPTSEITE ======================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<String> monthNames = [
    "Januar", "Februar", "März", "April", "Mai", "Juni",
    "Juli", "August", "September", "Oktober", "November", "Dezember"
  ];

  static const List<Color> monthColors = [
    Colors.red,
    Colors.orange,
    Colors.amber,
    Colors.green,
    Colors.teal,
    Colors.cyan,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
    Colors.pink,
    Colors.brown,
    Color(0xFF757575),        // Ersatz für Colors.grey.shade700
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PhotoSwiper"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // TODAY
            _buildBigCard(
              context,
              title: "Today",
              subtitle: "Bilder vom heutigen Tag",
              icon: Icons.today,
              gradient: const LinearGradient(colors: [Color(0xFF8E24AA), Color(0xFFBA68C8)]),
              onTap: () => _goToSwipePage(context, mode: 'today'),
            ),

            // RANDOM
            _buildBigCard(
              context,
              title: "Random",
              subtitle: "Zufällige Bilder aus deiner Bibliothek",
              icon: Icons.shuffle,
              gradient: const LinearGradient(colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)]),
              onTap: () => _goToSwipePage(context, mode: 'random'),
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Monate", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
            ),

            // MONATE
            ...List.generate(12, (index) {
              return _buildMonthCard(
                context,
                monthName: monthNames[index],
                color: monthColors[index],
                onTap: () => _goToSwipePage(context, mode: 'month', monthIndex: index + 1),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBigCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        height: 160,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 58, color: Colors.white),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 6),
                    Text(subtitle, style: const TextStyle(fontSize: 16, color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthCard(
    BuildContext context, {
    required String monthName,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        height: 110,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Center(
          child: Text(
            monthName.toUpperCase(),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
          ),
        ),
      ),
    );
  }

    void _goToSwipePage(BuildContext context, {required String mode, int? monthIndex}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SecondPage(
          mode: mode,
          monthIndex: monthIndex,
        ),
      ),
    );
  }
}

// ====================== SWIPE PAGE ======================
class SwipePage extends StatelessWidget {
  final String mode;
  final int? monthIndex;

  const SwipePage({super.key, required this.mode, this.monthIndex});

  @override
  Widget build(BuildContext context) {
    String title = "Fotos";

    if (mode == 'today') {
      title = "Today";
    } else if (mode == 'random') {
      title = "Random";
    } else if (mode == 'month' && monthIndex != null) {
  final months = HomeScreen.monthNames;
  final int index = monthIndex!; // <- FIX: explizit non-null
  title = months[index - 1];
}

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.deepPurple,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            "Hier kommt später die Swiping-Ansicht mit deinen Fotos.\n\n"
            "• Nach links wischen → In den Papierkorb\n"
            "• Nach rechts wischen → Behalten",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, height: 1.6),
          ),
        ),
      ),
    );
  }
}