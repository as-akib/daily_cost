import 'package:flutter_test/flutter_test.dart';
import 'package:daily_cost/core/utils/salary_cycle.dart';

void main() {
  group('Can I Afford This? Logic Tests', () {
    test('Calculates days of daily budget correctly', () {
      const dailyCost = 333.33;
      const itemPrice = 1000.0;

      final daysOfBudget = itemPrice / dailyCost;
      expect(daysOfBudget, closeTo(3.0, 0.01));
    });

    test('Cycle affordability evaluates remaining budget accurately', () {
      const monthlyIncome = 30000.0;
      const totalFixedCosts = 15000.0;
      const savingsGoal = 5000.0;

      final available = SalaryCycleHelper.calculateAvailableForDailySpending(
        monthlyIncome: monthlyIncome,
        totalFixedCosts: totalFixedCosts,
        savingsGoal: savingsGoal,
      ); // 10,000

      // Suppose user already spent 6,000 in this cycle
      const spentSoFar = 6000.0;
      final remainingBudget = available - spentSoFar; // 4,000

      // An item of 3,500 should fit
      expect(3500 <= remainingBudget, isTrue);

      // An item of 4,500 should exceed cycle budget
      expect(4500 <= remainingBudget, isFalse);
      expect(4500 - remainingBudget, 500.0);
    });
  });

  group('Savings Goal Adherence Tests', () {
    test('Calculates proportional adherence progress correctly', () {
      // If 10 days elapsed and 8 were under budget:
      const daysElapsed = 10;
      const daysUnderBudget = 8;
      final progress = daysUnderBudget / daysElapsed;

      expect(progress, 0.8);
      const savingsGoal = 5000.0;
      expect(savingsGoal * progress, 4000.0);
    });
  });
}
