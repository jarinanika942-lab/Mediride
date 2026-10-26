import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';

class DriverRegistrationScreen extends StatefulWidget {
  const DriverRegistrationScreen({super.key});

  @override
  State<DriverRegistrationScreen> createState() =>
      _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  static const Color navy = Color(0xFF0F2F5F);

  static const Color blue = Color(0xFF2563EB);

  static const Color background = Color(0xFFF4F7FC);

  static const Color textDark = Color(0xFF1E293B);

  static const Color textMuted = Color(0xFF64748B);

  static const Color border = Color(0xFFE2E8F0);

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();

  final _emailController = TextEditingController();

  final _phoneController = TextEditingController();

  final _passwordController = TextEditingController();

  final _confirmPasswordController = TextEditingController();

  final _licenseController = TextEditingController();

  final _nidController = TextEditingController();

  final _vehicleController = TextEditingController();

  final SupabaseClient supabase = Supabase.instance.client;

  String _selectedAmbulanceType = 'Normal';

  bool _isLoading = false;

  bool _obscurePassword = true;

  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();

    _emailController.dispose();

    _phoneController.dispose();

    _passwordController.dispose();

    _confirmPasswordController.dispose();

    _licenseController.dispose();

    _nidController.dispose();

    _vehicleController.dispose();

    super.dispose();
  }

  Future<void> _submitDriverApplication() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      _showMessage('Passwords do not match.', isError: true);

      return;
    }

    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      // Create the driver's authentication account.

      final AuthResponse response = await supabase.auth.signUp(
        email: _emailController.text.trim(),

        password: _passwordController.text,
      );

      final user = response.user;

      if (user == null) {
        throw Exception('Unable to create driver account.');
      }

      // Do not set profiles.role to "driver" here.

      // The application remains pending until an admin approves it.

      await supabase.from('driver_applications').insert({
        'user_id': user.id,

        'full_name': _nameController.text.trim(),

        'email': _emailController.text.trim(),

        'phone': _phoneController.text.trim(),

        'license_number': _licenseController.text.trim(),

        'nid_number': _nidController.text.trim(),

        'vehicle_number': _vehicleController.text.trim(),

        'ambulance_type': _selectedAmbulanceType,

        'status': 'pending',
      });

      if (!mounted) return;

      setState(() => _isLoading = false);

      await _showSuccessDialog();
    } on AuthException catch (error) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      _showMessage(error.message, isError: true);
    } on PostgrestException catch (error) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      _showMessage(
        'Application could not be submitted.\n${error.message}',

        isError: true,
      );
    } catch (error) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      _showMessage(
        error is Exception
            ? error.toString().replaceFirst('Exception: ', '')
            : 'Something went wrong. Please try again.',

        isError: true,
      );
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),

        behavior: SnackBarBehavior.floating,

        backgroundColor: isError
            ? const Color(0xFFDC2626)
            : const Color(0xFF15803D),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _showSuccessDialog() async {
    await showDialog<void>(
      context: context,

      barrierDismissible: false,

      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,

        surfaceTintColor: Colors.white,

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),

        contentPadding: const EdgeInsets.fromLTRB(26, 30, 26, 24),

        content: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Container(
              height: 76,

              width: 76,

              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),

                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.check_circle_rounded,

                size: 48,

                color: Color(0xFF16A34A),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Application Submitted',

              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 21,

                fontWeight: FontWeight.w800,

                color: navy,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Your driver application has been submitted successfully. '
              'Our admin team will review your information. Your driver '
              'account will become active after approval.',

              textAlign: TextAlign.center,

              style: TextStyle(fontSize: 13.5, height: 1.55, color: textMuted),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,

              height: 50,

              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);

                  await Supabase.instance.client.auth.signOut();

                  if (!mounted) return;

                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,

                  foregroundColor: Colors.white,

                  elevation: 0,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),

                child: const Text(
                  'Back to Login',

                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader({
    required IconData icon,

    required String title,

    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Container(
          height: 44,

          width: 44,

          decoration: BoxDecoration(
            color: const Color(0xFFEEF4FF),

            borderRadius: BorderRadius.circular(13),
          ),

          child: Icon(icon, color: blue, size: 22),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                title,

                style: const TextStyle(
                  color: navy,

                  fontSize: 16,

                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                subtitle,

                style: const TextStyle(
                  color: textMuted,

                  fontSize: 12.5,

                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: const Color(0xFFEAF0F7)),

        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16345A).withOpacity(0.045),

            blurRadius: 22,

            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: child,
    );
  }

  Widget _field({
    required TextEditingController controller,

    required String label,

    required String hint,

    required IconData icon,

    String? Function(String?)? validator,

    TextInputType keyboardType = TextInputType.text,

    bool obscureText = false,

    Widget? suffixIcon,

    TextCapitalization textCapitalization = TextCapitalization.none,

    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          label,

          style: const TextStyle(
            color: textDark,

            fontSize: 13,

            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 8),

        TextFormField(
          controller: controller,

          validator: validator,

          keyboardType: keyboardType,

          obscureText: obscureText,

          textCapitalization: textCapitalization,

          textInputAction: textInputAction,

          style: const TextStyle(
            fontSize: 14,

            color: textDark,

            fontWeight: FontWeight.w500,
          ),

          decoration: InputDecoration(
            hintText: hint,

            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),

            prefixIcon: Icon(icon, color: const Color(0xFF647CA0), size: 20),

            suffixIcon: suffixIcon,

            filled: true,

            fillColor: const Color(0xFFF8FAFD),

            isDense: true,

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,

              vertical: 16,
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),

              borderSide: const BorderSide(color: border),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),

              borderSide: const BorderSide(color: border),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),

              borderSide: const BorderSide(color: blue, width: 1.5),
            ),

            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),

              borderSide: const BorderSide(color: Color(0xFFDC2626)),
            ),

            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),

              borderSide: const BorderSide(
                color: Color(0xFFDC2626),

                width: 1.3,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String? _required(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;

    return null;
  }

  Widget _gap([double height = 17]) => SizedBox(height: height);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: navy,

        foregroundColor: Colors.white,

        elevation: 0,

        centerTitle: false,

        leading: IconButton(
          tooltip: 'Back',

          onPressed: () => Navigator.maybePop(context),

          icon: const Icon(Icons.arrow_back_rounded),
        ),

        title: const Text(
          'Driver Application',

          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),

      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_background.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const ColoredBox(color: Color(0xFFF4F7FC));
              },
            ),
          ),

          // Soft white overlay keeps the form readable
          Positioned.fill(
            child: Container(color: Colors.white.withOpacity(0.25)),
          ),

          // Existing form and functionality remain unchanged
          SafeArea(
            top: false,
            child: Form(
              key: _formKey,

              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),

                padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),

                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,

                      children: [
                        // Brand and application introduction.
                        Container(
                          padding: const EdgeInsets.all(22),

                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [navy, Color(0xFF1D4E89)],

                              begin: Alignment.topLeft,

                              end: Alignment.bottomRight,
                            ),

                            borderRadius: BorderRadius.circular(22),

                            boxShadow: [
                              BoxShadow(
                                color: navy.withOpacity(0.16),

                                blurRadius: 20,

                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),

                          child: Row(
                            children: [
                              Container(
                                height: 62,

                                width: 62,

                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.13),

                                  borderRadius: BorderRadius.circular(17),

                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),

                                child: const Icon(
                                  Icons.local_shipping_rounded,

                                  color: Colors.white,

                                  size: 32,
                                ),
                              ),

                              const SizedBox(width: 16),

                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [
                                    Text(
                                      'MediRide',

                                      style: TextStyle(
                                        color: Colors.white,

                                        fontSize: 25,

                                        fontWeight: FontWeight.w800,

                                        letterSpacing: -0.4,
                                      ),
                                    ),

                                    SizedBox(height: 5),

                                    Text(
                                      'Join our ambulance driver network',

                                      style: TextStyle(
                                        color: Color(0xFFDCE8F8),

                                        fontSize: 12.5,

                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        _gap(14),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,

                            vertical: 12,
                          ),

                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),

                            borderRadius: BorderRadius.circular(13),

                            border: Border.all(color: const Color(0xFFD7E7FF)),
                          ),

                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Icon(
                                Icons.verified_user_outlined,

                                color: blue,

                                size: 20,
                              ),

                              SizedBox(width: 10),

                              Expanded(
                                child: Text(
                                  'Admin verification required. Your driver access '
                                  'will be enabled only after your application is approved.',

                                  style: TextStyle(
                                    color: Color(0xFF1E40AF),

                                    fontSize: 12.5,

                                    height: 1.45,

                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        _gap(18),

                        // Personal information.
                        _sectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              _sectionHeader(
                                icon: Icons.person_outline_rounded,

                                title: 'Personal Information',

                                subtitle: 'Enter your basic contact details.',
                              ),

                              _gap(22),

                              _field(
                                controller: _nameController,

                                label: 'Full name',

                                hint: 'Enter your full name',

                                icon: Icons.person_outline_rounded,

                                textCapitalization: TextCapitalization.words,

                                validator: (v) {
                                  final error = _required(
                                    v,

                                    'Please enter your full name',
                                  );

                                  if (error != null) return error;

                                  if (v!.trim().length < 3) {
                                    return 'Name must be at least 3 characters';
                                  }

                                  return null;
                                },
                              ),

                              _gap(),

                              _field(
                                controller: _emailController,

                                label: 'Email address',

                                hint: 'name\@example.com',

                                icon: Icons.mail_outline_rounded,

                                keyboardType: TextInputType.emailAddress,

                                validator: (v) {
                                  final error = _required(
                                    v,

                                    'Please enter your email',
                                  );

                                  if (error != null) return error;

                                  if (!RegExp(
                                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                  ).hasMatch(v!.trim())) {
                                    return 'Please enter a valid email address';
                                  }

                                  return null;
                                },
                              ),

                              _gap(),

                              _field(
                                controller: _phoneController,

                                label: 'Phone number',

                                hint: '01XXXXXXXXX',

                                icon: Icons.phone_outlined,

                                keyboardType: TextInputType.phone,

                                validator: (v) {
                                  final error = _required(
                                    v,

                                    'Please enter your phone number',
                                  );

                                  if (error != null) return error;

                                  final digits = v!.replaceAll(
                                    RegExp(r'\D'),
                                    '',
                                  );

                                  if (digits.length < 10 ||
                                      digits.length > 14) {
                                    return 'Please enter a valid phone number';
                                  }

                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),

                        _gap(16),

                        // Account security.
                        _sectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              _sectionHeader(
                                icon: Icons.lock_outline_rounded,

                                title: 'Account Security',

                                subtitle: 'Create a password for signing in.',
                              ),

                              _gap(22),

                              _field(
                                controller: _passwordController,

                                label: 'Password',

                                hint: 'At least 6 characters',

                                icon: Icons.lock_outline_rounded,

                                obscureText: _obscurePassword,

                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword
                                      ? 'Show password'
                                      : 'Hide password',

                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),

                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,

                                    color: textMuted,

                                    size: 20,
                                  ),
                                ),

                                textInputAction: TextInputAction.next,

                                validator: (v) {
                                  final error = _required(
                                    v,

                                    'Please create a password',
                                  );

                                  if (error != null) return error;

                                  if (v!.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }

                                  return null;
                                },
                              ),

                              _gap(),

                              _field(
                                controller: _confirmPasswordController,

                                label: 'Confirm password',

                                hint: 'Enter the password again',

                                icon: Icons.lock_reset_outlined,

                                obscureText: _obscureConfirmPassword,

                                suffixIcon: IconButton(
                                  tooltip: _obscureConfirmPassword
                                      ? 'Show password'
                                      : 'Hide password',

                                  onPressed: () => setState(
                                    () => _obscureConfirmPassword =
                                        !_obscureConfirmPassword,
                                  ),

                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,

                                    color: textMuted,

                                    size: 20,
                                  ),
                                ),

                                validator: (v) {
                                  final error = _required(
                                    v,

                                    'Please confirm your password',
                                  );

                                  if (error != null) return error;

                                  if (v != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }

                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),

                        _gap(16),

                        // Driver and vehicle details.
                        _sectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              _sectionHeader(
                                icon: Icons.badge_outlined,

                                title: 'Driver & Vehicle',

                                subtitle:
                                    'Provide your licence and ambulance details.',
                              ),

                              _gap(22),

                              _field(
                                controller: _licenseController,

                                label: 'Driving licence number',

                                hint: 'Enter licence number',

                                icon: Icons.badge_outlined,

                                textCapitalization:
                                    TextCapitalization.characters,

                                validator: (v) => _required(
                                  v,

                                  'Please enter your licence number',
                                ),
                              ),

                              _gap(),

                              _field(
                                controller: _nidController,

                                label: 'National ID (NID)',

                                hint: 'Enter your NID number',

                                icon: Icons.credit_card_outlined,

                                keyboardType: TextInputType.number,

                                validator: (v) {
                                  final error = _required(
                                    v,

                                    'Please enter your NID number',
                                  );

                                  if (error != null) return error;

                                  final digits = v!.replaceAll(
                                    RegExp(r'\D'),
                                    '',
                                  );

                                  if (digits.length < 10) {
                                    return 'Please enter a valid NID number';
                                  }

                                  return null;
                                },
                              ),

                              _gap(),

                              _field(
                                controller: _vehicleController,

                                label: 'Ambulance vehicle number',

                                hint: 'e.g. DHAKA-METRO-CHA-1234',

                                icon: Icons.directions_car_outlined,

                                textCapitalization:
                                    TextCapitalization.characters,

                                validator: (v) => _required(
                                  v,
                                  'Please enter the vehicle number',
                                ),
                              ),

                              _gap(),

                              const Text(
                                'Ambulance type',

                                style: TextStyle(
                                  color: textDark,

                                  fontSize: 13,

                                  fontWeight: FontWeight.w700,
                                ),
                              ),

                              const SizedBox(height: 8),

                              DropdownButtonFormField<String>(
                                value: _selectedAmbulanceType,

                                isExpanded: true,

                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,

                                  color: textMuted,
                                ),

                                decoration: InputDecoration(
                                  prefixIcon: const Icon(
                                    Icons.medical_services_outlined,

                                    color: Color(0xFF647CA0),

                                    size: 20,
                                  ),

                                  filled: true,

                                  fillColor: const Color(0xFFF8FAFD),

                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,

                                    vertical: 13,
                                  ),

                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),

                                    borderSide: const BorderSide(color: border),
                                  ),

                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),

                                    borderSide: const BorderSide(color: border),
                                  ),

                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),

                                    borderSide: const BorderSide(
                                      color: blue,

                                      width: 1.5,
                                    ),
                                  ),
                                ),

                                items: const [
                                  DropdownMenuItem(
                                    value: 'Normal',

                                    child: Text('Normal Ambulance'),
                                  ),

                                  DropdownMenuItem(
                                    value: 'CCU',

                                    child: Text('CCU Ambulance'),
                                  ),

                                  DropdownMenuItem(
                                    value: 'ICU',

                                    child: Text('ICU Ambulance'),
                                  ),
                                ],

                                onChanged: (value) {
                                  if (value != null) {
                                    setState(
                                      () => _selectedAmbulanceType = value,
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),

                        _gap(16),

                        // Verification reminder.
                        Container(
                          padding: const EdgeInsets.all(15),

                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),

                            borderRadius: BorderRadius.circular(14),

                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),

                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Icon(
                                Icons.info_outline_rounded,

                                color: Color(0xFFB45309),

                                size: 21,
                              ),

                              SizedBox(width: 10),

                              Expanded(
                                child: Text(
                                  'Please make sure all details are accurate. '
                                  'MediRide administrators will review your application '
                                  'before activating driver access.',

                                  style: TextStyle(
                                    color: Color(0xFF92400E),

                                    fontSize: 12.5,

                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        _gap(20),

                        SizedBox(
                          height: 54,

                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : _submitDriverApplication,

                            style: ElevatedButton.styleFrom(
                              backgroundColor: blue,

                              disabledBackgroundColor: const Color(0xFF93B4F5),

                              foregroundColor: Colors.white,

                              elevation: 0,

                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),

                            child: _isLoading
                                ? const SizedBox(
                                    height: 22,

                                    width: 22,

                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,

                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,

                                    children: [
                                      Icon(Icons.send_rounded, size: 19),

                                      SizedBox(width: 9),

                                      Text(
                                        'Submit Application',

                                        style: TextStyle(
                                          fontSize: 15,

                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        _gap(15),

                        const Text(
                          'By submitting, you agree to MediRide driver verification requirements.',

                          textAlign: TextAlign.center,

                          style: TextStyle(
                            color: textMuted,

                            fontSize: 11.5,

                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
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