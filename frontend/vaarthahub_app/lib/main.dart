import 'dart:io';
import 'package:flutter/material.dart';
import 'screens/onboarding/onboarding_screen.dart'; 

// SSL Certificate validation bypass ( Development time only - Remove in Production! )
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  // SSL Certificate validation bypass for development (Remove this in production!)
  HttpOverrides.global = MyHttpOverrides();
  runApp(const VaarthaHubApp());
}

class VaarthaHubApp extends StatelessWidget {
  const VaarthaHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VaarthaHub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins', 
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF16AFD1)),
        useMaterial3: true,
      ),
      home: const OnboardingScreen(), 
    );
  }
}