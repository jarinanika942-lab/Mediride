import 'dart:async';

import 'package:flutter/material.dart';
//import 'login_screen.dart';
import 'auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    _checkAuthentication();
  }

  // ==================================================
  // CHECK AUTHENTICATION
  // ==================================================

  Future<void> _checkAuthentication() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthGate()),
    );
  }

  // ==================================================
  // BUILD
  // ==================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ==================================================
          // BACKGROUND IMAGE
          // ==================================================
          Image.asset(
            'assets/images/ambulance picture.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          // ==================================================
          // DARK OVERLAY
          // ==================================================
          Container(
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.55)),
          ),

          // ==================================================
          // MAIN CONTENT
          // ==================================================
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                // ==================================================
                // LOGO
                // ==================================================
                Container(
                  height: 120,
                  width: 120,

                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),

                  child: const Icon(
                    Icons.local_hospital,
                    size: 65,
                    color: Color(0xFF2E7D32),
                  ),
                ),

                const SizedBox(height: 25),

                // ==================================================
                // APP NAME
                // ==================================================
                const Text(
                  "MediRide",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 10),

                // ==================================================
                // TAGLINE
                // ==================================================
                const Text(
                  "Your Emergency, Our Priority",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 50),

                // ==================================================
                // LOADING
                // ==================================================
                const SizedBox(
                  height: 28,
                  width: 28,

                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 15),

                const Text(
                  "Getting things ready...",
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}