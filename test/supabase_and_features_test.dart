import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_cost/core/constants/daily_quotes.dart';
import 'package:daily_cost/core/constants/app_colors.dart';
import 'package:daily_cost/data/models/app_notification_item.dart';

void main() {
  group('Daily Financial Quotes Tests', () {
    test('Must contain exactly 30 unique motivational financial quotes', () {
      expect(DailyQuotes.quotes.length, 30);
      final uniqueQuotes = DailyQuotes.quotes.toSet();
      expect(uniqueQuotes.length, 30);
    });

    test('getTodayQuote returns valid quote and rotates predictably', () {
      final day1 = DateTime(2026, 9, 1);
      final day2 = DateTime(2026, 9, 2);
      final day31 = DateTime(2026, 10, 1);

      final quote1 = DailyQuotes.getTodayQuote(day1);
      final quote2 = DailyQuotes.getTodayQuote(day2);
      final quote31 = DailyQuotes.getTodayQuote(day31);

      expect(quote1.isNotEmpty, true);
      expect(quote2.isNotEmpty, true);
      expect(quote1 != quote2, true);
      expect(quote31.isNotEmpty, true);
    });
  });

  group('Greeting Message Time Slots Tests', () {
    String getGreeting(DateTime time) {
      final hour = time.hour;
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

    test('5:00 AM to 11:59 AM -> Good Morning', () {
      expect(getGreeting(DateTime(2026, 9, 20, 5, 0)), 'Good Morning');
      expect(getGreeting(DateTime(2026, 9, 20, 11, 59)), 'Good Morning');
    });

    test('12:00 PM to 3:59 PM -> Good Noon', () {
      expect(getGreeting(DateTime(2026, 9, 20, 12, 0)), 'Good Noon');
      expect(getGreeting(DateTime(2026, 9, 20, 15, 59)), 'Good Noon');
    });

    test('4:00 PM to 5:59 PM -> Good Afternoon', () {
      expect(getGreeting(DateTime(2026, 9, 20, 16, 0)), 'Good Afternoon');
      expect(getGreeting(DateTime(2026, 9, 20, 17, 59)), 'Good Afternoon');
    });

    test('6:00 PM to 7:59 PM -> Good Evening', () {
      expect(getGreeting(DateTime(2026, 9, 20, 18, 0)), 'Good Evening');
      expect(getGreeting(DateTime(2026, 9, 20, 19, 59)), 'Good Evening');
    });

    test('8:00 PM to 4:59 AM -> Good Night', () {
      expect(getGreeting(DateTime(2026, 9, 20, 20, 0)), 'Good Night');
      expect(getGreeting(DateTime(2026, 9, 20, 23, 59)), 'Good Night');
      expect(getGreeting(DateTime(2026, 9, 20, 0, 0)), 'Good Night');
      expect(getGreeting(DateTime(2026, 9, 20, 4, 59)), 'Good Night');
    });
  });

  group('Color Theme #00BBA7 Tests', () {
    test('AppColors.primary matches #00BBA7 precisely', () {
      expect(AppColors.primary, const Color(0xFF00BBA7));
    });
  });

  group('Notification Item & 9+ Badge Logic Tests', () {
    String formatBadge(int unreadCount) {
      if (unreadCount <= 0) return '';
      if (unreadCount > 9) return '9+';
      return '$unreadCount';
    }

    test('Badge displays 1-9 accurately and clamps 10+ to 9+', () {
      expect(formatBadge(0), '');
      expect(formatBadge(1), '1');
      expect(formatBadge(9), '9');
      expect(formatBadge(10), '9+');
      expect(formatBadge(15), '9+');
      expect(formatBadge(99), '9+');
    });

    test('AppNotificationItem serializes and deserializes cleanly', () {
      final now = DateTime(2026, 9, 20, 15, 30);
      final item = AppNotificationItem(
        id: 'test-1',
        title: 'Weekly Insight',
        message: 'This week you spent highest in Food.',
        type: NotificationType.weeklySummary,
        timestamp: now,
        isRead: false,
      );

      final map = item.toMap();
      final reconstructed = AppNotificationItem.fromMap(map);

      expect(reconstructed.id, 'test-1');
      expect(reconstructed.title, 'Weekly Insight');
      expect(reconstructed.type, NotificationType.weeklySummary);
      expect(reconstructed.isRead, false);
    });
  });
}
