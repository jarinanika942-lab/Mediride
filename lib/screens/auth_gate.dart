import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_screen.dart';
import 'home_screen.dart';
import 'admin/admin_dashboard.dart';

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
        final session = snapshot.data?.session ??
            Supabase.instance.client.auth.currentSession;

        if (session == null) {
          return const LoginScreen();
        }

        return FutureBuilder<String?>(
          future: _getUserRole(),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (roleSnapshot.hasError) {
              return const Scaffold(
                body: Center(
                  child: Text('Unable to load user role.'),
                ),
              );
            }

            final role = roleSnapshot.data;

            if (role == 'patient') {
              return const HomeScreen();
            }

            if (role == 'admin') {
              return const AdminDashboard();
            }

            if (role == 'driver') {
              return const Scaffold(
                body: Center(
                  child: Text('Driver Dashboard Coming Soon'),
                ),
              );
            }

            return const Scaffold(
              body: Center(
                child: Text('Invalid user role.'),
              ),
            );
          },
        );
      },
    );
  }
}