/// Model representing a travel trip
class TripModel {
  final int? id;
  final String name;
  final String? description;
  final int startTimestamp;
  final int? endTimestamp;
  final bool isActive;

  TripModel({
    this.id,
    required this.name,
    this.description,
    required this.startTimestamp,
    this.endTimestamp,
    this.isActive = true,
  });

  /// Convert TripModel to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'start_timestamp': startTimestamp,
      'end_timestamp': endTimestamp,
      'is_active': isActive ? 1 : 0,
    };
  }

  /// Create TripModel from database Map
  factory TripModel.fromMap(Map<String, dynamic> map) {
    return TripModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      startTimestamp: map['start_timestamp'] as int,
      endTimestamp: map['end_timestamp'] as int?,
      isActive: (map['is_active'] as int) == 1,
    );
  }

  /// Create a copy of this trip with updated fields
  TripModel copyWith({
    int? id,
    String? name,
    String? description,
    int? startTimestamp,
    int? endTimestamp,
    bool? isActive,
  }) {
    return TripModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      startTimestamp: startTimestamp ?? this.startTimestamp,
      endTimestamp: endTimestamp ?? this.endTimestamp,
      isActive: isActive ?? this.isActive,
    );
  }
}
