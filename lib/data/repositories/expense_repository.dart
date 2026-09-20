import '../models/expense.dart';
import '../services/supabase_service.dart';

class ExpenseRepository {
  final SupabaseService supabaseService;

  ExpenseRepository({required this.supabaseService});

  Stream<List<Expense>> streamExpenses(String uid) =>
      supabaseService.streamExpenses(uid);

  Future<void> addExpense(String uid, Expense expense) =>
      supabaseService.addExpense(uid, expense);

  Future<void> updateExpense(String uid, Expense expense) =>
      supabaseService.updateExpense(uid, expense);

  Future<void> deleteExpense(String uid, String expenseId) =>
      supabaseService.deleteExpense(uid, expenseId);
}
