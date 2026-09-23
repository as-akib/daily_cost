import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/salary_cycle.dart';
import '../../data/repositories/providers.dart';

class MonthlySummaryScreen extends ConsumerStatefulWidget {
  const MonthlySummaryScreen({super.key});

  @override
  ConsumerState<MonthlySummaryScreen> createState() =>
      _MonthlySummaryScreenState();
}

class _MonthlySummaryScreenState extends ConsumerState<MonthlySummaryScreen> {
  int _selectedCycleIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final profile = ref.watch(currentProfileProvider).value;
    final allExpenses = ref.watch(expensesProvider).value ?? [];
    final categories = ref.watch(categoriesProvider).value ?? [];
    final baseCurrency = profile?.baseCurrency ?? 'USD';

    if (profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Generate current cycle + 5 past cycles
    final pastCycles = SalaryCycleHelper.getPastCycles(
      cycleStartDay: profile.cycleStartDay,
      count: 6,
    );

    final selectedCycle = pastCycles[_selectedCycleIndex];
    final dailyCost = profile.calculateDailyCost(selectedCycle.totalDays);

    // Filter expenses in selected cycle
    final cycleExpenses =
        allExpenses.where((e) => selectedCycle.contains(e.date)).toList();

    final totalSpent = cycleExpenses.fold(
        0.0, (sum, exp) => sum + exp.amountInBaseCurrency);

    // Daily totals for this cycle
    final dailyTotals = <DateTime, double>{};
    final categoryTotals = <String, double>{};

    for (final exp in cycleExpenses) {
      final day = AppDateUtils.startOfDay(exp.date);
      dailyTotals[day] = (dailyTotals[day] ?? 0.0) + exp.amountInBaseCurrency;
      categoryTotals[exp.category] =
          (categoryTotals[exp.category] ?? 0.0) + exp.amountInBaseCurrency;
    }

    // Days over & under
    int daysOver = 0;
    int daysUnder = 0;
    final now = DateTime.now();
    final todayNormalized = AppDateUtils.startOfDay(now);

    DateTime dayIterator = AppDateUtils.startOfDay(selectedCycle.startDate);
    final limitDate = selectedCycle.endDate.isBefore(now)
        ? selectedCycle.endDate
        : todayNormalized;

    while (!dayIterator.isAfter(limitDate)) {
      final spentOnDay = dailyTotals[dayIterator] ?? 0.0;
      if (dailyCost > 0 && spentOnDay > dailyCost) {
        daysOver++;
      } else {
        daysUnder++;
      }
      dayIterator = dayIterator.add(const Duration(days: 1));
    }

    final totalDaysEvaluated = daysOver + daysUnder;
    final dailyAverage = totalDaysEvaluated > 0
        ? totalSpent / totalDaysEvaluated
        : 0.0;

    // Highest day
    DateTime? highestDay;
    double highestAmount = 0.0;
    dailyTotals.forEach((date, amount) {
      if (amount > highestAmount) {
        highestAmount = amount;
        highestDay = date;
      }
    });

    // Biggest category
    String? biggestCatName;
    double biggestCatAmount = 0.0;
    categoryTotals.forEach((catId, amount) {
      if (amount > biggestCatAmount) {
        biggestCatAmount = amount;
        final match = categories.where((c) => c.id == catId).firstOrNull;
        biggestCatName = match?.name ?? catId;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Salary Cycle Summaries'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ===================== CYCLE PICKER =====================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceElevatedDark
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history_rounded, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedCycleIndex,
                        isExpanded: true,
                        borderRadius: BorderRadius.circular(16),
                        items: List.generate(pastCycles.length, (i) {
                          final c = pastCycles[i];
                          final isCurrent = i == 0;
                          return DropdownMenuItem(
                            value: i,
                            child: Text(
                              '${c.formattedRange} ${isCurrent ? "(Current)" : ""}',
                              style: TextStyle(
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        }),
                        onChanged: (idx) {
                          if (idx != null) {
                            setState(() => _selectedCycleIndex = idx);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ===================== HERO STATS CARD =====================
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(80),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    selectedCycle.formattedFullRange,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    CurrencyFormatter.format(totalSpent,
                        currencyCode: baseCurrency),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total Spent (${cycleExpenses.length} transactions)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Divider(color: Colors.white38, height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildHeroStat(
                        'Daily Average',
                        CurrencyFormatter.format(dailyAverage,
                            currencyCode: baseCurrency),
                      ),
                      _buildHeroStat(
                        'Daily Target',
                        CurrencyFormatter.format(dailyCost,
                            currencyCode: baseCurrency),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ===================== KEY METRICS GRID =====================
            Row(
              children: [
                _buildMetricCard(
                  theme,
                  isDark,
                  title: 'Budget Adherence',
                  mainText: '$daysUnder under',
                  subText: '$daysOver over out of $totalDaysEvaluated days',
                  icon: Icons.pie_chart_outline_rounded,
                  color: AppColors.withinBudget,
                ),
                const SizedBox(width: 12),
                _buildMetricCard(
                  theme,
                  isDark,
                  title: 'Biggest Category',
                  mainText: biggestCatName ?? 'None',
                  subText: biggestCatAmount > 0
                      ? CurrencyFormatter.format(biggestCatAmount,
                          currencyCode: baseCurrency)
                      : 'No expenses',
                  icon: Icons.category_rounded,
                  color: AppColors.primary,
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (highestDay != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceElevatedDark
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.overBudget.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.trending_up_rounded,
                          color: AppColors.overBudget),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Highest Spending Day',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('EEEE, MMM d, y').format(highestDay!),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(highestAmount,
                          currencyCode: baseCurrency),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.overBudget,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    ThemeData theme,
    bool isDark, {
    required String title,
    required String mainText,
    required String subText,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceElevatedDark
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 10),
            Text(
              title,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              mainText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 2),
            Text(
              subText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryLight,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
