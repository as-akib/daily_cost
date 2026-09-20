import 'package:flutter_test/flutter_test.dart';
import 'package:daily_cost/core/utils/salary_cycle.dart';
import 'package:daily_cost/data/models/exchange_rates.dart';

void main() {
  group('DailyCost Section 5 Specification - Worked Example Verification', () {
    test('Calculates exact Daily Cost according to specification', () {
      // Worked example from spec:
      // - Monthly income = 30,000
      // - Fixed costs = 10,000 (rent) + 1,500 (internet) + 1,500 (electricity) + 2,000 (other) = 15,000
      // - Savings goal = 5,000
      // - Available = 30,000 − 15,000 − 5,000 = 10,000
      // - If cycle has 30 days -> Daily Cost = 333.33/day
      const monthlyIncome = 30000.0;
      const totalFixedCosts = 15000.0;
      const savingsGoal = 5000.0;

      final available = SalaryCycleHelper.calculateAvailableForDailySpending(
        monthlyIncome: monthlyIncome,
        totalFixedCosts: totalFixedCosts,
        savingsGoal: savingsGoal,
      );

      expect(available, 10000.0);

      const daysInCycle = 30;
      final dailyCost = SalaryCycleHelper.calculateDailyCost(
        availableForDailySpending: available,
        daysInCycle: daysInCycle,
      );

      expect(dailyCost, closeTo(333.333, 0.001));
    });

    test('Handles zero or negative available spending gracefully', () {
      final available = SalaryCycleHelper.calculateAvailableForDailySpending(
        monthlyIncome: 5000,
        totalFixedCosts: 4000,
        savingsGoal: 2000, // exceeds income
      );

      expect(available, 0.0);

      final dailyCost = SalaryCycleHelper.calculateDailyCost(
        availableForDailySpending: available,
        daysInCycle: 30,
      );

      expect(dailyCost, 0.0);
    });
  });

  group('Salary Cycle Clamping and Dates Edge Cases', () {
    test('Cycle starting on 5th runs from 5th to 4th of next month', () {
      final refDate = DateTime(2026, 3, 15);
      final cycle = SalaryCycleHelper.getCycleRange(
        cycleStartDay: 5,
        referenceDate: refDate,
      );

      expect(cycle.startDate.year, 2026);
      expect(cycle.startDate.month, 3);
      expect(cycle.startDate.day, 5);

      expect(cycle.nextCycleStartDate.year, 2026);
      expect(cycle.nextCycleStartDate.month, 4);
      expect(cycle.nextCycleStartDate.day, 5);

      // March has 31 days. From March 5 to April 5 is 31 days.
      expect(cycle.totalDays, 31);
      expect(cycle.contains(DateTime(2026, 3, 5)), isTrue);
      expect(cycle.contains(DateTime(2026, 4, 4)), isTrue);
      expect(cycle.contains(DateTime(2026, 4, 5)), isFalse);
    });

    test('Cycle starting before start day uses previous month start', () {
      final refDate = DateTime(2026, 3, 3); // before March 5
      final cycle = SalaryCycleHelper.getCycleRange(
        cycleStartDay: 5,
        referenceDate: refDate,
      );

      expect(cycle.startDate.year, 2026);
      expect(cycle.startDate.month, 2);
      expect(cycle.startDate.day, 5);

      expect(cycle.nextCycleStartDate.year, 2026);
      expect(cycle.nextCycleStartDate.month, 3);
      expect(cycle.nextCycleStartDate.day, 5);

      // February 2026 has 28 days. From Feb 5 to Mar 5 is 28 days.
      expect(cycle.totalDays, 28);
      expect(cycle.contains(DateTime(2026, 3, 3)), isTrue);
    });

    test('Cycle start day 31 clamps safely in February and April', () {
      // Test reference date in February 2026 (non-leap year = 28 days)
      final refDate = DateTime(2026, 2, 10);
      final cycle = SalaryCycleHelper.getCycleRange(
        cycleStartDay: 31,
        referenceDate: refDate,
      );

      // January has 31 days -> started Jan 31
      expect(cycle.startDate.month, 1);
      expect(cycle.startDate.day, 31);

      // February has 28 days -> next cycle clamped to Feb 28!
      expect(cycle.nextCycleStartDate.month, 2);
      expect(cycle.nextCycleStartDate.day, 28);
      expect(cycle.totalDays, 28);

      // Test April (30 days) with cycle start day 31
      final refDateApril = DateTime(2026, 4, 15);
      final aprilCycle = SalaryCycleHelper.getCycleRange(
        cycleStartDay: 31,
        referenceDate: refDateApril,
      );

      // March has 31 days -> started March 31
      expect(aprilCycle.startDate.month, 3);
      expect(aprilCycle.startDate.day, 31);

      // April has 30 days -> next cycle clamped to April 30!
      expect(aprilCycle.nextCycleStartDate.month, 4);
      expect(aprilCycle.nextCycleStartDate.day, 30);
      expect(aprilCycle.totalDays, 30);
    });

    test('getPastCycles generates correct historical sequence', () {
      final cycles = SalaryCycleHelper.getPastCycles(
        cycleStartDay: 1,
        count: 4,
        referenceDate: DateTime(2026, 4, 15),
      );

      expect(cycles.length, 4);
      expect(cycles[0].startDate.month, 4); // April
      expect(cycles[1].startDate.month, 3); // March
      expect(cycles[2].startDate.month, 2); // February
      expect(cycles[3].startDate.month, 1); // January
    });
  });

  group('Multi-Currency Exchange Rates Conversion', () {
    test('Converts correctly via base currency', () {
      final rates = ExchangeRates(
        base: 'USD',
        date: '2026-03-01',
        rates: {
          'EUR': 0.90,
          'BDT': 120.0,
          'GBP': 0.80,
        },
        lastFetched: DateTime.now(),
      );

      // Same currency
      expect(rates.convert(100, from: 'USD', to: 'USD'), 100);

      // USD to EUR: 100 * 0.90 = 90
      expect(rates.convert(100, from: 'USD', to: 'EUR'), 90.0);

      // EUR to USD: 90 / 0.90 = 100
      expect(rates.convert(90, from: 'EUR', to: 'USD'), 100.0);

      // Cross currency: EUR to BDT: (90 / 0.90) * 120 = 12,000
      expect(rates.convert(90, from: 'EUR', to: 'BDT'), 12000.0);
    });

    test('Default fallback provides stable conversion when offline', () {
      final fallback = ExchangeRates.defaultFallback('USD');
      expect(fallback.isOfflineFallback, isTrue);
      expect(fallback.rates.containsKey('EUR'), isTrue);
      expect(fallback.rates.containsKey('BDT'), isTrue);
      expect(fallback.convert(100, from: 'USD', to: 'EUR'), greaterThan(0));
    });
  });
}
