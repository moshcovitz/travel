import 'dart:math';

import '../database/database_helper.dart';
import '../models/trip_model.dart';
import '../models/location_model.dart';
import '../utils/app_logger.dart';

/// Service to manage trips and their associated locations
class TripService {
  static final TripService instance = TripService._init();

  TripService._init();

  /// Create a new trip and mark it as active
  Future<int> createTrip({
    required String name,
    String? description,
  }) async {
    try {
      AppLogger.info('Creating new trip: $name');

      // End any existing active trips first
      final activeTrip = await getActiveTrip();
      if (activeTrip != null) {
        AppLogger.info('Ending previous active trip: ${activeTrip.name}');
        await endTrip(activeTrip.id!);
      }

      final trip = TripModel(
        name: name,
        description: description,
        startTimestamp: DateTime.now().millisecondsSinceEpoch,
        isActive: true,
      );

      final tripId = await DatabaseHelper.instance.insertTrip(trip.toMap());
      AppLogger.info('Trip created successfully with ID: $tripId');
      return tripId;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create trip', e, stackTrace);
      rethrow;
    }
  }

  /// Get the currently active trip
  Future<TripModel?> getActiveTrip() async {
    try {
      final tripMap = await DatabaseHelper.instance.getActiveTrip();
      if (tripMap != null) {
        return TripModel.fromMap(tripMap);
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get active trip', e, stackTrace);
      rethrow;
    }
  }

  /// Get trip by ID
  Future<TripModel?> getTripById(int id) async {
    try {
      final tripMap = await DatabaseHelper.instance.getTripById(id);
      if (tripMap != null) {
        return TripModel.fromMap(tripMap);
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get trip by ID', e, stackTrace);
      rethrow;
    }
  }

  /// Get all trips
  Future<List<TripModel>> getAllTrips() async {
    try {
      final tripMaps = await DatabaseHelper.instance.getAllTrips();
      return tripMaps.map((map) => TripModel.fromMap(map)).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get all trips', e, stackTrace);
      rethrow;
    }
  }

  /// End a trip
  Future<void> endTrip(int tripId) async {
    try {
      AppLogger.info('Ending trip ID: $tripId');
      final endTimestamp = DateTime.now().millisecondsSinceEpoch;
      await DatabaseHelper.instance.endTrip(tripId, endTimestamp);
      AppLogger.info('Trip ended successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to end trip', e, stackTrace);
      rethrow;
    }
  }

  /// Update trip details
  Future<void> updateTrip(int tripId, TripModel trip) async {
    try {
      AppLogger.debug('Updating trip ID: $tripId');
      await DatabaseHelper.instance.updateTrip(tripId, trip.toMap());
      AppLogger.info('Trip updated successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update trip', e, stackTrace);
      rethrow;
    }
  }

  /// Delete a trip (will cascade delete all locations)
  Future<void> deleteTrip(int tripId) async {
    try {
      AppLogger.warning('Deleting trip ID: $tripId');
      await DatabaseHelper.instance.deleteTrip(tripId);
      AppLogger.info('Trip deleted successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete trip', e, stackTrace);
      rethrow;
    }
  }

  /// Get all locations for a specific trip
  Future<List<LocationModel>> getLocationsForTrip(int tripId) async {
    try {
      AppLogger.debug('Getting locations for trip ID: $tripId');
      final locationMaps = await DatabaseHelper.instance.getLocationsByTripId(tripId);
      return locationMaps.map((map) => LocationModel.fromMap(map)).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get locations for trip', e, stackTrace);
      rethrow;
    }
  }

  /// Get trip statistics (total locations, distance, duration)
  Future<Map<String, dynamic>> getTripStatistics(int tripId) async {
    try {
      AppLogger.debug('Calculating statistics for trip ID: $tripId');

      final trip = await getTripById(tripId);
      if (trip == null) {
        throw Exception('Trip not found');
      }

      final locations = await getLocationsForTrip(tripId);

      // Calculate duration
      final startTime = DateTime.fromMillisecondsSinceEpoch(trip.startTimestamp);
      final endTime = trip.endTimestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(trip.endTimestamp!)
          : DateTime.now();
      final duration = endTime.difference(startTime);

      // Calculate total distance (sum of distances between consecutive locations)
      double totalDistance = 0.0;
      if (locations.length > 1) {
        for (int i = 0; i < locations.length - 1; i++) {
          final start = locations[i];
          final end = locations[i + 1];
          // Using simple distance calculation (could be improved with proper geo calculation)
          final distance = _calculateDistance(
            start.latitude,
            start.longitude,
            end.latitude,
            end.longitude,
          );
          totalDistance += distance;
        }
      }

      return {
        'tripName': trip.name,
        'totalLocations': locations.length,
        'totalDistanceKm': totalDistance / 1000,
        'durationHours': duration.inHours,
        'durationMinutes': duration.inMinutes % 60,
        'isActive': trip.isActive,
      };
    } catch (e, stackTrace) {
      AppLogger.error('Failed to calculate trip statistics', e, stackTrace);
      rethrow;
    }
  }

  /// Calculate distance between two coordinates using Haversine formula (in meters)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // meters
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final lat1Rad = _toRadians(lat1);
    final lat2Rad = _toRadians(lat2);

    final a = pow(sin(dLat / 2), 2) +
        cos(lat1Rad) * cos(lat2Rad) * pow(sin(dLon / 2), 2);

    final c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (pi / 180);
  }
}
