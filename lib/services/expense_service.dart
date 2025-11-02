import '../database/database_helper.dart';
import '../models/expense_model.dart';
import '../utils/app_logger.dart';
import 'currency_service.dart';

/// Service for managing trip expenses
class ExpenseService {
  static final ExpenseService instance = ExpenseService._init();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final CurrencyService _currencyService = CurrencyService.instance;

  ExpenseService._init();

  /// Add a new expense to a trip
  Future<ExpenseModel> addExpense({
    required int tripId,
    required String title,
    String? description,
    required double amount,
    required String currency,
    required ExpenseCategory category,
  }) async {
    try {
      final expense = ExpenseModel(
        tripId: tripId,
        title: title,
        description: description,
        amount: amount,
        currency: currency,
        category: category,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      final id = await _dbHelper.insertExpense(expense.toMap());
      AppLogger.info('Added expense: $title (\$$amount)');

      return expense.copyWith(id: id);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to add expense', e, stackTrace);
      rethrow;
    }
  }

  /// Get all expenses for a trip
  Future<List<ExpenseModel>> getExpensesForTrip(int tripId) async {
    try {
      final maps = await _dbHelper.getExpensesByTripId(tripId);
      return maps.map((map) => ExpenseModel.fromMap(map)).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get expenses for trip $tripId', e, stackTrace);
      rethrow;
    }
  }

  /// Get expense by ID
  Future<ExpenseModel?> getExpenseById(int id) async {
    try {
      final map = await _dbHelper.getExpenseById(id);
      if (map == null) return null;
      return ExpenseModel.fromMap(map);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get expense $id', e, stackTrace);
      rethrow;
    }
  }

  /// Update an expense
  Future<void> updateExpense(ExpenseModel expense) async {
    if (expense.id == null) {
      throw Exception('Cannot update expense without ID');
    }

    try {
      await _dbHelper.updateExpense(expense.id!, expense.toMap());
      AppLogger.info('Updated expense ID: ${expense.id}');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update expense', e, stackTrace);
      rethrow;
    }
  }

  /// Delete an expense
  Future<void> deleteExpense(int id) async {
    try {
      await _dbHelper.deleteExpense(id);
      AppLogger.info('Deleted expense ID: $id');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete expense', e, stackTrace);
      rethrow;
    }
  }

  /// Get expense statistics for a trip
  /// If targetCurrency is provided, all expenses will be converted to that currency
  Future<Map<String, dynamic>> getExpenseStatistics(
    int tripId, {
    String? targetCurrency,
  }) async {
    try {
      final expenses = await getExpensesForTrip(tripId);

      if (expenses.isEmpty) {
        return {
          'totalExpenses': 0.0,
          'expenseCount': 0,
          'categoryBreakdown': <String, double>{},
          'currency': targetCurrency ?? 'USD',
          'multiCurrency': false,
        };
      }

      // Determine the target currency
      final currency = targetCurrency ?? expenses.first.currency;

      // Check if we have multiple currencies
      final currencies = expenses.map((e) => e.currency).toSet();
      final isMultiCurrency = currencies.length > 1 || targetCurrency != null;

      // Calculate total and category breakdown (with currency conversion)
      double total = 0.0;
      Map<String, double> categoryBreakdown = {};

      for (var expense in expenses) {
        double amount = expense.amount;

        // Convert to target currency if needed
        if (expense.currency != currency) {
          amount = await _currencyService.convert(
            amount: expense.amount,
            from: expense.currency,
            to: currency,
          );
        }

        total += amount;
        final categoryName = expense.category.displayName;
        categoryBreakdown[categoryName] =
            (categoryBreakdown[categoryName] ?? 0.0) + amount;
      }

      return {
        'totalExpenses': total,
        'expenseCount': expenses.length,
        'categoryBreakdown': categoryBreakdown,
        'currency': currency,
        'multiCurrency': isMultiCurrency,
        'currencies': currencies.toList(),
      };
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get expense statistics', e, stackTrace);
      rethrow;
    }
  }

  /// Get expenses grouped by category
  Future<Map<ExpenseCategory, List<ExpenseModel>>> getExpensesByCategory(
      int tripId) async {
    try {
      final expenses = await getExpensesForTrip(tripId);
      final Map<ExpenseCategory, List<ExpenseModel>> grouped = {};

      for (var expense in expenses) {
        if (!grouped.containsKey(expense.category)) {
          grouped[expense.category] = [];
        }
        grouped[expense.category]!.add(expense);
      }

      return grouped;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to group expenses by category', e, stackTrace);
      rethrow;
    }
  }
}
