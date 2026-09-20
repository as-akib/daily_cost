import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/math_expression_evaluator.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/models/category_item.dart';
import '../../data/models/fixed_cost.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/providers.dart';
import '../../core/utils/top_notification.dart';
import '../monthly_summary/monthly_summary_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isRefreshingRates = false;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPref();
  }

  Future<void> _loadNotificationPref() async {
    final notifService = ref.read(notificationServiceProvider);
    final enabled = await notifService.isNotificationsEnabled();
    if (mounted) setState(() => _notificationsEnabled = enabled);
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    final notifService = ref.read(notificationServiceProvider);
    await notifService.setNotificationsEnabled(value);
  }

  Future<void> _refreshExchangeRates(String baseCurrency) async {
    setState(() => _isRefreshingRates = true);
    try {
      final currencyService = ref.read(currencyServiceProvider);
      await currencyService.getExchangeRates(baseCurrency, forceRefresh: true);
      ref.invalidate(exchangeRatesProvider(baseCurrency));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exchange rates refreshed successfully!'),
            backgroundColor: AppColors.withinBudget,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh rates: $e'),
            backgroundColor: AppColors.overBudget,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshingRates = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    final profile = ref.watch(currentProfileProvider).value;
    final baseCurrency = profile?.baseCurrency ?? 'USD';
    final themeMode = ref.watch(themeModeProvider);
    final exchangeRates =
        ref.watch(exchangeRatesProvider(baseCurrency)).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // ===================== 1. ACCOUNT & UPGRADE =====================
          _buildSectionHeader('Account'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: isDark
                            ? AppColors.primaryContainerDark
                            : AppColors.primaryContainer,
                        backgroundImage: (user?.photoUrl != null &&
                                user!.photoUrl!.isNotEmpty)
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        child: (user?.photoUrl == null ||
                                user!.photoUrl!.isEmpty)
                            ? Icon(
                                user?.isAnonymous == true
                                    ? Icons.person_outline_rounded
                                    : Icons.account_circle_rounded,
                                color: isDark
                                    ? AppColors.primaryLight
                                    : AppColors.primary,
                                size: 28,
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    user?.isAnonymous == true
                                        ? 'Guest User'
                                        : (user?.displayName != null &&
                                                user!.displayName!.isNotEmpty
                                            ? user.displayName!
                                            : (user?.email?.split('@').first ??
                                                'Google User')),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (user?.isAnonymous == false) ...[
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () => _showEditNameDialog(
                                        context, user?.displayName),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Icon(
                                        Icons.edit_outlined,
                                        size: 16,
                                        color: isDark
                                            ? AppColors.primaryLight
                                            : AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.isAnonymous == true
                                  ? 'Data is stored locally on this device'
                                  : (user?.email ?? 'Google account linked'),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (user?.isAnonymous == true) ...[
                    const Divider(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                        label: const Text('Upgrade & Link with Google'),
                        onPressed: () => _handleUpgradeWithGoogle(context),
                      ),
                    ),
                  ],
                  const Divider(height: 24),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(Icons.logout_rounded,
                        color: AppColors.overBudget),
                    title: const Text('Sign Out',
                        style: TextStyle(
                            color: AppColors.overBudget,
                            fontWeight: FontWeight.w600)),
                    onTap: () => _confirmSignOut(context),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ===================== 2. APPEARANCE & THEME =====================
          _buildSectionHeader('Appearance'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        themeMode == ThemeMode.dark
                            ? Icons.dark_mode_rounded
                            : (themeMode == ThemeMode.light
                                ? Icons.light_mode_rounded
                                : Icons.brightness_auto_rounded),
                        color: isDark ? AppColors.primaryLight : AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Theme Mode',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            Text(
                              themeMode == ThemeMode.system
                                  ? 'Follows device system theme'
                                  : (themeMode == ThemeMode.dark
                                      ? 'Dark mode active'
                                      : 'Light mode active'),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.system,
                          icon: Icon(Icons.brightness_auto_rounded, size: 18),
                          label: Text('System'),
                        ),
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode_rounded, size: 18),
                          label: Text('Light'),
                        ),
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode_rounded, size: 18),
                          label: Text('Dark'),
                        ),
                      ],
                      selected: {themeMode},
                      onSelectionChanged: (newSelection) {
                        ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(newSelection.first);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ===================== 3. BUDGET & SALARY CYCLE =====================
          _buildSectionHeader('Budget & Salary Cycle'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined,
                      color: AppColors.primary),
                  title: const Text('Monthly Income'),
                  subtitle: Text(profile != null
                      ? CurrencyFormatter.format(profile.monthlyIncome,
                          currencyCode: baseCurrency)
                      : '-'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showEditIncomeDialog(context, profile),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.receipt_long_outlined,
                      color: AppColors.catBills),
                  title: const Text('Fixed Monthly Costs'),
                  subtitle: Text(profile != null
                      ? '${profile.fixedCosts.length} items (${CurrencyFormatter.format(profile.totalFixedCosts, currencyCode: baseCurrency)})'
                      : '-'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showManageFixedCostsDialog(context, profile),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.savings_outlined,
                      color: AppColors.withinBudget),
                  title: const Text('Savings Goal'),
                  subtitle: Text(profile != null
                      ? CurrencyFormatter.format(profile.savingsGoal,
                          currencyCode: baseCurrency)
                      : '-'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showEditSavingsGoalDialog(context, profile),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.calendar_today_rounded,
                      color: AppColors.accent),
                  title: const Text('Salary Cycle Start Day'),
                  subtitle: Text(profile != null
                      ? 'Day ${profile.cycleStartDay} of each month'
                      : '-'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showEditCycleStartDayDialog(context, profile),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.currency_exchange_rounded,
                      color: AppColors.secondary),
                  title: const Text('Base Currency'),
                  subtitle: Text(baseCurrency),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showChangeBaseCurrencyDialog(context, profile),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.history_rounded,
                      color: AppColors.primary),
                  title: const Text('Past Salary Cycles History'),
                  subtitle: const Text('View and compare past cycle reports'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MonthlySummaryScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ===================== 3. CATEGORIES =====================
          _buildSectionHeader('Categories'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.category_outlined,
                  color: AppColors.primary),
              title: const Text('Manage Categories'),
              subtitle:
                  const Text('Add custom categories or hide preset ones'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showManageCategoriesDialog(context),
            ),
          ),
          const SizedBox(height: 20),

          // ===================== 4. NOTIFICATIONS =====================
          _buildSectionHeader('Smart Notifications'),
          Card(
            child: SwitchListTile(
              value: _notificationsEnabled,
              activeThumbColor: AppColors.primary,
              title: const Text('Smart Notifications'),
              subtitle: const Text(
                  'Daily overspend alert, 11:45 PM summary & month-end savings review'),
              onChanged: _toggleNotifications,
            ),
          ),
          const SizedBox(height: 20),

          // ===================== 5. CURRENCY RATES STATUS =====================
          _buildSectionHeader('Exchange Rates'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status: ${exchangeRates?.isOfflineFallback == true ? "Offline Fallback" : "Live (Frankfurter)"}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: exchangeRates?.isOfflineFallback == true
                                  ? AppColors.nearBudget
                                  : AppColors.withinBudget,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            exchangeRates != null
                                ? 'Last updated: ${DateFormat('MMM d, h:mm a').format(exchangeRates.lastFetched)}'
                                : 'Fetching exchange rates...',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                      if (_isRefreshingRates)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded,
                              color: AppColors.primary),
                          tooltip: 'Refresh Rates',
                          onPressed: () => _refreshExchangeRates(baseCurrency),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ===================== HANDLERS & MODALS =====================

  Future<void> _handleUpgradeWithGoogle(BuildContext context) async {
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.linkWithGoogle();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully linked with Google! Data preserved.'),
            backgroundColor: AppColors.withinBudget,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account linking error: $e'),
            backgroundColor: AppColors.overBudget,
          ),
        );
      }
    }
  }

  Widget _buildDialogTitle(BuildContext context, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: _buildDialogTitle(ctx, 'Sign Out?'),
        content: const Text('Are you sure you want to sign out of DailyCost?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.overBudget,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final authRepo = ref.read(authRepositoryProvider);
              await authRepo.signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showEditIncomeDialog(BuildContext context, UserProfile? profile) {
    if (profile == null) return;
    final ctrl =
        TextEditingController(text: profile.monthlyIncome.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: _buildDialogTitle(ctx, 'Edit Monthly Income'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          onSubmitted: (val) {
            final eval = MathExpressionEvaluator.evaluateAndFormat(val);
            ctrl.text = eval;
          },
          decoration: InputDecoration(
            prefixText: '${AppConstants.getCurrencyInfo(profile.baseCurrency).symbol} ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newIncome = MathExpressionEvaluator.tryEvaluate(ctrl.text.trim()) ?? 0.0;
              if (newIncome > 0) {
                final updated = profile.copyWith(
                  monthlyIncome: newIncome,
                  updatedAt: DateTime.now(),
                );
                await ref.read(profileRepositoryProvider).saveProfile(updated);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditSavingsGoalDialog(
      BuildContext context, UserProfile? profile) {
    if (profile == null) return;
    final ctrl =
        TextEditingController(text: profile.savingsGoal.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: _buildDialogTitle(ctx, 'Edit Monthly Savings Goal'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          onSubmitted: (val) {
            final eval = MathExpressionEvaluator.evaluateAndFormat(val);
            ctrl.text = eval;
          },
          decoration: InputDecoration(
            prefixText: '${AppConstants.getCurrencyInfo(profile.baseCurrency).symbol} ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newGoal = MathExpressionEvaluator.tryEvaluate(ctrl.text.trim()) ?? 0.0;
              final updated = profile.copyWith(
                savingsGoal: newGoal,
                updatedAt: DateTime.now(),
              );
              await ref.read(profileRepositoryProvider).saveProfile(updated);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditCycleStartDayDialog(
      BuildContext context, UserProfile? profile) {
    if (profile == null) return;
    int selected = profile.cycleStartDay;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: _buildDialogTitle(ctx, 'Salary Cycle Start Day'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Day $selected',
                  style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary)),
              const SizedBox(height: 12),
              Slider(
                value: selected.toDouble(),
                min: 1,
                max: 31,
                divisions: 30,
                onChanged: (val) {
                  setDialogState(() => selected = val.round());
                },
              ),
              const Text(
                'Immediately recalculates Daily Cost across the app.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondaryLight),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updated = profile.copyWith(
                  cycleStartDay: selected,
                  updatedAt: DateTime.now(),
                );
                await ref.read(profileRepositoryProvider).saveProfile(updated);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeBaseCurrencyDialog(
      BuildContext context, UserProfile? profile) {
    if (profile == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: _buildDialogTitle(ctx, 'Change Base Currency'),
        content: SizedBox(
          width: double.maxFinite,
          height: 320,
          child: ListView.separated(
            itemCount: AppConstants.supportedCurrencies.length,
            separatorBuilder: (context, index) => const SizedBox(height: 4),
            itemBuilder: (ctx, i) {
              final c = AppConstants.supportedCurrencies[i];
              final isSelected = c.code == profile.baseCurrency;
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: isSelected
                    ? (isDark
                        ? AppColors.primary.withAlpha(50)
                        : AppColors.primaryContainer)
                    : null,
                leading: Text(
                  c.symbol,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isSelected
                        ? (isDark ? AppColors.primaryLight : AppColors.primaryDark)
                        : null,
                  ),
                ),
                title: Text(
                  '${c.code} (${c.name})',
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? Colors.white : AppColors.primaryDark)
                        : null,
                  ),
                ),
                trailing: isSelected
                    ? Icon(
                        Icons.check_circle_rounded,
                        color: isDark ? AppColors.primaryLight : AppColors.primary,
                        size: 20,
                      )
                    : null,
                selected: isSelected,
                onTap: () async {
                  final updated = profile.copyWith(
                    baseCurrency: c.code,
                    updatedAt: DateTime.now(),
                  );
                  await ref
                      .read(profileRepositoryProvider)
                      .saveProfile(updated);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showManageFixedCostsDialog(
      BuildContext context, UserProfile? profile) {
    if (profile == null) return;
    final costs = List<FixedCost>.from(profile.fixedCosts);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: _buildDialogTitle(ctx, 'Manage Fixed Costs'),
          content: SizedBox(
            width: double.maxFinite,
            height: 340,
            child: costs.isEmpty
                ? const Center(child: Text('No fixed costs added yet'))
                : ListView.builder(
                    itemCount: costs.length,
                    itemBuilder: (ctx, i) {
                      final item = costs[i];
                      return ListTile(
                        title: Text(item.label),
                        subtitle: Text(CurrencyFormatter.format(item.amount,
                            currencyCode: profile.baseCurrency)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: AppColors.overBudget),
                          onPressed: () {
                            setDialogState(() {
                              costs.removeAt(i);
                            });
                          },
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _showAddFixedCostItemDialog(ctx, (newItem) {
                  setDialogState(() => costs.add(newItem));
                }, profile.baseCurrency);
              },
              child: const Text('+ Add Item'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updated = profile.copyWith(
                  fixedCosts: costs,
                  updatedAt: DateTime.now(),
                );
                await ref.read(profileRepositoryProvider).saveProfile(updated);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddFixedCostItemDialog(BuildContext context,
      Function(FixedCost) onAdd, String baseCurrency) {
    final labelCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: _buildDialogTitle(ctx, 'Add Fixed Cost'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Label'),
            ),
            const SizedBox(height: 12),
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
                prefixText:
                    '${AppConstants.getCurrencyInfo(baseCurrency).symbol} ',
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
              if (label.isNotEmpty && amount >= 0) {
                onAdd(FixedCost(
                  id: 'fixed_${DateTime.now().millisecondsSinceEpoch}',
                  label: label,
                  amount: amount,
                  isPreset: false,
                ));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showManageCategoriesDialog(BuildContext context) {
    final categories = ref.watch(categoriesProvider).value ?? [];
    final authState = ref.read(authStateProvider);
    final uid = authState.value?.uid ?? 'local_user';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: _buildDialogTitle(ctx, 'Manage Categories'),
        content: SizedBox(
          width: double.maxFinite,
          height: 360,
          child: ListView.separated(
            itemCount: categories.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final cat = categories[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: cat.color.withAlpha(35),
                  child: Icon(cat.iconData, color: cat.color, size: 20),
                ),
                title: Text(cat.name,
                    style: TextStyle(
                      decoration:
                          cat.isHidden ? TextDecoration.lineThrough : null,
                    )),
                subtitle: Text(cat.isCustom ? 'Custom' : 'Preset'),
                trailing: cat.isCustom
                    ? IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: AppColors.overBudget),
                        onPressed: () async {
                          await ref
                              .read(categoryRepositoryProvider)
                              .deleteCategory(uid, cat.id);
                        },
                      )
                    : Switch(
                        value: !cat.isHidden,
                        activeThumbColor: AppColors.primary,
                        onChanged: (visible) async {
                          final updated = cat.copyWith(isHidden: !visible);
                          await ref
                              .read(categoryRepositoryProvider)
                              .saveCategory(uid, updated);
                        },
                      ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
          ElevatedButton(
            onPressed: () => _showAddCustomCategoryDialog(context),
            child: const Text('+ Add Custom'),
          ),
        ],
      ),
    );
  }

  void _showAddCustomCategoryDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    IconData selectedIcon = AppConstants.selectableIcons.first;
    Color selectedColor = AppColors.customCategoryColors.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: _buildDialogTitle(ctx, 'New Custom Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    hintText: 'e.g. Coffee, Streaming',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Choose Icon',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.selectableIcons.take(18).map((icon) {
                    final isSel = icon == selectedIcon;
                    return InkWell(
                      onTap: () => setDialogState(() => selectedIcon = icon),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSel
                              ? AppColors.primaryContainer
                              : Colors.transparent,
                          border: Border.all(
                            color: isSel ? AppColors.primary : AppColors.borderLight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon,
                            color: isSel ? AppColors.primary : Colors.grey,
                            size: 22),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Choose Color',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: AppColors.customCategoryColors.map((color) {
                    final isSel = color == selectedColor;
                    return InkWell(
                      onTap: () => setDialogState(() => selectedColor = color),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSel
                              ? Border.all(color: Colors.black, width: 2.5)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isNotEmpty) {
                  final auth = ref.read(authStateProvider);
                  final uid = auth.value?.uid ?? 'local_user';

                  final newCat = CategoryItem(
                    id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    iconCodePoint: selectedIcon.codePoint,
                    colorValue: selectedColor.toARGB32(),
                    isCustom: true,
                    isHidden: false,
                  );

                  await ref
                      .read(categoryRepositoryProvider)
                      .saveCategory(uid, newCat);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditNameDialog(
      BuildContext context, String? currentName) async {
    final controller = TextEditingController(text: currentName ?? '');
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Name'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              hintText: 'e.g. Rahim Uddin',
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() == true) {
                final newName = controller.text.trim();
                Navigator.pop(ctx);
                await ref
                    .read(authRepositoryProvider)
                    .updateDisplayName(newName);
                final profile = ref.read(currentProfileProvider).value;
                if (profile != null) {
                  await ref
                      .read(profileRepositoryProvider)
                      .saveProfile(profile, displayName: newName);
                }
                if (context.mounted) {
                  TopNotification.show(
                    context,
                    title: 'Name Updated',
                    message: 'Your name has been updated to $newName',
                    type: TopNotificationType.success,
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

