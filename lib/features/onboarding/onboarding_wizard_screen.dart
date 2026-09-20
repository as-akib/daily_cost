import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/math_expression_evaluator.dart';
import '../../core/utils/salary_cycle.dart';
import '../../data/models/fixed_cost.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/providers.dart';

class OnboardingWizardScreen extends ConsumerStatefulWidget {
  const OnboardingWizardScreen({super.key});

  @override
  ConsumerState<OnboardingWizardScreen> createState() =>
      _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState extends ConsumerState<OnboardingWizardScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isSaving = false;

  // Onboarding Form State
  String _selectedCurrency = 'USD';
  final TextEditingController _currencySearchCtrl = TextEditingController();
  List<CurrencyInfo> _filteredCurrencies = AppConstants.supportedCurrencies;

  final TextEditingController _incomeCtrl = TextEditingController();
  double _monthlyIncome = 0.0;

  final Map<String, double> _presetFixedCostsMap = {};
  final Map<String, TextEditingController> _presetControllers = {};
  final Map<String, FocusNode> _presetFocusNodes = {};
  final List<FixedCost> _customFixedCosts = [];

  final TextEditingController _savingsGoalCtrl = TextEditingController();
  double _savingsGoal = 0.0;

  int _cycleStartDay = 1;

  @override
  void initState() {
    super.initState();
    _currencySearchCtrl.addListener(_onCurrencySearchChanged);
  }

  void _onCurrencySearchChanged() {
    final query = _currencySearchCtrl.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCurrencies = AppConstants.supportedCurrencies;
      } else {
        _filteredCurrencies = AppConstants.supportedCurrencies
            .where((c) =>
                c.code.toLowerCase().contains(query) ||
                c.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _currencySearchCtrl.dispose();
    _incomeCtrl.dispose();
    _savingsGoalCtrl.dispose();
    for (final c in _presetControllers.values) {
      c.dispose();
    }
    for (final f in _presetFocusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  double get _totalFixedCosts {
    final presetSum =
        _presetFixedCostsMap.values.fold(0.0, (sum, val) => sum + val);
    final customSum =
        _customFixedCosts.fold(0.0, (sum, val) => sum + val.amount);
    return presetSum + customSum;
  }

  double get _availableForDailySpending {
    return SalaryCycleHelper.calculateAvailableForDailySpending(
      monthlyIncome: _monthlyIncome,
      totalFixedCosts: _totalFixedCosts,
      savingsGoal: _savingsGoal,
    );
  }

  SalaryCycleRange get _currentCycle {
    return SalaryCycleHelper.getCycleStartingInCurrentMonth(
        cycleStartDay: _cycleStartDay);
  }

  double get _computedDailyCost {
    return SalaryCycleHelper.calculateDailyCost(
      availableForDailySpending: _availableForDailySpending,
      daysInCycle: _currentCycle.totalDays,
    );
  }

  void _nextPage() {
    FocusScope.of(context).unfocus();
    if (_currentStep < 5) {
      _pageController.animateToPage(
        _currentStep + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    FocusScope.of(context).unfocus();
    if (_currentStep > 0) {
      _pageController.animateToPage(
        _currentStep - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isSaving = true);
    try {
      final authState = ref.read(authStateProvider);
      final uid = authState.value?.uid ?? 'local_user';

      // Build fixed costs list
      final allFixedCosts = <FixedCost>[];
      _presetFixedCostsMap.forEach((label, amount) {
        if (amount >= 0) {
          allFixedCosts.add(FixedCost(
            id: 'preset_${label.hashCode}',
            label: label,
            amount: amount,
            isPreset: true,
          ));
        }
      });
      allFixedCosts.addAll(_customFixedCosts);

      final profile = UserProfile(
        uid: uid,
        baseCurrency: _selectedCurrency,
        monthlyIncome: _monthlyIncome,
        fixedCosts: allFixedCosts,
        savingsGoal: _savingsGoal,
        cycleStartDay: _cycleStartDay,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isOnboardingCompleted: true,
      );

      final profileRepo = ref.read(profileRepositoryProvider);
      await profileRepo.saveProfile(profile);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: AppColors.overBudget,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showAddCustomFixedCostDialog() {
    final labelCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Custom Fixed Cost'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Label (e.g. Gym Membership)',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              onSubmitted: (val) {
                final eval = MathExpressionEvaluator.evaluateAndFormat(val);
                amountCtrl.text = eval;
              },
              decoration: InputDecoration(
                labelText: 'Monthly Amount',
                prefixText: '${AppConstants.getCurrencyInfo(_selectedCurrency).symbol} ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final label = labelCtrl.text.trim();
              final amount = MathExpressionEvaluator.tryEvaluate(amountCtrl.text.trim()) ?? 0.0;
              if (label.isNotEmpty && amount > 0) {
                setState(() {
                  _customFixedCosts.add(FixedCost(
                    id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                    label: label,
                    amount: amount,
                    isPreset: false,
                  ));
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyInfo = AppConstants.getCurrencyInfo(_selectedCurrency);

    return Scaffold(
      appBar: AppBar(
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _prevPage,
              )
            : null,
        title: Text(
          'Step ${_currentStep + 1} of 6',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 6,
            backgroundColor: AppColors.primaryContainer,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 4,
          ),
        ),
      ),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (page) => setState(() => _currentStep = page),
          children: [
            _buildCurrencyStep(theme),
            _buildIncomeStep(theme, currencyInfo),
            _buildFixedCostsStep(theme, currencyInfo),
            _buildSavingsGoalStep(theme, currencyInfo),
            _buildCycleStartStep(theme),
            _buildConfirmationStep(theme, currencyInfo),
          ],
        ),
      ),
    );
  }

  // ===================== STEP 1: BASE CURRENCY =====================
  Widget _buildCurrencyStep(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Choose your base currency',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'All expenses and summaries will be converted and tracked in this currency.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _currencySearchCtrl,
            decoration: InputDecoration(
              hintText: 'Search currency (e.g. USD, EUR, BDT)...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _currencySearchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () => _currencySearchCtrl.clear(),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: _filteredCurrencies.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final curr = _filteredCurrencies[index];
                final isSelected = curr.code == _selectedCurrency;

                return InkWell(
                  onTap: () => setState(() => _selectedCurrency = curr.code),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                              ? AppColors.primary.withAlpha(50)
                              : AppColors.primaryContainer)
                          : (isDark
                              ? AppColors.surfaceElevatedDark
                              : theme.cardTheme.color),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? (isDark ? AppColors.primaryLight : AppColors.primary)
                            : (isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? AppColors.primaryLight : AppColors.primary)
                                : (isDark
                                    ? AppColors.surfaceDark
                                    : AppColors.primaryContainer),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              curr.symbol,
                              style: TextStyle(
                                color: isSelected
                                    ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                                    : (isDark ? AppColors.primaryLight : AppColors.primary),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                curr.code,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? (isSelected ? Colors.white : AppColors.textPrimaryDark)
                                      : (isSelected ? AppColors.primaryDark : AppColors.textPrimaryLight),
                                ),
                              ),
                              Text(
                                curr.name,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? (isSelected ? Colors.white70 : AppColors.textSecondaryDark)
                                      : (isSelected ? AppColors.primaryDark.withAlpha(180) : AppColors.textSecondaryLight),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: isDark ? AppColors.primaryLight : AppColors.primary,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _nextPage,
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  // ===================== STEP 2: MONTHLY INCOME =====================
  Widget _buildIncomeStep(ThemeData theme, CurrencyInfo currencyInfo) {
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'What is your monthly income?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your expected total earnings for one salary cycle.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Income in ${currencyInfo.code}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _incomeCtrl,
                  autofocus: true,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                  decoration: InputDecoration(
                    prefixText: '${currencyInfo.symbol} ',
                    prefixStyle: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                    hintText: '0',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  onChanged: (val) {
                    setState(() {
                      _monthlyIncome = MathExpressionEvaluator.tryEvaluate(val) ?? 0.0;
                    });
                  },
                  onSubmitted: (val) {
                    final eval = MathExpressionEvaluator.evaluateAndFormat(val);
                    setState(() {
                      _incomeCtrl.text = eval;
                      _monthlyIncome = double.tryParse(eval) ?? 0.0;
                    });
                  },
                ),
              ],
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _monthlyIncome > 0 ? _nextPage : null,
            child: const Text('Next: Fixed Costs'),
          ),
        ],
      ),
    );
  }

  // ===================== STEP 3: FIXED COSTS =====================
  Widget _buildFixedCostsStep(ThemeData theme, CurrencyInfo currencyInfo) {
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Fixed Monthly Costs',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Rent, bills, and obligations that leave your account each cycle.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            children: [
              // Preset Checklist Items
              ...AppConstants.presetFixedCostLabels.map((label) {
                final isChecked = _presetFixedCostsMap.containsKey(label);
                final currentVal = _presetFixedCostsMap[label] ?? 0.0;

                final ctrl = _presetControllers.putIfAbsent(label, () {
                  return TextEditingController(
                    text: currentVal > 0
                        ? currentVal.toStringAsFixed(0)
                        : '100',
                  );
                });

                final focusNode = _presetFocusNodes.putIfAbsent(label, () {
                  final fn = FocusNode();
                  fn.addListener(() {
                    if (!fn.hasFocus) {
                      final c = _presetControllers[label];
                      if (c != null) {
                        final eval = MathExpressionEvaluator.evaluateAndFormat(c.text);
                        c.text = eval;
                        final parsed = double.tryParse(eval);
                        if (mounted) {
                          setState(() {
                            if (_presetFixedCostsMap.containsKey(label)) {
                              _presetFixedCostsMap[label] =
                                  (parsed != null && parsed >= 0) ? parsed : 0.0;
                            }
                          });
                        }
                      }
                    }
                  });
                  return fn;
                });

                void toggleItem(bool? checked) {
                  setState(() {
                    if (checked == true) {
                      final parsed = MathExpressionEvaluator.tryEvaluate(ctrl.text.trim());
                      final val = (parsed != null && parsed > 0)
                          ? parsed
                          : 100.0;
                      _presetFixedCostsMap[label] = val;
                      ctrl.text = val.toStringAsFixed(0);
                      ctrl.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: ctrl.text.length,
                      );
                    } else {
                      _presetFixedCostsMap.remove(label);
                    }
                  });
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isChecked,
                          activeColor: AppColors.primary,
                          onChanged: toggleItem,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => toggleItem(!isChecked),
                            child: Text(
                              label,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        if (isChecked)
                          SizedBox(
                            width: 110,
                            child: TextFormField(
                              controller: ctrl,
                              focusNode: focusNode,
                              keyboardType: TextInputType.text,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                prefixText: '${currencyInfo.symbol} ',
                                hintText: '0',
                                hintStyle: TextStyle(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.4),
                                ),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                              ),
                              onChanged: (val) {
                                final trimmed = val.trim();
                                final parsed = MathExpressionEvaluator.tryEvaluate(trimmed);
                                setState(() {
                                  // Minimum amount is 0.0 when cleared/backspaced or empty
                                  _presetFixedCostsMap[label] =
                                      (parsed != null && parsed >= 0)
                                          ? parsed
                                          : 0.0;
                                });
                              },
                              onFieldSubmitted: (val) {
                                final eval = MathExpressionEvaluator.evaluateAndFormat(val);
                                ctrl.text = eval;
                                final parsed = double.tryParse(eval);
                                setState(() {
                                  _presetFixedCostsMap[label] =
                                      (parsed != null && parsed >= 0) ? parsed : 0.0;
                                });
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),

              // Custom Fixed Costs
              if (_customFixedCosts.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Custom Fixed Costs',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                ..._customFixedCosts.map((custom) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(custom.label),
                      subtitle: Text(
                        CurrencyFormatter.format(custom.amount,
                            currencyCode: _selectedCurrency),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: AppColors.overBudget),
                        onPressed: () {
                          setState(() {
                            _customFixedCosts
                                .removeWhere((c) => c.id == custom.id);
                          });
                        },
                      ),
                    ),
                  );
                }),
              ],

              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _showAddCustomFixedCostDialog,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Custom Fixed Cost'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),

        // Running Total Bar at Bottom
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Fixed Costs:',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(_totalFixedCosts,
                        currencyCode: _selectedCurrency),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  child: const Text('Next: Savings Goal'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===================== STEP 4: SAVINGS GOAL =====================
  Widget _buildSavingsGoalStep(ThemeData theme, CurrencyInfo currencyInfo) {
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Monthly Savings Goal',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'How much do you want to keep untouched in savings this cycle?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 36),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Target Savings (${currencyInfo.code})',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _savingsGoalCtrl,
                  autofocus: true,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.withinBudget,
                  ),
                  decoration: InputDecoration(
                    prefixText: '${currencyInfo.symbol} ',
                    prefixStyle: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.withinBudget,
                    ),
                    hintText: '0',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  onChanged: (val) {
                    setState(() {
                      _savingsGoal = MathExpressionEvaluator.tryEvaluate(val) ?? 0.0;
                    });
                  },
                  onSubmitted: (val) {
                    final eval = MathExpressionEvaluator.evaluateAndFormat(val);
                    setState(() {
                      _savingsGoalCtrl.text = eval;
                      _savingsGoal = double.tryParse(eval) ?? 0.0;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceElevatedDark
                  : AppColors.withinBudget.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? AppColors.borderDark
                    : AppColors.withinBudget.withAlpha(60),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined,
                    color: AppColors.withinBudget, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This amount is protected upfront and subtracted before computing your Daily Cost.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _nextPage,
            child: const Text('Next: Salary Cycle'),
          ),
        ],
      ),
    );
  }

  // ===================== STEP 5: SALARY CYCLE START DAY =====================
  Widget _buildCycleStartStep(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Salary Cycle Start Day',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Which day of the month does your salary arrive or cycle begin?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 28),
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(80),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$_cycleStartDay',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Current cycle: ${_currentCycle.formattedRange} (${_currentCycle.totalDays} days)',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Slider(
            value: _cycleStartDay.toDouble(),
            min: 1,
            max: 31,
            divisions: 30,
            label: 'Day $_cycleStartDay',
            onChanged: (val) {
              setState(() {
                _cycleStartDay = val.round();
              });
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceElevatedDark
                  : AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Days 29-31 will automatically clamp to the last valid day in shorter months like February.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _nextPage,
            child: const Text('Review & Calculate'),
          ),
        ],
      ),
    );
  }

  // ===================== STEP 6: SUMMARY / CONFIRMATION =====================
  Widget _buildConfirmationStep(ThemeData theme, CurrencyInfo currencyInfo) {
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Your Daily Allowance 🎉',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Here is the exact amount you can spend each day without breaking your monthly plan.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Big Prominent Hero Daily Cost Card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(100),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'TODAY\'S DAILY COST',
                  style: TextStyle(
                    color: Colors.white70,
                    letterSpacing: 1.5,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  CurrencyFormatter.format(_computedDailyCost,
                      currencyCode: _selectedCurrency),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'for ${_currentCycle.totalDays} days in ${_currentCycle.cycleLabel}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Math Breakdown Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildMathRow('Monthly Income', _monthlyIncome, isPositive: true),
                  const Divider(height: 24),
                  _buildMathRow('Fixed Costs', -_totalFixedCosts),
                  const SizedBox(height: 8),
                  _buildMathRow('Savings Goal', -_savingsGoal),
                  const Divider(height: 24),
                  _buildMathRow(
                    'Available for Spending',
                    _availableForDailySpending,
                    isHighlight: true,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Days in this Cycle',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      Text(
                        '÷ ${_currentCycle.totalDays} days',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          if (_isSaving)
            const Center(child: CircularProgressIndicator())
          else
            ElevatedButton(
              onPressed: _completeOnboarding,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              child: const Text(
                'Let\'s Get Started 🚀',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMathRow(
    String label,
    double amount, {
    bool isPositive = false,
    bool isHighlight = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          CurrencyFormatter.format(amount.abs(), currencyCode: _selectedCurrency),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: isHighlight
                ? AppColors.primary
                : (amount < 0
                    ? AppColors.overBudget
                    : AppColors.withinBudget),
          ),
        ),
      ],
    );
  }
}
