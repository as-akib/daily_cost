import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;
import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import '../services/currency_service.dart';
import '../services/notification_service.dart';
import 'auth_repository.dart';
import 'profile_repository.dart';
import 'expense_repository.dart';
import 'category_repository.dart';
import '../models/user_profile.dart';
import '../models/expense.dart';
import '../models/category_item.dart';
import '../models/exchange_rates.dart';
import '../../core/utils/salary_cycle.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/currency_formatter.dart';

// ===================== CORE SERVICES =====================
final authServiceProvider = Provider<AuthService>((ref) {
  SupabaseClient? client;
  try {
    client = Supabase.instance.client;
  } catch (_) {}
  final supabaseService = ref.watch(supabaseServiceProvider);
  return AuthService(
    supabaseClient: client,
    supabaseService: supabaseService,
  );
});

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  SupabaseClient? client;
  try {
    client = Supabase.instance.client;
  } catch (_) {}
  return SupabaseService(client: client);
});

final currencyServiceProvider = Provider<CurrencyService>((ref) {
  return CurrencyService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// ===================== REPOSITORIES =====================
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    authService: ref.watch(authServiceProvider),
  );
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    supabaseService: ref.watch(supabaseServiceProvider),
  );
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(
    supabaseService: ref.watch(supabaseServiceProvider),
  );
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(
    supabaseService: ref.watch(supabaseServiceProvider),
  );
});

// ===================== DATA STREAMS =====================
final authStateProvider = StreamProvider<AuthUser?>((ref) async* {
  final authRepo = ref.watch(authRepositoryProvider);
  await authRepo.authService.ensureInitialized();
  yield authRepo.currentUser;
  yield* authRepo.authStateChanges();
});

final defaultFallbackProfile = UserProfile(
  uid: 'guest_user',
  baseCurrency: 'BDT',
  monthlyIncome: 0,
  fixedCosts: [],
  savingsGoal: 0,
  cycleStartDay: 1,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  isOnboardingCompleted: false,
);

final currentUserIdProvider = Provider<String>((ref) {
  try {
    final sbUser = Supabase.instance.client.auth.currentUser;
    if (sbUser != null && sbUser.id.isNotEmpty) {
      return sbUser.id;
    }
  } catch (_) {}
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user != null && user.uid.isNotEmpty) {
    return user.uid;
  }
  final authService = ref.watch(authServiceProvider);
  if (authService.currentUser != null && authService.currentUser!.uid.isNotEmpty) {
    return authService.currentUser!.uid;
  }
  return 'guest_user';
});

final currentProfileProvider = StreamProvider<UserProfile?>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  final profileRepo = ref.watch(profileRepositoryProvider);
  return profileRepo.streamProfile(uid).handleError((error) {
    debugPrint('StreamProfile error handled: $error');
    return defaultFallbackProfile;
  });
});

final expensesProvider = StreamProvider<List<Expense>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  final expenseRepo = ref.watch(expenseRepositoryProvider);
  return expenseRepo.streamExpenses(uid).handleError((error) {
    debugPrint('StreamExpenses error handled: $error');
    return <Expense>[];
  });
});

final categoriesProvider = StreamProvider<List<CategoryItem>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  final categoryRepo = ref.watch(categoryRepositoryProvider);
  return categoryRepo.streamCategories(uid).handleError((error) {
    debugPrint('StreamCategories error handled: $error');
    return <CategoryItem>[];
  });
});

final exchangeRatesProvider =
FutureProvider.family<ExchangeRates, String>((ref, baseCurrency) async {
  final currencyService = ref.watch(currencyServiceProvider);
  return currencyService.getExchangeRates(baseCurrency);
});

// ===================== COMPUTED BUDGET STATS =====================
class DailyBudgetStats {
  final SalaryCycleRange cycle;
  final double dailyCost;
  final double availableForDailySpending;
  final double todaySpent;
  final double thisWeekSpent;
  final double thisCycleSpent;
  final int todayTransactionCount;
  final double todayRemaining;
  final bool isOverBudgetToday;
  final int daysElapsedInCycle;
  final int daysUnderBudgetCount;
  final int daysOverBudgetCount;
  final double savingsGoalProgress;
  final double trailing7DayDailyAverage;
  final String? biggestCategoryName;
  final double biggestCategoryAmount;
  final DateTime? highestSpendingDayDate;
  final double highestSpendingDayAmount;
  final List<Expense> todayExpenses;
  final List<Expense> cycleExpenses;

  const DailyBudgetStats({
    required this.cycle,
    required this.dailyCost,
    required this.availableForDailySpending,
    required this.todaySpent,
    required this.thisWeekSpent,
    required this.thisCycleSpent,
    required this.todayTransactionCount,
    required this.todayRemaining,
    required this.isOverBudgetToday,
    required this.daysElapsedInCycle,
    required this.daysUnderBudgetCount,
    required this.daysOverBudgetCount,
    required this.savingsGoalProgress,
    required this.trailing7DayDailyAverage,
    this.biggestCategoryName,
    required this.biggestCategoryAmount,
    this.highestSpendingDayDate,
    required this.highestSpendingDayAmount,
    required this.todayExpenses,
    required this.cycleExpenses,
  });

  String get todayStatusMessage {
    if (dailyCost <= 0) return 'Set your budget to begin tracking';
    if (isOverBudgetToday) {
      final over = (todaySpent - dailyCost).toStringAsFixed(2);
      return "You're over today's budget by $over";
    }
    final left = todayRemaining.toStringAsFixed(2);
    return "You have $left left to spend today";
  }
}

final dailyBudgetStatsProvider = Provider<DailyBudgetStats?>((ref) {
  final profileAsync = ref.watch(currentProfileProvider);
  final expensesAsync = ref.watch(expensesProvider);
  final categoriesAsync = ref.watch(categoriesProvider);

  final profile = profileAsync.value ?? defaultFallbackProfile;
  final allExpenses = expensesAsync.value ?? [];
  final categories = categoriesAsync.value ?? [];

  final now = DateTime.now();
  final todayStart = AppDateUtils.startOfDay(now);
  final weekStart = AppDateUtils.startOfWeek(now);
  final weekEnd = AppDateUtils.endOfWeek(now);

  final cycle = SalaryCycleHelper.getCycleStartingInCurrentMonth(
    cycleStartDay: profile.cycleStartDay,
  );

  final totalFixed = profile.fixedCosts.fold(0.0, (s, f) => s + f.amount);
  final available = SalaryCycleHelper.calculateAvailableForDailySpending(
    monthlyIncome: profile.monthlyIncome,
    totalFixedCosts: totalFixed,
    savingsGoal: profile.savingsGoal,
  );

  final dailyCost = SalaryCycleHelper.calculateDailyCost(
    availableForDailySpending: available,
    daysInCycle: cycle.totalDays,
  );

  final todayExpenses = <Expense>[];
  double todaySpent = 0.0;
  double thisWeekSpent = 0.0;
  final cycleExpenses = <Expense>[];
  double thisCycleSpent = 0.0;
  final cycleDailyTotals = <DateTime, double>{};

  for (final exp in allExpenses) {
    // Exact Local day normalization
    final expDate = exp.date.toLocal();
    final inBase = exp.amountInBaseCurrency > 0 ? exp.amountInBaseCurrency : exp.amount;

    if (expDate.year == now.year && expDate.month == now.month && expDate.day == now.day) {
      todayExpenses.add(exp);
      todaySpent += inBase;
    }

    if ((expDate.isAtSameMomentAs(weekStart) || expDate.isAfter(weekStart)) &&
        (expDate.isAtSameMomentAs(weekEnd) || expDate.isBefore(weekEnd))) {
      thisWeekSpent += inBase;
    }

    if (cycle.contains(expDate)) {
      cycleExpenses.add(exp);
      thisCycleSpent += inBase;
      final dayKey = AppDateUtils.startOfDay(expDate);
      cycleDailyTotals[dayKey] = (cycleDailyTotals[dayKey] ?? 0.0) + inBase;
    }
  }

  final daysElapsedInCycle = cycle.getDayIndex(now);
  int daysOverBudget = 0;
  int daysUnderBudget = 0;
  DateTime dayIterator = AppDateUtils.startOfDay(cycle.startDate);
  final todayNormalized = AppDateUtils.startOfDay(now);

  while (!dayIterator.isAfter(todayNormalized) && !dayIterator.isAfter(cycle.endDate)) {
    final spentOnDay = cycleDailyTotals[dayIterator] ?? 0.0;
    if (dailyCost > 0 && spentOnDay > dailyCost) {
      daysOverBudget++;
    } else {
      daysUnderBudget++;
    }
    dayIterator = dayIterator.add(const Duration(days: 1));
  }

  final double savingsProgress = daysElapsedInCycle > 0
      ? (daysUnderBudget / daysElapsedInCycle).clamp(0.0, 1.0).toDouble()
      : 1.0;

  final sevenDaysAgo = todayStart.subtract(const Duration(days: 7));
  double trailing7DayTotal = 0.0;
  for (final exp in allExpenses) {
    final expDate = exp.date.toLocal();
    final inBase = exp.amountInBaseCurrency > 0 ? exp.amountInBaseCurrency : exp.amount;
    if (expDate.isAfter(sevenDaysAgo) && expDate.isBefore(todayStart)) {
      trailing7DayTotal += inBase;
    }
  }
  final trailing7DayAverage = trailing7DayTotal / 7.0;

  DateTime? highestDay;
  double highestDayAmount = 0.0;
  cycleDailyTotals.forEach((date, total) {
    if (total > highestDayAmount) {
      highestDayAmount = total;
      highestDay = date;
    }
  });

  final categoryTotals = <String, double>{};
  for (final exp in cycleExpenses) {
    final inBase = exp.amountInBaseCurrency > 0 ? exp.amountInBaseCurrency : exp.amount;
    categoryTotals[exp.category] =
        (categoryTotals[exp.category] ?? 0.0) + inBase;
  }

  String? biggestCatName;
  double biggestCatAmount = 0.0;
  categoryTotals.forEach((catId, total) {
    if (total > biggestCatAmount) {
      biggestCatAmount = total;
      final match = categories.where((c) => c.id == catId).firstOrNull;
      biggestCatName = match?.name ?? catId;
    }
  });

  final todayRemaining = dailyCost - todaySpent;

  return DailyBudgetStats(
    cycle: cycle,
    dailyCost: dailyCost,
    availableForDailySpending: available,
    todaySpent: todaySpent,
    thisWeekSpent: thisWeekSpent,
    thisCycleSpent: thisCycleSpent,
    todayTransactionCount: todayExpenses.length,
    todayRemaining: todayRemaining,
    isOverBudgetToday: dailyCost > 0 && todaySpent > dailyCost,
    daysElapsedInCycle: daysElapsedInCycle,
    daysUnderBudgetCount: daysUnderBudget,
    daysOverBudgetCount: daysOverBudget,
    savingsGoalProgress: savingsProgress,
    trailing7DayDailyAverage: trailing7DayAverage,
    biggestCategoryName: biggestCatName,
    biggestCategoryAmount: biggestCatAmount,
    highestSpendingDayDate: highestDay,
    highestSpendingDayAmount: highestDayAmount,
    todayExpenses: todayExpenses,
    cycleExpenses: cycleExpenses,
  );
});

// ===================== SELECTED DAY BUDGET STATS =====================
final selectedDashboardDateProvider = StateProvider<DateTime>((ref) {
  return AppDateUtils.startOfDay(DateTime.now());
});

class DayBudgetStats {
  final DateTime date;
  final bool isToday;
  final SalaryCycleRange cycle;
  final double dailyCost;
  final double availableForDailySpending;
  final double daySpent;
  final double dayRemaining;
  final bool isOverBudget;
  final int transactionCount;
  final List<Expense> expenses;
  final int daysElapsedInCycle;
  final String statusMessage;

  const DayBudgetStats({
    required this.date,
    required this.isToday,
    required this.cycle,
    required this.dailyCost,
    required this.availableForDailySpending,
    required this.daySpent,
    required this.dayRemaining,
    required this.isOverBudget,
    required this.transactionCount,
    required this.expenses,
    required this.daysElapsedInCycle,
    required this.statusMessage,
  });
}

final selectedDayBudgetStatsProvider = Provider<DayBudgetStats?>((ref) {
  final profileAsync = ref.watch(currentProfileProvider);
  final expensesAsync = ref.watch(expensesProvider);
  final selectedDate = ref.watch(selectedDashboardDateProvider);

  final profile = profileAsync.value ?? defaultFallbackProfile;
  final allExpenses = expensesAsync.value ?? [];

  final now = DateTime.now();
  final normalizedSelectedDate = AppDateUtils.startOfDay(selectedDate);
  final isToday = normalizedSelectedDate.year == now.year &&
      normalizedSelectedDate.month == now.month &&
      normalizedSelectedDate.day == now.day;

  final cycle = SalaryCycleHelper.getCycleRange(
    cycleStartDay: profile.cycleStartDay,
    referenceDate: normalizedSelectedDate,
  );

  final totalFixed = profile.fixedCosts.fold(0.0, (s, f) => s + f.amount);
  final available = SalaryCycleHelper.calculateAvailableForDailySpending(
    monthlyIncome: profile.monthlyIncome,
    totalFixedCosts: totalFixed,
    savingsGoal: profile.savingsGoal,
  );

  final dailyCost = SalaryCycleHelper.calculateDailyCost(
    availableForDailySpending: available,
    daysInCycle: cycle.totalDays,
  );

  final dayExpenses = <Expense>[];
  double daySpent = 0.0;

  for (final exp in allExpenses) {
    final expDate = exp.date.toLocal();
    final inBase = exp.amountInBaseCurrency > 0 ? exp.amountInBaseCurrency : exp.amount;

    if (expDate.year == normalizedSelectedDate.year &&
        expDate.month == normalizedSelectedDate.month &&
        expDate.day == normalizedSelectedDate.day) {
      dayExpenses.add(exp);
      daySpent += inBase;
    }
  }

  dayExpenses.sort((a, b) => b.date.compareTo(a.date));
  final dayRemaining = dailyCost - daySpent;
  final isOverBudget = dailyCost > 0 && daySpent > dailyCost;
  final daysElapsedInCycle = cycle.getDayIndex(normalizedSelectedDate);

  String statusMessage;
  if (isToday) {
    if (dailyCost <= 0) {
      statusMessage = 'Set your budget to begin tracking';
    } else if (isOverBudget) {
      final over = CurrencyFormatter.format(daySpent - dailyCost, currencyCode: profile.baseCurrency);
      statusMessage = "You're over today's budget by $over";
    } else {
      final left = CurrencyFormatter.format(dayRemaining, currencyCode: profile.baseCurrency);
      statusMessage = "You have $left left to spend today";
    }
  } else {
    final dateFmt = DateFormat('d MMM').format(normalizedSelectedDate);
    if (dailyCost <= 0) {
      statusMessage = 'No budget configured for this date';
    } else if (dayExpenses.isEmpty) {
      statusMessage = 'No expenses recorded on $dateFmt';
    } else if (isOverBudget) {
      final over = CurrencyFormatter.format(daySpent - dailyCost, currencyCode: profile.baseCurrency);
      statusMessage = "Over daily budget by $over on $dateFmt";
    } else {
      final left = CurrencyFormatter.format(dayRemaining, currencyCode: profile.baseCurrency);
      statusMessage = "Under daily budget with $left left on $dateFmt";
    }
  }

  return DayBudgetStats(
    date: normalizedSelectedDate,
    isToday: isToday,
    cycle: cycle,
    dailyCost: dailyCost,
    availableForDailySpending: available,
    daySpent: daySpent,
    dayRemaining: dayRemaining,
    isOverBudget: isOverBudget,
    transactionCount: dayExpenses.length,
    expenses: dayExpenses,
    daysElapsedInCycle: daysElapsedInCycle,
    statusMessage: statusMessage,
  );
});