import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Retrieves current coordinates, including comprehensive permission handling.
  static Future<Position?> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verify if system-level location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    // Check current permission status.
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Throw error with specific keywords for the UI layer to catch and show settings dialog.
      return Future.error('Location permissions are permanently denied.');
    }

    // Fetch high-accuracy position.
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Reverse Geocoding: Converts latitude and longitude into a readable address string.
  static Future<String> getAddress(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        lat,
        lng,
      );

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;

        // Optimization: Determine formatting strategy based on region.
        bool isChina = (place.country == 'China' || place.isoCountryCode == 'CN');

        final List<String?> parts = [
          place.administrativeArea, // State/Province
          place.locality,           // City
          place.subLocality,        // District
          place.thoroughfare,       // Street
          place.name                // Building/POI
        ];

        // Intelligent deduplication and string construction.
        List<String> finalParts = [];
        for (var part in parts) {
          if (part != null && part.isNotEmpty && !finalParts.contains(part)) {
            finalParts.add(part);
          }
        }

        if (isChina) {
          // Chinese Format: Continuous concatenation without spaces.
          return finalParts.join('');
        } else {
          // International Format: Comma-separated segments.
          return finalParts.join(', ');
        }
      }
    } catch (e) {
      debugPrint("[LocationService] Geocoding failed: $e");
    }

    // Fallback: Return formatted coordinates if geocoding fails.
    return "${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}";
  }
}