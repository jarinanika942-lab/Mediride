import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_screen.dart';
import 'booking_screen.dart';
import 'pickup_location_screen.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color navy = Color(0xFF0F2F5F);
  static const Color lightBlue = Color(0xFFEFF6FF);
  static const Color backgroundColor = Color(0xFFF5F7FB);
  static const Color borderColor = Color(0xFFE5EAF2);

  int _selectedIndex = 0;

  // User-selected pickup coordinates and address
  LatLng? _pickupLocation;
  String? _pickupAddress;

  Future<void> _selectPickupLocation() async {
    // Pickup screen theke coordinates ebong address receive korbo
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const PickupLocationScreen()),
    );

    if (!mounted) return;

    if (result != null) {
      setState(() {
        _pickupLocation = result['location'] as LatLng?;
        _pickupAddress = result['address'] as String?;
      });
    }
  }

  final List<Map<String, dynamic>> _ambulances = [
    {
      'name': 'Basic',
      'subtitle': 'Basic patient transportation',
      'image': 'assets/images/basic_ambulance.jpg',
      'icon': Icons.airport_shuttle_rounded,
      'color': primaryBlue,
      'eta': '7 min',
      'price': 1200,
      'facilities': ['Oxygen', 'Stretcher'],
      'description':
          'Suitable for patients who need safe transportation and basic medical assistance.',
    },
    {
      'name': 'CCU',
      'subtitle': 'Cardiac care support',
      'image': 'assets/images/ccu_ambulance.jpg',
      'icon': Icons.airport_shuttle_rounded,
      'color': Color(0xFFDC5A42),
      'eta': '10 min',
      'price': 2500,
      'facilities': ['Oxygen', 'Cardiac Monitor', 'Emergency Equipment'],
      'description':
          'Designed for patients requiring cardiac monitoring and advanced emergency support.',
    },
    {
      'name': 'ICU',
      'subtitle': 'Advanced critical care',
      'image': 'assets/images/icu_ambulance.jpg',
      'icon': Icons.airport_shuttle_rounded,
      'color': Color(0xFF7C3AED),
      'eta': '12 min',
      'price': 3500,
      'facilities': ['Ventilator', 'Cardiac Monitor', 'Medical Support'],
      'description':
          'For critically ill patients who require advanced equipment during transportation.',
    },
  ];

  String? _selectedBookingType;
  Map<String, dynamic>? _selectedAmbulance;
  DateTime? _reservationDate;
  TimeOfDay? _reservationTime;

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage('Logout failed. Please try again.');
    }
  }

  // Professional Google Map preview on the Home page.
  // Shows Sylhet by default and updates to the selected pickup location.
  // OpenStreetMap preview on the Home page.
  Widget _buildGoogleMap() {
    final LatLng mapLocation =
        _pickupLocation ?? const LatLng(24.8949, 91.8687);

    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            FlutterMap(
              key: ValueKey('${mapLocation.latitude},${mapLocation.longitude}'),
              options: MapOptions(initialCenter: mapLocation, initialZoom: 14),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.mediride',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: mapLocation,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Pickup Area label
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: primaryBlue,
                      size: 19,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Pickup Area',
                      style: TextStyle(
                        color: navy,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (match) => '${match[1]},',
    );
  }

  void _openAmbulanceDetails(Map<String, dynamic> ambulance) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final Color color = ambulance['color'] as Color;
        final List<String> facilities = List<String>.from(
          ambulance['facilities'] as List,
        );

        return Container(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        height: 76,
                        width: 76,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Image.asset(
                          ambulance['image'] as String,
                          width: 68,
                          height: 68,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              ambulance['icon'] as IconData,
                              color: color,
                              size: 42,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${ambulance['name']} Ambulance',
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                color: navy,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              ambulance['subtitle'] as String,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 16,
                                  color: primaryBlue,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    'Estimated arrival: ${ambulance['eta']}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: primaryBlue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Estimated fare',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '৳${_formatPrice(ambulance['price'] as int)}',
                                style: const TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                  color: navy,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(height: 42, width: 1, color: borderColor),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Estimated arrival',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                ambulance['eta'] as String,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: navy,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Available Facilities',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: navy,
                    ),
                  ),
                  const SizedBox(height: 13),
                  ...facilities.map(
                    (facility) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF16A34A),
                            size: 21,
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Text(
                              facility,
                              style: const TextStyle(fontSize: 14, color: navy),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ambulance['description'] as String,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      height: 1.6,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(sheetContext);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingScreen(
                              ambulance: {
                                ...ambulance,
                                'pickup_location': _pickupLocation,
                                'pickup_address': _pickupAddress,
                              },
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Continue Booking',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _startBooking(
    String bookingType,
    Map<String, dynamic> ambulance,
  ) async {
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    if (bookingType == 'Reservation') {
      selectedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now().add(const Duration(days: 1)),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );

      if (!mounted || selectedDate == null) return;

      selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (!mounted || selectedTime == null) return;
    }

    if (!mounted) return;

    setState(() {
      _selectedBookingType = bookingType;
      _selectedAmbulance = ambulance;
      _reservationDate = selectedDate;
      _reservationTime = selectedTime;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingScreen(
          ambulance: {
            ...ambulance,
            'booking_type': bookingType,
            if (selectedDate != null)
              'reservation_date':
                  '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
            if (selectedTime != null)
              'reservation_time': selectedTime.format(context),
          },
        ),
      ),
    );
  }

  void _openHelp() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Help & Support',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.emergency_rounded, color: Colors.red),
                title: const Text('Emergency Contacts'),
                subtitle: const Text('Emergency assistance'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showMessage(
                    'Emergency contact details need to be configured.',
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.support_agent_rounded,
                  color: primaryBlue,
                ),
                title: const Text('Contact Support'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showMessage(
                    'Support contact details need to be configured.',
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.help_outline_rounded,
                  color: primaryBlue,
                ),
                title: const Text('Frequently Asked Questions'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showMessage('FAQ section is not connected yet.');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, {String? subtitle}) {
    return Column(
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
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHome() {
    final user = Supabase.instance.client.auth.currentUser;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: [
        _buildGoogleMap(),
        const SizedBox(height: 18),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: _selectPickupLocation,
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: lightBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pickup location',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _pickupAddress ?? 'Sylhet, Bangladesh',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: navy,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
       
        _sectionTitle(
          'Choose Your Ambulance',
          subtitle:
              'Tap a type to view its facilities, estimated arrival and fare.',
        ),
        const SizedBox(height: 16),

        // UPDATED: ambulance types are shown side-by-side as compact buttons.
        _ambulanceTypeButtons(),

        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            border: Border.all(color: const Color(0xFFFED7AA)),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: Color(0xFFEA580C)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Prices and arrival times are illustrative estimates. Actual availability, equipment and fare must be confirmed by the ambulance provider.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: Color(0xFF9A3412),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // UPDATED: three compact, horizontal ambulance buttons on Home.
  Widget _ambulanceTypeButtons() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _ambulances.map((ambulance) {
        final Color color = ambulance['color'] as Color;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _openAmbulanceDetails(ambulance),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 3,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.35)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Image.asset(
                          ambulance['image'] as String,
                          width: 42,
                          height: 42,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              ambulance['icon'] as IconData,
                              color: color,
                              size: 25,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        ambulance['name'] as String,
                        style: const TextStyle(
                          color: navy,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '৳${_formatPrice(ambulance['price'] as int)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ETA ${ambulance['eta']}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Details',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildServices() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionTitle(
          'Our Services',
          subtitle: 'Choose how and when you need an ambulance.',
        ),
        const SizedBox(height: 22),
        _largeServiceCard(
          icon: Icons.emergency_rounded,
          color: const Color(0xFFDC2626),
          title: 'Emergency Booking',
          subtitle: 'Need an ambulance right now?',
          description:
              'Select an ambulance, enter pickup and destination, and provide patient information.',
          buttonText: 'Book Now',
          onTap: () => _openServiceAmbulances('Emergency'),
        ),
        const SizedBox(height: 16),
        _largeServiceCard(
          icon: Icons.calendar_month_rounded,
          color: const Color(0xFF0891B2),
          title: 'Reservation',
          subtitle: 'Plan your journey in advance.',
          description:
              'Choose your preferred date and time for a hospital visit, patient transfer or scheduled journey.',
          buttonText: 'Schedule Ambulance',
          onTap: () => _openServiceAmbulances('Reservation'),
        ),

        // Ambulance Categories section intentionally removed.
      ],
    );
  }

  Widget _largeServiceCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String description,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 15),
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey.shade600,
              height: 1.5,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 17),
          SizedBox(
            width: double.infinity,
            height: 47,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openServiceAmbulances(String bookingType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bookingType == 'Emergency'
                    ? 'Choose Emergency Ambulance'
                    : 'Choose Reservation Ambulance',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select the ambulance type that suits the patient.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ..._ambulances.map(
                (ambulance) => _serviceTypeTileForBooking(
                  ambulance,
                  bookingType,
                  sheetContext,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _serviceTypeTileForBooking(
    Map<String, dynamic> ambulance,
    String bookingType,
    BuildContext sheetContext,
  ) {
    final Color color = ambulance['color'] as Color;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.10),
        child: Icon(ambulance['icon'] as IconData, color: color),
      ),
      title: Text('${ambulance['name']} Ambulance'),
      subtitle: Text(
        '৳${_formatPrice(ambulance['price'] as int)} · ETA ${ambulance['eta']}',
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      onTap: () {
        Navigator.pop(sheetContext);
        _startBooking(bookingType, ambulance);
      },
    );
  }

  Widget _buildActivity() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionTitle(
          'My Activity',
          subtitle: 'Track your current bookings and previous journeys.',
        ),
        const SizedBox(height: 22),
        _activitySectionHeading(
          'Upcoming & Active',
          Icons.event_available_rounded,
        ),
        const SizedBox(height: 10),
        if (_selectedBookingType != null && _selectedAmbulance != null)
          _selectedBookingCard()
        else
          _emptyActivityCard(
            icon: Icons.local_shipping_outlined,
            title: 'No active bookings',
            subtitle:
                'Your pending, accepted and ongoing bookings will appear here.',
          ),
        const SizedBox(height: 25),
        _activitySectionHeading('Booking History', Icons.history_rounded),
        const SizedBox(height: 10),
        _emptyActivityCard(
          icon: Icons.receipt_long_outlined,
          title: 'No booking history yet',
          subtitle:
              'Your completed or cancelled ambulance trips will appear here.',
        ),
        const SizedBox(height: 22),
        SizedBox(
          height: 49,
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _selectedIndex = 0),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Book an Ambulance'),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryBlue,
              side: const BorderSide(color: primaryBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Note: Activity is currently a UI preview. Connect it to your Supabase bookings table to display real booking records and status updates.',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 11,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _activitySectionHeading(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: primaryBlue, size: 21),
        const SizedBox(width: 9),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: navy,
          ),
        ),
      ],
    );
  }

  Widget _emptyActivityCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Container(
            height: 62,
            width: 62,
            decoration: const BoxDecoration(
              color: lightBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primaryBlue, size: 31),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: navy,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 7),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectedBookingCard() {
    final ambulance = _selectedAmbulance!;
    final bool isReservation = _selectedBookingType == 'Reservation';

    final String reservationText =
        _reservationDate != null && _reservationTime != null
        ? '${_reservationDate!.day}/${_reservationDate!.month}/${_reservationDate!.year} at ${_reservationTime!.format(context)}'
        : 'Date and time not selected';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: (ambulance['color'] as Color).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  ambulance['icon'] as IconData,
                  color: ambulance['color'] as Color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${ambulance['name']} Ambulance',
                      style: const TextStyle(
                        color: navy,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedBookingType!,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Text(
                  'Not confirmed',
                  style: TextStyle(
                    color: Color(0xFF9A3412),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isReservation) ...[
            Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  size: 18,
                  color: primaryBlue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reservationText,
                    style: const TextStyle(color: navy, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Text(
            'Estimated fare: ৳${_formatPrice(ambulance['price'] as int)}',
            style: const TextStyle(color: navy, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          const Text(
            'This is a local selection preview, not a confirmed booking. Continue the booking flow to submit details.',
            style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.5),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _selectedBookingType = null;
                  _selectedAmbulance = null;
                  _reservationDate = null;
                  _reservationTime = null;
                });
              },
              child: const Text(
                'Clear selection',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile() {
    final user = Supabase.instance.client.auth.currentUser;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            height: 92,
            width: 92,
            decoration: const BoxDecoration(
              color: lightBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: primaryBlue,
              size: 53,
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'My Profile',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: navy,
            fontWeight: FontWeight.bold,
            fontSize: 23,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          user?.email ?? 'No email available',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 30),
        _profileTile(
          icon: Icons.person_outline_rounded,
          title: 'Personal Information',
          onTap: () => _showMessage(
            'Personal information editing is not connected yet.',
          ),
        ),
        _profileTile(
          icon: Icons.phone_outlined,
          title: 'Phone Number',
          onTap: () =>
              _showMessage('Phone number details are not connected yet.'),
        ),
        _profileTile(
          icon: Icons.local_hospital_outlined,
          title: 'Saved Hospitals',
          onTap: () => _showMessage('Saved hospitals are not connected yet.'),
        ),
        _profileTile(
          icon: Icons.contact_emergency_outlined,
          title: 'Emergency Contacts',
          onTap: () =>
              _showMessage('Emergency contacts are not configured yet.'),
        ),
        _profileTile(
          icon: Icons.notifications_none_rounded,
          title: 'Notifications',
          onTap: () => _showMessage('Notifications are not connected yet.'),
        ),
        _profileTile(
          icon: Icons.settings_outlined,
          title: 'Settings',
          onTap: () => _showMessage('Settings are not connected yet.'),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 51,
          child: OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade200),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _profileTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      leading: Icon(icon, color: primaryBlue),
      title: Text(
        title,
        style: const TextStyle(color: navy, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _menuTile(
    BuildContext sheetContext,
    IconData icon,
    String title,
    int index,
  ) {
    return ListTile(
      leading: Icon(icon, color: primaryBlue),
      title: Text(title),
      onTap: () {
        Navigator.pop(sheetContext);
        setState(() => _selectedIndex = index);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHome(),
      _buildServices(),
      _buildActivity(),
      _buildProfile(),
    ];

    final List<String> titles = [
      'MediRide',
      'Our Services',
      'My Activity',
      'My Profile',
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Menu',
          icon: const Icon(Icons.menu_rounded, color: navy),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              builder: (sheetContext) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _menuTile(sheetContext, Icons.home_rounded, 'Home', 0),
                    _menuTile(
                      sheetContext,
                      Icons.medical_services_rounded,
                      'Services',
                      1,
                    ),
                    _menuTile(
                      sheetContext,
                      Icons.history_rounded,
                      'Activity',
                      2,
                    ),
                    _menuTile(sheetContext, Icons.person_rounded, 'Profile', 3),
                  ],
                ),
              ),
            );
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_hospital_rounded,
              color: primaryBlue,
              size: 26,
            ),
            const SizedBox(width: 8),
            Text(
              titles[_selectedIndex],
              style: const TextStyle(
                color: navy,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Help & Support',
            onPressed: _openHelp,
            icon: const Icon(
              Icons.help_outline_rounded,
              color: primaryBlue,
              size: 25,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        backgroundColor: Colors.white,
        indicatorColor: lightBlue,
        elevation: 8,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: primaryBlue),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.medical_services_outlined),
            selectedIcon: Icon(
              Icons.medical_services_rounded,
              color: primaryBlue,
            ),
            label: 'Services',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded, color: primaryBlue),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: primaryBlue),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
