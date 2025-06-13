
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );
  }

  static Future<Placemark> getPlacemarkFromPosition(Position position) async {
    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
      localeIdentifier: 'en_SG',
    );
    return placemarks.first;
  }

  static Future<Placemark> getPlacemarkFromAddress(String address) async {
    final locations = await locationFromAddress('$address, Singapore');
    if (locations.isEmpty) {
      throw Exception('No location found for address');
    }

    final placemarks = await placemarkFromCoordinates(
      locations.first.latitude,
      locations.first.longitude,
      localeIdentifier: 'en_SG',
    );
    return placemarks.first;
  }

  static Future<bool> isSingaporeLocation(double latitude, double longitude) async {
    try {
      final place = await getPlacemarkFromPosition(Position(
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0, 
        headingAccuracy: 0,
      ));
      return place.isoCountryCode == 'SG';
    } catch (e) {
      return false;
    }
  }
}

