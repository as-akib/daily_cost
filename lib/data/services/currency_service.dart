import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exchange_rates.dart';

class CurrencyService {
  static const String _cacheKeyPrefix = 'dailycost_exchange_rates_';
  static const String _apiEndpointDev = 'https://api.frankfurter.dev/v1/latest';
  static const String _apiEndpointApp = 'https://api.frankfurter.app/latest';

  final http.Client _client;

  CurrencyService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches exchange rates for [baseCurrency], utilizing local cache if fresh (<24h).
  Future<ExchangeRates> getExchangeRates(
    String baseCurrency, {
    bool forceRefresh = false,
  }) async {
    final base = baseCurrency.toUpperCase();
    final prefs = await SharedPreferences.getInstance();
    final cachedString = prefs.getString('$_cacheKeyPrefix$base');

    if (cachedString != null && !forceRefresh) {
      try {
        final cached = ExchangeRates.fromJson(cachedString);
        final age = DateTime.now().difference(cached.lastFetched);
        // If cache is less than 24 hours old, return it directly
        if (age.inHours < 24) {
          return cached;
        }
      } catch (_) {
        // Corrupt cache, proceed to fetch
      }
    }

    // Attempt to fetch from Frankfurter API
    try {
      final fresh = await _fetchFromApi(base);
      // Cache successful response
      await prefs.setString('$_cacheKeyPrefix$base', fresh.toJson());
      return fresh;
    } catch (e) {
      // If network fails, return cached rates if available
      if (cachedString != null) {
        try {
          final cached = ExchangeRates.fromJson(cachedString);
          return ExchangeRates(
            base: cached.base,
            date: cached.date,
            rates: cached.rates,
            lastFetched: cached.lastFetched,
            isOfflineFallback: true,
          );
        } catch (_) {}
      }

      // Default hardcoded fallback rates if no cache exists
      return ExchangeRates.defaultFallback(base);
    }
  }

  Future<ExchangeRates> _fetchFromApi(String base) async {
    // Frankfurter supports EUR base or other major bases e.g. ?base=USD
    final uri = Uri.parse('$_apiEndpointDev?base=$base');

    http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 8));
    } catch (_) {
      // Fallback domain
      final fallbackUri = Uri.parse('$_apiEndpointApp?base=$base');
      response =
          await _client.get(fallbackUri).timeout(const Duration(seconds: 8));
    }

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final rawRates = data['rates'] as Map<String, dynamic>? ?? {};
      final rates = <String, double>{base: 1.0};

      rawRates.forEach((k, v) {
        if (v is num) rates[k.toUpperCase()] = v.toDouble();
      });

      return ExchangeRates(
        base: data['base'] as String? ?? base,
        date: data['date'] as String? ?? '',
        rates: rates,
        lastFetched: DateTime.now(),
        isOfflineFallback: false,
      );
    } else {
      throw Exception('Failed to load exchange rates: HTTP ${response.statusCode}');
    }
  }
}
