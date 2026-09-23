import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/math_expression_evaluator.dart';
import '../../core/utils/top_notification.dart';
import '../../data/models/expense.dart';
import '../../data/models/category_item.dart';
import '../../data/repositories/providers.dart';

class AddExpenseSheet extends ConsumerStatefulWidget {
  final Expense? expenseToEdit;
  const AddExpenseSheet({super.key, this.expenseToEdit});

  static Future<void> show(BuildContext context, {Expense? expenseToEdit}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddExpenseSheet(expenseToEdit: expenseToEdit),
    );
  }

  @override
  ConsumerState<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<AddExpenseSheet> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  late String _selectedCurrency;
  late DateTime _selectedDate;
  String? _selectedCategoryId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentProfileProvider).value;
    final base = profile?.baseCurrency ?? 'BDT';

    if (widget.expenseToEdit != null) {
      final exp = widget.expenseToEdit!;
      _amountController.text = exp.amount.toString();
      _noteController.text = exp.note ?? '';
      _selectedCurrency = exp.currency;
      _selectedDate = exp.date.toLocal();
      _selectedCategoryId = exp.category;
    } else {
      _selectedCurrency = base;
      _selectedDate = DateTime.now();
      _selectedCategoryId = 'food';
    }
  }

  void _evaluateAmount() {
    final text = _amountController.text.trim();
    if (MathExpressionEvaluator.hasOperator(text)) {
      final evaluated = MathExpressionEvaluator.evaluateAndFormat(text);
      if (evaluated != text) {
        setState(() {
          _amountController.text = evaluated;
          _amountController.selection =
              TextSelection.collapsed(offset: evaluated.length);
        });
      }
    }
  }

  void _appendOperator(String op) {
    if (op == '=') {
      _evaluateAmount();
      return;
    }
    final text = _amountController.text;
    setState(() {
      _amountController.text = '$text$op';
      _amountController.selection =
          TextSelection.collapsed(offset: _amountController.text.length);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          DateTime.now().hour,
          DateTime.now().minute,
        );
      });
    }
  }

  Future<void> _saveExpense() async {
    _evaluateAmount();
    final amount = MathExpressionEvaluator.tryEvaluate(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      TopNotification.show(
        context,
        message: 'Please enter a valid amount',
        type: TopNotificationType.error,
      );
      return;
    }

    final catId = _selectedCategoryId ?? 'food';
    final profile = ref.read(currentProfileProvider).value;
    final baseCurrency = profile?.baseCurrency ?? 'BDT';

    // 1. Exact UID resolve kora
    final sbUser = Supabase.instance.client.auth.currentUser;
    final String uid = sbUser?.id ?? ref.read(currentUserIdProvider);

    setState(() => _isSubmitting = true);
    try {
      final exchangeRatesAsync = ref.read(exchangeRatesProvider(baseCurrency));
      final exchangeRates = exchangeRatesAsync.value;

      double amountInBase = amount;
      if (exchangeRates != null && _selectedCurrency != baseCurrency) {
        amountInBase = exchangeRates.convert(
          amount,
          from: _selectedCurrency,
          to: baseCurrency,
        );
      }

      final expenseRepo = ref.read(expenseRepositoryProvider);
      final expenseId = widget.expenseToEdit?.id ?? const Uuid().v4();
      final expense = Expense(
        id: expenseId,
        amount: amount,
        currency: _selectedCurrency,
        amountInBaseCurrency: amountInBase,
        category: catId,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        date: _selectedDate,
        createdAt: widget.expenseToEdit?.createdAt ?? DateTime.now(),
      );

      if (widget.expenseToEdit != null) {
        await expenseRepo.updateExpense(uid, expense);
      } else {
        await expenseRepo.addExpense(uid, expense);
      }

      // 2. UI Refresh
      ref.invalidate(expensesProvider);
      ref.invalidate(dailyBudgetStatsProvider);
      ref.invalidate(selectedDayBudgetStatsProvider);

      if (!mounted) return;
      final overlayState = Overlay.maybeOf(context, rootOverlay: true);
      Navigator.pop(context);

      TopNotification.show(
        null,
        overlayState: overlayState,
        title: 'Success',
        message: widget.expenseToEdit != null
            ? 'Expense updated successfully!'
            : 'Expense of ${CurrencyFormatter.format(amountInBase, currencyCode: baseCurrency)} added!',
        type: TopNotificationType.success,
      );
    } catch (e) {
      if (mounted) {
        TopNotification.show(
          context,
          title: 'Error',
          message: 'Failed to save expense: $e',
          type: TopNotificationType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profile = ref.watch(currentProfileProvider).value;
    final baseCurrency = profile?.baseCurrency ?? 'BDT';

    final categoriesAsync = ref.watch(categoriesProvider);
    final rawCategories = categoriesAsync.value ?? [];

    final List<CategoryItem> categories = rawCategories.isNotEmpty
        ? rawCategories
        : AppConstants.presetCategoryData
        .map((c) => CategoryItem(
      id: c['id'] as String,
      name: c['name'] as String,
      iconCodePoint: c['icon'] as int,
      colorValue: c['color'] as int,
      isCustom: false,
      isHidden: false,
    ))
        .toList();

    final visibleCategories = categories.where((c) => !c.isHidden).toList();
    if ((_selectedCategoryId == null || _selectedCategoryId!.isEmpty) &&
        visibleCategories.isNotEmpty) {
      _selectedCategoryId = visibleCategories.first.id;
    }

    final exchangeRates = ref.watch(exchangeRatesProvider(baseCurrency)).value;
    final parsedAmount =
    MathExpressionEvaluator.tryEvaluate(_amountController.text.trim());
    final enteredAmount = parsedAmount ?? 0.0;
    final convertedAmount = (_selectedCurrency != baseCurrency && exchangeRates != null)
        ? exchangeRates.convert(enteredAmount,
        from: _selectedCurrency, to: baseCurrency)
        : enteredAmount;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.expenseToEdit != null ? 'Edit Expense' : 'Add Expense',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: Text(
                    DateFormat('MMM d').format(_selectedDate),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceElevatedDark
                    : AppColors.surfaceElevatedLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
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
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          autofocus: widget.expenseToEdit == null,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _evaluateAmount(),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[\d\.\+\-\*xX \s]')),
                          ],
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
                  if (MathExpressionEvaluator.hasOperator(
                      _amountController.text)) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                          onTap: _evaluateAmount,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: parsedAmount != null
                                  ? AppColors.primary.withValues(alpha: 0.15)
                                  : AppColors.overBudget.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              parsedAmount != null
                                  ? '= ${MathExpressionEvaluator.formatResult(parsedAmount)} (Tap to apply)'
                                  : 'Incomplete expression',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: parsedAmount != null
                                    ? AppColors.primary
                                    : AppColors.overBudget,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildMathChip('+'),
                      const SizedBox(width: 6),
                      _buildMathChip('-'),
                      const SizedBox(width: 6),
                      _buildMathChip('×', val: '*'),
                      const SizedBox(width: 6),
                      _buildMathChip('÷', val: '/'),
                      const SizedBox(width: 6),
                      _buildMathChip('=', isAction: true),
                    ],
                  ),
                  if (_selectedCurrency != baseCurrency && enteredAmount > 0) ...[
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
                          CurrencyFormatter.format(convertedAmount,
                              currencyCode: baseCurrency),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.withinBudget,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Category',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: visibleCategories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final cat = visibleCategories[index];
                  final isSelected = cat.id == _selectedCategoryId;
                  return InkWell(
                    onTap: () => setState(() => _selectedCategoryId = cat.id),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 76,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? cat.color.withAlpha(40)
                            : (isDark
                            ? AppColors.surfaceElevatedDark
                            : AppColors.surfaceElevatedLight),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? cat.color : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: cat.color.withAlpha(isSelected ? 255 : 40),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              cat.iconData,
                              size: 20,
                              color: isSelected ? Colors.white : cat.color,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cat.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? cat.color
                                  : (isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'e.g. Lunch with team, Groceries',
                prefixIcon: Icon(Icons.edit_note_rounded),
              ),
            ),
            const SizedBox(height: 24),
            if (_isSubmitting)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _saveExpense,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  widget.expenseToEdit != null
                      ? 'Update Expense'
                      : 'Add Expense',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMathChip(String label, {String? val, bool isAction = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isAction
          ? AppColors.primary
          : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _appendOperator(val ?? label),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isAction
                  ? Colors.white
                  : (isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight),
            ),
          ),
        ),
      ),
    );
  }
}