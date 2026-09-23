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

  final Map<String, UserProfile> _localProfiles = {};
  final Map<String, List<Expense>> _localExpenses = {};
  final Map<String, List<CategoryItem>> _localCategories = {};
  final Map<String, List<StreamController<UserProfile?>>> _profileControllers = {};
  final Map<String, List<StreamController<List<Expense>>>> _expenseControllers = {};
  final Map<String, List<StreamController<List<CategoryItem>>>> _categoryControllers = {};

  SupabaseService({this.client}) {
    _initLocalCache();
  }

  bool get isSupabaseAvailable => client != null;

  void _notifyProfileSubscribers(String uid) {
    final profile = _localProfiles[uid];
    final list = List<StreamController<UserProfile?>>.from(_profileControllers[uid] ?? []);
    for (final c in list) {
      if (!c.isClosed) c.add(profile);
    }
  }

  void _notifyExpenseSubscribers(String uid) {
    final list = List<Expense>.from(_localExpenses[uid] ?? []);
    list.sort((a, b) => b.date.compareTo(a.date));
    final controllers = List<StreamController<List<Expense>>>.from(_expenseControllers[uid] ?? []);
    for (final c in controllers) {
      if (!c.isClosed) c.add(list);
    }
  }

  void _notifyCategorySubscribers(String uid) {
    final list = List<CategoryItem>.from(_localCategories[uid] ?? _getDefaultCategories());
    final controllers = List<StreamController<List<CategoryItem>>>.from(_categoryControllers[uid] ?? []);
    for (final c in controllers) {
      if (!c.isClosed) c.add(list);
    }
  }

  List<CategoryItem> _getDefaultCategories() {
    return AppConstants.presetCategoryData
        .map((c) => CategoryItem(
      id: c['id'] as String,
      name: c['name'] as String,
      iconCodePoint: c['icon'] as int,
      colorValue: c['color'] as int,
      isCustom: false,
      isHidden: false,
    ))
        .toList();
  }

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

      final categoriesJson = prefs.getString('dailycost_cache_categories');
      if (categoriesJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(categoriesJson);
        decoded.forEach((uid, val) {
          final List list = val as List;
          _localCategories[uid] = list
              .map((c) => CategoryItem.fromMap(Map<String, dynamic>.from(c), ''))
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

  Future<void> _persistCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> map = {};
      _localCategories.forEach((uid, categories) {
        map[uid] = categories.map((c) => c.toMap()).toList();
      });
      await prefs.setString('dailycost_cache_categories', jsonEncode(map));
    } catch (_) {}
  }

  // ===================== PROFILES =====================
  Stream<UserProfile?> streamProfile(String uid) {
    late StreamController<UserProfile?> controller;
    controller = StreamController<UserProfile?>.broadcast(
      onListen: () {
        // Immediate broadcast so router doesn't hang in loading
        controller.add(_localProfiles[uid]);
        if (isSupabaseAvailable) {
          _fetchRemoteProfile(uid);
        }
      },
    );
    _profileControllers.putIfAbsent(uid, () => []);
    _profileControllers[uid]!.add(controller);
    controller.onCancel = () {
      _profileControllers[uid]?.remove(controller);
    };
    return controller.stream;
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
      final response = await client!
          .from('profiles')
          .select()
          .eq('id', uid)
          .maybeSingle()
          .timeout(const Duration(seconds: 3));

      if (response != null) {
        final profile =
        UserProfile.fromMap(Map<String, dynamic>.from(response), uid);
        _localProfiles[uid] = profile;
        _persistProfiles();
        _notifyProfileSubscribers(uid);
        return profile;
      } else {
        _notifyProfileSubscribers(uid);
      }
    } catch (e) {
      debugPrint('SUPABASE FETCH PROFILE: $e');
      _notifyProfileSubscribers(uid);
    }
    return _localProfiles[uid];
  }

  Future<void> saveProfile(
      UserProfile profile, {
        String? email,
        String? displayName,
        String? photoUrl,
      }) async {
    _localProfiles[profile.uid] = profile;
    await _persistProfiles();
    _notifyProfileSubscribers(profile.uid);

    if (isSupabaseAvailable) {
      try {
        final currencyInfo = AppConstants.getCurrencyInfo(profile.baseCurrency);
        final isAnon = profile.uid.startsWith('guest_') || profile.uid == 'guest_user';

        final data = <String, dynamic>{
          'id': profile.uid,
          'base_currency': profile.baseCurrency,
          'currency_symbol': currencyInfo.symbol,
          'monthly_income': profile.monthlyIncome,
          'savings_goal': profile.savingsGoal,
          'fixed_costs': profile.fixedCosts.map((c) => c.toMap()).toList(),
          'cycle_start_day': profile.cycleStartDay,
          'is_onboarded': profile.isOnboardingCompleted,
          'is_anonymous': isAnon,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        };
        if (email != null) data['email'] = email;
        if (displayName != null) data['display_name'] = displayName;
        if (photoUrl != null) data['photo_url'] = photoUrl;

        await client!.from('profiles').upsert(data).timeout(const Duration(seconds: 4));
        debugPrint('SUPABASE SAVE PROFILE SUCCESS');
      } catch (e) {
        debugPrint('SUPABASE SAVE PROFILE ERROR: $e');
      }
    }
  }

  // ===================== EXPENSES =====================
  Stream<List<Expense>> streamExpenses(String uid) {
    late StreamController<List<Expense>> controller;
    controller = StreamController<List<Expense>>.broadcast(
      onListen: () {
        controller.add(_localExpenses[uid] ?? []);
        if (isSupabaseAvailable) {
          _fetchRemoteExpenses(uid);
        }
      },
    );
    _expenseControllers.putIfAbsent(uid, () => []);
    _expenseControllers[uid]!.add(controller);
    controller.onCancel = () {
      _expenseControllers[uid]?.remove(controller);
    };
    return controller.stream;
  }

  Future<void> _fetchRemoteExpenses(String uid) async {
    try {
      final response = await client!
          .from('expenses')
          .select()
          .eq('user_id', uid)
          .timeout(const Duration(seconds: 3));

      final List list = response as List;
      final parsed = list
          .map((e) => Expense.fromMap(Map<String, dynamic>.from(e), ''))
          .toList();

      final existingMap = <String, Expense>{};
      for (final exp in parsed) {
        existingMap[exp.id] = exp;
      }
      for (final local in (_localExpenses[uid] ?? [])) {
        if (!existingMap.containsKey(local.id)) {
          existingMap[local.id] = local;
        }
      }

      final merged = existingMap.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      _localExpenses[uid] = merged;
      await _persistExpenses();
      _notifyExpenseSubscribers(uid);
    } catch (e) {
      debugPrint('SUPABASE FETCH EXPENSES ERROR: $e');
      _notifyExpenseSubscribers(uid);
    }
  }

  Future<void> addExpense(String uid, Expense expense) async {
    final list = _localExpenses[uid] ?? [];
    list.removeWhere((e) => e.id == expense.id);
    list.insert(0, expense);
    _localExpenses[uid] = list;
    await _persistExpenses();
    _notifyExpenseSubscribers(uid);

    if (isSupabaseAvailable) {
      try {
        final insertData = <String, dynamic>{
          'id': expense.id,
          'user_id': uid,
          'amount': expense.amount,
          'currency': expense.currency,
          'amount_in_base_currency': expense.amountInBaseCurrency,
          'category': expense.category,
          'note': expense.note ?? '',
          'date': expense.date.toUtc().toIso8601String(),
          'created_at': expense.createdAt.toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        };

        await client!.from('expenses').upsert(insertData).timeout(const Duration(seconds: 4));
        debugPrint('SUPABASE ADD EXPENSE SUCCESS');
      } catch (e) {
        debugPrint('SUPABASE ADD EXPENSE ERROR: $e');
      }
    }
  }

  Future<void> updateExpense(String uid, Expense expense) async {
    final list = _localExpenses[uid] ?? [];
    final idx = list.indexWhere((e) => e.id == expense.id);
    if (idx != -1) {
      list[idx] = expense;
      _localExpenses[uid] = list;
      await _persistExpenses();
      _notifyExpenseSubscribers(uid);
    }

    if (isSupabaseAvailable) {
      try {
        await client!.from('expenses').update({
          'amount': expense.amount,
          'currency': expense.currency,
          'amount_in_base_currency': expense.amountInBaseCurrency,
          'category': expense.category,
          'note': expense.note ?? '',
          'date': expense.date.toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', expense.id);
      } catch (e) {
        debugPrint('SUPABASE UPDATE EXPENSE ERROR: $e');
      }
    }
  }

  Future<void> deleteExpense(String uid, String expenseId) async {
    final list = _localExpenses[uid] ?? [];
    list.removeWhere((e) => e.id == expenseId);
    _localExpenses[uid] = list;
    await _persistExpenses();
    _notifyExpenseSubscribers(uid);

    if (isSupabaseAvailable) {
      try {
        await client!.from('expenses').delete().eq('id', expenseId);
      } catch (e) {
        debugPrint('SUPABASE DELETE EXPENSE ERROR: $e');
      }
    }
  }

  // ===================== CATEGORIES =====================
  Stream<List<CategoryItem>> streamCategories(String uid) {
    late StreamController<List<CategoryItem>> controller;
    controller = StreamController<List<CategoryItem>>.broadcast(
      onListen: () {
        if (!_localCategories.containsKey(uid) || _localCategories[uid]!.isEmpty) {
          _localCategories[uid] = _getDefaultCategories();
        }
        controller.add(List<CategoryItem>.from(_localCategories[uid]!));
        if (isSupabaseAvailable) {
          _fetchRemoteCategories(uid);
        }
      },
    );
    _categoryControllers.putIfAbsent(uid, () => []);
    _categoryControllers[uid]!.add(controller);
    controller.onCancel = () {
      _categoryControllers[uid]?.remove(controller);
    };
    return controller.stream;
  }

  Future<void> _fetchRemoteCategories(String uid) async {
    try {
      final res = await client!
          .from('categories')
          .select()
          .eq('user_id', uid)
          .timeout(const Duration(seconds: 3));

      final List list = res as List;
      final defaultPresets = _getDefaultCategories();

      if (list.isNotEmpty) {
        final parsed = list.map((c) => CategoryItem(
          id: c['id'] as String,
          name: c['name'] as String,
          iconCodePoint: (c['icon_code_point'] as num).toInt(),
          colorValue: (c['color_value'] as num).toInt(),
          isCustom: c['is_custom'] as bool? ?? true,
          isHidden: false,
        )).toList();

        _localCategories[uid] = [...defaultPresets, ...parsed];
      } else {
        _localCategories[uid] = defaultPresets;
      }
      await _persistCategories();
      _notifyCategorySubscribers(uid);
    } catch (_) {
      if (!_localCategories.containsKey(uid) || _localCategories[uid]!.isEmpty) {
        _localCategories[uid] = _getDefaultCategories();
        _notifyCategorySubscribers(uid);
      }
    }
  }

  Future<void> addCategory(String uid, CategoryItem category) async {
    final list = _localCategories[uid] ?? _getDefaultCategories();
    list.add(category);
    _localCategories[uid] = list;
    await _persistCategories();
    _notifyCategorySubscribers(uid);

    if (isSupabaseAvailable) {
      try {
        await client!.from('categories').insert({
          'id': category.id,
          'user_id': uid,
          'name': category.name,
          'icon_code_point': category.iconCodePoint,
          'color_value': category.colorValue,
          'is_custom': category.isCustom,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });
      } catch (e) {
        debugPrint('SUPABASE ADD CATEGORY ERROR: $e');
      }
    }
  }

  Future<void> deleteCategory(String uid, String categoryId) async {
    final list = _localCategories[uid] ?? _getDefaultCategories();
    list.removeWhere((c) => c.id == categoryId);
    _localCategories[uid] = list;
    await _persistCategories();
    _notifyCategorySubscribers(uid);

    if (isSupabaseAvailable) {
      try {
        await client!.from('categories').delete().eq('id', categoryId);
      } catch (_) {}
    }
  }

  Future<void> deleteUserData(String uid) async {
    _localProfiles.remove(uid);
    _localExpenses.remove(uid);
    _localCategories.remove(uid);
    await _persistProfiles();
    await _persistExpenses();
    await _persistCategories();

    if (isSupabaseAvailable) {
      try {
        await client!.from('expenses').delete().eq('user_id', uid);
        await client!.from('categories').delete().eq('user_id', uid);
        await client!.from('profiles').delete().eq('id', uid);
      } catch (e) {
        debugPrint('SUPABASE DELETE USER ERROR: $e');
      }
    }
  }
}