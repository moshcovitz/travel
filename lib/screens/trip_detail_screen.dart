import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/trip_model.dart';
import '../models/location_model.dart';
import '../models/expense_model.dart';
import '../services/trip_service.dart';
import '../services/photo_service.dart';
import '../services/expense_service.dart';
import '../screens/add_expense_screen.dart';
import '../utils/app_logger.dart';

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
  List<LocationModel> _locations = [];
  Map<String, dynamic>? _statistics;
  List<AssetEntity> _photos = [];
  List<ExpenseModel> _expenses = [];
  Map<String, dynamic>? _expenseStatistics;
  bool _isLoading = false;
  bool _isLoadingPhotos = false;
  bool _isLoadingExpenses = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    AppLogger.debug('TripDetailScreen initialized for trip ${widget.trip.id}');
    _loadTripData();
    _loadPhotos();
    _loadExpenses();
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
    setState(() {
      _isLoadingPhotos = true;
    });

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
      setState(() {
        _isLoadingPhotos = false;
      });
    }
  }

  Future<void> _loadExpenses() async {
    AppLogger.debug('Loading expenses for trip ${widget.trip.id}');
    setState(() {
      _isLoadingExpenses = true;
    });

    try {
      final expenses = await _expenseService.getExpensesForTrip(widget.trip.id!);
      final expenseStats = await _expenseService.getExpenseStatistics(widget.trip.id!);

      setState(() {
        _expenses = expenses;
        _expenseStatistics = expenseStats;
        _isLoadingExpenses = false;
      });
      AppLogger.info('Loaded ${expenses.length} expenses for trip ${widget.trip.id}');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load expenses in UI', e, stackTrace);
      setState(() {
        _isLoadingExpenses = false;
      });
    }
  }

  Future<void> _navigateToAddExpense() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(tripId: widget.trip.id!),
      ),
    );

    if (result == true) {
      // Reload expenses if an expense was added
      await _loadExpenses();
    }
  }

  Future<void> _deleteExpense(int expenseId) async {
    try {
      await _expenseService.deleteExpense(expenseId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense deleted successfully!'),
            backgroundColor: Colors.orange,
          ),
        );
        await _loadExpenses(); // Reload expenses
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete expense in UI', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete expense: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteExpense(ExpenseModel expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text(
          'Delete expense of ${expense.amount.toStringAsFixed(2)} ${expense.currency}?',
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

    if (confirmed == true) {
      await _deleteExpense(expense.id!);
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
        Navigator.pop(context, true); // Return to trips list
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
            onPressed: _isLoading ? null : _loadTripData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTripData,
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddExpense,
        backgroundColor: Colors.green,
        tooltip: 'Add Expense',
        child: const Icon(Icons.add, color: Colors.white),
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
                onPressed: _loadTripData,
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
        const SizedBox(height: 16),
        if (_statistics != null) _buildStatisticsCard(),
        if (_statistics != null) const SizedBox(height: 16),
        _buildExpensesSection(),
        const SizedBox(height: 16),
        _buildPhotosSection(),
        const SizedBox(height: 16),
        _buildLocationsSection(),
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

  Widget _buildStatisticsCard() {
    final durationHours = _statistics!['durationHours'] as int;
    final durationMinutes = _statistics!['durationMinutes'] as int;
    final duration = Duration(hours: durationHours, minutes: durationMinutes);
    final distance = _statistics!['totalDistanceKm'] as double;
    final locationCount = _statistics!['totalLocations'] as int;

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trip Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.straighten,
                  distance.toStringAsFixed(2),
                  'km',
                  Colors.blue,
                ),
                _buildStatItem(
                  Icons.timer,
                  _formatDuration(duration),
                  '',
                  Colors.orange,
                ),
                _buildStatItem(
                  Icons.location_on,
                  locationCount.toString(),
                  'points',
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
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

  Widget _buildExpensesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Expenses (${_expenses.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: _navigateToAddExpense,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingExpenses)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (_expenses.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No expenses recorded yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _navigateToAddExpense,
                      icon: const Icon(Icons.add),
                      label: const Text('Add First Expense'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else ...[
          // Expense summary card
          if (_expenseStatistics != null) _buildExpenseSummaryCard(),
          if (_expenseStatistics != null) const SizedBox(height: 12),
          // Expense list
          ..._expenses.map((expense) => _buildExpenseCard(expense)),
        ],
      ],
    );
  }

  Widget _buildExpenseSummaryCard() {
    final totalExpenses = _expenseStatistics!['totalExpenses'] as double;
    final expenseCount = _expenseStatistics!['expenseCount'] as int;
    final categoryBreakdown = _expenseStatistics!['categoryBreakdown'] as Map<String, double>;

    return Card(
      elevation: 3,
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Expenses',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${totalExpenses.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
            if (categoryBreakdown.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                'By Category',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              ...categoryBreakdown.entries.map((entry) {
                final percentage = (entry.value / totalExpenses * 100);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(_getCategoryIcon(entry.key), size: 16, color: Colors.grey.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Text(
                        '\$${entry.value.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${percentage.toStringAsFixed(0)}%)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseCard(ExpenseModel expense) {
    final date = DateTime.fromMillisecondsSinceEpoch(expense.timestamp);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: Icon(
            _getCategoryIcon(expense.category),
            color: Colors.green.shade700,
            size: 20,
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              expense.category,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              '${expense.amount.toStringAsFixed(2)} ${expense.currency}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (expense.description != null && expense.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                expense.description!,
                style: const TextStyle(fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              _formatDateTime(date),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _confirmDeleteExpense(expense),
          tooltip: 'Delete expense',
        ),
        isThreeLine: expense.description != null && expense.description!.isNotEmpty,
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case ExpenseCategory.food:
        return Icons.restaurant;
      case ExpenseCategory.transportation:
        return Icons.directions_car;
      case ExpenseCategory.accommodation:
        return Icons.hotel;
      case ExpenseCategory.activities:
        return Icons.local_activity;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag;
      case ExpenseCategory.other:
        return Icons.more_horiz;
      default:
        return Icons.receipt;
    }
  }

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photos (${_photos.length})',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoadingPhotos)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (_photos.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No photos taken during this trip',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _photos.length,
              itemBuilder: (context, index) {
                return _buildPhotoThumbnail(_photos[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPhotoThumbnail(AssetEntity photo) {
    return FutureBuilder<Widget>(
      future: _buildThumbnailImage(photo),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          return GestureDetector(
            onTap: () => _showPhotoDialog(photo),
            child: Container(
              width: 120,
              height: 120,
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
          width: 120,
          height: 120,
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

  Future<void> _showPhotoDialog(AssetEntity photo) async {
    final file = await photo.file;
    if (file == null || !mounted) return;

    final photoDate = photo.createDateTime;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(_formatDateTime(photoDate)),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.file(file),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Locations (${_locations.length})',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_locations.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.location_off,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No locations tracked yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ..._locations.map((location) => _buildLocationCard(location)),
      ],
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
