import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_cost/core/theme/theme_provider.dart';

void main() {
  group('Greeting and Time Logic Tests', () {
    String getGreetingForHour(int hour) {
      if (hour >= 5 && hour < 12) {
        return 'Good morning';
      } else if (hour >= 12 && hour < 17) {
        return 'Good afternoon';
      } else if (hour >= 17 && hour < 21) {
        return 'Good evening';
      } else {
        return 'Good night';
      }
    }

    test('Returns Good morning between 05:00 and 11:59', () {
      expect(getGreetingForHour(5), equals('Good morning'));
      expect(getGreetingForHour(8), equals('Good morning'));
      expect(getGreetingForHour(11), equals('Good morning'));
    });

    test('Returns Good afternoon between 12:00 and 16:59', () {
      expect(getGreetingForHour(12), equals('Good afternoon'));
      expect(getGreetingForHour(14), equals('Good afternoon'));
      expect(getGreetingForHour(16), equals('Good afternoon'));
    });

    test('Returns Good evening between 17:00 and 20:59', () {
      expect(getGreetingForHour(17), equals('Good evening'));
      expect(getGreetingForHour(19), equals('Good evening'));
      expect(getGreetingForHour(20), equals('Good evening'));
    });

    test('Returns Good night between 21:00 and 04:59', () {
      expect(getGreetingForHour(21), equals('Good night'));
      expect(getGreetingForHour(23), equals('Good night'));
      expect(getGreetingForHour(0), equals('Good night'));
      expect(getGreetingForHour(4), equals('Good night'));
    });
  });

  group('ThemeModeNotifier Tests', () {
    test('Defaults to ThemeMode.light and updates correctly', () async {
      final notifier = ThemeModeNotifier();
      expect(notifier.state, equals(ThemeMode.light));

      await notifier.setThemeMode(ThemeMode.dark);
      expect(notifier.state, equals(ThemeMode.dark));

      await notifier.setThemeMode(ThemeMode.light);
      expect(notifier.state, equals(ThemeMode.light));

      await notifier.setThemeMode(ThemeMode.system);
      expect(notifier.state, equals(ThemeMode.system));
    });
  });
}
