// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Standalone CLI Migration Tool: Migrate Firebase / Local Data to Supabase
///
/// Usage:
///   dart run tool/migrate_firebase_to_supabase.dart [path_to_export.json]
///
/// If no file argument is given, it checks for `data_export.json` in the root directory.
void main(List<String> args) async {
  const supabaseUrl = 'https://nnwjfnjzkdonhezmdluz.supabase.co';
  const supabaseAnonKey = 'sb_publishable__bMTmX4n0LoEQqDUEjGezQ_te7E-F0T';

  print('==============================================');
  print('🚀 DailyCost Firebase -> Supabase Migrator');
  print('==============================================');

  final client = SupabaseClient(supabaseUrl, supabaseAnonKey);

  final filePath = args.isNotEmpty ? args.first : 'data_export.json';
  final file = File(filePath);

  if (!file.existsSync()) {
    print('ℹ️ No export file found at "$filePath".');
    print('To migrate existing data:');
    print('1. Export your Firestore / Local data as JSON with structure:');
    print('   { "profiles": [...], "expenses": [...], "categories": [...] }');
    print('2. Save as "$filePath" and run this script again:');
    print('   dart run tool/migrate_firebase_to_supabase.dart $filePath');
    return;
  }

  try {
    final content = await file.readAsString();
    final Map<String, dynamic> data = jsonDecode(content);

    // 1. Migrate Profiles
    final profiles = data['profiles'] as List<dynamic>? ?? [];
    print('📦 Migrating ${profiles.length} profiles...');
    for (final p in profiles) {
      final map = Map<String, dynamic>.from(p as Map);
      await client.from('profiles').upsert({
        'id': map['id'] ?? map['uid'],
        'email': map['email'],
        'display_name': map['displayName'] ?? map['display_name'],
        'monthly_income': map['monthlyIncome'] ?? map['monthly_income'] ?? 0,
        'savings_goal': map['savingsGoal'] ?? map['savings_goal'] ?? 0,
        'base_currency': map['baseCurrency'] ?? map['base_currency'] ?? 'USD',
        'cycle_start_day': map['cycleStartDay'] ?? map['cycle_start_day'] ?? 1,
        'fixed_costs': map['fixedCosts'] ?? map['fixed_costs'] ?? [],
        'created_at': map['createdAt'] ?? map['created_at'] ?? DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }

    // 2. Migrate Expenses
    final expenses = data['expenses'] as List<dynamic>? ?? [];
    print('💸 Migrating ${expenses.length} expenses...');
    for (final e in expenses) {
      final map = Map<String, dynamic>.from(e as Map);
      await client.from('expenses').upsert({
        'id': map['id'],
        'user_id': map['userId'] ?? map['user_id'],
        'amount': map['amount'] ?? 0,
        'currency': map['currency'] ?? 'USD',
        'amount_in_base_currency': map['amountInBaseCurrency'] ?? map['amount_in_base_currency'] ?? 0,
        'category': map['category'] ?? 'other',
        'note': map['note'],
        'date': map['date'] ?? DateTime.now().toIso8601String(),
        'created_at': map['createdAt'] ?? map['created_at'] ?? DateTime.now().toIso8601String(),
      });
    }

    // 3. Migrate Categories
    final categories = data['categories'] as List<dynamic>? ?? [];
    print('🏷️ Migrating ${categories.length} categories...');
    for (final c in categories) {
      final map = Map<String, dynamic>.from(c as Map);
      await client.from('categories').upsert({
        'id': map['id'],
        'user_id': map['userId'] ?? map['user_id'],
        'name': map['name'],
        'icon': map['icon'] ?? 'more_horiz',
        'color': map['colorHex'] ?? map['color'] ?? '#64748B',
        'is_default': map['isDefault'] ?? map['is_default'] ?? false,
        'is_hidden': map['isHidden'] ?? map['is_hidden'] ?? false,
      });
    }

    print('✅ Migration completed successfully!');
  } catch (e) {
    print('❌ Error during migration: $e');
  }
}
