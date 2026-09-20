import 'package:flutter/material.dart';

class CurrencyInfo {
  final String code;
  final String symbol;
  final String name;

  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.name,
  });
}

class AppConstants {
  AppConstants._();

  static const String appName = 'DailyCost';
  static const String appTagline = 'Know where your money goes.';

  // Default base currency
  static const String defaultCurrency = 'USD';

  // Comprehensive ISO currencies list
  static const List<CurrencyInfo> supportedCurrencies = [
    CurrencyInfo(code: 'USD', symbol: '\$', name: 'US Dollar'),
    CurrencyInfo(code: 'EUR', symbol: '€', name: 'Euro'),
    CurrencyInfo(code: 'GBP', symbol: '£', name: 'British Pound'),
    CurrencyInfo(code: 'BDT', symbol: '৳', name: 'Bangladeshi Taka'),
    CurrencyInfo(code: 'INR', symbol: '₹', name: 'Indian Rupee'),
    CurrencyInfo(code: 'CAD', symbol: 'CA\$', name: 'Canadian Dollar'),
    CurrencyInfo(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar'),
    CurrencyInfo(code: 'JPY', symbol: '¥', name: 'Japanese Yen'),
    CurrencyInfo(code: 'CNY', symbol: '¥', name: 'Chinese Yuan'),
    CurrencyInfo(code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar'),
    CurrencyInfo(code: 'AED', symbol: 'AED', name: 'UAE Dirham'),
    CurrencyInfo(code: 'SAR', symbol: 'SAR', name: 'Saudi Riyal'),
    CurrencyInfo(code: 'MYR', symbol: 'RM', name: 'Malaysian Ringgit'),
    CurrencyInfo(code: 'THB', symbol: '฿', name: 'Thai Baht'),
    CurrencyInfo(code: 'IDR', symbol: 'Rp', name: 'Indonesian Rupiah'),
    CurrencyInfo(code: 'PHP', symbol: '₱', name: 'Philippine Peso'),
    CurrencyInfo(code: 'PKR', symbol: '₨', name: 'Pakistani Rupee'),
    CurrencyInfo(code: 'CHF', symbol: 'CHF', name: 'Swiss Franc'),
    CurrencyInfo(code: 'NZD', symbol: 'NZ\$', name: 'New Zealand Dollar'),
    CurrencyInfo(code: 'SEK', symbol: 'kr', name: 'Swedish Krona'),
    CurrencyInfo(code: 'NOK', symbol: 'kr', name: 'Norwegian Krone'),
    CurrencyInfo(code: 'DKK', symbol: 'kr', name: 'Danish Krone'),
    CurrencyInfo(code: 'BRL', symbol: 'R\$', name: 'Brazilian Real'),
    CurrencyInfo(code: 'MXN', symbol: 'MX\$', name: 'Mexican Peso'),
    CurrencyInfo(code: 'ZAR', symbol: 'R', name: 'South African Rand'),
    CurrencyInfo(code: 'TRY', symbol: '₺', name: 'Turkish Lira'),
    CurrencyInfo(code: 'KRW', symbol: '₩', name: 'South Korean Won'),
    CurrencyInfo(code: 'HKD', symbol: 'HK\$', name: 'Hong Kong Dollar'),
  ];

  static CurrencyInfo getCurrencyInfo(String code) {
    return supportedCurrencies.firstWhere(
      (c) => c.code.toUpperCase() == code.toUpperCase(),
      orElse: () => CurrencyInfo(code: code, symbol: code, name: code),
    );
  }

  // Preset categories as required by specification:
  // Food, Transport, Bills, Shopping, Entertainment, Health, Groceries, Rent, Other
  static const List<Map<String, dynamic>> presetCategoryData = [
    {
      'id': 'food',
      'name': 'Food & Dining',
      'icon': 0xe532, // Icons.restaurant_rounded
      'color': 0xFFF97316,
    },
    {
      'id': 'transport',
      'name': 'Transport',
      'icon': 0xe1d5, // Icons.directions_car_rounded
      'color': 0xFF0284C7,
    },
    {
      'id': 'bills',
      'name': 'Bills & Utilities',
      'icon': 0xf2ea, // Icons.receipt_long_rounded
      'color': 0xFFEAB308,
    },
    {
      'id': 'shopping',
      'name': 'Shopping',
      'icon': 0xf016e, // Icons.shopping_bag_rounded
      'color': 0xFFA855F7,
    },
    {
      'id': 'entertainment',
      'name': 'Entertainment',
      'icon': 0xe406, // Icons.movie_rounded
      'color': 0xFFEC4899,
    },
    {
      'id': 'health',
      'name': 'Health & Fitness',
      'icon': 0xe395, // Icons.local_hospital_rounded
      'color': 0xFF14B8A6,
    },
    {
      'id': 'groceries',
      'name': 'Groceries',
      'icon': 0xe391, // Icons.local_grocery_store_rounded
      'color': 0xFF22C55E,
    },
    {
      'id': 'rent',
      'name': 'Rent & Housing',
      'icon': 0xe318, // Icons.home_rounded
      'color': 0xFF6366F1,
    },
    {
      'id': 'other',
      'name': 'Other',
      'icon': 0xe402, // Icons.more_horiz_rounded
      'color': 0xFF64748B,
    },
  ];

  // Curated list of Material icons for custom categories
  static const List<IconData> selectableIcons = [
    Icons.restaurant_rounded,
    Icons.coffee_rounded,
    Icons.local_bar_rounded,
    Icons.directions_car_rounded,
    Icons.directions_bus_rounded,
    Icons.flight_rounded,
    Icons.receipt_long_rounded,
    Icons.electric_bolt_rounded,
    Icons.wifi_rounded,
    Icons.shopping_bag_rounded,
    Icons.checkroom_rounded,
    Icons.movie_rounded,
    Icons.sports_esports_rounded,
    Icons.music_note_rounded,
    Icons.local_hospital_rounded,
    Icons.fitness_center_rounded,
    Icons.spa_rounded,
    Icons.local_grocery_store_rounded,
    Icons.home_rounded,
    Icons.pets_rounded,
    Icons.school_rounded,
    Icons.work_rounded,
    Icons.savings_rounded,
    Icons.card_giftcard_rounded,
    Icons.brush_rounded,
    Icons.phone_android_rounded,
    Icons.beach_access_rounded,
    Icons.build_rounded,
    Icons.more_horiz_rounded,
  ];

  // Preset fixed costs for onboarding checklist
  static const List<String> presetFixedCostLabels = [
    'Rent & Housing',
    'Utilities & Internet',
    'Subscriptions (Netflix, Spotify, etc.)',
    'Insurance',
    'Loan / EMI',
    'Other Fixed Costs',
  ];
}
