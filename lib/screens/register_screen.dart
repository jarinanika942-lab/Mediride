import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // ==================================================
  // CONTROLLERS
  // ==================================================

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // ==================================================
  // STATE
  // ==================================================

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // ==================================================
  // DISPOSE
  // ==================================================

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  // ==================================================
  // REGISTER
  // ==================================================

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // ------------------------------------------------
    // VALIDATION
    // ------------------------------------------------

    if (name.isEmpty) {
      _showMessage('Please enter your full name.');
      return;
    }

    if (email.isEmpty) {
      _showMessage('Please enter your email address.');
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (!emailRegex.hasMatch(email)) {
      _showMessage('Please enter a valid email address.');
      return;
    }

    if (phone.isEmpty) {
      _showMessage('Please enter your phone number.');
      return;
    }

    if (password.isEmpty) {
      _showMessage('Please create a password.');
      return;
    }

    if (password.length < 6) {
      _showMessage('Password must be at least 6 characters.');
      return;
    }

    if (confirmPassword.isEmpty) {
      _showMessage('Please confirm your password.');
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Passwords do not match.');
      return;
    }

    // ------------------------------------------------
    // START LOADING
    // ------------------------------------------------

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      // ==================================================
      // SUPABASE AUTH SIGN UP
      // ==================================================

      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,

        // User information is also stored as metadata.
        data: {'full_name': name, 'phone': phone},
      );

      if (!mounted) return;

      // ==================================================
      // CHECK USER
      // ==================================================

      if (response.user == null) {
        _showMessage('Registration failed. Please try again.');
        return;
      }

      // ==================================================
      // PROFILE CREATION
      // ==================================================

      /*
       * If Supabase email confirmation is disabled,
       * a session will be available immediately.
       *
       * In that case we can insert the profile directly.
       */

      await Supabase.instance.client.from('profiles').insert({
        'id': response.user!.id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': 'patient',
      });

      if (!mounted) return;

      // ==================================================
      // SUCCESS
      // ==================================================

      if (response.session == null) {
        // Email confirmation is enabled.
        _showMessage(
          'Account created! Please check your email to verify your account.',
        );
      } else {
        _showMessage('Account created successfully!');
      }

      // Go to Login
      await Future.delayed(const Duration(milliseconds: 700));

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      _showMessage('Auth Error: ${e.message}');
    } catch (e) {
      if (!mounted) return;

      _showMessage('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ==================================================
  // MESSAGE
  // ==================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // ==================================================
  // INPUT DECORATION
  // ==================================================

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,

      prefixIcon: Icon(icon, size: 21, color: const Color(0xFF2563EB)),

      suffixIcon: suffixIcon,

      filled: true,
      fillColor: const Color(0xFFF5F7FB),

      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.4),
      ),
    );
  }

  // ==================================================
  // BUILD
  // ==================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),

      body: Stack(
        children: [
          // ==================================================
          // BACKGROUND IMAGE
          // ==================================================
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_background.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // ==================================================
          // BLUE OVERLAY
          // ==================================================
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0F3B78).withOpacity(0.25),
                    const Color(0xFF0F3B78).withOpacity(0.88),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),

          // ==================================================
          // MAIN CONTENT
          // ==================================================
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),

              padding: const EdgeInsets.fromLTRB(22, 5, 22, 25),

              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),

                  child: Column(
                    children: [
                      // ==================================================
                      // LOGO
                      // ==================================================
                      Container(
                        height: 68,
                        width: 68,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 18,
                              offset: const Offset(0, 7),
                            ),
                          ],
                        ),

                        child: const Icon(
                          Icons.local_hospital_rounded,
                          size: 35,
                          color: Color(0xFF2563EB),
                        ),
                      ),

                      const SizedBox(height: 14),

                      const Text(
                        "Create Account",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        "Create your MediRide account",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13.5, color: Colors.white70),
                      ),

                      const SizedBox(height: 22),

                      // ==================================================
                      // REGISTER CARD
                      // ==================================================
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),

                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.22),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            // ==================================================
                            // FULL NAME
                            // ==================================================
                            const Text(
                              "Full Name",
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF263238),
                              ),
                            ),

                            const SizedBox(height: 7),

                            TextField(
                              controller: _nameController,
                              textInputAction: TextInputAction.next,
                              decoration: _inputDecoration(
                                hintText: "Enter your full name",
                                icon: Icons.person_outline_rounded,
                              ),
                            ),

                            const SizedBox(height: 17),

                            // ==================================================
                            // EMAIL
                            // ==================================================
                            const Text(
                              "Email Address",
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF263238),
                              ),
                            ),

                            const SizedBox(height: 7),

                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: _inputDecoration(
                                hintText: "you@example.com",
                                icon: Icons.email_outlined,
                              ),
                            ),

                            const SizedBox(height: 17),

                            // ==================================================
                            // PHONE
                            // ==================================================
                            const Text(
                              "Phone Number",
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF263238),
                              ),
                            ),

                            const SizedBox(height: 7),

                            TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              decoration: _inputDecoration(
                                hintText: "Enter your phone number",
                                icon: Icons.phone_outlined,
                              ),
                            ),

                            const SizedBox(height: 17),

                            // ==================================================
                            // PASSWORD
                            // ==================================================
                            const Text(
                              "Password",
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF263238),
                              ),
                            ),

                            const SizedBox(height: 7),

                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.next,

                              decoration: _inputDecoration(
                                hintText: "Create a password",
                                icon: Icons.lock_outline_rounded,
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 21,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 17),

                            // ==================================================
                            // CONFIRM PASSWORD
                            // ==================================================
                            const Text(
                              "Confirm Password",
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF263238),
                              ),
                            ),

                            const SizedBox(height: 7),

                            TextField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,

                              textInputAction: TextInputAction.done,

                              onSubmitted: (_) {
                                if (!_isLoading) {
                                  _register();
                                }
                              },

                              decoration: _inputDecoration(
                                hintText: "Confirm your password",
                                icon: Icons.lock_outline_rounded,
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 21,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 25),

                            // ==================================================
                            // CREATE ACCOUNT BUTTON
                            // ==================================================
                            SizedBox(
                              width: double.infinity,
                              height: 54,

                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _register,

                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),

                                  disabledBackgroundColor: const Color(
                                    0xFF93B4F5,
                                  ),

                                  foregroundColor: Colors.white,

                                  elevation: 2,

                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),

                                child: _isLoading
                                    ? const SizedBox(
                                        height: 23,
                                        width: 23,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Create Account",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                              ),
                            ),

                            const SizedBox(height: 19),

                            // ==================================================
                            // LOGIN
                            // ==================================================
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,

                              children: [
                                const Text(
                                  "Already have an account?",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),

                                const SizedBox(width: 3),

                                TextButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const LoginScreen(),
                                      ),
                                    );
                                  },

                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 4,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),

                                  child: const Text(
                                    "Login",
                                    style: TextStyle(
                                      color: Color(0xFF2563EB),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 17),

                      // ==================================================
                      // SECURITY
                      // ==================================================
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 15,
                            color: Colors.white.withOpacity(0.75),
                          ),

                          const SizedBox(width: 6),

                          Text(
                            "Your information is protected",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 5),

                      Text(
                        "MediRide • Emergency care when you need it",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}