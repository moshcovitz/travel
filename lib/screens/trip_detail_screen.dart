import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/trip_model.dart';
import '../models/location_model.dart';
import '../services/trip_service.dart';
import '../services/photo_service.dart';
import '../services/expense_service.dart';
import '../services/note_service.dart';
import '../services/weather_service.dart';
import '../models/weather_model.dart';
import '../utils/app_logger.dart';
import '../widgets/summary_tile.dart';
import '../widgets/budget_summary.dart';
import '../widgets/map_preview.dart';
import '../widgets/weather_display.dart';
import 'expenses_screen.dart';
import 'photo_gallery_screen.dart';
import 'notes_screen.dart';

class TripDetailScreen extends StatefulWidget {
  final TripModel trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final TripService _tripService = TripService.instance;
  final PhotoService _photoService = PhotoService.instance;
  final ExpenseService _expenseService = ExpenseService.instance;
  final NoteService _noteService = NoteService.instance;
  final WeatherService _weatherService = WeatherService.instance;

  List<LocationModel> _locations = [];
  Map<String, dynamic>? _statistics;
  List<AssetEntity> _photos = [];
  Map<String, dynamic>? _expenseStats;
  int _noteCount = 0;
  WeatherModel? _weather;

  bool _isLoading = false;
  bool _isLoadingPhotos = false;
  bool _isLoadingExpenses = false;
  bool _isLoadingNotes = false;
  bool _isLoadingWeather = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    AppLogger.debug('TripDetailScreen initialized for trip ${widget.trip.id}');
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    _loadTripData();
    _loadPhotos();
    _loadExpenses();
    _loadNotes();
    _loadWeather();
  }

  Future<void> _loadTripData() async {
    AppLogger.debug('Loading trip data for trip ${widget.trip.id}');
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final locations = await _tripService.getLocationsForTrip(widget.trip.id!);
      final stats = await _tripService.getTripStatistics(widget.trip.id!);

      setState(() {
        _locations = locations;
        _statistics = stats;
        _isLoading = false;
      });
      AppLogger.info('Loaded ${locations.length} locations for trip ${widget.trip.id}');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load trip data in UI', e, stackTrace);
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPhotos() async {
    AppLogger.debug('Loading photos for trip ${widget.trip.id}');
    setState(() => _isLoadingPhotos = true);

    try {
      final startDate = DateTime.fromMillisecondsSinceEpoch(widget.trip.startTimestamp);
      final endDate = widget.trip.endTimestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(widget.trip.endTimestamp!)
          : DateTime.now();

      final photos = await _photoService.getPhotosInDateRange(startDate, endDate);

      setState(() {
        _photos = photos;
        _isLoadingPhotos = false;
      });
      AppLogger.info('Loaded ${photos.length} photos for trip ${widget.trip.id}');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load photos in UI', e, stackTrace);
      setState(() => _isLoadingPhotos = false);
    }
  }

  Future<void> _loadExpenses() async {
    AppLogger.debug('Loading expenses for trip ${widget.trip.id}');
    setState(() => _isLoadingExpenses = true);

    try {
      // Use trip's budget currency if available, otherwise use first expense currency
      final stats = await _expenseService.getExpenseStatistics(
        widget.trip.id!,
        targetCurrency: widget.trip.budgetCurrency,
      );
      setState(() {
        _expenseStats = stats;
        _isLoadingExpenses = false;
      });
      AppLogger.info('Loaded expense stats for trip ${widget.trip.id}');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load expenses in UI', e, stackTrace);
      setState(() => _isLoadingExpenses = false);
    }
  }

  Future<void> _loadNotes() async {
    AppLogger.debug('Loading notes for trip ${widget.trip.id}');
    setState(() => _isLoadingNotes = true);

    try {
      final count = await _noteService.getNoteCount(widget.trip.id!);
      setState(() {
        _noteCount = count;
        _isLoadingNotes = false;
      });
      AppLogger.info('Loaded note count for trip ${widget.trip.id}');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load notes in UI', e, stackTrace);
      setState(() => _isLoadingNotes = false);
    }
  }

  Future<void> _loadWeather() async {
    // Only load weather if API key is configured and we have locations
    if (!_weatherService.isConfigured) {
      AppLogger.debug('Weather API not configured, skipping weather fetch');
      return;
    }

    AppLogger.debug('Loading weather for trip ${widget.trip.id}');
    setState(() => _isLoadingWeather = true);

    try {
      // Get the most recent location for the trip
      final locations = await _tripService.getLocationsForTrip(widget.trip.id!);

      if (locations.isNotEmpty) {
        // Use the most recent location (last in the list)
        final recentLocation = locations.last;

        final weather = await _weatherService.getWeather(
          latitude: recentLocation.latitude,
          longitude: recentLocation.longitude,
          locationName: recentLocation.country,
        );

        setState(() {
          _weather = weather;
          _isLoadingWeather = false;
        });

        if (weather != null) {
          AppLogger.info('Loaded weather for trip ${widget.trip.id}: ${weather.temperatureString}');
        }
      } else {
        AppLogger.debug('No locations available for weather fetch');
        setState(() => _isLoadingWeather = false);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load weather in UI', e, stackTrace);
      setState(() => _isLoadingWeather = false);
    }
  }

  Future<void> _endTrip() async {
    try {
      await _tripService.endTrip(widget.trip.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip ended successfully!'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context, true);
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Trip'),
        content: Text('End the trip "${widget.trip.name}"?'),
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
      await _endTrip();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trip.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (widget.trip.isActive)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _confirmEndTrip,
              tooltip: 'End trip',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadAllData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        child: _buildBody(),
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
                onPressed: _loadAllData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildTripInfoCard(),
        const SizedBox(height: 8),
        if (widget.trip.budget != null) _buildBudgetTile(),
        _buildExpensesTile(),
        _buildPhotosTile(),
        _buildLocationsTile(),
        if (_weatherService.isConfigured) _buildWeatherTile(),
        _buildNotesTile(),
      ],
    );
  }

  Widget _buildTripInfoCard() {
    final startDate = DateTime.fromMillisecondsSinceEpoch(widget.trip.startTimestamp);
    final endDate = widget.trip.endTimestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(widget.trip.endTimestamp!)
        : null;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  widget.trip.isActive ? Icons.trip_origin : Icons.luggage,
                  color: widget.trip.isActive ? Colors.green : Colors.blue,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.trip.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.trip.isActive)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'ACTIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.trip.description != null &&
                widget.trip.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                widget.trip.description!,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
            ],
            const Divider(height: 24),
            _buildInfoRow(Icons.calendar_today, 'Started',
                _formatDateTime(startDate)),
            if (endDate != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.event_available, 'Ended',
                  _formatDateTime(endDate)),
            ] else ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.timelapse, 'Duration',
                  _formatDuration(DateTime.now().difference(startDate))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetTile() {
    if (_isLoadingExpenses) {
      return SummaryTile(
        title: 'Budget',
        icon: Icons.account_balance_wallet,
        iconColor: Colors.blue,
        content: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ),
        ),
        showArrow: false,
      );
    }

    final budget = widget.trip.budget ?? 0.0;
    final currency = widget.trip.budgetCurrency ?? 'USD';
    final spent = _expenseStats?['totalExpenses'] as double? ?? 0.0;

    return SummaryTile(
      title: 'Budget',
      icon: Icons.account_balance_wallet,
      iconColor: Colors.blue,
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExpensesScreen(trip: widget.trip),
          ),
        );
        _loadExpenses();
      },
      content: BudgetSummary(
        budget: budget,
        spent: spent,
        currency: currency,
      ),
    );
  }

  Widget _buildExpensesTile() {
    if (_isLoadingExpenses) {
      return SummaryTile(
        title: 'Expenses',
        icon: Icons.attach_money,
        iconColor: Colors.green,
        content: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ),
        ),
        showArrow: false,
      );
    }

    final total = _expenseStats?['totalExpenses'] as double? ?? 0.0;
    final count = _expenseStats?['expenseCount'] as int? ?? 0;
    final currency = _expenseStats?['currency'] as String? ?? 'USD';
    final categoryBreakdown =
        _expenseStats?['categoryBreakdown'] as Map<String, double>? ?? {};

    return SummaryTile(
      title: 'Expenses',
      icon: Icons.attach_money,
      iconColor: Colors.green,
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExpensesScreen(trip: widget.trip),
          ),
        );
        _loadExpenses();
      },
      content: count == 0
          ? Text(
              'No expenses yet',
              style: TextStyle(color: Colors.grey.shade600),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      '$currency ${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$count ${count == 1 ? 'expense' : 'expenses'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (categoryBreakdown.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: categoryBreakdown.entries.take(3).map((entry) {
                      return Chip(
                        label: Text(
                          '${entry.key}: $currency ${entry.value.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildPhotosTile() {
    if (_isLoadingPhotos) {
      return SummaryTile(
        title: 'Photos',
        icon: Icons.photo_library,
        iconColor: Colors.purple,
        content: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ),
        ),
        showArrow: false,
      );
    }

    return SummaryTile(
      title: 'Photos (${_photos.length})',
      icon: Icons.photo_library,
      iconColor: Colors.purple,
      onTap: _photos.isEmpty
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PhotoGalleryScreen(
                    trip: widget.trip,
                    photos: _photos,
                  ),
                ),
              );
            },
      content: _photos.isEmpty
          ? Text(
              'No photos taken during this trip',
              style: TextStyle(color: Colors.grey.shade600),
            )
          : SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _photos.length > 10 ? 10 : _photos.length,
                itemBuilder: (context, index) {
                  return _buildPhotoThumbnail(_photos[index], index);
                },
              ),
            ),
    );
  }

  Widget _buildPhotoThumbnail(AssetEntity photo, int index) {
    return FutureBuilder<Widget>(
      future: _buildThumbnailImage(photo),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PhotoGalleryScreen(
                    trip: widget.trip,
                    photos: _photos,
                    initialIndex: index,
                  ),
                ),
              );
            },
            child: Container(
              width: 100,
              height: 100,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: snapshot.data!,
              ),
            ),
          );
        }
        return Container(
          width: 100,
          height: 100,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Future<Widget> _buildThumbnailImage(AssetEntity photo) async {
    final thumbnail = await photo.thumbnailDataWithSize(
      const ThumbnailSize(200, 200),
    );
    if (thumbnail != null) {
      return Image.memory(
        thumbnail,
        fit: BoxFit.cover,
      );
    }
    return Icon(Icons.broken_image, color: Colors.grey[400], size: 48);
  }

  Widget _buildLocationsTile() {
    if (_isLoading && _statistics == null) {
      return SummaryTile(
        title: 'Locations',
        icon: Icons.location_on,
        iconColor: Colors.blue,
        content: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ),
        ),
        showArrow: false,
      );
    }

    final distance = _statistics?['totalDistanceKm'] as double? ?? 0.0;
    final locationCount = _statistics?['totalLocations'] as int? ?? 0;

    return SummaryTile(
      title: 'Locations & Map',
      icon: Icons.map,
      iconColor: Colors.blue,
      onTap: null, // Could navigate to a detailed map view
      showArrow: false,
      content: locationCount == 0
          ? Text(
              'No locations tracked yet',
              style: TextStyle(color: Colors.grey.shade600),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Statistics row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatColumn(
                        Icons.straighten,
                        distance.toStringAsFixed(2),
                        'km traveled',
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildStatColumn(
                        Icons.location_on,
                        locationCount.toString(),
                        'points',
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Map preview
                MapPreview(
                  locations: _locations,
                  height: 200,
                ),
              ],
            ),
    );
  }

  Widget _buildNotesTile() {
    if (_isLoadingNotes) {
      return SummaryTile(
        title: 'Notes',
        icon: Icons.note,
        iconColor: Colors.orange,
        content: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ),
        ),
        showArrow: false,
      );
    }

    return SummaryTile(
      title: 'Notes & Journal',
      icon: Icons.note,
      iconColor: Colors.orange,
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NotesScreen(trip: widget.trip),
          ),
        );
        _loadNotes();
      },
      content: _noteCount == 0
          ? Text(
              'No notes yet',
              style: TextStyle(color: Colors.grey.shade600),
            )
          : Text(
              '$_noteCount ${_noteCount == 1 ? 'note' : 'notes'}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
    );
  }

  Widget _buildWeatherTile() {
    if (_isLoadingWeather) {
      return SummaryTile(
        title: 'Weather',
        icon: Icons.wb_sunny,
        iconColor: Colors.amber,
        content: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ),
        ),
        showArrow: false,
      );
    }

    if (_weather == null) {
      return SummaryTile(
        title: 'Weather',
        icon: Icons.wb_sunny,
        iconColor: Colors.amber,
        content: Text(
          _locations.isEmpty
              ? 'No location data available'
              : 'Weather data unavailable',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        showArrow: false,
      );
    }

    return SummaryTile(
      title: 'Current Weather',
      icon: Icons.wb_sunny,
      iconColor: Colors.amber,
      onTap: null,
      showArrow: false,
      content: WeatherDisplay(
        weather: _weather!,
        showDetails: true,
      ),
    );
  }

  Widget _buildStatColumn(
      IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(value),
      ],
    );
  }

  String _formatDateTime(DateTime date) {
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
