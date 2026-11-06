import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class PickupLocationScreen extends StatefulWidget {
  const PickupLocationScreen({super.key});

  @override
  State<PickupLocationScreen> createState() => _PickupLocationScreenState();
}

class _PickupLocationScreenState extends State<PickupLocationScreen> {
  // Sylhet-এর initial location
  final LatLng initialLocation = LatLng(24.8949, 91.8687);

  // Map controller
  final MapController mapController = MapController();

  // User selected pickup location
  LatLng? selectedLocation;

  // User-এর current GPS location
  LatLng? currentLocation;

  // Selected location-এর address
  String selectedAddress = 'Please select a location from the map.';

  // Address খোঁজার সময় loading দেখাবে
  bool isLoadingAddress = false;

  // নতুন request এলে আগের request-এর result ignore করবে
  int addressRequestId = 0;

  // Latitude ও Longitude থেকে address বের করা
  Future<void> _getAddressFromCoordinates(LatLng location) async {
    final int requestId = ++addressRequestId;

    setState(() {
      isLoadingAddress = true;
      selectedAddress = 'Finding address...';
    });

    try {
      final Uri url = Uri.https(
        'nominatim.openstreetmap.org',
        '/reverse',
        {
          'format': 'jsonv2',
          'lat': location.latitude.toString(),
          'lon': location.longitude.toString(),
          'zoom': '18',
          'addressdetails': '1',
        },
      );

      final response = await http.get(
        url,
        headers: {
          // নিজের app-এর পরিচয় দিন; production-এ contact info যোগ করুন
          'User-Agent': 'MediRide/1.0 (Flutter app)',
          'Accept': 'application/json',
        },
      );

      if (requestId != addressRequestId || !mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;

        final String? address = data['display_name'] as String?;

        setState(() {
          selectedAddress = (address != null && address.isNotEmpty)
              ? address
              : 'Address not found for this location.';
          isLoadingAddress = false;
        });
      } else {
        setState(() {
          selectedAddress =
              'Could not find address. Please try another location.';
          isLoadingAddress = false;
        });
      }
    } catch (e) {
      if (requestId != addressRequestId || !mounted) return;

      setState(() {
        selectedAddress =
            'Address lookup failed. Please check your internet connection.';
        isLoadingAddress = false;
      });
    }
  }

  // Current GPS Location বের করার function
  Future<void> _getCurrentLocation() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please turn on Location Service.'),
          ),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permission denied. Please allow location in Chrome.',
            ),
          ),
        );
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      final LatLng location = LatLng(
        position.latitude,
        position.longitude,
      );

      setState(() {
        currentLocation = location;
        selectedLocation = location;
      });

      mapController.move(location, 16);

      // Current location-এর address বের করা
      await _getAddressFromCoordinates(location);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location error: $e'),
        ),
      );
    }
  }

  // Map-এ tap করলে pickup location এবং address update হবে
  void _selectLocation(LatLng point) {
    setState(() {
      selectedLocation = point;
    });

    _getAddressFromCoordinates(point);
  }

  @override
  void dispose() {
    // চলমান address request-এর result আর ব্যবহার হবে না
    addressRequestId++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showRedPickupMarker = selectedLocation != null &&
        (currentLocation == null ||
            const Distance().as(
                  LengthUnit.Meter,
                  selectedLocation!,
                  currentLocation!,
                ) >
                10);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Pickup Location',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Stack(
        children: [
          // OpenStreetMap
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: initialLocation,
              initialZoom: 14,
              onTap: (tapPosition, point) {
                _selectLocation(point);
              },
            ),
            children: [
              // Map Tiles
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.mediride',
              ),

              // Red Marker: selected pickup location
              if (showRedPickupMarker)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: selectedLocation!,
                      width: 60,
                      height: 60,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 50,
                      ),
                    ),
                  ],
                ),

              // Blue Dot: current GPS location
              if (currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: currentLocation!,
                      width: 30,
                      height: 30,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Instruction
          Positioned(
            top: 15,
            left: 15,
            right: 15,
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.blue,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tap on the map to select your pickup location',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Current Location GPS Button
          Positioned(
            right: 15,
            bottom: 250,
            child: FloatingActionButton(
              heroTag: 'currentLocationButton',
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue,
              onPressed: _getCurrentLocation,
              child: const Icon(Icons.my_location),
            ),
          ),

          // Bottom Location Details
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pickup Location',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Address দেখাবে
                    if (isLoadingAddress)
                      const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Finding address...',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        selectedAddress,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),

                    const SizedBox(height: 10),

                    if (selectedLocation != null)
                      Text(
                        'Latitude: ${selectedLocation!.latitude.toStringAsFixed(6)}\n'
                        'Longitude: ${selectedLocation!.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: selectedLocation == null || isLoadingAddress
                            ? null
                            : () {
                                Navigator.pop(
                                  context,
                                  {
                                    'location': selectedLocation,
                                    'address': selectedAddress,
                                  },
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Confirm Pickup Location',
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
          ),
        ],
      ),
    );
  }
}
