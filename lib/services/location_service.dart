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
  /// If there's an active trip, associates the location with that trip
  Future<void> _saveLocationToDatabase(Position position) async {
    try {
      AppLogger.debug('Saving location to database');

      // Try to get the active trip
      final activeTripMap = await DatabaseHelper.instance.getActiveTrip();
      final int? tripId = activeTripMap?['id'] as int?;

      if (tripId != null) {
        AppLogger.debug('Associating location with active trip ID: $tripId');
      } else {
        AppLogger.debug('No active trip found, saving location without trip association');
      }

      final location = LocationModel(
        tripId: tripId,
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: position.altitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp.millisecondsSinceEpoch,
        address: 'Lat: ${position.latitude.toStringAsFixed(6)}, Lon: ${position.longitude.toStringAsFixed(6)}',
      );

      await DatabaseHelper.instance.insertLocation(location.toMap());
      AppLogger.info('Location saved to database successfully${tripId != null ? ' (Trip ID: $tripId)' : ''}');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save location to database', e, stackTrace);
      // Don't rethrow - we don't want to fail the entire location fetch if DB save fails
    }
  }

  /// Get all locations from the database
  Future<List<LocationModel>> getAllLocations() async {
    try {
      AppLogger.debug('Fetching all locations from database');
      final locationMaps = await DatabaseHelper.instance.getAllLocations();
      final locations = locationMaps.map((map) => LocationModel.fromMap(map)).toList();
      AppLogger.info('Fetched ${locations.length} locations');
      return locations;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch all locations', e, stackTrace);
      rethrow;
    }
  }

  /// Get locations for a specific trip
  Future<List<LocationModel>> getLocationsByTripId(int tripId) async {
    try {
      AppLogger.debug('Fetching locations for trip ID: $tripId');
      final locationMaps = await DatabaseHelper.instance.getLocationsByTripId(tripId);
      final locations = locationMaps.map((map) => LocationModel.fromMap(map)).toList();
      AppLogger.info('Fetched ${locations.length} locations for trip $tripId');
      return locations;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch locations for trip', e, stackTrace);
      rethrow;
    }
  }

  /// Delete a location by ID
  Future<void> deleteLocation(int locationId) async {
    try {
      AppLogger.info('Deleting location ID: $locationId');
      await DatabaseHelper.instance.deleteLocation(locationId);
      AppLogger.info('Location deleted successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete location', e, stackTrace);
      rethrow;
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
