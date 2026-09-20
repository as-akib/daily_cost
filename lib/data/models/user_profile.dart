import 'fixed_cost.dart';

class UserProfile {
  final String uid;
  final String baseCurrency;
  final double monthlyIncome;
  final List<FixedCost> fixedCosts;
  final double savingsGoal;
  final int cycleStartDay;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isOnboardingCompleted;

  const UserProfile({
    required this.uid,
    required this.baseCurrency,
    required this.monthlyIncome,
    required this.fixedCosts,
    required this.savingsGoal,
    required this.cycleStartDay,
    required this.createdAt,
    required this.updatedAt,
    this.isOnboardingCompleted = false,
  });

  double get totalFixedCosts =>
      fixedCosts.fold(0.0, (total, item) => total + item.amount);

  double get availableForDailySpending {
    final available = monthlyIncome - totalFixedCosts - savingsGoal;
    return available > 0 ? available : 0.0;
  }

  double calculateDailyCost(int daysInCycle) {
    if (daysInCycle <= 0) return 0.0;
    return availableForDailySpending / daysInCycle;
  }

  UserProfile copyWith({
    String? uid,
    String? baseCurrency,
    double? monthlyIncome,
    List<FixedCost>? fixedCosts,
    double? savingsGoal,
    int? cycleStartDay,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isOnboardingCompleted,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      fixedCosts: fixedCosts ?? this.fixedCosts,
      savingsGoal: savingsGoal ?? this.savingsGoal,
      cycleStartDay: cycleStartDay ?? this.cycleStartDay,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isOnboardingCompleted:
          isOnboardingCompleted ?? this.isOnboardingCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'baseCurrency': baseCurrency,
      'monthlyIncome': monthlyIncome,
      'fixedCosts': fixedCosts.map((c) => c.toMap()).toList(),
      'savingsGoal': savingsGoal,
      'cycleStartDay': cycleStartDay,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isOnboardingCompleted': isOnboardingCompleted,
    };
  }

  Map<String, dynamic> toSupabaseMap({String? email, String? displayName, String? photoUrl}) {
    final map = <String, dynamic>{
      'id': uid,
      'base_currency': baseCurrency,
      'monthly_income': monthlyIncome,
      'fixed_costs': fixedCosts.map((c) => c.toMap()).toList(),
      'savings_goal': savingsGoal,
      'cycle_start_day': cycleStartDay,
      'created_at': createdAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (email != null) map['email'] = email;
    if (displayName != null) map['display_name'] = displayName;
    if (photoUrl != null) map['photo_url'] = photoUrl;
    return map;
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, String uid) {
    DateTime parseDate(dynamic val) {
      if (val is DateTime) return val;
      if (val != null) {
        try {
          // Dynamic invocation for Timestamp.toDate() if present without importing firestore
          final dynamic dyn = val;
          if (dyn.toDate is Function) {
            return dyn.toDate() as DateTime;
          }
        } catch (_) {}
      }
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final rawFixedCosts = (map['fixedCosts'] ?? map['fixed_costs']) as List<dynamic>? ?? [];
    final parsedFixedCosts = rawFixedCosts.map((e) {
      if (e is Map) {
        return FixedCost.fromMap(Map<String, dynamic>.from(e));
      }
      return const FixedCost(id: '', label: '', amount: 0.0);
    }).toList();

    return UserProfile(
      uid: uid,
      baseCurrency: (map['baseCurrency'] ?? map['base_currency']) as String? ?? 'USD',
      monthlyIncome: ((map['monthlyIncome'] ?? map['monthly_income']) as num?)?.toDouble() ?? 0.0,
      fixedCosts: parsedFixedCosts,
      savingsGoal: ((map['savingsGoal'] ?? map['savings_goal']) as num?)?.toDouble() ?? 0.0,
      cycleStartDay: ((map['cycleStartDay'] ?? map['cycle_start_day']) as num?)?.toInt() ?? 1,
      createdAt: parseDate(map['createdAt'] ?? map['created_at']),
      updatedAt: parseDate(map['updatedAt'] ?? map['updated_at']),
      isOnboardingCompleted: (map['isOnboardingCompleted'] ?? map['is_onboarding_completed']) as bool? ?? true,
    );
  }
}
