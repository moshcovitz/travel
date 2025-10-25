import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import '../services/trip_service.dart';
import '../utils/app_logger.dart';
import 'trip_detail_screen.dart';
import 'create_trip_screen.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  final TripService _tripService = TripService.instance;
  List<TripModel> _trips = [];
  TripModel? _activeTrip;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    AppLogger.debug('TripsScreen initialized');
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    AppLogger.debug('Loading trips from service');
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final trips = await _tripService.getAllTrips();
      final activeTrip = await _tripService.getActiveTrip();

      setState(() {
        _trips = trips;
        _activeTrip = activeTrip;
        _isLoading = false;
      });
      AppLogger.info('Loaded ${trips.length} trips to UI');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load trips in UI', e, stackTrace);
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToCreateTrip() async {
    AppLogger.debug('Navigating to create trip screen');
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateTripScreen(),
      ),
    );

    if (result == true) {
      await _loadTrips();
    }
  }

  Future<void> _navigateToTripDetails(TripModel trip) async {
    AppLogger.debug('Navigating to trip details for trip ${trip.id}');
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripDetailScreen(trip: trip),
      ),
    );

    if (result == true) {
      await _loadTrips();
    }
  }

  Future<void> _endActiveTrip() async {
    if (_activeTrip == null) return;

    try {
      await _tripService.endTrip(_activeTrip!.id!);
      await _loadTrips();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip ended successfully!'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to end trip in UI', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to end trip: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmEndTrip() async {
    if (_activeTrip == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Trip'),
        content: Text(
          'End the current trip "${_activeTrip!.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('End Trip'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _endActiveTrip();
    }
  }

  Future<void> _confirmDeleteTrip(TripModel trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip'),
        content: Text(
          'Delete trip "${trip.name}"? This will also delete all associated locations.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && trip.id != null) {
      await _deleteTrip(trip.id!);
    }
  }

  Future<void> _deleteTrip(int tripId) async {
    try {
      await _tripService.deleteTrip(tripId);
      await _loadTrips();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip deleted'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete trip in UI', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadTrips,
            tooltip: 'Refresh trips',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTrips,
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _navigateToCreateTrip,
        icon: const Icon(Icons.add),
        label: const Text('New Trip'),
        tooltip: 'Create a new trip',
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _trips.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty && _trips.isEmpty) {
      return Center(
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
                onPressed: _loadTrips,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (_activeTrip != null) _buildActiveTripBanner(),
        Expanded(
          child: _trips.isEmpty ? _buildEmptyState() : _buildTripsList(),
        ),
      ],
    );
  }

  Widget _buildActiveTripBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.green.shade200, width: 2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.trip_origin, color: Colors.green.shade700, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Trip: ${_activeTrip!.name}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
                Text(
                  'Started ${_formatDate(DateTime.fromMillisecondsSinceEpoch(_activeTrip!.startTimestamp))}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _confirmEndTrip,
            icon: const Icon(Icons.stop, size: 18),
            label: const Text('End Trip'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.luggage,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No trips yet',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first trip to start tracking',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTripsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _trips.length,
      itemBuilder: (context, index) {
        final trip = _trips[index];
        return _buildTripCard(trip);
      },
    );
  }

  Widget _buildTripCard(TripModel trip) {
    final startDate = DateTime.fromMillisecondsSinceEpoch(trip.startTimestamp);
    final endDate = trip.endTimestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(trip.endTimestamp!)
        : null;

    final duration = endDate != null
        ? endDate.difference(startDate)
        : DateTime.now().difference(startDate);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      child: ListTile(
        onTap: () => _navigateToTripDetails(trip),
        leading: CircleAvatar(
          backgroundColor: trip.isActive ? Colors.green : Colors.blue,
          child: Icon(
            trip.isActive ? Icons.trip_origin : Icons.luggage,
            color: Colors.white,
          ),
        ),
        title: Text(
          trip.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (trip.description != null && trip.description!.isNotEmpty)
              Text(trip.description!, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text('Started: ${_formatDate(startDate)}'),
            if (endDate != null)
              Text('Ended: ${_formatDate(endDate)}')
            else
              Text('Active (${_formatDuration(duration)})',
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
        isThreeLine: true,
        trailing: trip.isActive
            ? null
            : IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _confirmDeleteTrip(trip),
                tooltip: 'Delete trip',
              ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }
}
