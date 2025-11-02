import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/app_logger.dart';

/// Service for currency conversion with exchange rates
class CurrencyService {
  static final CurrencyService instance = CurrencyService._init();

  CurrencyService._init();

  // Cache for exchange rates (valid for 1 day)
  final Map<String, Map<String, double>> _rateCache = {};
  final Map<String, DateTime> _cacheTimestamp = {};

  // Free API from exchangerate-api.com (you can replace with your preferred provider)
  static const String _apiBaseUrl = 'https://api.exchangerate-api.com/v4/latest';

  /// Common currencies supported
  static const List<String> commonCurrencies = [
    'USD', // US Dollar
    'EUR', // Euro
    'GBP', // British Pound
    'JPY', // Japanese Yen
    'CAD', // Canadian Dollar
    'AUD', // Australian Dollar
    'CHF', // Swiss Franc
    'CNY', // Chinese Yuan
    'INR', // Indian Rupee
    'ILS', // Israeli Shekel
    'MXN', // Mexican Peso
    'BRL', // Brazilian Real
    'ZAR', // South African Rand
    'KRW', // South Korean Won
    'SGD', // Singapore Dollar
  ];

  /// Get currency symbol
  static String getCurrencySymbol(String currency) {
    switch (currency) {
      case 'USD':
      case 'CAD':
      case 'AUD':
      case 'MXN':
      case 'SGD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
      case 'CNY':
        return '¥';
      case 'INR':
        return '₹';
      case 'ILS':
        return '₪';
      case 'CHF':
        return 'CHF';
      case 'BRL':
        return 'R\$';
      case 'ZAR':
        return 'R';
      case 'KRW':
        return '₩';
      default:
        return currency;
    }
  }

  /// Convert amount from one currency to another
  Future<double> convert({
    required double amount,
    required String from,
    required String to,
  }) async {
    if (from == to) return amount;

    try {
      final rate = await getExchangeRate(from: from, to: to);
      return amount * rate;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to convert currency', e, stackTrace);
      // Return original amount as fallback
      return amount;
    }
  }

  /// Get exchange rate from one currency to another
  Future<double> getExchangeRate({
    required String from,
    required String to,
  }) async {
    if (from == to) return 1.0;

    // Check cache first
    if (_isCacheValid(from)) {
      final rate = _rateCache[from]?[to];
      if (rate != null) {
        AppLogger.debug('Using cached exchange rate: 1 $from = $rate $to');
        return rate;
      }
    }

    // Fetch fresh rates
    try {
      await _fetchExchangeRates(from);
      final rate = _rateCache[from]?[to];
      if (rate != null) {
        return rate;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch exchange rate', e, stackTrace);
    }

    // Fallback: return 1.0 (no conversion)
    AppLogger.warning('Exchange rate not available, returning 1.0');
    return 1.0;
  }

  /// Fetch exchange rates from API
  Future<void> _fetchExchangeRates(String baseCurrency) async {
    try {
      final url = '$_apiBaseUrl/$baseCurrency';
      AppLogger.debug('Fetching exchange rates from: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;

        // Convert to Map<String, double>
        final rateMap = <String, double>{};
        rates.forEach((key, value) {
          rateMap[key] = (value as num).toDouble();
        });

        _rateCache[baseCurrency] = rateMap;
        _cacheTimestamp[baseCurrency] = DateTime.now();

        AppLogger.info('Fetched exchange rates for $baseCurrency');
      } else {
        AppLogger.error(
            'Failed to fetch exchange rates: ${response.statusCode}', null, null);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching exchange rates', e, stackTrace);
      rethrow;
    }
  }

  /// Check if cache is valid (less than 24 hours old)
  bool _isCacheValid(String currency) {
    final timestamp = _cacheTimestamp[currency];
    if (timestamp == null) return false;

    final age = DateTime.now().difference(timestamp);
    return age.inHours < 24;
  }

  /// Format amount with currency
  String formatAmount(double amount, String currency) {
    final symbol = getCurrencySymbol(currency);
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  /// Clear cache
  void clearCache() {
    _rateCache.clear();
    _cacheTimestamp.clear();
    AppLogger.info('Currency cache cleared');
  }
}
