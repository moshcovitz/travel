import 'package:geolocator/geolocator.dart';
import '../database/database_helper.dart';
import '../models/location_model.dart';
import '../utils/app_logger.dart';

class LocationService {
  static final LocationService instance = LocationService._init();

  LocationService._init();

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      AppLogger.info('Getting current location');

      // Check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.warning('Location services are disabled');
        throw Exception('Location services are disabled. Please enable location services in Settings.');
      }
      AppLogger.debug('Location services are enabled');

      // Check permissions
      LocationPermission permission = await checkPermission();
      AppLogger.debug('Current permission status: $permission');

      if (permission == LocationPermission.denied) {
        AppLogger.info('Requesting location permission');
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          AppLogger.warning('Location permissions denied by user');
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        AppLogger.warning('Location permissions permanently denied');
        throw Exception('Location permissions are permanently denied. Please enable them in Settings.');
      }

      // Get current position
      AppLogger.debug('Fetching current position with high accuracy');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      AppLogger.info('Location retrieved: Lat ${position.latitude.toStringAsFixed(6)}, Lon ${position.longitude.toStringAsFixed(6)}');

      // Save to database
      await _saveLocationToDatabase(position);

      return position;
    } catch (e, stackTrace) {
      AppLogger.error('Error getting location', e, stackTrace);
      rethrow;
    }
  }

  /// Save location to database
  Future<void> _saveLocationToDatabase(Position position) async {
    try {
      AppLogger.debug('Saving location to database');
      final location = LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: position.altitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp.millisecondsSinceEpoch,
        address: 'Lat: ${position.latitude.toStringAsFixed(6)}, Lon: ${position.longitude.toStringAsFixed(6)}',
      );

      await DatabaseHelper.instance.insertLocation(location.toMap());
      AppLogger.info('Location saved to database successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save location to database', e, stackTrace);
      // Don't rethrow - we don't want to fail the entire location fetch if DB save fails
    }
  }

  /// Stream location updates
  Stream<Position> getLocationStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  /// Calculate distance between two coordinates in meters
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }
}
