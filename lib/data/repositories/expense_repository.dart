import '../models/expense.dart';
import '../services/supabase_service.dart';

class ExpenseRepository {
  final SupabaseService supabaseService;

  ExpenseRepository({required this.supabaseService});

  /// Stream expenses in real-time
  Stream<List<Expense>> streamExpenses(String uid) =>
      supabaseService.streamExpenses(uid);

  /// Add a new expense
  Future<void> addExpense(String uid, Expense expense) =>
      supabaseService.addExpense(uid, expense);

  /// Update an existing expense
  Future<void> updateExpense(String uid, Expense expense) =>
      supabaseService.updateExpense(uid, expense);

  /// Delete an expense by ID
  Future<void> deleteExpense(String uid, String expenseId) =>
      supabaseService.deleteExpense(uid, expenseId);
}