/// Model representing a location data point
class LocationModel {
  final int? id;
  final int? tripId; // Foreign key to trips table
  final double latitude;
  final double longitude;
  final double altitude;
  final double accuracy;
  final int timestamp;
  final String address;

  LocationModel({
    this.id,
    this.tripId,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracy,
    required this.timestamp,
    required this.address,
  });

  /// Convert LocationModel to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'accuracy': accuracy,
      'timestamp': timestamp,
      'address': address,
    };
  }

  /// Create LocationModel from database Map
  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      id: map['id'] as int?,
      tripId: map['trip_id'] as int?,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      altitude: map['altitude'] as double,
      accuracy: map['accuracy'] as double,
      timestamp: map['timestamp'] as int,
      address: map['address'] as String,
    );
  }
}
