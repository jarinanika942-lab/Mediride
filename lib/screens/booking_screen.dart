import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic> ambulance;

  const BookingScreen({
    super.key,
    required this.ambulance,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color navy = Color(0xFF0F2F64);
  static const Color background = Color(0xFFF4F7FC);

  final _formKey = GlobalKey<FormState>();

  final _pickupController = TextEditingController();
  final _destinationController = TextEditingController();
  final _patientNameController = TextEditingController();
  final _patientAgeController = TextEditingController();
  final _patientPhoneController = TextEditingController();

  String _emergencyType = 'Accident';
  bool _isLoading = false;

  // Receive the ambulance selected on HomeScreen.
  String get ambulanceName =>
      widget.ambulance['name']?.toString() ??
      widget.ambulance['type']?.toString() ??
      'Ambulance';

  int get ambulanceFare {
    final value = widget.ambulance['price'] ??
        widget.ambulance['fare'] ??
        0;

    return int.tryParse(
          value.toString().replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    _patientNameController.dispose();
    _patientAgeController.dispose();
    _patientPhoneController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator ?? _validateRequired,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: primaryBlue),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(
              color: Color(0xFFE0E7F1),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(
              color: Color(0xFFE0E7F1),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(
              color: primaryBlue,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: navy,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmBooking() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in before booking.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.from('bookings').insert({
        'user_id': user.id,
        'pickup_address': _pickupController.text.trim(),
        'destination_address':
            _destinationController.text.trim(),
        'ambulance_type': ambulanceName,
        'patient_name': _patientNameController.text.trim(),
        'patient_age':
            int.parse(_patientAgeController.text.trim()),
        'patient_phone': _patientPhoneController.text.trim(),
        'emergency_type': _emergencyType,
        'fare': ambulanceFare,
        'status': 'pending',
      });

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 65,
              ),
              SizedBox(height: 14),
              Text(
                'Booking Submitted!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Your booking has been saved. '
                'Please wait for a driver to respond.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking failed: $error'),
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: navy,
        elevation: 0,
        title: const Text(
          'Complete Your Booking',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pickup and destination
                _sectionTitle(
                  '1. Trip Details',
                  'Where should the ambulance pick up the patient?',
                ),

                _buildTextField(
                  label: 'Pickup Location',
                  hint: 'e.g. Zindabazar, Sylhet',
                  icon: Icons.my_location_rounded,
                  controller: _pickupController,
                ),

                _buildTextField(
                  label: 'Destination',
                  hint: 'e.g. Osmani Medical, Sylhet',
                  icon: Icons.location_on_rounded,
                  controller: _destinationController,
                ),

                const SizedBox(height: 12),

                // Patient information
                _sectionTitle(
                  '2. Patient Information',
                  'Enter the patient’s details.',
                ),

                _buildTextField(
                  label: 'Patient Name',
                  hint: 'Enter full name',
                  icon: Icons.person_rounded,
                  controller: _patientNameController,
                ),

                _buildTextField(
                  label: 'Patient Age',
                  hint: 'Enter age in years',
                  icon: Icons.cake_rounded,
                  controller: _patientAgeController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter patient age';
                    }

                    final age = int.tryParse(value.trim());

                    if (age == null || age < 0 || age > 120) {
                      return 'Enter an age between 0 and 120';
                    }

                    return null;
                  },
                ),

                _buildTextField(
                  label: 'Contact Phone Number',
                  hint: 'Enter a contact number',
                  icon: Icons.phone_rounded,
                  controller: _patientPhoneController,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a phone number';
                    }

                    if (value.trim().length < 7) {
                      return 'Enter a valid phone number';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 8),

                // Emergency type
                _sectionTitle(
                  '3. Emergency Type',
                  'Select the reason for ambulance service.',
                ),

                DropdownButtonFormField<String>(
                  value: _emergencyType,
                  isExpanded: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.medical_services_rounded,
                      color: primaryBlue,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Accident',
                      child: Text('Accident'),
                    ),
                    DropdownMenuItem(
                      value: 'Heart Problem',
                      child: Text('Heart Problem'),
                    ),
                    DropdownMenuItem(
                      value: 'Breathing Problem',
                      child: Text('Breathing Problem'),
                    ),
                    DropdownMenuItem(
                      value: 'Pregnancy',
                      child: Text('Pregnancy'),
                    ),
                    DropdownMenuItem(
                      value: 'Other',
                      child: Text('Other'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _emergencyType = value);
                    }
                  },
                ),

                const SizedBox(height: 28),

                // Booking summary: no duplicate ambulance cards
                _sectionTitle(
                  '4. Booking Summary',
                  'Check your details before confirming.',
                ),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFE0E7F1),
                    ),
                  ),
                  child: Column(
                    children: [
                      _summaryRow(
                        'Pickup',
                        _pickupController.text.trim(),
                      ),
                      _summaryRow(
                        'Destination',
                        _destinationController.text.trim(),
                      ),
                      _summaryRow(
                        'Ambulance',
                        '$ambulanceName Ambulance',
                      ),
                      _summaryRow(
                        'Patient',
                        _patientNameController.text.trim(),
                      ),
                      _summaryRow(
                        'Age',
                        _patientAgeController.text.trim(),
                      ),
                      _summaryRow(
                        'Contact',
                        _patientPhoneController.text.trim(),
                      ),
                      _summaryRow(
                        'Emergency',
                        _emergencyType,
                      ),
                      const Divider(height: 28),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Estimated Fare',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: navy,
                            ),
                          ),
                          Text(
                            '৳$ambulanceFare',
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              color: primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Confirm booking
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed:
                        _isLoading ? null : _confirmBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Confirm Booking',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
