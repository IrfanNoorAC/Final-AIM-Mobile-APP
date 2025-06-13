
import 'dart:math';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

class DistanceCalculator {
  // Default walking speed in km/h
  static const double defaultWalkingSpeed = 5.0;
  // Default cycling speed in km/h
  static const double defaultCyclingSpeed = 15.0;
  static const double defaultBusSpeed = 25.0; 
  // Default driving speed in km/h
  static const double defaultDrivingSpeed = 50.0;

  /// Get detailed location information from a postal code
  static Future<Map<String, dynamic>> getLocationDetails(String postalCode) async {
    try {
      final locations = await locationFromAddress('$postalCode, Singapore');
      if (locations.isEmpty) {
        throw Exception('Could not determine coordinates for postal code');
      }
      
      final placemarks = await placemarkFromCoordinates(
        locations.first.latitude,
        locations.first.longitude,
        localeIdentifier: 'en_SG',
      );
      
      return {
        'latitude': locations.first.latitude,
        'longitude': locations.first.longitude,
        'postalCode': postalCode,
        'address': placemarks.isNotEmpty 
          ? _formatAddress(placemarks.first) 
          : 'Unknown location',
      };
    } catch (e) {
      throw Exception('Failed to get coordinates: $e');
    }
  }

  /// Formats an address from placemark data
  static String _formatAddress(Placemark place) {
    return [
      place.street,
      place.subLocality,
      place.locality,
      place.postalCode,
    ].where((part) => part != null && part.isNotEmpty).join(', ');
  }

  /// Calculates the distance between two postal codes in kilometers
  static Future<double> calculateDistance(String postal1, String postal2) async {
    try {
      final loc1 = await getLocationDetails(postal1);
      final loc2 = await getLocationDetails(postal2);
      return _haversineDistance(
        loc1['latitude'], loc1['longitude'],
        loc2['latitude'], loc2['longitude'],
      );
    } catch (e) {
      // Default large distance if calculation fails
      return 10000.0; 
    }
  }

  /// Gets a formatted distance string (for e.g "3.5 km")
  static Future<String> getFormattedDistance(String postal1, String postal2) async {
    final distance = await calculateDistance(postal1, postal2);
    return '${distance.toStringAsFixed(1)} km';
  }

  /// Gets a time estimate string based on walking speed
  static Future<String> getTimeEstimate(String postal1, String postal2, 
      {String transportMode = 'walking'}) async {
    final distance = await calculateDistance(postal1, postal2);
    double speed;
    
    switch (transportMode.toLowerCase()) {
      case 'cycling':
        speed = defaultCyclingSpeed;
        break;
         case 'bus':
    speed = defaultBusSpeed;
    break;
      case 'driving':
        speed = defaultDrivingSpeed;
        break;
      case 'walking':
      default:
        speed = defaultWalkingSpeed;
    }

    final minutes = (distance / speed * 60).toInt();
    
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '$hours h ${remainingMinutes} min';
  }

  /// Calculates estimated time in minutes
  static Future<double> calculateEstimatedTime(
    String postal1, 
    String postal2, {
    String transportMode = 'walking',
  }) async {
    final distance = await calculateDistance(postal1, postal2);
    double speed;
    
    switch (transportMode.toLowerCase()) {
      case 'cycling':
        speed = defaultCyclingSpeed;
        break;
        case 'bus':
    speed = defaultBusSpeed;
    break;
      case 'driving':
        speed = defaultDrivingSpeed;
        break;
      case 'walking':
      default:
        speed = defaultWalkingSpeed;
    }

    return (distance / speed) * 60;
  }

  /// Gets both distance and time estimate in a single call
  static Future<Map<String, dynamic>> getDistanceAndTime(
    String postal1, 
    String postal2, {
    String transportMode = 'walking',
  }) async {
    final distance = await calculateDistance(postal1, postal2);
    final time = await calculateEstimatedTime(postal1, postal2, transportMode: transportMode);
    
    return {
      'distance': distance,
      'distanceText': '${distance.toStringAsFixed(1)} km',
      'time': time,
      'timeText': _formatTimeEstimate(time),
      'transportMode': transportMode,
    };
  }

  /// Formats time estimate into a readable string
  static String _formatTimeEstimate(double minutes) {
    if (minutes < 60) return '${minutes.toStringAsFixed(0)} min';
    final hours = (minutes / 60).floor();
    final remainingMinutes = (minutes % 60).round();
    return '$hours h ${remainingMinutes} min';
  }

  /// Haversine formula for calculating distance between two coordinates
  static double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    // Earth radius in km
    const R = 6371.0; 
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  /// Converts degrees to radians
  static double _toRadians(double degree) => degree * pi / 180;

  /// Checks if coordinates are in Singapore
  static Future<bool> isSingaporeLocation(double lat, double lng) async {
    try {
      final places = await placemarkFromCoordinates(lat, lng);
      return places.isNotEmpty && 
             (places.first.isoCountryCode == 'SG' || 
              places.first.country?.toLowerCase().contains('singapore') == true);
    } catch (e) {
      return false;
    }
  }
}

