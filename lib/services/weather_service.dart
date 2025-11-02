import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';
import '../utils/app_logger.dart';

/// Service for fetching weather information
class WeatherService {
  static final WeatherService instance = WeatherService._init();

  WeatherService._init();

  // OpenWeatherMap API key (Free tier)
  // NOTE: In production, this should be stored securely (environment variables, etc.)
  // You can get a free API key at: https://openweathermap.org/api
  static const String _apiKey = 'YOUR_API_KEY_HERE'; // Replace with your actual API key
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  // Cache for weather data (valid for 30 minutes)
  WeatherModel? _cachedWeather;
  DateTime? _cacheTimestamp;

  /// Get current weather for a location
  Future<WeatherModel?> getWeather({
    required double latitude,
    required double longitude,
    String? locationName,
  }) async {
    try {
      // Check cache first (30 minutes validity)
      if (_isCacheValid()) {
        AppLogger.debug('Using cached weather data');
        return _cachedWeather;
      }

      AppLogger.debug('Fetching weather for lat: $latitude, lon: $longitude');

      final url = Uri.parse(
        '$_baseUrl?lat=$latitude&lon=$longitude&appid=$_apiKey&units=metric',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final location = locationName ?? data['name'] as String? ?? 'Unknown';

        final weather = WeatherModel.fromJson(data, location);

        // Update cache
        _cachedWeather = weather;
        _cacheTimestamp = DateTime.now();

        AppLogger.info('Weather fetched successfully for $location: ${weather.temperatureString}, ${weather.description}');
        return weather;
      } else if (response.statusCode == 401) {
        AppLogger.error('Weather API authentication failed. Please check your API key.', null, null);
        return null;
      } else {
        AppLogger.error('Failed to fetch weather: ${response.statusCode}', null, null);
        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching weather', e, stackTrace);
      return null;
    }
  }

  /// Get weather by city name
  Future<WeatherModel?> getWeatherByCity(String cityName) async {
    try {
      AppLogger.debug('Fetching weather for city: $cityName');

      final url = Uri.parse(
        '$_baseUrl?q=$cityName&appid=$_apiKey&units=metric',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final weather = WeatherModel.fromJson(data, cityName);

        AppLogger.info('Weather fetched for $cityName: ${weather.temperatureString}');
        return weather;
      } else {
        AppLogger.error('Failed to fetch weather for $cityName: ${response.statusCode}', null, null);
        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching weather by city', e, stackTrace);
      return null;
    }
  }

  /// Check if cache is valid (less than 30 minutes old)
  bool _isCacheValid() {
    if (_cacheTimestamp == null || _cachedWeather == null) {
      return false;
    }

    final age = DateTime.now().difference(_cacheTimestamp!);
    return age.inMinutes < 30;
  }

  /// Clear cache
  void clearCache() {
    _cachedWeather = null;
    _cacheTimestamp = null;
    AppLogger.info('Weather cache cleared');
  }

  /// Check if API key is configured
  bool get isConfigured => _apiKey != 'YOUR_API_KEY_HERE' && _apiKey.isNotEmpty;
}
