import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../models/expense.dart';
import '../models/category_item.dart';
import '../../core/constants/app_constants.dart';

class FirestoreService {
  final FirebaseFirestore? firestore;

  // Local fallback storage for development / tests when Firebase isn't provisioned
  final Map<String, UserProfile> _localProfiles = {};
  final Map<String, List<Expense>> _localExpenses = {};
  final Map<String, List<CategoryItem>> _localCategories = {};

  final _profileControllers = <String, StreamController<UserProfile?>>{};
  final _expenseControllers = <String, StreamController<List<Expense>>>{};
  final _categoryControllers = <String, StreamController<List<CategoryItem>>>{};

  FirestoreService({this.firestore});

  bool get isFirebaseAvailable => firestore != null;

  // ===================== USER PROFILE =====================

  Stream<UserProfile?> streamUserProfile(String uid) {
    if (isFirebaseAvailable) {
      return firestore!.collection('users').doc(uid).snapshots().map((snapshot) {
        if (!snapshot.exists || snapshot.data() == null) {
          return null;
        }
        return UserProfile.fromMap(snapshot.data()!, uid);
      });
    }

    if (!_profileControllers.containsKey(uid)) {
      _profileControllers[uid] = StreamController<UserProfile?>.broadcast();
    }
    // Emit current value
    Timer.run(() {
      _profileControllers[uid]?.add(_localProfiles[uid]);
    });
    return _profileControllers[uid]!.stream;
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    if (isFirebaseAvailable) {
      final doc = await firestore!.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserProfile.fromMap(doc.data()!, uid);
    }
    return _localProfiles[uid];
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    if (isFirebaseAvailable) {
      await firestore!
          .collection('users')
          .doc(profile.uid)
          .set(profile.toMap(), SetOptions(merge: true));
      return;
    }

    _localProfiles[profile.uid] = profile;
    _profileControllers[profile.uid]?.add(profile);
  }

  // ===================== EXPENSES =====================

  Stream<List<Expense>> streamExpenses(String uid) {
    if (isFirebaseAvailable) {
      return firestore!
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => Expense.fromMap(doc.data(), doc.id))
            .toList();
      });
    }

    if (!_expenseControllers.containsKey(uid)) {
      _expenseControllers[uid] = StreamController<List<Expense>>.broadcast();
    }
    Timer.run(() {
      final list = List<Expense>.from(_localExpenses[uid] ?? []);
      list.sort((a, b) => b.date.compareTo(a.date));
      _expenseControllers[uid]?.add(list);
    });
    return _expenseControllers[uid]!.stream;
  }

  Future<void> addExpense(String uid, Expense expense) async {
    final id = expense.id.isEmpty
        ? 'exp_${DateTime.now().millisecondsSinceEpoch}'
        : expense.id;
    final toSave = expense.copyWith(id: id);

    // Update local cache and controllers for immediate responsiveness
    _localExpenses.putIfAbsent(uid, () => []);
    _localExpenses[uid]!.removeWhere((e) => e.id == id);
    _localExpenses[uid]!.add(toSave);
    final sorted = List<Expense>.from(_localExpenses[uid]!);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    _expenseControllers[uid]?.add(sorted);

    if (isFirebaseAvailable) {
      try {
        final docRef = firestore!
            .collection('users')
            .doc(uid)
            .collection('expenses')
            .doc(id);

        await docRef.set(toSave.toMap()).timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            // Firestore persistence queues writes offline
          },
        );
      } catch (_) {
        // Fallback gracefully to offline cache if firestore rules/permissions block
      }
    }
  }

  Future<void> updateExpense(String uid, Expense expense) async {
    await addExpense(uid, expense);
  }

  Future<void> deleteExpense(String uid, String expenseId) async {
    _localExpenses[uid]?.removeWhere((e) => e.id == expenseId);
    final sorted = List<Expense>.from(_localExpenses[uid] ?? []);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    _expenseControllers[uid]?.add(sorted);

    if (isFirebaseAvailable) {
      try {
        await firestore!
            .collection('users')
            .doc(uid)
            .collection('expenses')
            .doc(expenseId)
            .delete()
            .timeout(
          const Duration(seconds: 3),
          onTimeout: () {},
        );
      } catch (_) {
        // Fallback gracefully
      }
    }
  }

  // ===================== CATEGORIES =====================

  Stream<List<CategoryItem>> streamCategories(String uid) {
    if (isFirebaseAvailable) {
      return firestore!
          .collection('users')
          .doc(uid)
          .collection('categories')
          .snapshots()
          .map((snapshot) {
        final customList = snapshot.docs
            .map((doc) => CategoryItem.fromMap(doc.data(), doc.id))
            .toList();
        return _combinePresetsWithCustom(customList);
      });
    }

    if (!_categoryControllers.containsKey(uid)) {
      _categoryControllers[uid] =
          StreamController<List<CategoryItem>>.broadcast();
    }
    Timer.run(() {
      final customList = _localCategories[uid] ?? [];
      _categoryControllers[uid]?.add(_combinePresetsWithCustom(customList));
    });
    return _categoryControllers[uid]!.stream;
  }

  List<CategoryItem> _combinePresetsWithCustom(List<CategoryItem> custom) {
    final presets = AppConstants.presetCategoryData.map((data) {
      return CategoryItem(
        id: data['id'] as String,
        name: data['name'] as String,
        iconCodePoint: data['icon'] as int,
        colorValue: data['color'] as int,
        isCustom: false,
        isHidden: false,
      );
    }).toList();

    // Override presets if user hid them or altered them
    final result = <CategoryItem>[];
    for (final p in presets) {
      final match = custom.where((c) => c.id == p.id).firstOrNull;
      if (match != null) {
        result.add(match);
      } else {
        result.add(p);
      }
    }

    // Add remaining custom categories
    for (final c in custom) {
      if (!presets.any((p) => p.id == c.id)) {
        result.add(c);
      }
    }

    return result;
  }

  Future<void> saveCategory(String uid, CategoryItem category) async {
    if (isFirebaseAvailable) {
      await firestore!
          .collection('users')
          .doc(uid)
          .collection('categories')
          .doc(category.id)
          .set(category.toMap(), SetOptions(merge: true));
      return;
    }

    _localCategories.putIfAbsent(uid, () => []);
    _localCategories[uid]!.removeWhere((c) => c.id == category.id);
    _localCategories[uid]!.add(category);
    _categoryControllers[uid]
        ?.add(_combinePresetsWithCustom(_localCategories[uid]!));
  }

  Future<void> deleteCategory(String uid, String categoryId) async {
    if (isFirebaseAvailable) {
      await firestore!
          .collection('users')
          .doc(uid)
          .collection('categories')
          .doc(categoryId)
          .delete();
      return;
    }

    _localCategories[uid]?.removeWhere((c) => c.id == categoryId);
    _categoryControllers[uid]
        ?.add(_combinePresetsWithCustom(_localCategories[uid] ?? []));
  }

  // ===================== DATA MERGING (§3) =====================

  /// Merges all data from [sourceUid] (anonymous guest) into [targetUid] (linked Google account)
  /// without overwriting existing expenses in the target account.
  Future<void> mergeUserData(String sourceUid, String targetUid) async {
    final db = firestore;
    if (db != null) {
      // 1. Fetch source profile & target profile
      final sourceProfileDoc =
          await db.collection('users').doc(sourceUid).get();
      final targetProfileDoc =
          await db.collection('users').doc(targetUid).get();

      final batch = db.batch();

      // If target has no profile or onboarding is incomplete, copy source profile
      if (sourceProfileDoc.exists && (!targetProfileDoc.exists || targetProfileDoc.data() == null)) {
        final profileData = Map<String, dynamic>.from(sourceProfileDoc.data()!);
        profileData['uid'] = targetUid;
        batch.set(db.collection('users').doc(targetUid), profileData);
      }

      // 2. Fetch and merge expenses
      final sourceExpensesSnap = await db
          .collection('users')
          .doc(sourceUid)
          .collection('expenses')
          .get();

      for (final doc in sourceExpensesSnap.docs) {
        final targetDocRef = db
            .collection('users')
            .doc(targetUid)
            .collection('expenses')
            .doc(doc.id);
        batch.set(targetDocRef, doc.data(), SetOptions(merge: true));
      }

      // 3. Fetch and merge custom categories
      final sourceCatsSnap = await db
          .collection('users')
          .doc(sourceUid)
          .collection('categories')
          .get();

      for (final doc in sourceCatsSnap.docs) {
        final targetDocRef = db
            .collection('users')
            .doc(targetUid)
            .collection('categories')
            .doc(doc.id);
        batch.set(targetDocRef, doc.data(), SetOptions(merge: true));
      }

      await batch.commit();
      return;
    }

    // Local fallback merge
    if (_localProfiles.containsKey(sourceUid) && !_localProfiles.containsKey(targetUid)) {
      _localProfiles[targetUid] = _localProfiles[sourceUid]!.copyWith(uid: targetUid);
    }

    final srcExpenses = _localExpenses[sourceUid] ?? [];
    final trgExpenses = _localExpenses.putIfAbsent(targetUid, () => []);
    for (final exp in srcExpenses) {
      if (!trgExpenses.any((e) => e.id == exp.id)) {
        trgExpenses.add(exp);
      }
    }

    final srcCats = _localCategories[sourceUid] ?? [];
    final trgCats = _localCategories.putIfAbsent(targetUid, () => []);
    for (final cat in srcCats) {
      if (!trgCats.any((c) => c.id == cat.id)) {
        trgCats.add(cat);
      }
    }
  }
}
