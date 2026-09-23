import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static DateTime startOfDay(DateTime date) {
    final d = date.toLocal();
    return DateTime(d.year, d.month, d.day);
  }

  static DateTime endOfDay(DateTime date) {
    final d = date.toLocal();
    return DateTime(d.year, d.month, d.day, 23, 59, 59, 999);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    final la = a.toLocal();
    final lb = b.toLocal();
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
  }

  /// Start of the week (Monday 00:00:00)
  static DateTime startOfWeek(DateTime date) {
    final d = date.toLocal();
    final weekday = d.weekday; // 1 = Monday, 7 = Sunday
    final monday = d.subtract(Duration(days: weekday - 1));
    return startOfDay(monday);
  }

  /// End of the week (Sunday 23:59:59)
  static DateTime endOfWeek(DateTime date) {
    final start = startOfWeek(date);
    return endOfDay(start.add(const Duration(days: 6)));
  }

  /// Formats date friendly for lists: "Today", "Yesterday", or "Oct 12"
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    if (isSameDay(date, now)) return 'Today';
    if (isSameDay(date, now.subtract(const Duration(days: 1)))) return 'Yesterday';
    if (date.year == now.year) {
      return DateFormat('EEE, MMM d').format(date);
    }
    return DateFormat('MMM d, y').format(date);
  }

  /// Formats full date with time
  static String formatDateTime(DateTime date) {
    return DateFormat('MMM d, y • h:mm a').format(date);
  }
}
