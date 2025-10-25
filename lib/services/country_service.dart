import '../services/location_service.dart';
import '../models/location_model.dart';
import '../utils/app_logger.dart';

class CountryService {
  static final CountryService instance = CountryService._init();
  final LocationService _locationService = LocationService.instance;

  CountryService._init();

  Future<Map<String, CountryVisitInfo>> getVisitedCountries() async {
    try {
      AppLogger.debug('Getting visited countries from database');
      final locations = await _locationService.getAllLocations();

      Map<String, CountryVisitInfo> countries = {};

      for (var location in locations) {
        final country = location.country;

        if (country != null && country.isNotEmpty) {
          if (countries.containsKey(country)) {
            countries[country] = countries[country]!.addVisit(location);
          } else {
            countries[country] = CountryVisitInfo(
              countryName: country,
              firstVisit: location.timestamp,
              lastVisit: location.timestamp,
              visitCount: 1,
              locationIds: [location.id!],
            );
          }
        }
      }

      AppLogger.info('Found ${countries.length} visited countries');
      return countries;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get visited countries', e, stackTrace);
      rethrow;
    }
  }

  /// Get country statistics
  Future<Map<String, dynamic>> getCountryStatistics() async {
    try {
      final countries = await getVisitedCountries();
      final totalLocations = await _locationService.getAllLocations();

      int totalVisits = 0;
      int oldestVisit = DateTime.now().millisecondsSinceEpoch;
      int newestVisit = 0;

      for (var countryInfo in countries.values) {
        totalVisits += countryInfo.visitCount;
        if (countryInfo.firstVisit < oldestVisit) {
          oldestVisit = countryInfo.firstVisit;
        }
        if (countryInfo.lastVisit > newestVisit) {
          newestVisit = countryInfo.lastVisit;
        }
      }

      return {
        'totalCountries': countries.length,
        'totalVisits': totalVisits,
        'totalLocations': totalLocations.length,
        'oldestVisit': oldestVisit,
        'newestVisit': newestVisit,
      };
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get country statistics', e, stackTrace);
      rethrow;
    }
  }
}

/// Information about a visited country
class CountryVisitInfo {
  final String countryName;
  final int firstVisit;
  final int lastVisit;
  final int visitCount;
  final List<int> locationIds;

  CountryVisitInfo({
    required this.countryName,
    required this.firstVisit,
    required this.lastVisit,
    required this.visitCount,
    required this.locationIds,
  });

  /// Add a new visit to this country
  CountryVisitInfo addVisit(LocationModel location) {
    return CountryVisitInfo(
      countryName: countryName,
      firstVisit: firstVisit < location.timestamp ? firstVisit : location.timestamp,
      lastVisit: lastVisit > location.timestamp ? lastVisit : location.timestamp,
      visitCount: visitCount + 1,
      locationIds: [...locationIds, location.id!],
    );
  }

  /// Get country flag emoji (simplified - based on country name)
  String get flagEmoji {
    // Map of country names to their flag emojis
    const countryFlags = {
      'United States': '🇺🇸',
      'United Kingdom': '🇬🇧',
      'Canada': '🇨🇦',
      'France': '🇫🇷',
      'Germany': '🇩🇪',
      'Italy': '🇮🇹',
      'Spain': '🇪🇸',
      'Japan': '🇯🇵',
      'China': '🇨🇳',
      'Australia': '🇦🇺',
      'Brazil': '🇧🇷',
      'Mexico': '🇲🇽',
      'India': '🇮🇳',
      'Russia': '🇷🇺',
      'South Korea': '🇰🇷',
      'Netherlands': '🇳🇱',
      'Switzerland': '🇨🇭',
      'Sweden': '🇸🇪',
      'Norway': '🇳🇴',
      'Denmark': '🇩🇰',
      'Finland': '🇫🇮',
      'Belgium': '🇧🇪',
      'Austria': '🇦🇹',
      'Greece': '🇬🇷',
      'Portugal': '🇵🇹',
      'Poland': '🇵🇱',
      'Ireland': '🇮🇪',
      'New Zealand': '🇳🇿',
      'Singapore': '🇸🇬',
      'Thailand': '🇹🇭',
      'Vietnam': '🇻🇳',
      'Indonesia': '🇮🇩',
      'Malaysia': '🇲🇾',
      'Philippines': '🇵🇭',
      'South Africa': '🇿🇦',
      'Egypt': '🇪🇬',
      'Turkey': '🇹🇷',
      'Israel': '🇮🇱',
      'United Arab Emirates': '🇦🇪',
      'Saudi Arabia': '��🇦',
      'Argentina': '🇦🇷',
      'Chile': '🇨🇱',
      'Colombia': '🇨🇴',
      'Peru': '🇵🇪',
      'Czech Republic': '🇨🇿',
      'Hungary': '🇭🇺',
      'Romania': '🇷🇴',
      'Ukraine': '🇺🇦',
      'Croatia': '🇭🇷',
      'Iceland': '🇮🇸',
    };

    return countryFlags[countryName] ?? '🌍';
  }
}
