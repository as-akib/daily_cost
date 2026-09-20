import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  /// Formats an amount with currency symbol and thousands separator.
  /// E.g. $1,250.00 or ৳30,000
  static String format(
    double amount, {
    required String currencyCode,
    int decimalDigits = 2,
    bool compact = false,
  }) {
    final currencyInfo = AppConstants.getCurrencyInfo(currencyCode);
    final symbol = currencyInfo.symbol;

    if (compact && amount >= 10000) {
      final compactFmt = NumberFormat.compact();
      return '$symbol${compactFmt.format(amount)}';
    }

    final formatter = NumberFormat.currency(
      symbol: symbol.length <= 2 ? symbol : '$symbol ',
      decimalDigits: decimalDigits,
    );

    return formatter.format(amount);
  }

  /// Format with exact 2 decimal places.
  static String formatWithDecimals(double amount, String currencyCode) {
    return format(amount, currencyCode: currencyCode, decimalDigits: 2);
  }

  /// Format rounded to integer if desired.
  static String formatWhole(double amount, String currencyCode) {
    return format(amount, currencyCode: currencyCode, decimalDigits: 0);
  }
}
