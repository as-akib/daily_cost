import 'dart:convert';

class ExchangeRates {
  final String base;
  final String date;
  final Map<String, double> rates;
  final DateTime lastFetched;
  final bool isOfflineFallback;

  const ExchangeRates({
    required this.base,
    required this.date,
    required this.rates,
    required this.lastFetched,
    this.isOfflineFallback = false,
  });

  /// Converts an [amount] from currency [from] to currency [to].
  double convert(double amount, {required String from, required String to}) {
    if (from.toUpperCase() == to.toUpperCase()) return amount;

    final fromUpper = from.toUpperCase();
    final toUpper = to.toUpperCase();

    // Direct conversion if base matches
    if (base.toUpperCase() == fromUpper) {
      final rate = rates[toUpper];
      if (rate != null && rate > 0) return amount * rate;
    } else if (base.toUpperCase() == toUpper) {
      final rate = rates[fromUpper];
      if (rate != null && rate > 0) return amount / rate;
    } else {
      // Cross-currency conversion via base
      final fromRate = rates[fromUpper];
      final toRate = rates[toUpper];
      if (fromRate != null && toRate != null && fromRate > 0) {
        final amountInBase = amount / fromRate;
        return amountInBase * toRate;
      }
    }

    // Default fallback if currency is not available in exchange table
    return amount;
  }

  Map<String, dynamic> toMap() {
    return {
      'base': base,
      'date': date,
      'rates': rates,
      'lastFetched': lastFetched.toIso8601String(),
      'isOfflineFallback': isOfflineFallback,
    };
  }

  String toJson() => json.encode(toMap());

  factory ExchangeRates.fromMap(Map<String, dynamic> map) {
    final rawRates = map['rates'] as Map<String, dynamic>? ?? {};
    final parsedRates = <String, double>{};
    rawRates.forEach((key, val) {
      if (val is num) {
        parsedRates[key.toUpperCase()] = val.toDouble();
      }
    });

    DateTime parseDate(dynamic val) {
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return ExchangeRates(
      base: map['base'] as String? ?? 'USD',
      date: map['date'] as String? ?? '',
      rates: parsedRates,
      lastFetched: parseDate(map['lastFetched']),
      isOfflineFallback: map['isOfflineFallback'] as bool? ?? false,
    );
  }

  factory ExchangeRates.fromJson(String source) =>
      ExchangeRates.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Creates a fallback baseline with common currencies if offline on first launch.
  factory ExchangeRates.defaultFallback(String baseCurrency) {
    return ExchangeRates(
      base: baseCurrency.toUpperCase(),
      date: 'offline',
      rates: {
        'USD': 1.0,
        'EUR': 0.92,
        'GBP': 0.79,
        'BDT': 118.5,
        'INR': 83.2,
        'CAD': 1.36,
        'AUD': 1.52,
        'JPY': 151.0,
        'CNY': 7.23,
        'SGD': 1.35,
        'AED': 3.67,
        'SAR': 3.75,
        'MYR': 4.72,
        'THB': 36.5,
        'IDR': 15800.0,
        'PHP': 56.5,
        'PKR': 278.0,
        'CHF': 0.90,
      },
      lastFetched: DateTime.now(),
      isOfflineFallback: true,
    );
  }
}
