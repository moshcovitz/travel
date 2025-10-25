import '../services/trip_service.dart';
import '../database/database_helper.dart';
import '../models/location_model.dart';
import '../utils/app_logger.dart';

class DebugData {
  static final TripService _tripService = TripService.instance;

  static Future<void> addSampleTrips() async {
    try {
      AppLogger.info('Adding sample trips for debugging...');

      await _addEuropeTripSummer2024();
      await _addJapanTrip2024();
      await _addUSARoadTrip2023();

      AppLogger.info('Sample trips added successfully!');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to add sample trips', e, stackTrace);
      rethrow;
    }
  }

  static Future<void> _addEuropeTripSummer2024() async {
    final tripId = await _tripService.createTrip(
      name: 'Europe Summer 2024',
      description: 'Backpacking through Western Europe',
    );

    await _tripService.endTrip(tripId);

    final locations = [
      LocationModel(
        tripId: tripId,
        latitude: 48.8566,
        longitude: 2.3522,
        altitude: 35.0,
        accuracy: 10.0,
        timestamp: DateTime(2024, 7, 1, 10, 0).millisecondsSinceEpoch,
        address: 'Paris, France',
        country: 'France',
      ),
      LocationModel(
        tripId: tripId,
        latitude: 48.8584,
        longitude: 2.2945,
        altitude: 35.0,
        accuracy: 10.0,
        timestamp: DateTime(2024, 7, 1, 14, 30).millisecondsSinceEpoch,
        address: 'Eiffel Tower, Paris',
        country: 'France',
      ),
      LocationModel(
        tripId: tripId,
        latitude: 51.5074,
        longitude: -0.1278,
        altitude: 11.0,
        accuracy: 10.0,
        timestamp: DateTime(2024, 7, 5, 9, 0).millisecondsSinceEpoch,
        address: 'London, United Kingdom',
        country: 'United Kingdom',
      ),
      LocationModel(
        tripId: tripId,
        latitude: 51.5007,
        longitude: -0.1246,
        altitude: 11.0,
        accuracy: 10.0,
        timestamp: DateTime(2024, 7, 5, 15, 0).millisecondsSinceEpoch,
        address: 'Big Ben, London',
        country: 'United Kingdom',
      ),
      LocationModel(
        tripId: tripId,
        latitude: 52.5200,
        longitude: 13.4050,
        altitude: 34.0,
        accuracy: 10.0,
        timestamp: DateTime(2024, 7, 10, 11, 0).millisecondsSinceEpoch,
        address: 'Berlin, Germany',
        country: 'Germany',
      ),
      LocationModel(
        tripId: tripId,
        latitude: 52.5163,
        longitude: 13.3777,
        altitude: 34.0,
        accuracy: 10.0,
        timestamp: DateTime(2024, 7, 10, 16, 0).millisecondsSinceEpoch,
        address: 'Brandenburg Gate, Berlin',
        country: 'Germany',
      ),
    ];

    for (var location in locations) {
      await DatabaseHelper.instance.insertLocation(location.toMap());
    }

    AppLogger.info('Added Europe Summer 2024 trip with ${locations.length} locations');
  }

  static Future<void> _addJapanTrip2024() async {
    final tripId = await _tripService.createTrip(
      name: 'Japan Adventure 2024',
      description: 'Exploring Tokyo, Kyoto, and Mount Fuji',
    );

    await _tripService.endTrip(tripId);

    final locations = [
      LocationModel(
        tripId: tripId,
        latitude: 35.6762,
        longitude: 139.6503,
        altitude: 40.0,
        accuracy: 10.0,
        timestamp: DateTime(2024, 9, 1, 8, 0).millisecondsSinceEpoch,
        address: 'Tokyo, Japan',
        country: 'Japan',
      ),
      LocationModel(
        tripId: tripId,
        latitude: 35.7096,
        longitude: 139.8107,
        altitude: 40.0,
        accuracy: 10.0,
        timestamp: DateTime(2024, 9, 2, 10, 0).millisecondsSinceEpoch,
        address: 'Tokyo Skytree, Tokyo',
        country: 'Japan',
      ),
      LocationModel(
        tripId: tripId,
        latitude: 35.0116,
        longitude: 135.7681,
        altitude: 50.0,
        accuracy: 10.0,
        timestamp: DateTime(2024, 9, 5, 9, 0).millisecondsSinceEpoch,
        address: 'Kyoto, Japan',
        country: 'Japan',
      ),
      LocationModel(
        tripId: tripId,
        latitude: 35.3606,
        longitude: 138.7274,
        altitude: 1200.0,
        accuracy: 15.0,
        timestamp: DateTime(2024, 9, 8, 7, 0).millisecondsSinceEpoch,
        address: 'Mount Fuji, Japan',
        country: 'Japan',
      ),
    ];

    for (var location in locations) {
      await DatabaseHelper.instance.insertLocation(location.toMap());
    }

    AppLogger.info('Added Japan Adventure 2024 trip with ${locations.length} locations');
  }

  static Future<void> _addUSARoadTrip2023() async {
    final tripId = await _tripService.createTrip(
      name: 'USA Road Trip 2023',
      description: 'Cross-country adventure from NYC to LA',
    );

    await _tripService.endTrip(tripId);

    final locations = [
      LocationModel(
        tripId: tripId,
        latitude: 40.7128,
        longitude: -74.0060,
        altitude: 10.0,
        accuracy: 10.0,
        timestamp: DateTime(2023, 8, 1, 9, 0).millisecondsSinceEpoch,
        address: 'New York City, NY',
        country: 'United States',
      ),
      LocationModel(
        tripId: tripId,
        latitude: 40.7580,
        longitude: -73.9855,
        altitude: 10.0,
        accuracy: 10.0,
        timestamp: DateTime(2023, 8, 1, 14, 0).millisecondsSinceEpoch,
        address: 'Times Square, NYC',
        country: 'United States',
      ),
      LocationModel(
        tripId: tripId,
        latitude: 41.8781,
        longitude: -87.6298,
        altitude: 181.0,
        accuracy: 10.0,
        timestamp: DateTime(2023, 8, 5, 10, 0).millisecondsSinceEpoch,
        address: 'Chicago, IL',
        country: 'United States',
      ),
      LocationModel(
        tripId: tripId,
        latitude: 36.1699,
        longitude: -115.1398,
        altitude: 610.0,
        accuracy: 10.0,
        timestamp: DateTime(2023, 8, 10, 20, 0).millisecondsSinceEpoch,
        address: 'Las Vegas, NV',
        country: 'United States',
      ),
      LocationModel(
        tripId: tripId,
        latitude: 36.0544,
        longitude: -112.1401,
        altitude: 2100.0,
        accuracy: 15.0,
        timestamp: DateTime(2023, 8, 12, 11, 0).millisecondsSinceEpoch,
        address: 'Grand Canyon, AZ',
        country: 'United States',
      ),
      LocationModel(
        tripId: tripId,
        latitude: 34.0522,
        longitude: -118.2437,
        altitude: 71.0,
        accuracy: 10.0,
        timestamp: DateTime(2023, 8, 15, 16, 0).millisecondsSinceEpoch,
        address: 'Los Angeles, CA',
        country: 'United States',
      ),
    ];

    for (var location in locations) {
      await DatabaseHelper.instance.insertLocation(location.toMap());
    }

    AppLogger.info('Added USA Road Trip 2023 with ${locations.length} locations');
  }

  static Future<void> clearAllData() async {
    try {
      AppLogger.info('Clearing all trips and locations...');

      final trips = await _tripService.getAllTrips();
      for (var trip in trips) {
        await _tripService.deleteTrip(trip.id!);
      }

      AppLogger.info('All data cleared successfully!');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear data', e, stackTrace);
      rethrow;
    }
  }
}
