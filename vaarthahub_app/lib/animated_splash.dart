import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/delivery/delivery_home_screen.dart';
import 'screens/reader/reader_home_screen.dart';

class AnimatedSplash extends StatefulWidget {
  const AnimatedSplash({super.key});

  @override
  State<AnimatedSplash> createState() => _AnimatedSplashState();
}

class _AnimatedSplashState extends State<AnimatedSplash> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // 1. Splash Screen kurachu neram (3 seconds) kaanikkan vendi wait cheyyunnu
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // 2. Local memory-il ninnu login status edukkunnu.
      // Key illengil default aayi 'false' edukkum.
      final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final String? role = prefs.getString('userRole');

      if (isLoggedIn && role != null) {
        // 3. User logout cheyithittillengil direct Dashboard-ilekk vidunnu
        Widget dashboard;
        if (role == "Admin") {
          dashboard = const AdminDashboard();
        } else if (role == "DeliveryPartner") {
          dashboard = const DeliveryHomeScreen();
        } else {
          dashboard = const ReaderHomeScreen();
        }

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => dashboard),
            (route) => false, // Splash Screen-ilekk thirichu varaan pattilla
          );
        }
      } else {
        // 4. Logout aayittundo allengil puthiya user aanengil Onboarding kaanikkanam
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        }
      }
    } catch (e) {
      debugPrint("Error checking login status: $e");
      // Safety-kku vendi error vannalum Onboarding-ilekk navigate cheyyunnu
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9C55E), // Theme-inulla yellow color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo load cheyyunnu
            Image.asset(
              "assets/logo/vaarthaHub-logo.png",
              width: 150,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.newspaper, size: 80),
            ),
          ],
        ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), curve: Curves.easeOutBack),
      ),
    );
  }
}
