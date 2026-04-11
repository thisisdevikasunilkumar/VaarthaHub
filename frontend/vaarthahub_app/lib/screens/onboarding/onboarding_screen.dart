import 'package:flutter/material.dart';

import 'package:vaarthahub_app/screens/auth/register_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

// Custom Clipper
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(size.width / 4, size.height, size.width / 2.25, size.height - 40);
    path.quadraticBezierTo(size.width - (size.width / 3.24), size.height - 95, size.width, size.height - 20);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// 🟡 Yellow Curve Painter
class YellowCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFFF9C55E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    final Path path = Path();
    path.moveTo(0, size.height / 2);
    path.quadraticBezierTo(size.width * 0.25, size.height, size.width * 0.5, size.height / 2);
    path.quadraticBezierTo(size.width * 0.75, 0, size.width, size.height / 2);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      "title": "Smart Panchayat-Level\nNewspaper Distribution and\nPredictive Analytics System",
      "desc": "",
      "image": "assets/onboarding/slide1.png" 
    },
    {
      "title": "Smart Subscriptions",
      "desc": "Manage multiple newspapers, pause for vacations, and chat with our AI assistant in Malayalam for all your billing needs.",
      "image": "assets/onboarding/slide2.png"
    },
    {
      "title": "Community & Announcements",
      "desc": "Book local ads instantly, swap magazines with neighbors, and showcase your creativity in the Reader's Corner.",
      "image": "assets/onboarding/slide3.png"
    },    
    {
      "title": "Eco-Friendly Scrap Pickup",
      "desc": "Turn your old newspapers into earnings. We predict when your scrap is ready and pick it up right from your doorstep.",
      "image": "assets/onboarding/slide4.png"
    },
    {
      "title": "Smart Delivery",
      "desc": "AI-powered route optimization ensures your newspaper arrives on time, every time, while saving fuel and effort.",
      "image": "assets/onboarding/slide5.png"
    },    
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Background Decorative Element (Visible after Page 0)
          if (_currentPage != 0)
            Positioned(
              top: 330,
              left: 0,
              right: 0,
              child: Image.asset(
                'assets/onboarding/Element1.png',
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.fitWidth,
              ),
            ),

          PageView.builder(
            controller: _controller,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              if (index == 0) {
                // --- FIRST PAGE (Unique Layout with Wave Clipper) ---
                return Stack(
                  children: [
                    Column(
                      children: [
                        ClipPath(
                          clipper: WaveClipper(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.45,
                            width: double.infinity,
                            child: Image.asset(_pages[index]['image']!, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(height: 60),
                        Image.asset('assets/logo/vaarthaHub-resolution-logo.png', height: 50),
                        const SizedBox(height: 30),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Text(
                            _pages[index]['title']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 79,
                      left: 0,
                      right: 0,
                      child: SizedBox(
                        height: 40,
                        child: CustomPaint(
                          painter: YellowCurvePainter(),
                        ),
                      ),
                    ),
                  ],
                );
              }

              // --- OTHER PAGES (Feature Screens) ---
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _pages[index]['title']!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      height: MediaQuery.of(context).size.height * 0.28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(
                          image: AssetImage(_pages[index]['image']!), 
                          fit: BoxFit.contain
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      _pages[index]['desc']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[800], height: 1.5),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              );
            },
          ),

          // 2. Bottom Navigation Controls (Fixed at bottom)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              decoration: const BoxDecoration(
                color: Color(0xFFF2F3F7),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      // INI LOGIN/REGISTER SCREEN
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                    },
                    child: const Text("Skip", style: TextStyle(color: Colors.black, fontSize: 16)),
                  ),
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? const Color(0xFF16AFD1) : Colors.grey[400],
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 500), 
                          curve: Curves.easeInOut
                        );
                      } else {
                        // INI LOGIN/REGISTER SCREEN
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                      }
                    },
                    child: const Text("Next", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
