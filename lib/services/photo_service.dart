import 'package:photo_manager/photo_manager.dart';
import '../utils/app_logger.dart';

/// Service for managing photo gallery access and filtering photos by date
class PhotoService {
  static final PhotoService _instance = PhotoService._internal();
  static PhotoService get instance => _instance;

  PhotoService._internal();

  /// Request permission to access photos
  Future<bool> requestPermission() async {
    try {
      final PermissionState result = await PhotoManager.requestPermissionExtend();
      AppLogger.debug('Photo permission state: $result');
      return result == PermissionState.authorized || result == PermissionState.limited;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to request photo permission', e, stackTrace);
      return false;
    }
  }

  /// Get photos taken during a specific date range
  /// Returns a list of AssetEntity objects that can be used to display photos
  Future<List<AssetEntity>> getPhotosInDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Request permission first
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        AppLogger.warning('Photo permission not granted');
        return [];
      }

      AppLogger.debug('Fetching photos from ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');

      // Get all photo albums
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        filterOption: FilterOptionGroup(
          imageOption: const FilterOption(
            sizeConstraint: SizeConstraint(ignoreSize: true),
          ),
          createTimeCond: DateTimeCond(
            min: startDate,
            max: endDate,
          ),
        ),
      );

      if (albums.isEmpty) {
        AppLogger.debug('No photo albums found');
        return [];
      }

      // Collect all photos from all albums that fall within the date range
      List<AssetEntity> allPhotos = [];

      for (final album in albums) {
        final int photoCount = await album.assetCountAsync;
        if (photoCount > 0) {
          final List<AssetEntity> photos = await album.getAssetListRange(
            start: 0,
            end: photoCount,
          );
          allPhotos.addAll(photos);
        }
      }

      // Filter photos by creation date to ensure they're within range
      final filteredPhotos = allPhotos.where((photo) {
        final createDate = photo.createDateTime;
        return createDate.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
               createDate.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();

      // Sort by date, newest first
      filteredPhotos.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));

      AppLogger.info('Found ${filteredPhotos.length} photos in date range');
      return filteredPhotos;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch photos', e, stackTrace);
      return [];
    }
  }
}
