import '../database/database_helper.dart';
import '../models/expense_model.dart';
import '../utils/app_logger.dart';

/// Service to manage expenses for trips
class ExpenseService {
  static final ExpenseService instance = ExpenseService._init();

  ExpenseService._init();

  /// Add a new expense to a trip
  Future<int> addExpense({
    required int tripId,
    required double amount,
    required String category,
    String? description,
    String currency = 'USD',
  }) async {
    try {
      AppLogger.info('Adding expense for trip ID: $tripId');

      final expense = ExpenseModel(
        tripId: tripId,
        amount: amount,
        category: category,
        description: description,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        currency: currency,
      );

      final expenseId = await DatabaseHelper.instance.insertExpense(expense.toMap());
      AppLogger.info('Expense added successfully with ID: $expenseId');
      return expenseId;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to add expense', e, stackTrace);
      rethrow;
    }
  }

  /// Get all expenses
  Future<List<ExpenseModel>> getAllExpenses() async {
    try {
      final expenseMaps = await DatabaseHelper.instance.getAllExpenses();
      return expenseMaps.map((map) => ExpenseModel.fromMap(map)).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get all expenses', e, stackTrace);
      rethrow;
    }
  }

  /// Get all expenses for a specific trip
  Future<List<ExpenseModel>> getExpensesForTrip(int tripId) async {
    try {
      AppLogger.debug('Getting expenses for trip ID: $tripId');
      final expenseMaps = await DatabaseHelper.instance.getExpensesByTripId(tripId);
      return expenseMaps.map((map) => ExpenseModel.fromMap(map)).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get expenses for trip', e, stackTrace);
      rethrow;
    }
  }

  /// Get expense by ID
  Future<ExpenseModel?> getExpenseById(int id) async {
    try {
      final expenseMap = await DatabaseHelper.instance.getExpenseById(id);
      if (expenseMap != null) {
        return ExpenseModel.fromMap(expenseMap);
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get expense by ID', e, stackTrace);
      rethrow;
    }
  }

  /// Update an expense
  Future<void> updateExpense(int expenseId, ExpenseModel expense) async {
    try {
      AppLogger.debug('Updating expense ID: $expenseId');
      await DatabaseHelper.instance.updateExpense(expenseId, expense.toMap());
      AppLogger.info('Expense updated successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update expense', e, stackTrace);
      rethrow;
    }
  }

  /// Delete an expense
  Future<void> deleteExpense(int expenseId) async {
    try {
      AppLogger.info('Deleting expense ID: $expenseId');
      await DatabaseHelper.instance.deleteExpense(expenseId);
      AppLogger.info('Expense deleted successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete expense', e, stackTrace);
      rethrow;
    }
  }

  /// Get total expenses for a trip
  Future<double> getTotalExpensesForTrip(int tripId) async {
    try {
      AppLogger.debug('Calculating total expenses for trip ID: $tripId');
      final total = await DatabaseHelper.instance.getTotalExpensesForTrip(tripId);
      return total;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to calculate total expenses', e, stackTrace);
      rethrow;
    }
  }

  /// Get expenses grouped by category for a trip
  Future<Map<String, double>> getExpensesByCategoryForTrip(int tripId) async {
    try {
      AppLogger.debug('Getting expense breakdown by category for trip ID: $tripId');
      return await DatabaseHelper.instance.getExpensesByCategoryForTrip(tripId);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get expenses by category', e, stackTrace);
      rethrow;
    }
  }

  /// Get expense statistics for a trip
  Future<Map<String, dynamic>> getExpenseStatistics(int tripId) async {
    try {
      AppLogger.debug('Calculating expense statistics for trip ID: $tripId');

      final expenses = await getExpensesForTrip(tripId);
      final total = await getTotalExpensesForTrip(tripId);
      final categoryBreakdown = await getExpensesByCategoryForTrip(tripId);

      // Find the highest category
      String topCategory = 'None';
      double topCategoryAmount = 0.0;
      if (categoryBreakdown.isNotEmpty) {
        final sortedCategories = categoryBreakdown.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        topCategory = sortedCategories.first.key;
        topCategoryAmount = sortedCategories.first.value;
      }

      return {
        'totalExpenses': total,
        'expenseCount': expenses.length,
        'categoryBreakdown': categoryBreakdown,
        'topCategory': topCategory,
        'topCategoryAmount': topCategoryAmount,
        'averageExpense': expenses.isNotEmpty ? total / expenses.length : 0.0,
      };
    } catch (e, stackTrace) {
      AppLogger.error('Failed to calculate expense statistics', e, stackTrace);
      rethrow;
    }
  }
}
