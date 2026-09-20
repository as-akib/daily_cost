import 'package:flutter_test/flutter_test.dart';
import 'package:daily_cost/core/utils/salary_cycle.dart';
import 'package:daily_cost/data/models/user_profile.dart';
import 'package:daily_cost/data/models/fixed_cost.dart';

void main() {
  group('SalaryCycleHelper - getCycleStartingInCurrentMonth', () {
    test('guarantees cycle start date is in current month and end date in next month', () {
      final now = DateTime(2026, 9, 8); // Sep 8
      // Start day 9 -> Should be Sep 9, 2026 to Oct 8, 2026
      final cycle9 = SalaryCycleHelper.getCycleStartingInCurrentMonth(
        cycleStartDay: 9,
        referenceDate: now,
      );

      expect(cycle9.startDate.month, equals(9));
      expect(cycle9.startDate.day, equals(9));
      expect(cycle9.startDate.year, equals(2026));
      expect(cycle9.endDate.month, equals(10));
      expect(cycle9.endDate.day, equals(8));
      expect(cycle9.endDate.year, equals(2026));

      // Start day 1 -> Sep 1, 2026 to Sep 30, 2026
      final cycle1 = SalaryCycleHelper.getCycleStartingInCurrentMonth(
        cycleStartDay: 1,
        referenceDate: now,
      );
      expect(cycle1.startDate.month, equals(9));
      expect(cycle1.startDate.day, equals(1));
      expect(cycle1.endDate.month, equals(9));
      expect(cycle1.endDate.day, equals(30));
    });
  });

  group('Savings Goal & Budget calculations', () {
    test('UserProfile computes correct daily cost and available budget', () {
      final now = DateTime.now();
      final profile = UserProfile(
        uid: 'test_user',
        monthlyIncome: 100000,
        fixedCosts: [
          const FixedCost(id: '1', label: 'Rent', amount: 30000),
          const FixedCost(id: '2', label: 'Internet', amount: 2000),
        ],
        savingsGoal: 20000,
        cycleStartDay: 1,
        baseCurrency: 'BDT',
        createdAt: now,
        updatedAt: now,
      );

      // Total Fixed = 32,000. Savings = 20,000. Total Deductions = 52,000.
      // Available for daily spending = 100,000 - 52,000 = 48,000.
      expect(profile.totalFixedCosts, equals(32000));
      expect(profile.availableForDailySpending, equals(48000));

      // Daily Cost for a 30-day month = 48,000 / 30 = 1,600
      expect(profile.calculateDailyCost(30), equals(1600));

      // Test real-time actual savings formula:
      // Current Savings = Savings Target + (Available Budget - Total Spent)
      // Case 1: Spent exactly available budget -> Savings remains 20,000
      double totalSpent = 48000;
      double currentSavings = profile.savingsGoal + (profile.availableForDailySpending - totalSpent);
      expect(currentSavings, equals(20000));

      // Case 2: Underspent (only spent 30,000, leftover 18,000) -> Savings increases to 38,000
      totalSpent = 30000;
      currentSavings = profile.savingsGoal + (profile.availableForDailySpending - totalSpent);
      expect(currentSavings, equals(38000));

      // Case 3: Overspent (spent 58,000, over by 10,000) -> Savings reduced to 10,000
      totalSpent = 58000;
      currentSavings = profile.savingsGoal + (profile.availableForDailySpending - totalSpent);
      expect(currentSavings, equals(10000));

      // Case 4: Deep Overspent (spent 75,000, over by 27,000) -> Deficit / Loss of 7,000
      totalSpent = 75000;
      currentSavings = profile.savingsGoal + (profile.availableForDailySpending - totalSpent);
      expect(currentSavings, equals(-7000));
      expect(currentSavings < 0, isTrue);
    });
  });
}
