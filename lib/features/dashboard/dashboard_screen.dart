import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/daily_quotes.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/top_notification.dart';
import '../../data/models/expense.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/notification_center_repository.dart';
import '../add_expense/add_expense_sheet.dart';
import '../premium/premium_screen.dart';
import '../notifications/notifications_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 16) {
      return 'Good Noon';
    } else if (hour >= 16 && hour < 18) {
      return 'Good Afternoon';
    } else if (hour >= 18 && hour < 20) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return Icons.wb_sunny_rounded;
    } else if (hour >= 12 && hour < 16) {
      return Icons.wb_sunny_outlined;
    } else if (hour >= 16 && hour < 18) {
      return Icons.wb_cloudy_rounded;
    } else if (hour >= 18 && hour < 20) {
      return Icons.nights_stay_rounded;
    } else {
      return Icons.bedtime_rounded;
    }
  }

  Future<void> _pickDate(
      BuildContext context, WidgetRef ref, DateTime currentDate) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate.isAfter(now) ? now : currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      ref.read(selectedDashboardDateProvider.notifier).state =
          AppDateUtils.startOfDay(picked);
    }
  }

  void _goToToday(WidgetRef ref) {
    ref.read(selectedDashboardDateProvider.notifier).state =
        AppDateUtils.startOfDay(DateTime.now());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profileAsync = ref.watch(currentProfileProvider);
    final stats = ref.watch(dailyBudgetStatsProvider);
    final dayStats = ref.watch(selectedDayBudgetStatsProvider);
    final selectedDate = ref.watch(selectedDashboardDateProvider);
    final profile = profileAsync.value;
    final baseCurrency = profile?.baseCurrency ?? 'BDT';
    final categories = ref.watch(categoriesProvider).value ?? [];
    final authUser = ref.watch(authStateProvider).value;

    if (stats == null || dayStats == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final dailyCost = dayStats.dailyCost;
    final daySpent = dayStats.daySpent;
    final progress = dailyCost > 0 ? (daySpent / dailyCost) : 0.0;
    final isOver = dayStats.isOverBudget;
    final isToday = dayStats.isToday;
    final isGoogleUser = authUser?.isGoogle == true && authUser?.isAnonymous == false;
    final firstName = isGoogleUser
        ? (authUser?.firstName ?? authUser?.displayName?.split(' ').first)
        : null;
    final greeting = _getGreeting();
    final greetingText = firstName != null && firstName.isNotEmpty
        ? '$greeting, $firstName'
        : greeting;
    final greetingIcon = _getGreetingIcon();
    final todayQuote = DailyQuotes.getTodayQuote();
    final unreadNotificationCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConstants.appName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              dayStats.cycle.formattedRange,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        actions: [
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PremiumScreen()),
              );
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFD97706), Color(0xFFB45309)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withAlpha(100),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'VIP',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.notifications_outlined,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  size: 24,
                ),
                if (unreadNotificationCount > 0)
                  Positioned(
                    right: -5,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? AppColors.backgroundDark : Colors.white,
                          width: 1.5,
                        ),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        unreadNotificationCount > 9 ? '9+' : '$unreadNotificationCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddExpenseSheet.show(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentProfileProvider);
          ref.invalidate(expensesProvider);
          ref.invalidate(categoriesProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceElevatedDark
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 30 : 6),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                greetingIcon,
                                color: AppColors.nearBudget,
                                size: 19,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  greetingText,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Day ${dayStats.daysElapsedInCycle}/${dayStats.cycle.totalDays}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.primaryLight
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withAlpha(40)
                            : AppColors.primaryContainer.withAlpha(70),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.primary.withAlpha(35),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.format_quote_rounded,
                            size: 16,
                            color: isDark
                                ? AppColors.primaryLight
                                : AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              todayQuote,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w600,
                                fontSize: 11.5,
                                height: 1.35,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // ===================== 1. MODERN HERO DAILY COST CARD =====================
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: (isOver ? AppColors.overBudget : AppColors.primary)
                          .withAlpha(isDark ? 50 : 80),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: CustomPaint(
                    painter: TopHeroCardBackgroundPainter(
                      isDark: isDark,
                      isOver: isOver,
                    ),
                    child: Stack(
                      children: [
                      Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(35),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isOver
                                            ? Icons.warning_amber_rounded
                                            : Icons.auto_awesome_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isOver
                                            ? 'OVER BUDGET'
                                            : (isToday
                                            ? 'DAILY ALLOWANCE'
                                            : 'DAILY BUDGET - ${DateFormat('d MMM').format(selectedDate).toUpperCase()}'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (isOver
                                        ? Colors.black.withAlpha(50)
                                        : (progress > 0.85
                                        ? AppColors.nearBudget
                                        : AppColors.withinBudget))
                                        .withAlpha(45),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withAlpha(50),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    isOver
                                        ? 'Exceeded'
                                        : (progress > 0.85
                                        ? 'Caution'
                                        : 'On Track'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isOver
                                  ? 'Exceeded limit by'
                                  : (isToday
                                  ? 'Remaining to spend today'
                                  : 'Remaining on ${DateFormat('d MMMM').format(selectedDate)}'),
                              style: TextStyle(
                                color: Colors.white.withAlpha(210),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                CurrencyFormatter.format(
                                  isOver
                                      ? (daySpent - dailyCost)
                                      : dayStats.dayRemaining,
                                  currencyCode: baseCurrency,
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 38,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.0,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${(progress.clamp(0.0, 9.99) * 100).toInt()}% used',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      '${CurrencyFormatter.format(daySpent, currencyCode: baseCurrency)} of ${CurrencyFormatter.format(dailyCost, currencyCode: baseCurrency)}',
                                      style: TextStyle(
                                        color: Colors.white.withAlpha(220),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(40),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        final fillWidth =
                                            constraints.maxWidth *
                                                progress.clamp(0.0, 1.0);
                                        return Stack(
                                          children: [
                                            Container(
                                              width: fillWidth,
                                              decoration: BoxDecoration(
                                                color: isOver
                                                    ? const Color(0xFFEF4444)
                                                    : (progress > 0.85
                                                    ? AppColors.nearBudget
                                                    : (isDark
                                                    ? AppColors.primaryLight
                                                    : Colors.white)),
                                                borderRadius:
                                                BorderRadius.circular(10),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(35),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceAround,
                                children: [
                                  _buildCardMicroStat(
                                    label: isToday
                                        ? 'Spent Today'
                                        : 'Spent on Day',
                                    value: CurrencyFormatter.format(daySpent,
                                        currencyCode: baseCurrency),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 22,
                                    color: Colors.white.withAlpha(40),
                                  ),
                                  _buildCardMicroStat(
                                    label: 'Daily Target',
                                    value: CurrencyFormatter.format(dailyCost,
                                        currencyCode: baseCurrency),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 22,
                                    color: Colors.white.withAlpha(40),
                                  ),
                                  _buildCardMicroStat(
                                    label:
                                    isToday ? 'Days Left' : 'Cycle Day',
                                    value: isToday
                                        ? '${stats.cycle.totalDays - stats.daysElapsedInCycle} days'
                                        : 'Day ${dayStats.daysElapsedInCycle}/${dayStats.cycle.totalDays}',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isOver
                      ? AppColors.overBudget.withAlpha(25)
                      : AppColors.withinBudget.withAlpha(25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isOver
                        ? AppColors.overBudget.withAlpha(70)
                        : AppColors.withinBudget.withAlpha(70),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isOver
                          ? Icons.warning_amber_rounded
                          : Icons.celebration_rounded,
                      color: isOver
                          ? AppColors.overBudget
                          : AppColors.withinBudget,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        dayStats.statusMessage,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isOver
                              ? AppColors.overBudget
                              : AppColors.withinBudget,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildStatTile(
                    context,
                    label: isToday ? 'Spent Today' : 'Spent on Day',
                    amount: daySpent,
                    currencyCode: baseCurrency,
                    color: AppColors.primary,
                    icon: Icons.today_rounded,
                  ),
                  const SizedBox(width: 12),
                  _buildStatTile(
                    context,
                    label: 'This Week',
                    amount: stats.thisWeekSpent,
                    currencyCode: baseCurrency,
                    color: AppColors.secondary,
                    icon: Icons.view_week_rounded,
                  ),
                  const SizedBox(width: 12),
                  _buildStatTile(
                    context,
                    label: 'This Month',
                    amount: stats.thisCycleSpent,
                    currencyCode: baseCurrency,
                    color: AppColors.accent,
                    icon: Icons.calendar_month_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDateSelectorCarousel(
                context,
                ref,
                selectedDate: selectedDate,
                isToday: isToday,
                isDark: isDark,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isToday
                        ? "Today's Expenses"
                        : "Expenses for ${DateFormat('d MMMM').format(selectedDate)}",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    '${dayStats.transactionCount} ${dayStats.transactionCount == 1 ? 'expense' : 'expenses'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (dayStats.expenses.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 36, horizontal: 20),
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 48,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight),
                        const SizedBox(height: 12),
                        Text(
                          isToday
                              ? 'No expense today'
                              : 'No expense on this day',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isToday
                              ? 'Tap "+ Add Expense" to record what you spend today.'
                              : 'No expenses were recorded on ${DateFormat('EEEE, MMMM d, yyyy').format(selectedDate)}.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: dayStats.expenses.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final exp = dayStats.expenses[index];

                    // Unified Intelligent Category matching
                    final catLower = exp.category.toLowerCase().trim();
                    final cat = categories.where((c) {
                      return c.id.toLowerCase() == catLower ||
                          c.name.toLowerCase() == catLower ||
                          catLower.contains(c.id.toLowerCase()) ||
                          c.id.toLowerCase().contains(catLower);
                    }).firstOrNull;

                    final catColor = cat?.color ?? _getPresetColor(catLower);
                    final catIcon = cat?.iconData ?? _getPresetIcon(catLower);
                    final catName = cat?.name ?? _getPresetName(catLower);

                    return Dismissible(
                      key: Key(exp.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return await _confirmDeleteExpense(
                          context,
                          exp,
                          baseCurrency,
                        );
                      },
                      onDismissed: (direction) async {
                        final auth = ref.read(authStateProvider);
                        final uid = auth.value?.uid ?? 'guest_user';
                        await ref
                            .read(expenseRepositoryProvider)
                            .deleteExpense(uid, exp.id);
                        if (context.mounted) {
                          TopNotification.show(
                            context,
                            title: 'Expense Deleted',
                            message:
                            '${CurrencyFormatter.format(exp.amountInBaseCurrency, currencyCode: baseCurrency)} removed',
                            type: TopNotificationType.info,
                            onUndo: () async {
                              await ref
                                  .read(expenseRepositoryProvider)
                                  .addExpense(uid, exp);
                            },
                          );
                        }
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: AppColors.overBudget,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.delete_outline_rounded,
                                color: Colors.white, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      child: Card(
                        child: ListTile(
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: catColor.withAlpha(35),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(catIcon, color: catColor, size: 22),
                          ),
                          title: Text(
                            exp.note?.isNotEmpty == true ? exp.note! : catName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${AppDateUtils.formatRelative(exp.date)} - $catName',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '-${CurrencyFormatter.format(exp.amountInBaseCurrency, currencyCode: baseCurrency)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              if (exp.currency != baseCurrency)
                                Text(
                                  '${exp.currency} ${exp.amount.toStringAsFixed(0)}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.textSecondaryLight,
                                  ),
                                ),
                            ],
                          ),
                          onTap: () => AddExpenseSheet.show(context,
                              expenseToEdit: exp),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getPresetIcon(String id) {
    if (id.contains('food')) return Icons.restaurant_rounded;
    if (id.contains('trans')) return Icons.directions_bus_rounded;
    if (id.contains('bill')) return Icons.receipt_long_rounded;
    if (id.contains('shop')) return Icons.shopping_bag_rounded;
    if (id.contains('ent')) return Icons.movie_rounded;
    if (id.contains('health')) return Icons.local_hospital_rounded;
    if (id.contains('groc')) return Icons.local_grocery_store_rounded;
    if (id.contains('rent')) return Icons.home_rounded;
    return Icons.category_rounded;
  }

  Color _getPresetColor(String id) {
    if (id.contains('food')) return AppColors.catFood;
    if (id.contains('trans')) return AppColors.catTransport;
    if (id.contains('bill')) return AppColors.catBills;
    if (id.contains('shop')) return AppColors.catShopping;
    if (id.contains('ent')) return AppColors.catEntertainment;
    if (id.contains('health')) return AppColors.catHealth;
    if (id.contains('groc')) return AppColors.catGroceries;
    if (id.contains('rent')) return AppColors.catRent;
    return AppColors.catOther;
  }

  String _getPresetName(String id) {
    if (id.contains('food')) return 'Food & Dining';
    if (id.contains('trans')) return 'Transport';
    if (id.contains('bill')) return 'Bills & Utilities';
    if (id.contains('shop')) return 'Shopping';
    if (id.contains('ent')) return 'Entertainment';
    if (id.contains('health')) return 'Health & Fitness';
    if (id.contains('groc')) return 'Groceries';
    if (id.contains('rent')) return 'Rent & Housing';
    return id.toUpperCase();
  }

  Widget _buildCardMicroStat({
    required String label,
    required String value,
    Color color = Colors.white,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color.withAlpha(190),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile(
      BuildContext context, {
        required String label,
        required double amount,
        required String currencyCode,
        required Color color,
        required IconData icon,
      }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(amount,
                  currencyCode: currencyCode, compact: true),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelectorCarousel(
      BuildContext context,
      WidgetRef ref, {
        required DateTime selectedDate,
        required bool isToday,
        required bool isDark,
      }) {
    final now = DateTime.now();
    final today = AppDateUtils.startOfDay(now);
    final normalizedSelected = AppDateUtils.startOfDay(selectedDate);
    final recentDays = List.generate(7, (index) {
      return AppDateUtils.startOfDay(now.subtract(Duration(days: index)));
    });
    final bool isCustomOlderDate = !recentDays.any((d) => d.isAtSameMomentAs(normalizedSelected));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 16,
                  color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                ),
                const SizedBox(width: 6),
                Text(
                  'SELECT DATE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                  ),
                ),
              ],
            ),
            if (!isToday)
              InkWell(
                onTap: () => _goToToday(ref),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(isDark ? 35 : 20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withAlpha(80),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.replay_rounded, size: 12, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Back to Today',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              ...recentDays.map((date) {
                final isSelected = date.isAtSameMomentAs(normalizedSelected);
                final bool isDayToday = date.isAtSameMomentAs(today);
                final bool isDayYesterday =
                date.isAtSameMomentAs(today.subtract(const Duration(days: 1)));
                final String label;
                if (isDayToday) {
                  label = 'Today';
                } else if (isDayYesterday) {
                  label = 'Yesterday';
                } else {
                  label = DateFormat('EEE').format(date);
                }
                final String dayNum = DateFormat('d MMM').format(date);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      ref.read(selectedDashboardDateProvider.notifier).state = date;
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? const Color(0xFF0F766E) : AppColors.primary)
                            : (isDark
                            ? AppColors.surfaceElevatedDark
                            : AppColors.surfaceLight),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? (isDark ? AppColors.primaryLight : AppColors.primary)
                              : (isDark ? AppColors.borderDark : AppColors.borderLight),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? AppColors.primary.withAlpha(isDark ? 70 : 50)
                                : Colors.black.withAlpha(isDark ? 20 : 4),
                            blurRadius: isSelected ? 8 : 4,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dayNum,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              if (isCustomOlderDate)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F766E) : AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.primaryLight : AppColors.primary,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(isDark ? 70 : 50),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Selected',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('d MMM yyyy').format(selectedDate),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              InkWell(
                onTap: () => _pickDate(context, ref, selectedDate),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.primary.withAlpha(60),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        size: 18,
                        color: isDark ? AppColors.primaryLight : AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Pick Date',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.primaryLight : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<bool?> _confirmDeleteExpense(
      BuildContext context,
      Expense expense,
      String baseCurrency,
      ) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Delete Expense?'),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(ctx, false),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "${expense.note?.isNotEmpty == true ? expense.note! : expense.category}" (${CurrencyFormatter.format(expInBase(expense), currencyCode: baseCurrency)}) from your expenses?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.overBudget,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  double expInBase(Expense exp) {
    return exp.amountInBaseCurrency > 0 ? exp.amountInBaseCurrency : exp.amount;
  }
}

class TopHeroCardBackgroundPainter extends CustomPainter {
  final bool isDark;
  final bool isOver;

  TopHeroCardBackgroundPainter({
    required this.isDark,
    required this.isOver,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Base background paint
    final baseGradient = LinearGradient(
      colors: isOver
          ? (isDark
              ? [const Color(0xFF4C0519), const Color(0xFF881337), const Color(0xFF9F1239)]
              : [const Color(0xFF991B1B), const Color(0xFFDC2626), const Color(0xFFEF4444)])
          : (isDark
              ? [const Color(0xFF022C22), const Color(0xFF064E3B), const Color(0xFF0F766E)]
              : [const Color(0xFF047857), const Color(0xFF0D9488), const Color(0xFF14B8A6)]),
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final paint = Paint()..shader = baseGradient.createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(28)),
      paint,
    );

    // Decorative Layer 1: Glowing Radial Circle
    final circlePaint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          (isOver ? const Color(0xFFF87171) : (isDark ? const Color(0xFF2DD4BF) : Colors.white))
              .withAlpha(isDark ? 40 : 50),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.85, size.height * 0.15),
        radius: size.width * 0.45,
      ));
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.15),
      size.width * 0.45,
      circlePaint1,
    );

    // Decorative Layer 2: Translucent Ring / Arc
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = Colors.white.withAlpha(22);
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.85),
      size.width * 0.35,
      ringPaint,
    );

    final ringPaint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withAlpha(15);
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.85),
      size.width * 0.5,
      ringPaint2,
    );

    // Decorative Layer 3: Curved Line Accent
    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.4,
      size.height * 0.3,
      size.width,
      size.height * 0.6,
    );

    final curvePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withAlpha(25);
    canvas.drawPath(path, curvePaint);

    // Decorative Layer 4: Accent Dots
    final dotPaint = Paint()
      ..color = (isOver ? const Color(0xFFFECDD3) : const Color(0xFF99F6E4)).withAlpha(70);
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.75), 4, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.88, size.height * 0.45), 2.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant TopHeroCardBackgroundPainter oldDelegate) {
    return oldDelegate.isDark != isDark || oldDelegate.isOver != isOver;
  }
}