import 'package:flutter/material.dart';
import '../models/weather_model.dart';

/// Widget to display weather information
class WeatherDisplay extends StatelessWidget {
  final WeatherModel weather;
  final bool showDetails;

  const WeatherDisplay({
    super.key,
    required this.weather,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main weather info
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weather icon and temperature
            Column(
              children: [
                _buildWeatherIcon(),
                const SizedBox(height: 4),
                Text(
                  weather.temperatureString,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Feels like ${weather.feelsLike.toStringAsFixed(0)}°C',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // Weather description and location
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    weather.capitalizedDescription,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          weather.location,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        if (showDetails) ...[
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Additional weather details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDetailItem(
                Icons.water_drop,
                '${weather.humidity}%',
                'Humidity',
              ),
              _buildDetailItem(
                Icons.air,
                '${weather.windSpeed.toStringAsFixed(1)} m/s',
                'Wind',
              ),
              _buildDetailItem(
                Icons.compress,
                '${weather.pressure} hPa',
                'Pressure',
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildWeatherIcon() {
    // Map weather icons to Material icons
    IconData iconData;
    Color iconColor;

    // OpenWeatherMap icon codes: https://openweathermap.org/weather-conditions
    if (weather.icon.startsWith('01')) {
      // Clear sky
      iconData = Icons.wb_sunny;
      iconColor = Colors.orange;
    } else if (weather.icon.startsWith('02')) {
      // Few clouds
      iconData = Icons.wb_cloudy;
      iconColor = Colors.blue.shade300;
    } else if (weather.icon.startsWith('03') || weather.icon.startsWith('04')) {
      // Clouds
      iconData = Icons.cloud;
      iconColor = Colors.grey;
    } else if (weather.icon.startsWith('09') || weather.icon.startsWith('10')) {
      // Rain
      iconData = Icons.grain;
      iconColor = Colors.blue;
    } else if (weather.icon.startsWith('11')) {
      // Thunderstorm
      iconData = Icons.flash_on;
      iconColor = Colors.deepPurple;
    } else if (weather.icon.startsWith('13')) {
      // Snow
      iconData = Icons.ac_unit;
      iconColor = Colors.lightBlue.shade100;
    } else if (weather.icon.startsWith('50')) {
      // Mist/Fog
      iconData = Icons.foggy;
      iconColor = Colors.grey.shade400;
    } else {
      iconData = Icons.wb_sunny;
      iconColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        size: 48,
        color: iconColor,
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.blue),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
