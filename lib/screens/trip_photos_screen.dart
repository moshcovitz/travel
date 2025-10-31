import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/trip_model.dart';
import '../services/photo_service.dart';
import '../utils/app_logger.dart';

class TripPhotosScreen extends StatefulWidget {
  final TripModel trip;

  const TripPhotosScreen({super.key, required this.trip});

  @override
  State<TripPhotosScreen> createState() => _TripPhotosScreenState();
}

class _TripPhotosScreenState extends State<TripPhotosScreen> {
  final PhotoService _photoService = PhotoService.instance;
  List<AssetEntity> _photos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    AppLogger.debug('Loading photos for trip ${widget.trip.id}');
    setState(() {
      _isLoading = true;
    });

    try {
      final startDate = DateTime.fromMillisecondsSinceEpoch(widget.trip.startTimestamp);
      final endDate = widget.trip.endTimestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(widget.trip.endTimestamp!)
          : DateTime.now();

      final photos = await _photoService.getPhotosInDateRange(startDate, endDate);

      setState(() {
        _photos = photos;
        _isLoading = false;
      });
      AppLogger.info('Loaded ${photos.length} photos for trip ${widget.trip.id}');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load photos in UI', e, stackTrace);
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Photos (${_photos.length})'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _photos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No photos taken during this trip',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: _photos.length,
                  itemBuilder: (context, index) {
                    return _buildPhotoThumbnail(_photos[index]);
                  },
                ),
    );
  }

  Widget _buildPhotoThumbnail(AssetEntity photo) {
    return FutureBuilder<Widget>(
      future: _buildThumbnailImage(photo),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          return GestureDetector(
            onTap: () => _showPhotoDialog(photo),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: snapshot.data!,
            ),
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
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

  String _formatDateTime(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
