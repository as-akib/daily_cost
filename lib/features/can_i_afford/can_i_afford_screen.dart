import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/math_expression_evaluator.dart';
import '../../data/repositories/providers.dart';

class CanIAffordScreen extends ConsumerStatefulWidget {
  const CanIAffordScreen({super.key});

  @override
  ConsumerState<CanIAffordScreen> createState() => _CanIAffordScreenState();
}

class _CanIAffordScreenState extends ConsumerState<CanIAffordScreen> {
  final TextEditingController _priceCtrl = TextEditingController();
  late String _selectedCurrency;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentProfileProvider).value;
    _selectedCurrency = profile?.baseCurrency ?? 'USD';
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final profileAsync = ref.watch(currentProfileProvider);
    final stats = ref.watch(dailyBudgetStatsProvider);
    final profile = profileAsync.value;
    final baseCurrency = profile?.baseCurrency ?? 'USD';

    if (stats == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final exchangeRates =
        ref.watch(exchangeRatesProvider(baseCurrency)).value;

    final inputPrice =
        MathExpressionEvaluator.tryEvaluate(_priceCtrl.text.trim()) ?? 0.0;
    double priceInBase = inputPrice;
    if (exchangeRates != null && _selectedCurrency != baseCurrency) {
      priceInBase = exchangeRates.convert(
        inputPrice,
        from: _selectedCurrency,
        to: baseCurrency,
      );
    }

    final dailyCost = stats.dailyCost;
    final remainingDays = stats.cycle.getRemainingDays();

    // 1. Days of daily budget
    final daysOfBudget = dailyCost > 0 ? (priceInBase / dailyCost) : 0.0;

    // 2. Cycle remaining budget check:
    // Available for Daily Spending − spent so far in this cycle
    final remainingCycleBudget =
        (stats.availableForDailySpending - stats.thisCycleSpent);
    final canAffordInCycle =
        priceInBase > 0 && priceInBase <= remainingCycleBudget;
    final overCycleAmount =
        priceInBase > remainingCycleBudget ? (priceInBase - remainingCycleBudget) : 0.0;

    // Adjusted daily budget for remaining days if purchased
    final remainingAfterPurchase = remainingCycleBudget - priceInBase;
    final adjustedDailyCost = remainingDays > 0
        ? (remainingAfterPurchase > 0 ? remainingAfterPurchase / remainingDays : 0.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Can I Afford This?'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Intro text
            Text(
              'Thinking of buying something?',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Enter the price below to see how many days of your daily budget it represents and if it fits your cycle.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 24),

            // Price & Currency Input Box
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
                  Row(
                    children: [
                      // Currency Selector
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCurrency,
                          icon: const Icon(Icons.arrow_drop_down_rounded),
                          borderRadius: BorderRadius.circular(16),
                          items: AppConstants.supportedCurrencies.map((c) {
                            return DropdownMenuItem(
                              value: c.code,
                              child: Text(
                                '${c.code} (${c.symbol})',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedCurrency = val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                          ],
                          textInputAction: TextInputAction.done,
                          textAlign: TextAlign.end,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  if (_selectedCurrency != baseCurrency && inputPrice > 0) ...[
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Converts to ($baseCurrency):',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(priceInBase,
                              currencyCode: baseCurrency),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (priceInBase <= 0)
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 36, horizontal: 20),
                  child: Column(
                    children: [
                      const Icon(Icons.calculate_outlined,
                          size: 44, color: AppColors.primary),
                      const SizedBox(height: 12),
                      Text(
                        'Enter a price above to evaluate',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'DailyCost will tell you the cost in daily allowance days.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // ===================== DUAL OUTPUT 1: DAYS OF BUDGET =====================
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(80),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'DAILY BUDGET IMPACT',
                      style: TextStyle(
                        color: Colors.white70,
                        letterSpacing: 1.4,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${daysOfBudget.toStringAsFixed(1)} days',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'This purchase costs ${daysOfBudget.toStringAsFixed(1)} days of your daily budget (${CurrencyFormatter.format(dailyCost, currencyCode: baseCurrency)}/day).',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ===================== DUAL OUTPUT 2: CYCLE AFFORDABILITY STATUS =====================
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: canAffordInCycle
                      ? AppColors.withinBudget.withAlpha(25)
                      : AppColors.overBudget.withAlpha(25),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: canAffordInCycle
                        ? AppColors.withinBudget
                        : AppColors.overBudget,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          canAffordInCycle
                              ? Icons.check_circle_rounded
                              : Icons.warning_rounded,
                          color: canAffordInCycle
                              ? AppColors.withinBudget
                              : AppColors.overBudget,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            canAffordInCycle
                                ? 'You can afford this!'
                                : 'Budget Warning',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: canAffordInCycle
                                  ? AppColors.withinBudget
                                  : AppColors.overBudget,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      canAffordInCycle
                          ? '✅ You can afford this without breaking your monthly plan. You still have ${CurrencyFormatter.format(remainingCycleBudget, currencyCode: baseCurrency)} remaining in this salary cycle.'
                          : '⚠️ This would push you over budget by ${CurrencyFormatter.format(overCycleAmount, currencyCode: baseCurrency)} for this cycle.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    const Divider(height: 24),

                    // If purchased impact on remaining days
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Remaining Days in Cycle:',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                        Text(
                          '$remainingDays days',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'New Daily Budget if bought:',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                        Text(
                          '${CurrencyFormatter.format(adjustedDailyCost, currencyCode: baseCurrency)} / day',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: canAffordInCycle
                                ? AppColors.primary
                                : AppColors.overBudget,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
