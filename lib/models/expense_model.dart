class ExpenseModel {
  final int? id;
  final int tripId;
  final double amount;
  final String category;
  final String? description;
  final int timestamp;
  final String currency;

  ExpenseModel({
    this.id,
    required this.tripId,
    required this.amount,
    required this.category,
    this.description,
    required this.timestamp,
    this.currency = 'USD',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'amount': amount,
      'category': category,
      'description': description,
      'timestamp': timestamp,
      'currency': currency,
    };
  }

  static ExpenseModel fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] as int?,
      tripId: map['trip_id'] as int,
      amount: map['amount'] as double,
      category: map['category'] as String,
      description: map['description'] as String?,
      timestamp: map['timestamp'] as int,
      currency: map['currency'] as String? ?? 'USD',
    );
  }

  @override
  String toString() {
    return 'ExpenseModel{id: $id, tripId: $tripId, amount: $amount, category: $category, description: $description, timestamp: $timestamp, currency: $currency}';
  }
}

// Common expense categories
class ExpenseCategory {
  static const String food = 'Food';
  static const String transportation = 'Transportation';
  static const String accommodation = 'Accommodation';
  static const String activities = 'Activities';
  static const String shopping = 'Shopping';
  static const String other = 'Other';

  static List<String> get all => [
        food,
        transportation,
        accommodation,
        activities,
        shopping,
        other,
      ];
}
