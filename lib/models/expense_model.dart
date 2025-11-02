enum ExpenseCategory {
  food,
  transport,
  accommodation,
  activities,
  shopping,
  other;

  String get displayName {
    switch (this) {
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.accommodation:
        return 'Accommodation';
      case ExpenseCategory.activities:
        return 'Activities';
      case ExpenseCategory.shopping:
        return 'Shopping';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  String get iconName {
    switch (this) {
      case ExpenseCategory.food:
        return 'restaurant';
      case ExpenseCategory.transport:
        return 'directions_car';
      case ExpenseCategory.accommodation:
        return 'hotel';
      case ExpenseCategory.activities:
        return 'local_activity';
      case ExpenseCategory.shopping:
        return 'shopping_bag';
      case ExpenseCategory.other:
        return 'more_horiz';
    }
  }
}

class ExpenseModel {
  final int? id;
  final int tripId;
  final String title;
  final String? description;
  final double amount;
  final String currency;
  final ExpenseCategory category;
  final int timestamp;

  ExpenseModel({
    this.id,
    required this.tripId,
    required this.title,
    this.description,
    required this.amount,
    required this.currency,
    required this.category,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'title': title,
      'description': description,
      'amount': amount,
      'currency': currency,
      'category': category.name,
      'timestamp': timestamp,
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] as int?,
      tripId: map['trip_id'] as int,
      title: map['title'] as String,
      description: map['description'] as String?,
      amount: map['amount'] as double,
      currency: map['currency'] as String,
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ExpenseCategory.other,
      ),
      timestamp: map['timestamp'] as int,
    );
  }

  ExpenseModel copyWith({
    int? id,
    int? tripId,
    String? title,
    String? description,
    double? amount,
    String? currency,
    ExpenseCategory? category,
    int? timestamp,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
