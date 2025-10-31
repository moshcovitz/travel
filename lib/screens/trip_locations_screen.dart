import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import '../models/location_model.dart';
import '../services/trip_service.dart';
import '../utils/app_logger.dart';

class TripLocationsScreen extends StatefulWidget {
  final TripModel trip;

  const TripLocationsScreen({super.key, required this.trip});

  @override
  State<TripLocationsScreen> createState() => _TripLocationsScreenState();
}

class _TripLocationsScreenState extends State<TripLocationsScreen> {
  final TripService _tripService = TripService.instance;
  List<LocationModel> _locations = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    AppLogger.debug('Loading locations for trip ${widget.trip.id}');
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final locations = await _tripService.getLocationsForTrip(widget.trip.id!);

      setState(() {
        _locations = locations;
        _isLoading = false;
      });
      AppLogger.info('Loaded ${locations.length} locations for trip ${widget.trip.id}');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load locations in UI', e, stackTrace);
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Locations (${_locations.length})'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadLocations,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadLocations,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _locations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No locations tracked yet',
                            style: TextStyle(color: Colors.grey[600], fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: _locations.length,
                      itemBuilder: (context, index) {
                        return _buildLocationCard(_locations[index]);
                      },
                    ),
    );
  }

  Widget _buildLocationCard(LocationModel location) {
    final date = DateTime.fromMillisecondsSinceEpoch(location.timestamp);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: const Icon(Icons.location_on, color: Colors.white, size: 20),
        ),
        title: Text(
          '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(location.address, style: const TextStyle(fontSize: 12)),
            Text(_formatDateTime(date), style: const TextStyle(fontSize: 11)),
            Text('Accuracy: ${location.accuracy.toStringAsFixed(1)} m',
                style: const TextStyle(fontSize: 11)),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
