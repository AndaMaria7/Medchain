import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:logger/logger.dart';
import 'package:medchain_emergency/features/hospital/location_model.dart';

class LocationService {
  late final Logger _logger;

  LocationService() {
    _logger = Logger(
      printer: PrettyPrinter(methodCount: 0, lineLength: 50),
    );
  }

  /// Check location permissions
  Future<bool> checkPermissions() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        _logger.w('⚠️ Location permission denied, requesting...');
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _logger.e('❌ Location permission denied forever');
        return false;
      }

      return permission != LocationPermission.denied;
    } catch (e) {
      _logger.e('❌ Error checking location permissions: $e');
      return false;
    }
  }

  /// Get current location
  Future<LocationModel?> getCurrentLocation() async {
    try {
      final hasPermission = await checkPermissions();
      if (!hasPermission) {
        throw Exception('Location permission required');
      }

      _logger.i('📍 Getting current location...');

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Get address from coordinates
      String? address;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          address = '${placemark.street}, ${placemark.locality}, ${placemark.country}';
        }
      } catch (e) {
        _logger.w('⚠️ Could not get address: $e');
      }

      final location = LocationModel.fromPosition(position, address: address);
      
      _logger.i('✅ Location obtained: ${location.coordinatesString}');
      return location;

    } catch (e) {
      _logger.e('❌ Failed to get current location: $e');
      throw Exception('Failed to get current location: $e');
    }
  }

  /// Get location from address
  Future<LocationModel?> getLocationFromAddress(String address) async {
    try {
      _logger.d('🔍 Getting location for address: $address');

      final locations = await locationFromAddress(address);
      
      if (locations.isNotEmpty) {
        final location = locations.first;
        return LocationModel(
          latitude: location.latitude,
          longitude: location.longitude,
          address: address,
          timestamp: DateTime.now(),
        );
      }

      return null;
    } catch (e) {
      _logger.e('❌ Failed to get location from address: $e');
      return null;
    }
  }

  /// Calculate distance between two locations
  double calculateDistance(LocationModel from, LocationModel to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    ) / 1000; // Convert to kilometers
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Open location settings
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Stream of location updates
  Stream<LocationModel> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).map((position) => LocationModel.fromPosition(position));
  }
}