/// Model representing weather information
class WeatherModel {
  final String location;
  final double temperature; // in Celsius
  final double feelsLike; // in Celsius
  final String description;
  final String icon; // weather icon code
  final int humidity; // percentage
  final double windSpeed; // m/s
  final int pressure; // hPa
  final int timestamp;

  WeatherModel({
    required this.location,
    required this.temperature,
    required this.feelsLike,
    required this.description,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
    required this.pressure,
    required this.timestamp,
  });

  /// Create WeatherModel from OpenWeatherMap API response
  factory WeatherModel.fromJson(Map<String, dynamic> json, String location) {
    final main = json['main'] as Map<String, dynamic>;
    final weather = (json['weather'] as List).first as Map<String, dynamic>;
    final wind = json['wind'] as Map<String, dynamic>;

    return WeatherModel(
      location: location,
      temperature: (main['temp'] as num).toDouble(),
      feelsLike: (main['feels_like'] as num).toDouble(),
      description: weather['description'] as String,
      icon: weather['icon'] as String,
      humidity: main['humidity'] as int,
      windSpeed: (wind['speed'] as num).toDouble(),
      pressure: main['pressure'] as int,
      timestamp: json['dt'] as int,
    );
  }

  /// Get temperature in Fahrenheit
  double get temperatureF => (temperature * 9 / 5) + 32;

  /// Get feels like temperature in Fahrenheit
  double get feelsLikeF => (feelsLike * 9 / 5) + 32;

  /// Get formatted temperature string (Celsius)
  String get temperatureString => '${temperature.toStringAsFixed(1)}°C';

  /// Get formatted temperature string (Fahrenheit)
  String get temperatureFString => '${temperatureF.toStringAsFixed(1)}°F';

  /// Get icon URL from OpenWeatherMap
  String get iconUrl => 'https://openweathermap.org/img/wn/$icon@2x.png';

  /// Capitalize first letter of each word in description
  String get capitalizedDescription {
    return description
        .split(' ')
        .map((word) => word.isEmpty
            ? word
            : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
