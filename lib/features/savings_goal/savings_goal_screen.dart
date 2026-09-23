import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/repositories/providers.dart';

class SavingsGoalScreen extends ConsumerWidget {
  const SavingsGoalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final profile = ref.watch(currentProfileProvider).value;
    final stats = ref.watch(dailyBudgetStatsProvider);
    final baseCurrency = profile?.baseCurrency ?? 'USD';

    if (stats == null || profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final savingsGoal = profile.savingsGoal;
    final totalSpentInCycle = stats.thisCycleSpent;
    final availableBudget = stats.availableForDailySpending;

    // Real-time Savings calculation:
    // Available budget minus total spent is the remaining buffer.
    // If user spent less than available budget, extra money is added to savings.
    // If user exceeded available budget, the overspent amount is deducted from savings.
    final budgetBalance = availableBudget - totalSpentInCycle;
    final currentSavings = savingsGoal + budgetBalance;

    final isDeficit = currentSavings < 0;
    final isBoosted = currentSavings > savingsGoal;
    final isExactTarget = currentSavings == savingsGoal;

    // Today's daily unspent allowance
    final todayUnspent = (stats.dailyCost - stats.todaySpent).clamp(0.0, double.infinity);
    final isTodaySaving = todayUnspent > 0;

    final daysUnder = stats.daysUnderBudgetCount;
    final daysOver = stats.daysOverBudgetCount;
    final totalDaysElapsed = stats.daysElapsedInCycle;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Tracker'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ===================== CARD 1: MONTHLY SAVINGS TARGET =====================
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withAlpha(80),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'MONTHLY SAVINGS TARGET',
                        style: TextStyle(
                          color: Colors.white70,
                          letterSpacing: 1.2,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(35),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.flag_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.format(savingsGoal,
                        currencyCode: baseCurrency),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Protected upfront before computing your daily allowance',
                    style: TextStyle(
                      color: Colors.white.withAlpha(210),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ===================== CARD 2: ACTUAL SAVINGS THIS MONTH =====================
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDeficit
                    ? const Color(0xFFDC2626)
                    : isBoosted
                        ? const Color(0xFF059669)
                        : const Color(0xFF0D9488),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (isDeficit
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF059669))
                        .withAlpha(90),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'CURRENT SAVINGS THIS MONTH',
                        style: TextStyle(
                          color: Colors.white70,
                          letterSpacing: 1.2,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(35),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isDeficit
                              ? Icons.warning_amber_rounded
                              : Icons.savings_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.format(currentSavings,
                        currencyCode: baseCurrency),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Dynamic appreciation / deficit alert banner
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(40),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isDeficit
                              ? Icons.error_outline_rounded
                              : isBoosted
                                  ? Icons.celebration_rounded
                                  : Icons.check_circle_outline_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isDeficit
                                ? '⚠️ You are in ${CurrencyFormatter.format(currentSavings.abs(), currencyCode: baseCurrency)} loss this cycle!'
                                : isBoosted
                                    ? '🎉 +${CurrencyFormatter.format(currentSavings - savingsGoal, currencyCode: baseCurrency)} added above target!'
                                    : isExactTarget
                                        ? '🎯 100% of savings target on track'
                                        : '📉 ${CurrencyFormatter.format(savingsGoal - currentSavings, currencyCode: baseCurrency)} reduced due to overspending',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ===================== TODAY'S SAVINGS & APPRECIATION =====================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceElevatedDark
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isTodaySaving
                      ? AppColors.withinBudget.withAlpha(120)
                      : (isDark ? AppColors.borderDark : AppColors.borderLight),
                  width: isTodaySaving ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 30 : 10),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isTodaySaving
                                  ? AppColors.withinBudget
                                  : AppColors.nearBudget)
                              .withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isTodaySaving
                              ? Icons.thumb_up_alt_rounded
                              : Icons.schedule_rounded,
                          color: isTodaySaving
                              ? AppColors.withinBudget
                              : AppColors.nearBudget,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Today\'s Daily Savings',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              isTodaySaving
                                  ? 'Unspent: ${CurrencyFormatter.format(todayUnspent, currencyCode: baseCurrency)}'
                                  : 'No unspent allowance today',
                              style: TextStyle(
                                color: isTodaySaving
                                    ? AppColors.withinBudget
                                    : AppColors.textSecondaryLight,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isTodaySaving
                        ? '👏 Great discipline today! After 12:00 AM midnight, your unspent daily allowance of ${CurrencyFormatter.format(todayUnspent, currencyCode: baseCurrency)} is automatically banked into your monthly savings!'
                        : 'Any money you save under your daily allowance is safely added to your monthly savings every night at midnight.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ===================== BUDGET ADHERENCE BREAKDOWN =====================
            Text(
              'Cycle Budget Adherence',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceElevatedDark
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.check_circle_rounded,
                                color: AppColors.withinBudget, size: 20),
                            SizedBox(width: 8),
                            Text('Under Budget',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '$daysUnder days',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'out of $totalDaysElapsed days so far',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceElevatedDark
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: AppColors.overBudget, size: 20),
                            SizedBox(width: 8),
                            Text('Over Budget',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '$daysOver days',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'deducted from savings',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ===================== FINANCIAL FLOW CARD =====================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceElevatedDark
                    : AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined,
                          color: AppColors.primary, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'Monthly Cycle Accounting',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildFlowRow(theme, 'Monthly Income', profile.monthlyIncome, baseCurrency),
                  const Divider(height: 16),
                  _buildFlowRow(theme, 'Fixed Costs (Spent)', -profile.totalFixedCosts, baseCurrency),
                  const SizedBox(height: 6),
                  _buildFlowRow(theme, 'Discretionary Spent', -totalSpentInCycle, baseCurrency),
                  const Divider(height: 16),
                  _buildFlowRow(
                    theme,
                    'Net Savings This Month',
                    currentSavings,
                    baseCurrency,
                    isHighlight: true,
                    isDeficit: isDeficit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowRow(
    ThemeData theme,
    String label,
    double amount,
    String currencyCode, {
    bool isHighlight = false,
    bool isDeficit = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        Text(
          CurrencyFormatter.format(amount, currencyCode: currencyCode),
          style: TextStyle(
            fontWeight: isHighlight ? FontWeight.w900 : FontWeight.w700,
            fontSize: isHighlight ? 16 : 14,
            color: isDeficit
                ? AppColors.overBudget
                : isHighlight
                    ? AppColors.primary
                    : null,
          ),
        ),
      ],
    );
  }
}
