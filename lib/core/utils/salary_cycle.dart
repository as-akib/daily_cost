import 'dart:math';
import 'package:intl/intl.dart';

/// Represents the calculated date boundaries and duration of a salary cycle.
class SalaryCycleRange {
  final DateTime startDate;
  final DateTime endDate;
  final DateTime nextCycleStartDate;
  final int totalDays;
  final int cycleStartDay;

  const SalaryCycleRange({
    required this.startDate,
    required this.endDate,
    required this.nextCycleStartDate,
    required this.totalDays,
    required this.cycleStartDay,
  });

  /// Check if a given date falls inside this cycle.
  bool contains(DateTime date) {
    return (date.isAtSameMomentAs(startDate) || date.isAfter(startDate)) &&
        (date.isAtSameMomentAs(endDate) || date.isBefore(endDate));
  }

  /// 1-based index of which day of the cycle the reference date is.
  /// Clamped between 1 and [totalDays].
  int getDayIndex([DateTime? date]) {
    final target = date ?? DateTime.now();
    final normalizedTarget = DateTime(target.year, target.month, target.day);
    final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
    final diff = normalizedTarget.difference(normalizedStart).inDays + 1;
    return diff.clamp(1, totalDays);
  }

  /// Remaining days in this cycle from the reference date (inclusive of reference date).
  int getRemainingDays([DateTime? date]) {
    final target = date ?? DateTime.now();
    final normalizedTarget = DateTime(target.year, target.month, target.day);
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);
    if (normalizedTarget.isAfter(normalizedEnd)) return 0;
    if (normalizedTarget.isBefore(startDate)) return totalDays;
    return normalizedEnd.difference(normalizedTarget).inDays + 1;
  }

  /// Formatted string like "Mar 5 – Apr 4"
  String get formattedRange {
    final startFmt = DateFormat('MMM d').format(startDate);
    final endFmt = DateFormat('MMM d').format(endDate);
    return '$startFmt – $endFmt';
  }

  /// Formatted range with year like "Mar 5, 2026 – Apr 4, 2026"
  String get formattedFullRange {
    final startFmt = DateFormat('MMM d, y').format(startDate);
    final endFmt = DateFormat('MMM d, y').format(endDate);
    return '$startFmt – $endFmt';
  }

  /// Cycle label like "March 2026 Cycle"
  String get cycleLabel {
    return '${DateFormat('MMMM yyyy').format(startDate)} Cycle';
  }
}

/// Helper for computing salary cycles, clamping edge dates, and daily cost formulas.
class SalaryCycleHelper {
  SalaryCycleHelper._();

  /// Gets the number of days in a specific month and year.
  static int getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  /// Returns the clamped cycle start day for a given year and month.
  /// E.g. If cycleStartDay is 31 and month is February (28 days), returns 28.
  static int getClampedDay(int year, int month, int targetDay) {
    final daysInMonth = getDaysInMonth(year, month);
    return min(targetDay, daysInMonth);
  }

  /// Computes the [SalaryCycleRange] for a given reference date and configured [cycleStartDay].
  static SalaryCycleRange getCycleRange({
    required int cycleStartDay,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final normalizedNow = DateTime(now.year, now.month, now.day);

    // Clamped start day in the current month
    final currentMonthStartDay = getClampedDay(now.year, now.month, cycleStartDay);
    final candidateStartThisMonth = DateTime(now.year, now.month, currentMonthStartDay);

    DateTime cycleStartDate;
    DateTime nextCycleStartDate;

    if (normalizedNow.isAtSameMomentAs(candidateStartThisMonth) ||
        normalizedNow.isAfter(candidateStartThisMonth)) {
      // Current cycle started in the current calendar month
      cycleStartDate = candidateStartThisMonth;

      // Next cycle starts in month + 1
      final nextMonth = now.month == 12 ? 1 : now.month + 1;
      final nextYear = now.month == 12 ? now.year + 1 : now.year;
      final nextMonthStartDay = getClampedDay(nextYear, nextMonth, cycleStartDay);
      nextCycleStartDate = DateTime(nextYear, nextMonth, nextMonthStartDay);
    } else {
      // Current cycle started in the previous calendar month
      final prevMonth = now.month == 1 ? 12 : now.month - 1;
      final prevYear = now.month == 1 ? now.year - 1 : now.year;
      final prevMonthStartDay = getClampedDay(prevYear, prevMonth, cycleStartDay);
      cycleStartDate = DateTime(prevYear, prevMonth, prevMonthStartDay);

      nextCycleStartDate = candidateStartThisMonth;
    }

    // End date is 23:59:59.999 before nextCycleStartDate
    final cycleEndDate = nextCycleStartDate.subtract(const Duration(milliseconds: 1));
    final totalDays = nextCycleStartDate.difference(cycleStartDate).inDays;

    return SalaryCycleRange(
      startDate: cycleStartDate,
      endDate: cycleEndDate,
      nextCycleStartDate: nextCycleStartDate,
      totalDays: totalDays,
      cycleStartDay: cycleStartDay,
    );
  }

  /// Computes the [SalaryCycleRange] starting in the current calendar month
  /// and ending in the next month (used for setup, preview, and new cycles).
  static SalaryCycleRange getCycleStartingInCurrentMonth({
    required int cycleStartDay,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final currentMonthStartDay =
        getClampedDay(now.year, now.month, cycleStartDay);
    final cycleStartDate =
        DateTime(now.year, now.month, currentMonthStartDay);

    final nextMonth = now.month == 12 ? 1 : now.month + 1;
    final nextYear = now.month == 12 ? now.year + 1 : now.year;
    final nextMonthStartDay =
        getClampedDay(nextYear, nextMonth, cycleStartDay);
    final nextCycleStartDate =
        DateTime(nextYear, nextMonth, nextMonthStartDay);

    final cycleEndDate =
        nextCycleStartDate.subtract(const Duration(milliseconds: 1));
    final totalDays = nextCycleStartDate.difference(cycleStartDate).inDays;

    return SalaryCycleRange(
      startDate: cycleStartDate,
      endDate: cycleEndDate,
      nextCycleStartDate: nextCycleStartDate,
      totalDays: totalDays,
      cycleStartDay: cycleStartDay,
    );
  }

  /// Generate a list of recent past cycles for the monthly summary history.
  static List<SalaryCycleRange> getPastCycles({
    required int cycleStartDay,
    int count = 6,
    DateTime? referenceDate,
  }) {
    final current = getCycleRange(
      cycleStartDay: cycleStartDay,
      referenceDate: referenceDate,
    );

    final cycles = <SalaryCycleRange>[current];
    DateTime prevRef = current.startDate.subtract(const Duration(days: 1));

    for (int i = 1; i < count; i++) {
      final prevCycle = getCycleRange(
        cycleStartDay: cycleStartDay,
        referenceDate: prevRef,
      );
      cycles.add(prevCycle);
      prevRef = prevCycle.startDate.subtract(const Duration(days: 1));
    }

    return cycles;
  }

  /// Core Formula:
  /// Available for Daily Spending = Monthly Income − Total Fixed Monthly Costs − Monthly Savings Goal
  static double calculateAvailableForDailySpending({
    required double monthlyIncome,
    required double totalFixedCosts,
    required double savingsGoal,
  }) {
    final available = monthlyIncome - totalFixedCosts - savingsGoal;
    return available > 0 ? available : 0.0;
  }

  /// Core Formula:
  /// Daily Cost = Available for Daily Spending ÷ Days in Current Salary Cycle
  static double calculateDailyCost({
    required double availableForDailySpending,
    required int daysInCycle,
  }) {
    if (daysInCycle <= 0 || availableForDailySpending <= 0) return 0.0;
    return availableForDailySpending / daysInCycle;
  }
}
