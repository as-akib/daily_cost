import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../models/expense.dart';
import '../models/category_item.dart';
import '../../core/constants/app_constants.dart';

class SupabaseService {
  final SupabaseClient? client;

  // In-memory reactive state
  final Map<String, UserProfile> _localProfiles = {};
  final Map<String, List<Expense>> _localExpenses = {};
  final Map<String, List<CategoryItem>> _localCategories = {};

  final Map<String, StreamController<UserProfile?>> _profileControllers = {};
  final Map<String, StreamController<List<Expense>>> _expenseControllers = {};
  final Map<String, StreamController<List<CategoryItem>>> _categoryControllers = {};

  SupabaseService({this.client}) {
    _initLocalCache();
  }

  bool get isSupabaseAvailable => client != null;

  Future<void> _initLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profilesJson = prefs.getString('dailycost_cache_profiles');
      if (profilesJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(profilesJson);
        decoded.forEach((uid, val) {
          _localProfiles[uid] =
              UserProfile.fromMap(Map<String, dynamic>.from(val), uid);
        });
      }

      final expensesJson = prefs.getString('dailycost_cache_expenses');
      if (expensesJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(expensesJson);
        decoded.forEach((uid, val) {
          final List list = val as List;
          _localExpenses[uid] = list
              .map((e) => Expense.fromMap(Map<String, dynamic>.from(e), ''))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error reading local cache: $e');
    }
  }

  Future<void> _persistProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> map = {};
      _localProfiles.forEach((uid, profile) {
        map[uid] = profile.toMap();
      });
      await prefs.setString('dailycost_cache_profiles', jsonEncode(map));
    } catch (_) {}
  }

  Future<void> _persistExpenses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> map = {};
      _localExpenses.forEach((uid, expenses) {
        map[uid] = expenses.map((e) => e.toMap()).toList();
      });
      await prefs.setString('dailycost_cache_expenses', jsonEncode(map));
    } catch (_) {}
  }

  // ===================== PROFILES =====================

  Stream<UserProfile?> streamProfile(String uid) {
    if (!_profileControllers.containsKey(uid)) {
      _profileControllers[uid] = StreamController<UserProfile?>.broadcast();
    }

    // 1. Emit local cache immediately
    final cached = _localProfiles[uid];
    Timer.run(() {
      _profileControllers[uid]?.add(cached);
    });

    // 2. Fetch from Supabase in background
    if (isSupabaseAvailable) {
      _fetchRemoteProfile(uid);
    }

    return _profileControllers[uid]!.stream;
  }

  Future<UserProfile?> getProfile(String uid) async {
    if (_localProfiles.containsKey(uid)) {
      return _localProfiles[uid];
    }
    if (isSupabaseAvailable) {
      return await _fetchRemoteProfile(uid);
    }
    return null;
  }

  Future<UserProfile?> _fetchRemoteProfile(String uid) async {
    try {
      final response =
          await client!.from('profiles').select().eq('id', uid).maybeSingle();
      if (response != null) {
        final profile =
            UserProfile.fromMap(Map<String, dynamic>.from(response), uid);
        _localProfiles[uid] = profile;
        _persistProfiles();
        _profileControllers[uid]?.add(profile);
        return profile;
      }
    } catch (e) {
      debugPrint('Supabase fetchProfile error: $e');
    }
    return null;
  }

  Future<void> saveProfile(UserProfile profile, {String? email, String? displayName, String? photoUrl}) async {
    final uid = profile.uid;

    // Instant local update
    _localProfiles[uid] = profile;
    _profileControllers[uid]?.add(profile);
    _persistProfiles();

    // Background sync to Supabase
    if (isSupabaseAvailable) {
      unawaited(_syncProfileToSupabase(profile, email: email, displayName: displayName, photoUrl: photoUrl));
    }
  }

  Future<void> _syncProfileToSupabase(UserProfile profile, {String? email, String? displayName, String? photoUrl}) async {
    try {
      final payload = profile.toSupabaseMap(
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
      );
      await client!.from('profiles').upsert(payload);
    } catch (e) {
      debugPrint('Supabase saveProfile error: $e');
    }
  }

  // ===================== EXPENSES =====================

  Stream<List<Expense>> streamExpenses(String uid) {
    if (!_expenseControllers.containsKey(uid)) {
      _expenseControllers[uid] = StreamController<List<Expense>>.broadcast();
    }

    // 1. Emit local cache immediately
    Timer.run(() {
      final list = List<Expense>.from(_localExpenses[uid] ?? []);
      list.sort((a, b) => b.date.compareTo(a.date));
      _expenseControllers[uid]?.add(list);
    });

    // 2. Fetch from Supabase in background
    if (isSupabaseAvailable) {
      _fetchRemoteExpenses(uid);
    }

    return _expenseControllers[uid]!.stream;
  }

  Future<List<Expense>> _fetchRemoteExpenses(String uid) async {
    try {
      final response = await client!
          .from('expenses')
          .select()
          .eq('user_id', uid)
          .order('date', ascending: false);

      final List list = response as List;
      final expenses = list
          .map((e) => Expense.fromMap(Map<String, dynamic>.from(e), e['id'] ?? ''))
          .toList();

      _localExpenses[uid] = expenses;
      _persistExpenses();
      _expenseControllers[uid]?.add(expenses);
      return expenses;
    } catch (e) {
      debugPrint('Supabase fetchExpenses error: $e');
      return _localExpenses[uid] ?? [];
    }
  }

  Future<void> addExpense(String uid, Expense expense) async {
    final id = expense.id.isEmpty
        ? 'exp_${DateTime.now().millisecondsSinceEpoch}'
        : expense.id;
    final toSave = expense.copyWith(id: id);

    // 1. Instant local update
    _localExpenses.putIfAbsent(uid, () => []);
    _localExpenses[uid]!.removeWhere((e) => e.id == id);
    _localExpenses[uid]!.add(toSave);

    final sorted = List<Expense>.from(_localExpenses[uid]!);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    _expenseControllers[uid]?.add(sorted);
    _persistExpenses();

    // 2. Background sync to Supabase (non-blocking)
    if (isSupabaseAvailable) {
      unawaited(_syncAddExpense(uid, toSave));
    }
  }

  Future<void> _syncAddExpense(String uid, Expense expense) async {
    try {
      await client!.from('expenses').upsert(expense.toSupabaseMap(uid));
    } catch (e) {
      debugPrint('Supabase addExpense error: $e');
    }
  }

  Future<void> updateExpense(String uid, Expense expense) async {
    await addExpense(uid, expense);
  }

  Future<void> deleteExpense(String uid, String expenseId) async {
    // 1. Instant local removal
    _localExpenses[uid]?.removeWhere((e) => e.id == expenseId);
    final sorted = List<Expense>.from(_localExpenses[uid] ?? []);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    _expenseControllers[uid]?.add(sorted);
    _persistExpenses();

    // 2. Background delete in Supabase (non-blocking)
    if (isSupabaseAvailable) {
      unawaited(_syncDeleteExpense(expenseId));
    }
  }

  Future<void> _syncDeleteExpense(String expenseId) async {
    try {
      await client!.from('expenses').delete().eq('id', expenseId);
    } catch (e) {
      debugPrint('Supabase deleteExpense error: $e');
    }
  }

  // ===================== CATEGORIES =====================

  Stream<List<CategoryItem>> streamCategories(String uid) {
    if (!_categoryControllers.containsKey(uid)) {
      _categoryControllers[uid] =
          StreamController<List<CategoryItem>>.broadcast();
    }

    final initialList = _localCategories[uid] ??
        AppConstants.presetCategoryData
            .map((c) => CategoryItem(
                  id: c['id'] as String,
                  name: c['name'] as String,
                  iconCodePoint: c['icon'] as int,
                  colorValue: c['color'] as int,
                  isCustom: false,
                  isHidden: false,
                ))
            .toList();

    _localCategories[uid] = initialList;

    Timer.run(() {
      _categoryControllers[uid]?.add(initialList);
    });

    if (isSupabaseAvailable) {
      _fetchRemoteCategories(uid);
    }

    return _categoryControllers[uid]!.stream;
  }

  Future<void> _fetchRemoteCategories(String uid) async {
    try {
      final response = await client!
          .from('categories')
          .select()
          .or('user_id.is.null,user_id.eq.$uid');

      final List list = response as List;
      if (list.isNotEmpty) {
        final categories = list.map((e) {
          final iconVal = int.tryParse(e['icon']?.toString() ?? '') ?? 0xe402;
          final colorVal =
              int.tryParse(e['color']?.toString() ?? '') ?? 0xFF64748B;
          return CategoryItem(
            id: e['id']?.toString() ?? '',
            name: e['name']?.toString() ?? '',
            iconCodePoint: iconVal,
            colorValue: colorVal,
            isCustom: !(e['is_default'] as bool? ?? false),
            isHidden: e['is_hidden'] as bool? ?? false,
          );
        }).toList();
        _localCategories[uid] = categories;
        _categoryControllers[uid]?.add(categories);
      }
    } catch (e) {
      debugPrint('Supabase fetchCategories error: $e');
    }
  }

  Future<void> addCategory(String uid, CategoryItem category) async {
    _localCategories.putIfAbsent(uid, () => []);
    _localCategories[uid]!.removeWhere((c) => c.id == category.id);
    _localCategories[uid]!.add(category);
    _categoryControllers[uid]?.add(List.from(_localCategories[uid]!));

    if (isSupabaseAvailable) {
      try {
        await client!.from('categories').upsert({
          'id': category.id,
          'user_id': uid,
          'name': category.name,
          'icon': category.iconCodePoint.toString(),
          'color': category.colorValue.toString(),
          'is_default': !category.isCustom,
          'is_hidden': category.isHidden,
        });
      } catch (e) {
        debugPrint('Supabase addCategory error: $e');
      }
    }
  }

  Future<void> updateCategory(String uid, CategoryItem category) async {
    await addCategory(uid, category);
  }

  Future<void> deleteCategory(String uid, String categoryId) async {
    _localCategories[uid]?.removeWhere((c) => c.id == categoryId);
    _categoryControllers[uid]?.add(List.from(_localCategories[uid] ?? []));

    if (isSupabaseAvailable) {
      try {
        await client!.from('categories').delete().eq('id', categoryId);
      } catch (e) {
        debugPrint('Supabase deleteCategory error: $e');
      }
    }
  }
}
