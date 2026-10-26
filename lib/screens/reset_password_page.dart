

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_gate.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() =>
      _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _loading = false;
  bool _obscure = true;

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final supabase = Supabase.instance.client;

    // Check whether a valid recovery session exists.
    if (supabase.auth.currentSession == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Recovery session not found. Please open the '
            'latest password reset email link again.',
          ),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      await supabase.auth.updateUser(
        UserAttributes(
          password: _passwordController.text,
        ),
      );

      if (!mounted) return;

      await supabase.auth.signOut();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password updated. Please sign in with your new password.',
          ),
        ),
      );

      // Return to the authentication screen.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const AuthGate(),
        ),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password update failed. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Password'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_reset,
                    size: 68,
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Choose a new password',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'New password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscure = !_obscure;
                          });
                        },
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.length < 8) {
                        return 'Use at least 8 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm new password',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _updatePassword,
                      child: _loading
                          ? const CircularProgressIndicator()
                          : const Text('Update Password'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
