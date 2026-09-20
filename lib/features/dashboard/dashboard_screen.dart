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
      lastDate: DateTime(now.year, now.month, now.day), // Only past dates & today
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
    final baseCurrency = profile?.baseCurrency ?? 'USD';
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

    // Greeting logic: Display First Name ONLY for Google Sign-in users
    final isGoogleUser = authUser?.isGoogle == true && authUser?.isAnonymous == false;
    final firstName = isGoogleUser
        ? (authUser?.firstName ?? authUser?.displayName?.split(' ').first)
        : null;
    final greeting = _getGreeting();
    final greetingText = firstName != null && firstName.isNotEmpty
        ? '$greeting, $firstName 👋'
        : '$greeting 👋';
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
          // VIP / Pro Button
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
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withAlpha(80),
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
                    'PRO',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Notification Bell Button with 9+ badge
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
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ===================== GREETING & DAILY QUOTE CARD =====================
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceElevatedDark
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
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
                    // Top greeting row with cycle badge
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

                    // Daily Financial Quote Strip
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
                  gradient: isOver
                      ? AppColors.dangerGradient
                      : (isDark
                          ? AppColors.heroGradientDark
                          : AppColors.heroGradient),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: (isOver ? AppColors.overBudget : AppColors.primary)
                          .withAlpha(isDark ? 70 : 110),
                      blurRadius: 26,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 60 : 25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    children: [
                      // Decorative background radial accent
                      Positioned(
                        top: -40,
                        right: -40,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withAlpha(20),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Top Tag Row
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
                                                : 'DAILY BUDGET • ${DateFormat('d MMM').format(selectedDate).toUpperCase()}'),
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
                                        ? '🚨 Exceeded'
                                        : (progress > 0.85
                                            ? '⚡ Caution'
                                            : '🎉 On Track'),
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

                            // Main Hero Balance
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

                            // Glowing Gradient Progress Bar
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
                                                gradient: LinearGradient(
                                                  colors: isOver
                                                      ? [
                                                          const Color(
                                                              0xFFFCA5A5),
                                                          const Color(
                                                              0xFFEF4444)
                                                        ]
                                                      : (progress > 0.85
                                                          ? [
                                                              const Color(
                                                                  0xFFFDE68A),
                                                              const Color(
                                                                  0xFFF59E0B)
                                                            ]
                                                          : [
                                                              const Color(
                                                                  0xFFA7F3D0),
                                                              const Color(
                                                                  0xFF10B981)
                                                            ]),
                                                ),
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

                            // Micro-Stats Footer Strip
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

              const SizedBox(height: 16),

              // ===================== 2. FRIENDLY STATUS BANNER =====================
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

              // ===================== 3. AT-A-GLANCE TOTALS =====================
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

              // ===================== DATE SELECTOR & TIMELINE CAROUSEL =====================
              _buildDateSelectorCarousel(
                context,
                ref,
                selectedDate: selectedDate,
                isToday: isToday,
                isDark: isDark,
              ),

              const SizedBox(height: 20),

              // ===================== 4. TODAY'S / SELECTED DAY'S EXPENSES =====================
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
                    final cat = categories
                        .where((c) => c.id == exp.category)
                        .firstOrNull;
                    final catColor = cat?.color ?? AppColors.catOther;
                    final catIcon = cat?.iconData ?? Icons.more_horiz_rounded;
                    final catName = cat?.name ?? exp.category;

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
                        final uid = auth.value?.uid ?? 'local_user';
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
                            '${AppDateUtils.formatRelative(exp.date)} • $catName',
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

    // Build list of recent past days (Today, Yesterday, -2, -3, -4, -5, -6)
    final recentDays = List.generate(7, (index) {
      return AppDateUtils.startOfDay(now.subtract(Duration(days: index)));
    });

    final bool isCustomOlderDate = !recentDays.any((d) => d.isAtSameMomentAs(normalizedSelected));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row: Section Label + Active Date Pill
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

        // Horizontal Carousel
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              // 7 Recent Days
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
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFF00BBA7), Color(0xFF0F766E)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: !isSelected
                            ? (isDark
                                ? AppColors.surfaceElevatedDark
                                : AppColors.surfaceLight)
                            : null,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF00BBA7)
                              : (isDark ? AppColors.borderDark : AppColors.borderLight),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? const Color(0xFF00BBA7).withAlpha(isDark ? 80 : 60)
                                : Colors.black.withAlpha(isDark ? 20 : 4),
                            blurRadius: isSelected ? 10 : 4,
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

              // If a custom older date was selected via calendar picker
              if (isCustomOlderDate)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00BBA7), Color(0xFF0F766E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF00BBA7),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00BBA7).withAlpha(isDark ? 80 : 60),
                          blurRadius: 10,
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

              // Calendar Picker Action Button
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
          'Are you sure you want to remove "${expense.note?.isNotEmpty == true ? expense.note! : expense.category}" (${CurrencyFormatter.format(expense.amountInBaseCurrency, currencyCode: baseCurrency)}) from your expenses?',
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
}
