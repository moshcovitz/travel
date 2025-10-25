import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/country_service.dart';

class WorldMapWidget extends StatelessWidget {
  final Map<String, CountryVisitInfo> visitedCountries;

  const WorldMapWidget({
    super.key,
    required this.visitedCountries,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 300,
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: const LatLng(20, 0), // Center of world
                  initialZoom: 1.5,
                  minZoom: 1.0,
                  maxZoom: 5.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.travel.app',
                    maxZoom: 19,
                  ),
                  // Add markers for visited countries
                  if (visitedCountries.isNotEmpty) _buildCountryMarkers(),
                ],
              ),
              // Visited countries badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flag, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${visitedCountries.length} visited',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Map attribution
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: Colors.white.withOpacity(0.8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.public, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Tap & drag to explore • Pinch to zoom',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountryMarkers() {
    final markers = <Marker>[];

    // Map of country names to approximate center coordinates
    final countryCoordinates = _getCountryCoordinates();

    for (var country in visitedCountries.values) {
      final coords = countryCoordinates[country.countryName];
      if (coords != null) {
        markers.add(
          Marker(
            point: coords,
            width: 40,
            height: 40,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.9),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  country.flagEmoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
          ),
        );
      }
    }

    return MarkerLayer(markers: markers);
  }

  Map<String, LatLng> _getCountryCoordinates() {
    return {
      'United States': const LatLng(37.0902, -95.7129),
      'United Kingdom': const LatLng(55.3781, -3.4360),
      'Canada': const LatLng(56.1304, -106.3468),
      'France': const LatLng(46.2276, 2.2137),
      'Germany': const LatLng(51.1657, 10.4515),
      'Italy': const LatLng(41.8719, 12.5674),
      'Spain': const LatLng(40.4637, -3.7492),
      'Japan': const LatLng(36.2048, 138.2529),
      'China': const LatLng(35.8617, 104.1954),
      'Australia': const LatLng(-25.2744, 133.7751),
      'Brazil': const LatLng(-14.2350, -51.9253),
      'Mexico': const LatLng(23.6345, -102.5528),
      'India': const LatLng(20.5937, 78.9629),
      'Russia': const LatLng(61.5240, 105.3188),
      'South Korea': const LatLng(35.9078, 127.7669),
      'Netherlands': const LatLng(52.1326, 5.2913),
      'Switzerland': const LatLng(46.8182, 8.2275),
      'Sweden': const LatLng(60.1282, 18.6435),
      'Norway': const LatLng(60.4720, 8.4689),
      'Denmark': const LatLng(56.2639, 9.5018),
      'Finland': const LatLng(61.9241, 25.7482),
      'Belgium': const LatLng(50.5039, 4.4699),
      'Austria': const LatLng(47.5162, 14.5501),
      'Greece': const LatLng(39.0742, 21.8243),
      'Portugal': const LatLng(39.3999, -8.2245),
      'Poland': const LatLng(51.9194, 19.1451),
      'Ireland': const LatLng(53.4129, -8.2439),
      'New Zealand': const LatLng(-40.9006, 174.8860),
      'Singapore': const LatLng(1.3521, 103.8198),
      'Thailand': const LatLng(15.8700, 100.9925),
      'Vietnam': const LatLng(14.0583, 108.2772),
      'Indonesia': const LatLng(-0.7893, 113.9213),
      'Malaysia': const LatLng(4.2105, 101.9758),
      'Philippines': const LatLng(12.8797, 121.7740),
      'South Africa': const LatLng(-30.5595, 22.9375),
      'Egypt': const LatLng(26.8206, 30.8025),
      'Turkey': const LatLng(38.9637, 35.2433),
      'Israel': const LatLng(31.0461, 34.8516),
      'United Arab Emirates': const LatLng(23.4241, 53.8478),
      'Saudi Arabia': const LatLng(23.8859, 45.0792),
      'Argentina': const LatLng(-38.4161, -63.6167),
      'Chile': const LatLng(-35.6751, -71.5430),
      'Colombia': const LatLng(4.5709, -74.2973),
      'Peru': const LatLng(-9.1900, -75.0152),
      'Czech Republic': const LatLng(49.8175, 15.4730),
      'Hungary': const LatLng(47.1625, 19.5033),
      'Romania': const LatLng(45.9432, 24.9668),
      'Ukraine': const LatLng(48.3794, 31.1656),
      'Croatia': const LatLng(45.1, 15.2),
      'Iceland': const LatLng(64.9631, -19.0208),
    };
  }
}
