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
  return AuthService(supabaseClient: client);
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

final authStateProvider = StreamProvider<AuthUser?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges();
});

final currentProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) return Stream.value(null);

  final profileRepo = ref.watch(profileRepositoryProvider);
  return profileRepo.streamProfile(user.uid);
});

final expensesProvider = StreamProvider<List<Expense>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) return Stream.value(const []);

  final expenseRepo = ref.watch(expenseRepositoryProvider);
  return expenseRepo.streamExpenses(user.uid);
});

final categoriesProvider = StreamProvider<List<CategoryItem>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) return Stream.value(const []);

  final categoryRepo = ref.watch(categoryRepositoryProvider);
  return categoryRepo.streamCategories(user.uid);
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
  final double savingsGoalProgress; // 0.0 to 1.0
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

  /// Status description
  String get todayStatusMessage {
    if (dailyCost <= 0) return 'Set your budget to begin tracking';
    if (isOverBudgetToday) {
      final over = (todaySpent - dailyCost).toStringAsFixed(2);
      return "You're over today's budget by $over";
    }
    final left = todayRemaining.toStringAsFixed(2);
    return "You have $left left to spend today 🎉";
  }
}

final dailyBudgetStatsProvider = Provider<DailyBudgetStats?>((ref) {
  final profileAsync = ref.watch(currentProfileProvider);
  final expensesAsync = ref.watch(expensesProvider);
  final categoriesAsync = ref.watch(categoriesProvider);

  final profile = profileAsync.value;
  if (profile == null) return null;

  final allExpenses = expensesAsync.value ?? [];
  final categories = categoriesAsync.value ?? [];

  final now = DateTime.now();
  final todayStart = AppDateUtils.startOfDay(now);
  final todayEnd = AppDateUtils.endOfDay(now);
  final weekStart = AppDateUtils.startOfWeek(now);
  final weekEnd = AppDateUtils.endOfWeek(now);

  // Compute Salary Cycle
  final cycle = SalaryCycleHelper.getCycleRange(
    cycleStartDay: profile.cycleStartDay,
    referenceDate: now,
  );

  final available = profile.availableForDailySpending;
  final dailyCost = profile.calculateDailyCost(cycle.totalDays);

  // Filter expenses by period
  final todayExpenses = <Expense>[];
  double todaySpent = 0.0;

  double thisWeekSpent = 0.0;

  final cycleExpenses = <Expense>[];
  double thisCycleSpent = 0.0;

  // Day by day aggregation inside this cycle
  final cycleDailyTotals = <DateTime, double>{};

  for (final exp in allExpenses) {
    final expDate = exp.date;
    final inBase = exp.amountInBaseCurrency;

    // Today
    if ((expDate.isAtSameMomentAs(todayStart) || expDate.isAfter(todayStart)) &&
        (expDate.isAtSameMomentAs(todayEnd) || expDate.isBefore(todayEnd))) {
      todayExpenses.add(exp);
      todaySpent += inBase;
    }

    // This Week
    if ((expDate.isAtSameMomentAs(weekStart) || expDate.isAfter(weekStart)) &&
        (expDate.isAtSameMomentAs(weekEnd) || expDate.isBefore(weekEnd))) {
      thisWeekSpent += inBase;
    }

    // This Cycle
    if (cycle.contains(expDate)) {
      cycleExpenses.add(exp);
      thisCycleSpent += inBase;

      final dayKey = AppDateUtils.startOfDay(expDate);
      cycleDailyTotals[dayKey] = (cycleDailyTotals[dayKey] ?? 0.0) + inBase;
    }
  }

  // Days over and under budget in current cycle
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

  // Savings goal progress (§7.6):
  // (days in cycle so far where spending <= Daily Cost) contributing proportionally toward the goal
  final savingsProgress = daysElapsedInCycle > 0
      ? (daysUnderBudget / daysElapsedInCycle).clamp(0.0, 1.0)
      : 1.0;

  // Trailing 7-day average spending
  final sevenDaysAgo = todayStart.subtract(const Duration(days: 7));
  double trailing7DayTotal = 0.0;
  for (final exp in allExpenses) {
    if (exp.date.isAfter(sevenDaysAgo) && exp.date.isBefore(todayStart)) {
      trailing7DayTotal += exp.amountInBaseCurrency;
    }
  }
  final trailing7DayAverage = trailing7DayTotal / 7.0;

  // Highest spending day in cycle
  DateTime? highestDay;
  double highestDayAmount = 0.0;
  cycleDailyTotals.forEach((date, total) {
    if (total > highestDayAmount) {
      highestDayAmount = total;
      highestDay = date;
    }
  });

  // Biggest category in cycle
  final categoryTotals = <String, double>{};
  for (final exp in cycleExpenses) {
    categoryTotals[exp.category] =
        (categoryTotals[exp.category] ?? 0.0) + exp.amountInBaseCurrency;
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

  final profile = profileAsync.value;
  if (profile == null) return null;

  final allExpenses = expensesAsync.value ?? [];
  final now = DateTime.now();
  final todayNormalized = AppDateUtils.startOfDay(now);
  final normalizedSelectedDate = AppDateUtils.startOfDay(selectedDate);
  final isToday = normalizedSelectedDate.isAtSameMomentAs(todayNormalized);

  // Compute Salary Cycle for the selected date
  final cycle = SalaryCycleHelper.getCycleRange(
    cycleStartDay: profile.cycleStartDay,
    referenceDate: normalizedSelectedDate,
  );

  final available = profile.availableForDailySpending;
  final dailyCost = profile.calculateDailyCost(cycle.totalDays);

  final dayStart = AppDateUtils.startOfDay(normalizedSelectedDate);
  final dayEnd = AppDateUtils.endOfDay(normalizedSelectedDate);

  final dayExpenses = <Expense>[];
  double daySpent = 0.0;

  for (final exp in allExpenses) {
    final expDate = exp.date;
    if ((expDate.isAtSameMomentAs(dayStart) || expDate.isAfter(dayStart)) &&
        (expDate.isAtSameMomentAs(dayEnd) || expDate.isBefore(dayEnd))) {
      dayExpenses.add(exp);
      daySpent += exp.amountInBaseCurrency;
    }
  }

  // Sort latest first
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
      statusMessage = "You have $left left to spend today 🎉";
    }
  } else {
    final dateFmt = DateFormat('d MMM').format(normalizedSelectedDate);
    if (dailyCost <= 0) {
      statusMessage = 'No budget configured for this date';
    } else if (dayExpenses.isEmpty) {
      statusMessage = 'No expenses recorded on $dateFmt';
    } else if (isOverBudget) {
      final over = CurrencyFormatter.format(daySpent - dailyCost, currencyCode: profile.baseCurrency);
      statusMessage = "Over daily budget by $over on $dateFmt 🚨";
    } else {
      final left = CurrencyFormatter.format(dayRemaining, currencyCode: profile.baseCurrency);
      statusMessage = "Under daily budget with $left left on $dateFmt 🎉";
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

