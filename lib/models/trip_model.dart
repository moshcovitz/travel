/// Model representing a travel trip
class TripModel {
  final int? id;
  final String name;
  final String? description;
  final int startTimestamp;
  final int? endTimestamp;
  final bool isActive;
  final double? budget;
  final String? budgetCurrency;

  TripModel({
    this.id,
    required this.name,
    this.description,
    required this.startTimestamp,
    this.endTimestamp,
    this.isActive = true,
    this.budget,
    this.budgetCurrency,
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
      'budget': budget,
      'budget_currency': budgetCurrency,
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
      budget: map['budget'] as double?,
      budgetCurrency: map['budget_currency'] as String?,
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
    double? budget,
    String? budgetCurrency,
  }) {
    return TripModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      startTimestamp: startTimestamp ?? this.startTimestamp,
      endTimestamp: endTimestamp ?? this.endTimestamp,
      isActive: isActive ?? this.isActive,
      budget: budget ?? this.budget,
      budgetCurrency: budgetCurrency ?? this.budgetCurrency,
    );
  }
}
