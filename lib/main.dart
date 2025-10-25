import 'package:flutter/material.dart';
import 'models/location_model.dart';
import 'models/trip_model.dart';
import 'services/location_service.dart';
import 'services/trip_service.dart';
import 'utils/app_logger.dart';
import 'screens/trips_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const LocationScreen(),
    const TripsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Locations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.luggage),
            label: 'Trips',
          ),
        ],
      ),
    );
  }
}

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final LocationService _locationService = LocationService.instance;
  final TripService _tripService = TripService.instance;
  List<LocationModel> _locations = [];
  TripModel? _activeTrip;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    AppLogger.debug('LocationScreen initialized');
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    AppLogger.debug('Loading locations from service');
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final locations = await _locationService.getAllLocations();
      final activeTrip = await _tripService.getActiveTrip();
      setState(() {
        _locations = locations;
        _activeTrip = activeTrip;
        _isLoading = false;
      });
      AppLogger.info('Loaded ${locations.length} locations to UI');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load locations in UI', e, stackTrace);
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addNewLocation() async {
    AppLogger.debug('User requested to add new location');
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _locationService.getCurrentLocation();
      // Reload the list after adding new location
      await _loadLocations();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location added successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.warning('Failed to add location in UI', e, stackTrace);
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _deleteLocation(int locationId) async {
    try {
      await _locationService.deleteLocation(locationId);
      await _loadLocations();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location deleted'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete location in UI', e, stackTrace);
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
        title: const Text('Location Tracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadLocations,
            tooltip: 'Refresh list',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadLocations,
        child: Column(
          children: [
            if (_activeTrip != null) _buildActiveTripBanner(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _addNewLocation,
        icon: const Icon(Icons.add_location),
        label: const Text('Add Location'),
        tooltip: 'Add current location',
      ),
    );
  }

  Widget _buildActiveTripBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.green.shade200, width: 2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.trip_origin, color: Colors.green.shade700, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Active Trip: ${_activeTrip!.name}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade900,
              ),
            ),
          ),
          Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _locations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty && _locations.isEmpty) {
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
                onPressed: _loadLocations,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_locations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No locations yet',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the button below to add your first location',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _locations.length,
      itemBuilder: (context, index) {
        final location = _locations[index];
        return _buildLocationCard(location);
      },
    );
  }

  Widget _buildLocationCard(LocationModel location) {
    final date = DateTime.fromMillisecondsSinceEpoch(location.timestamp);
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(
            location.tripId != null ? Icons.trip_origin : Icons.location_on,
            color: Colors.white,
          ),
        ),
        title: Text(
          '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('📍 ${location.address}'),
            Text('🕐 $dateStr'),
            Text('📏 Accuracy: ${location.accuracy.toStringAsFixed(2)} m'),
            if (location.tripId != null)
              Text('🗺️  Trip ID: ${location.tripId}'),
          ],
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _confirmDelete(location),
          tooltip: 'Delete location',
        ),
      ),
    );
  }

  Future<void> _confirmDelete(LocationModel location) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Location'),
        content: Text(
          'Delete location at ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}?',
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

    if (confirmed == true && location.id != null) {
      await _deleteLocation(location.id!);
    }
  }
}
