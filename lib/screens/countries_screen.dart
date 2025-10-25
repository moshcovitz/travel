import 'package:flutter/material.dart';
import '../services/country_service.dart';
import '../utils/app_logger.dart';
import '../widgets/world_map_widget.dart';

class CountriesScreen extends StatefulWidget {
  const CountriesScreen({super.key});

  @override
  State<CountriesScreen> createState() => _CountriesScreenState();
}

class _CountriesScreenState extends State<CountriesScreen> {
  final CountryService _countryService = CountryService.instance;
  Map<String, CountryVisitInfo> _visitedCountries = {};
  Map<String, dynamic>? _statistics;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    AppLogger.debug('CountriesScreen initialized');
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    AppLogger.debug('Loading visited countries');
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final countries = await _countryService.getVisitedCountries();
      final stats = await _countryService.getCountryStatistics();

      setState(() {
        _visitedCountries = countries;
        _statistics = stats;
        _isLoading = false;
      });
      AppLogger.info('Loaded ${countries.length} visited countries');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load countries in UI', e, stackTrace);
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
        title: const Text('Countries Visited'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadCountries,
            tooltip: 'Refresh countries',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCountries,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _visitedCountries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty && _visitedCountries.isEmpty) {
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
                onPressed: _loadCountries,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_visitedCountries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.public,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No countries visited yet',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a trip and add locations to track countries',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        if (_statistics != null) _buildStatisticsCard(),
        const SizedBox(height: 16),
        WorldMapWidget(visitedCountries: _visitedCountries),
        const SizedBox(height: 16),
        Text(
          'Visited Countries (${_visitedCountries.length})',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._buildCountryCards(),
      ],
    );
  }

  Widget _buildStatisticsCard() {
    final totalCountries = _statistics!['totalCountries'] as int;
    final totalVisits = _statistics!['totalVisits'] as int;

    return Card(
      elevation: 4,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(Icons.public, size: 48, color: Colors.blue.shade700),
            const SizedBox(height: 12),
            Text(
              'Your Travel Stats',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.flag,
                  totalCountries.toString(),
                  totalCountries == 1 ? 'Country' : 'Countries',
                  Colors.green,
                ),
                _buildStatItem(
                  Icons.location_on,
                  totalVisits.toString(),
                  totalVisits == 1 ? 'Visit' : 'Visits',
                  Colors.orange,
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
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCountryCards() {
    final sortedCountries = _visitedCountries.values.toList()
      ..sort((a, b) => b.visitCount.compareTo(a.visitCount));

    return sortedCountries.map((country) => _buildCountryCard(country)).toList();
  }

  Widget _buildCountryCard(CountryVisitInfo country) {
    final firstVisitDate = DateTime.fromMillisecondsSinceEpoch(country.firstVisit);
    final lastVisitDate = DateTime.fromMillisecondsSinceEpoch(country.lastVisit);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          radius: 28,
          child: Text(
            country.flagEmoji,
            style: const TextStyle(fontSize: 32),
          ),
        ),
        title: Text(
          country.countryName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'First visit: ${_formatDate(firstVisitDate)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.event_available, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Last visit: ${_formatDate(lastVisitDate)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.shade600,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                country.visitCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                country.visitCount == 1 ? 'visit' : 'visits',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        isThreeLine: true,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
