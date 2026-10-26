import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_gate.dart';
import 'register_screen.dart';
import 'driver_registration_screen.dart';
import 'forgot_password_page.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ================= CONTROLLERS =================

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  // ================= STATES =================

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  // ================= DISPOSE =================

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    _emailFocus.dispose();
    _passwordFocus.dispose();

    super.dispose();
  }

  // ================= LOGIN =================

  Future<void> _login() async {
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // ================= SUPABASE LOGIN =================

      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      // ================= LOGIN SUCCESS =================

      if (response.user != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthGate()),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;

      String message = e.message;

      if (e.message.toLowerCase().contains('invalid login')) {
        message = 'Invalid email or password.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  // ================= GOOGLE LOGIN =================

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: Uri.base.origin,
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google login failed. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  // ================= EMAIL VALIDATION =================

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // ================= PASSWORD VALIDATION =================

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  // ================= FORGOT PASSWORD =================


void _forgotPassword() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const ForgotPasswordPage(),
    ),
  );
}


  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
          // BACKGROUND OVERLAY
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
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 25,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    children: [
                      // ==================================================
                      // APP LOGO
                      // ==================================================
                      Container(
                        height: 72,
                        width: 72,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.local_hospital_rounded,
                          size: 38,
                          color: Color(0xFF2563EB),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ==================================================
                      // APP NAME
                      // ==================================================
                      const Text(
                        'MediRide',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 29,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),

                      const SizedBox(height: 4),

                      const Text(
                        'Emergency Ambulance Service',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      const SizedBox(height: 22),

                      // ==================================================
                      // LOGIN CARD
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ==================================================
                              // TITLE
                              // ==================================================
                              const Text(
                                'Welcome back',
                                style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF173B6B),
                                ),
                              ),

                              const SizedBox(height: 5),

                              const Text(
                                'Sign in to access your MediRide account.',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: Colors.black54,
                                ),
                              ),

                              const SizedBox(height: 23),

                              // ==================================================
                              // EMAIL LABEL
                              // ==================================================
                              const Text(
                                'Email address',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF263238),
                                ),
                              ),

                              const SizedBox(height: 7),

                              // ==================================================
                              // EMAIL FIELD
                              // ==================================================
                              TextFormField(
                                controller: _emailController,
                                focusNode: _emailFocus,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                validator: _validateEmail,
                                onFieldSubmitted: (_) {
                                  FocusScope.of(
                                    context,
                                  ).requestFocus(_passwordFocus);
                                },
                                decoration: InputDecoration(
                                  hintText: 'you@example.com',
                                  prefixIcon: const Icon(
                                    Icons.email_outlined,
                                    size: 21,
                                    color: Color(0xFF2563EB),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF5F7FB),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 16,
                                  ),
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
                                    borderSide: const BorderSide(
                                      color: Color(0xFF2563EB),
                                      width: 1.4,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: Colors.redAccent,
                                      width: 1.2,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 17),

                              // ==================================================
                              // PASSWORD LABEL
                              // ==================================================
                              const Text(
                                'Password',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF263238),
                                ),
                              ),

                              const SizedBox(height: 7),

                              // ==================================================
                              // PASSWORD FIELD
                              // ==================================================
                              TextFormField(
                                controller: _passwordController,
                                focusNode: _passwordFocus,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                validator: _validatePassword,
                                onFieldSubmitted: (_) {
                                  _login();
                                },
                                decoration: InputDecoration(
                                  hintText: 'Enter your password',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                    size: 21,
                                    color: Color(0xFF2563EB),
                                  ),
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
                                  filled: true,
                                  fillColor: const Color(0xFFF5F7FB),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 16,
                                  ),
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
                                    borderSide: const BorderSide(
                                      color: Color(0xFF2563EB),
                                      width: 1.4,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: Colors.redAccent,
                                      width: 1.2,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              // ==================================================
                              // REMEMBER ME + FORGOT PASSWORD
                              // ==================================================
                              Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: Checkbox(
                                            value: _rememberMe,
                                            activeColor: const Color(
                                              0xFF2563EB,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                            onChanged: (value) {
                                              setState(() {
                                                _rememberMe = value ?? false;
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          'Remember me',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  TextButton(
                                    onPressed: _forgotPassword,
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Forgot password?',
                                      style: TextStyle(
                                        color: Color(0xFF2563EB),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // ==================================================
                              // LOGIN BUTTON
                              // ==================================================
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _login,
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
                                          height: 22,
                                          width: 22,
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
                                              'Sign in',
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

                              const SizedBox(height: 20),

                              // ================= SOCIAL LOGIN DIVIDER =================
                              Row(
                                children: [
                                  const Expanded(child: Divider()),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      'OR CONTINUE WITH',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                  const Expanded(child: Divider()),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // ================= GOOGLE LOGIN BUTTON =================
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: OutlinedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : _signInWithGoogle,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF202124),
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: Color(0xFFD7DFEA),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.g_mobiledata,
                                        size: 30,
                                        color: Color(0xFF4285F4),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Continue with Google',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // ==================================================
                              // PATIENT REGISTRATION
                              // ==================================================
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'New to MediRide?',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const RegisterScreen(),
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
                                      'Create Patient Account',
                                      style: TextStyle(
                                        color: Color(0xFF2563EB),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // ==================================================
                              // DRIVER REGISTRATION
                              // ==================================================
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Are you a driver?',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  TextButton(
                                    onPressed: () {
                                      // Driver registration screen
                                      // will be connected here later.

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const DriverRegistrationScreen(),
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
                                      'Apply as Driver',
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
                      ),

                      const SizedBox(height: 17),

                      // ==================================================
                      // SECURITY MESSAGE
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
                            'Your information is protected',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 5),

                      Text(
                        'MediRide • Emergency care when you need it',
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