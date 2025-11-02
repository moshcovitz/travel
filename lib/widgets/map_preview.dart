import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/location_model.dart';

/// A small map preview widget showing locations on a map
class MapPreview extends StatelessWidget {
  final List<LocationModel> locations;
  final double height;

  const MapPreview({
    super.key,
    required this.locations,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    if (locations.isEmpty) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 8),
              Text(
                'No locations to display',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate bounds to fit all locations
    final bounds = _calculateBounds();
    final center = LatLng(
      (bounds['minLat']! + bounds['maxLat']!) / 2,
      (bounds['minLon']! + bounds['maxLon']!) / 2,
    );

    // Calculate appropriate zoom level based on bounds
    final zoom = _calculateZoom(bounds);

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none, // Disable interaction for preview
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.travel',
            ),
            // Draw lines between consecutive locations
            if (locations.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: locations.map((loc) {
                      return LatLng(loc.latitude, loc.longitude);
                    }).toList(),
                    color: Colors.blue,
                    strokeWidth: 3.0,
                  ),
                ],
              ),
            // Add markers for each location
            MarkerLayer(
              markers: locations.asMap().entries.map((entry) {
                final index = entry.key;
                final location = entry.value;
                final isFirst = index == 0;
                final isLast = index == locations.length - 1;

                return Marker(
                  point: LatLng(location.latitude, location.longitude),
                  width: 30,
                  height: 30,
                  child: Icon(
                    isFirst
                        ? Icons.place
                        : isLast
                            ? Icons.location_on
                            : Icons.circle,
                    color: isFirst
                        ? Colors.green
                        : isLast
                            ? Colors.red
                            : Colors.blue,
                    size: isFirst || isLast ? 30 : 15,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Calculate bounds (min/max lat/lon) for all locations
  Map<String, double> _calculateBounds() {
    double minLat = locations.first.latitude;
    double maxLat = locations.first.latitude;
    double minLon = locations.first.longitude;
    double maxLon = locations.first.longitude;

    for (var location in locations) {
      if (location.latitude < minLat) minLat = location.latitude;
      if (location.latitude > maxLat) maxLat = location.latitude;
      if (location.longitude < minLon) minLon = location.longitude;
      if (location.longitude > maxLon) maxLon = location.longitude;
    }

    return {
      'minLat': minLat,
      'maxLat': maxLat,
      'minLon': minLon,
      'maxLon': maxLon,
    };
  }

  /// Calculate appropriate zoom level based on bounds
  /// This is a simplified calculation
  double _calculateZoom(Map<String, double> bounds) {
    final latDiff = bounds['maxLat']! - bounds['minLat']!;
    final lonDiff = bounds['maxLon']! - bounds['minLon']!;
    final maxDiff = latDiff > lonDiff ? latDiff : lonDiff;

    // Simple zoom calculation
    if (maxDiff > 10) return 3;
    if (maxDiff > 5) return 5;
    if (maxDiff > 2) return 7;
    if (maxDiff > 1) return 9;
    if (maxDiff > 0.5) return 11;
    if (maxDiff > 0.1) return 13;
    return 15;
  }
}
