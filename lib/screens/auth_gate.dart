import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_screen.dart';
import 'home_screen.dart';
//import 'driver_home_screen.dart';
//import 'admin_dashboard.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<String?> _getUserRole() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return null;
    }

    final profile = await Supabase.instance.client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single();

    return profile['role'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session =
            snapshot.data?.session ??
            Supabase.instance.client.auth.currentSession;

        // User is not logged in
        if (session == null) {
          return const LoginScreen();
        }

        // User is logged in
        return FutureBuilder<String?>(
          future: _getUserRole(),
          builder: (context, roleSnapshot) {
            // Loading role
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // Error while getting role
            if (roleSnapshot.hasError) {
              return const Scaffold(
                body: Center(child: Text('Unable to load user role.')),
              );
            }

            final role = roleSnapshot.data;

            // Patient
            if (role == 'patient') {
              return const HomeScreen();
            }

            // Driver
            if (role == 'driver') {
              // return const DriverHomeScreen();
            }

            // Admin
            if (role == 'admin') {
              //  return const AdminDashboard();
            }

            // Unknown role
            return const Scaffold(
              body: Center(child: Text('Invalid user role.')),
            );
          },
        );
      },
    );
  }
}