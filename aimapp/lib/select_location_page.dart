
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'as latlong;
import 'package:geocoding/geocoding.dart';
import 'package:aimapp/available_helpers_page.dart';
import 'package:aimapp/database_helper.dart';
import 'package:aimapp/distance_calculator.dart';

class SelectLocationPage extends StatefulWidget {
  final String service;
  final String date;
  final String time;
  final bool isRequestingHelp;
  final int userId;
  final String requestType;

  const SelectLocationPage({
    required this.service,
    required this.date,
    required this.time,
    required this.isRequestingHelp,
    required this.userId,
    required this.requestType,
  });

  @override
  _SelectLocationPageState createState() => _SelectLocationPageState();
}

class _SelectLocationPageState extends State<SelectLocationPage> {
  final MapController _mapController = MapController();
  final TextEditingController _locationController = TextEditingController();
  latlong.LatLng? _selectedLocation;
  String? _locationName;
  String? _postalCode;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    final user = await DatabaseHelper().getUser(widget.userId);
    if (user != null && user['postalCode'] != null) {
      try {
        final location = await DistanceCalculator.getLocationDetails(user['postalCode']);
        setState(() {
          _selectedLocation = latlong.LatLng(location['latitude'], location['longitude']);
          _postalCode = location['postalCode'];
          _locationName = location['address'];
          _locationController.text = _locationName!;
        });
        _mapController.move(_selectedLocation!, 15.0);
      } catch (e) {
        _showErrorSnackBar('Failed to load your location: ${e.toString()}');
      }
    }
  }
  Future<void> _searchLocation() async {
    final query = _locationController.text.trim();
    if (query.isEmpty) {
      _showErrorSnackBar('Please enter a location');
      return;
    }

    setState(() => _isSearching = true);
    try {
      _showLoadingSnackBar('Searching for location...');
      
      if (RegExp(r'^\d{6}$').hasMatch(query)) {
        await _searchByPostalCode(query);
      } else {
        await _searchByAddress(query);
      }
    } catch (e) {
      _showErrorSnackBar('Location search failed: ${e.toString()}');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _searchByPostalCode(String postalCode) async {
    try {
      final location = await DistanceCalculator.getLocationDetails(postalCode);
      await _updateLocationFromCoordinates(
        location['latitude'],
        location['longitude'],
        searchQuery: postalCode,
      );
    } catch (e) {
      _showErrorSnackBar('Invalid Singapore postal code');
      rethrow;
    }
  }

  Future<void> _searchByAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress('$address, Singapore');
      if (locations.isEmpty) {
        throw Exception('Could not find location for address');
      }
      
      final isSingapore = await DistanceCalculator.isSingaporeLocation(
        locations.first.latitude,
        locations.first.longitude,
      );
      
      if (!isSingapore) {
        throw Exception('Location must be in Singapore');
      }
      
      await _updateLocationFromCoordinates(
        locations.first.latitude,
        locations.first.longitude,
        searchQuery: address,
      );
    } catch (e) {
      _showErrorSnackBar('Address not found in Singapore');
      rethrow;
    }
  }

  Future<void> _updateLocationFromCoordinates(
    double latitude,
    double longitude, {
    String? searchQuery,
    bool isCurrentLocation = false,
  }) async {
    try {
      final location = await DistanceCalculator.getLocationDetails(
        searchQuery ?? '$latitude,$longitude',
      );
      
      await DatabaseHelper().updateUserLocation(
        userId: widget.userId,
        latitude: latitude,
        longitude: longitude,
        postalCode: location['postalCode'],
      );
      
      setState(() {
        _selectedLocation = latlong.LatLng(latitude, longitude);
        _postalCode = location['postalCode'];
        _locationName = location['address'];
        _locationController.text = _locationName!;
      });
      
      _mapController.move(_selectedLocation!, 15.0);
      _showSuccessSnackBar(
        isCurrentLocation
          ? 'Current location set'
          : 'Location set to ${location['postalCode']}',
      );
    } catch (e) {
      _showErrorSnackBar('Failed to update location: ${e.toString()}');
      rethrow;
    }
  }

  void _showLoadingSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 10),
            Text(message),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: action,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isRequestingHelp ? 'Select Location' : 'Offer Help Location'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          hintText: 'Enter Singapore address or postal code',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.location_on),
                          suffixIcon: _isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : null,
                        ),
                        onSubmitted: (_) => _searchLocation(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _isSearching ? null : _searchLocation,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_selectedLocation != null && _postalCode != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Selected Location:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_locationName ?? 'Unknown address'),
                  Text('Postal Code: $_postalCode'),
                  const SizedBox(height: 8),
                  FutureBuilder<String>(
                    // Compare with self for ETA calculation
                    future: DistanceCalculator.getTimeEstimate(
                      _postalCode!,
                      _postalCode!, 
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Text('Please Check');
                      }
                      return const SizedBox();
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: _selectedLocation ?? latlong.LatLng(1.3521, 103.8198),
                zoom: 11.0,
                onTap: (_, latlong.LatLng latlng) async {
                  try {
                    _showLoadingSnackBar('Getting address...');
                    await _updateLocationFromCoordinates(
                      latlng.latitude,
                      latlng.longitude,
                    );
                  } catch (e) {
                    _showErrorSnackBar('Failed to select location: ${e.toString()}');
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),
                if (_selectedLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedLocation!,
                        builder: (ctx) => const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _selectedLocation == null || _postalCode == null
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AvailableHelpersPage(
                              service: widget.service,
                              date: widget.date,
                              time: widget.time,
                              location: _locationName!,
                              postalCode: _postalCode!,
                              isRequestingHelp: widget.isRequestingHelp,
                              userId: widget.userId,
                              requestType: widget.requestType,
                            ),
                          ),
                        );
                      },
                child: Text(
                  widget.isRequestingHelp ? 'Find Nearby Helpers' : 'Find Nearby Requests',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
