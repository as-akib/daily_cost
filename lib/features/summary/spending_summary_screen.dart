import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/expense.dart';
import '../../data/repositories/providers.dart';

enum SummaryPeriod { today, thisWeek, thisMonth, custom }

class SpendingSummaryScreen extends ConsumerStatefulWidget {
  const SpendingSummaryScreen({super.key});

  @override
  ConsumerState<SpendingSummaryScreen> createState() =>
      _SpendingSummaryScreenState();
}

class _SpendingSummaryScreenState extends ConsumerState<SpendingSummaryScreen> {
  SummaryPeriod _selectedPeriod = SummaryPeriod.thisMonth;
  DateTimeRange? _customDateRange;
  int _touchedPieIndex = -1;

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _customDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 30)),
            end: DateTime.now(),
          ),
    );
    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedPeriod = SummaryPeriod.custom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final profileAsync = ref.watch(currentProfileProvider);
    final stats = ref.watch(dailyBudgetStatsProvider);
    final allExpenses = ref.watch(expensesProvider).value ?? [];
    final categories = ref.watch(categoriesProvider).value ?? [];

    final profile = profileAsync.value;
    final baseCurrency = profile?.baseCurrency ?? 'USD';

    if (stats == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final now = DateTime.now();
    final todayStart = AppDateUtils.startOfDay(now);
    final todayEnd = AppDateUtils.endOfDay(now);
    final weekStart = AppDateUtils.startOfWeek(now);
    final weekEnd = AppDateUtils.endOfWeek(now);
    final cycle = stats.cycle;

    // Filter expenses based on selected period
    List<Expense> periodExpenses;
    String periodTitle;
    double expectedPace = 0.0;

    switch (_selectedPeriod) {
      case SummaryPeriod.today:
        periodExpenses = allExpenses.where((e) {
          return (e.date.isAtSameMomentAs(todayStart) ||
                  e.date.isAfter(todayStart)) &&
              (e.date.isAtSameMomentAs(todayEnd) || e.date.isBefore(todayEnd));
        }).toList();
        periodTitle = 'Today';
        expectedPace = stats.dailyCost;
        break;

      case SummaryPeriod.thisWeek:
        periodExpenses = allExpenses.where((e) {
          return (e.date.isAtSameMomentAs(weekStart) ||
                  e.date.isAfter(weekStart)) &&
              (e.date.isAtSameMomentAs(weekEnd) || e.date.isBefore(weekEnd));
        }).toList();
        final daysInWeekSoFar = now.weekday; // 1 (Mon) to 7 (Sun)
        expectedPace = stats.dailyCost * daysInWeekSoFar;
        periodTitle = 'This Week';
        break;

      case SummaryPeriod.thisMonth:
        periodExpenses = allExpenses.where((e) => cycle.contains(e.date)).toList();
        expectedPace = stats.availableForDailySpending;
        periodTitle = 'This Salary Cycle (${cycle.formattedRange})';
        break;

      case SummaryPeriod.custom:
        if (_customDateRange != null) {
          final rangeStart = AppDateUtils.startOfDay(_customDateRange!.start);
          final rangeEnd = AppDateUtils.endOfDay(_customDateRange!.end);
          periodExpenses = allExpenses.where((e) {
            return (e.date.isAtSameMomentAs(rangeStart) ||
                    e.date.isAfter(rangeStart)) &&
                (e.date.isAtSameMomentAs(rangeEnd) ||
                    e.date.isBefore(rangeEnd));
          }).toList();
          final days = _customDateRange!.duration.inDays + 1;
          expectedPace = stats.dailyCost * days;
          periodTitle =
              '${AppDateUtils.formatRelative(_customDateRange!.start)} – ${AppDateUtils.formatRelative(_customDateRange!.end)}';
        } else {
          periodExpenses = [];
          periodTitle = 'Custom Range';
        }
        break;
    }

    final totalSpent = periodExpenses.fold(
        0.0, (sum, exp) => sum + exp.amountInBaseCurrency);

    // Group by category
    final categoryAmounts = <String, double>{};
    final categoryCounts = <String, int>{};
    for (final exp in periodExpenses) {
      categoryAmounts[exp.category] =
          (categoryAmounts[exp.category] ?? 0.0) + exp.amountInBaseCurrency;
      categoryCounts[exp.category] =
          (categoryCounts[exp.category] ?? 0) + 1;
    }

    final sortedCategoryKeys = categoryAmounts.keys.toList()
      ..sort((a, b) => categoryAmounts[b]!.compareTo(categoryAmounts[a]!));

    final paceDifference = expectedPace - totalSpent;
    final isAheadOfPace = paceDifference >= 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending & Breakdown'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ===================== PERIOD SEGMENTED SELECTOR =====================
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPeriodChip(SummaryPeriod.today, 'Today', isDark),
                  const SizedBox(width: 8),
                  _buildPeriodChip(SummaryPeriod.thisWeek, 'This Week', isDark),
                  const SizedBox(width: 8),
                  _buildPeriodChip(SummaryPeriod.thisMonth, 'This Month', isDark),
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: Icon(
                      Icons.date_range_rounded,
                      size: 16,
                      color: _selectedPeriod == SummaryPeriod.custom
                          ? (isDark ? Colors.white : AppColors.primary)
                          : (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight),
                    ),
                    label: Text(
                      _selectedPeriod == SummaryPeriod.custom &&
                              _customDateRange != null
                          ? 'Custom (${_customDateRange!.duration.inDays + 1}d)'
                          : 'Custom Range',
                      style: TextStyle(
                        color: _selectedPeriod == SummaryPeriod.custom
                            ? (isDark ? Colors.white : AppColors.primaryDark)
                            : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight),
                        fontWeight: _selectedPeriod == SummaryPeriod.custom
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    backgroundColor: _selectedPeriod == SummaryPeriod.custom
                        ? (isDark
                            ? AppColors.primary
                            : AppColors.primaryContainer)
                        : (isDark
                            ? AppColors.surfaceElevatedDark
                            : AppColors.surfaceElevatedLight),
                    side: BorderSide(
                      color: _selectedPeriod == SummaryPeriod.custom
                          ? (isDark ? AppColors.primaryLight : AppColors.primary)
                          : (isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    onPressed: _pickCustomRange,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ===================== METRICS SUMMARY CARD =====================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceElevatedDark
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    periodTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    CurrencyFormatter.format(totalSpent,
                        currencyCode: baseCurrency),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${periodExpenses.length} transactions logged',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const Divider(height: 24),

                  // Budget Comparison
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedPeriod == SummaryPeriod.today
                                ? 'Daily Budget'
                                : _selectedPeriod == SummaryPeriod.thisWeek
                                    ? 'Weekly Budget'
                                    : _selectedPeriod == SummaryPeriod.thisMonth
                                        ? 'Full Month Budget'
                                        : 'Budget for Period',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyFormatter.format(expectedPace,
                                currencyCode: baseCurrency),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (isAheadOfPace
                                  ? AppColors.withinBudget
                                  : AppColors.overBudget)
                              .withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isAheadOfPace
                              ? '+${CurrencyFormatter.format(paceDifference, currencyCode: baseCurrency)} under budget 🎉'
                              : '-${CurrencyFormatter.format(paceDifference.abs(), currencyCode: baseCurrency)} over budget ⚠️',
                          style: TextStyle(
                            color: isAheadOfPace
                                ? AppColors.withinBudget
                                : AppColors.overBudget,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ===================== CATEGORY DONUT CHART =====================
            Text(
              'Where Did My Money Go?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 14),

            if (periodExpenses.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 36, horizontal: 16),
                  child: Center(
                    child: Text(
                      'No spending recorded for $periodTitle.',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ),
              )
            else ...[
              // Pie Chart Widget
              Container(
                height: 230,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceElevatedDark
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  _touchedPieIndex = -1;
                                  return;
                                }
                                _touchedPieIndex = pieTouchResponse
                                    .touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 3,
                          centerSpaceRadius: 36,
                          sections: _buildPieSections(
                            sortedCategoryKeys,
                            categoryAmounts,
                            totalSpent,
                            categories,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Breakdown List Header
              Text(
                'Category Breakdown',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),

              // Breakdown List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedCategoryKeys.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final catId = sortedCategoryKeys[index];
                  final cat =
                      categories.where((c) => c.id == catId).firstOrNull;
                  final catName = cat?.name ?? 'Other';
                  final catIcon = cat?.iconData ?? Icons.category_rounded;
                  final catColor = cat?.color ?? AppColors.catOther;
                  final catAmount = categoryAmounts[catId] ?? 0.0;
                  final percentage = totalSpent > 0
                      ? (catAmount / totalSpent) * 100
                      : 0.0;
                  final count = categoryCounts[catId] ?? 0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: catColor.withAlpha(25),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(catIcon,
                                    color: catColor, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      catName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                    Text(
                                      '$count transactions • ${percentage.toStringAsFixed(1)}%',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(catAmount,
                                    currencyCode: baseCurrency),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (percentage / 100).clamp(0.0, 1.0),
                              color: catColor,
                              backgroundColor: catColor.withAlpha(30),
                              minHeight: 5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(SummaryPeriod period, String label, bool isDark) {
    final isSelected = _selectedPeriod == period;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? (isDark ? Colors.white : AppColors.primaryDark)
              : (isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight),
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: isSelected,
      selectedColor: isDark ? AppColors.primary : AppColors.primaryContainer,
      backgroundColor:
          isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight,
      checkmarkColor: isDark ? Colors.white : AppColors.primary,
      side: BorderSide(
        color: isSelected
            ? (isDark ? AppColors.primaryLight : AppColors.primary)
            : (isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      onSelected: (_) {
        setState(() => _selectedPeriod = period);
      },
    );
  }

  List<PieChartSectionData> _buildPieSections(
    List<String> keys,
    Map<String, double> amounts,
    double total,
    List<dynamic> categories,
  ) {
    return List.generate(keys.length, (i) {
      final isTouched = i == _touchedPieIndex;
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 65.0 : 55.0;

      final catId = keys[i];
      final amount = amounts[catId] ?? 0.0;
      final percentage = total > 0 ? (amount / total) * 100 : 0.0;

      final cat = categories.where((c) => c.id == catId).firstOrNull;
      final color = cat?.color ?? AppColors.catOther;

      return PieChartSectionData(
        color: color,
        value: amount,
        title: percentage >= 5 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }
}
