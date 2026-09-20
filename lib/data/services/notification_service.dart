import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../core/utils/currency_formatter.dart';

class NotificationService {
  static const String _prefKeyEnabled = 'dailycost_notifications_enabled';

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(initSettings);
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    await initialize();

    // Android 13+
    final androidImpl = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    bool? androidGranted;
    if (androidImpl != null) {
      androidGranted =
          await androidImpl.requestNotificationsPermission();
    }

    // iOS / macOS
    final iosImpl = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    bool? iosGranted;
    if (iosImpl != null) {
      iosGranted = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    final granted = (androidGranted ?? iosGranted ?? true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyEnabled, granted);
    return granted;
  }

  Future<bool> isNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyEnabled) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyEnabled, enabled);
    if (enabled) {
      await requestPermissions();
    } else {
      await _notificationsPlugin.cancelAll();
    }
  }

  // ===========================================================================
  // 1. REAL-TIME NOTIFICATION: Daily Over-Expense Warning Alert
  // ===========================================================================
  /// Triggered immediately when adding an expense causes the daily total to exceed the daily budget.
  Future<void> notifyDailyOverspend({
    required double overAmount,
    required String currencyCode,
  }) async {
    final enabled = await isNotificationsEnabled();
    if (!enabled || overAmount <= 0) return;

    final formattedExtra = CurrencyFormatter.format(overAmount, currencyCode: currencyCode);

    await _showNotification(
      id: 1001,
      title: 'Daily Budget Exceeded ⚠️',
      body: 'Your expense is more than your daily budget. Your extra amount is $formattedExtra.',
    );
  }

  // ===========================================================================
  // 2. SCHEDULED NOTIFICATION: Daily Nightly Review at 11:45 PM
  // ===========================================================================
  /// Schedules a 11:45 PM nightly notification summarizing today's spending.
  Future<void> scheduleDailyNightlyReview({
    required double todayTotal,
    required double dailyCost,
    required String currencyCode,
  }) async {
    final enabled = await isNotificationsEnabled();
    if (!enabled) return;
    await initialize();

    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        23,
        45,
      );

      // If 11:45 PM has already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final formattedSpent = CurrencyFormatter.format(todayTotal, currencyCode: currencyCode);
      final isUnder = todayTotal <= dailyCost;

      final body = isUnder
          ? "Today's expense is $formattedSpent, which is under your budget — Good work! 🎉"
          : "Today's expense is $formattedSpent, which is over your daily budget.";

      await _notificationsPlugin.zonedSchedule(
        2001,
        'Daily Spending Summary 🌙',
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'dailycost_nightly_summary',
            'Daily Nightly Summary',
            channelDescription: 'Daily 11:45 PM spending review',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Error scheduling nightly review notification: $e');
    }
  }

  // ===========================================================================
  // 3. SCHEDULED NOTIFICATION: Weekly Top Category Insight at 11:30 PM (Sunday)
  // ===========================================================================
  /// Schedules a weekly 11:30 PM notification summarizing the highest expense category for the week.
  Future<void> scheduleWeeklyCategoryInsight({
    required String topCategoryName,
    required double topCategoryAmount,
    required String currencyCode,
  }) async {
    final enabled = await isNotificationsEnabled();
    if (!enabled) return;
    await initialize();

    try {
      final now = tz.TZDateTime.now(tz.local);
      // Calculate next Sunday at 23:30
      int daysUntilSunday = (DateTime.sunday - now.weekday) % 7;
      if (daysUntilSunday == 0 && (now.hour > 23 || (now.hour == 23 && now.minute >= 30))) {
        daysUntilSunday = 7;
      }

      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + daysUntilSunday,
        23,
        30,
      );

      final String body;
      if (topCategoryAmount > 0 && topCategoryName.isNotEmpty) {
        final formattedAmount = CurrencyFormatter.format(topCategoryAmount, currencyCode: currencyCode);
        body = "This week your highest spending was in $topCategoryName ($formattedAmount). Stay mindful and finish strong! 💡";
      } else {
        body = "You had great spending control this week with minimal expenses. Fantastic job! 🌟";
      }

      await _notificationsPlugin.zonedSchedule(
        2501,
        'Weekly Spending Insight 📊',
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'dailycost_weekly_insight',
            'Weekly Spending Insight',
            channelDescription: 'Weekly 11:30 PM top spending category review',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e) {
      debugPrint('Error scheduling weekly category insight notification: $e');
    }
  }

  // ===========================================================================
  // 4. SCHEDULED NOTIFICATION: Month-End Summary at 11:55 PM
  // ===========================================================================
  /// Schedules a 11:55 PM notification on the final day of the current month.
  Future<void> scheduleMonthEndReview({
    required bool reachedSavingsTarget,
  }) async {
    final enabled = await isNotificationsEnabled();
    if (!enabled) return;
    await initialize();

    try {
      final now = tz.TZDateTime.now(tz.local);
      // Last day of current month:
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        lastDayOfMonth,
        23,
        55,
      );

      if (scheduledDate.isBefore(now)) {
        // Schedule for next month's end
        final nextMonth = now.month == 12 ? 1 : now.month + 1;
        final nextYear = now.month == 12 ? now.year + 1 : now.year;
        final lastDayOfNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
        scheduledDate = tz.TZDateTime(
          tz.local,
          nextYear,
          nextMonth,
          lastDayOfNextMonth,
          23,
          55,
        );
      }

      final body = reachedSavingsTarget
          ? "This month you reached your savings target! Congratulations! 🏆"
          : "This month your expenses crossed your monthly savings target. Let's do better saving next month! 💪";

      await _notificationsPlugin.zonedSchedule(
        3001,
        'Monthly Budget & Savings Summary 📊',
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'dailycost_monthly_summary',
            'Monthly Summary',
            channelDescription: 'Month-end 11:55 PM savings goal summary',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Error scheduling month-end review notification: $e');
    }
  }

  // ===========================================================================
  // PRIVATE HELPER
  // ===========================================================================
  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'dailycost_budget_alerts',
      'Daily Budget Alerts',
      channelDescription: 'Alerts for daily budget and spending targets',
      importance: Importance.high,
      priority: Priority.high,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );
  }
}
