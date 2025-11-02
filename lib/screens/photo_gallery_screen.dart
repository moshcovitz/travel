import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/trip_model.dart';
import '../utils/app_logger.dart';
import 'photo_viewer_screen.dart';

class PhotoGalleryScreen extends StatefulWidget {
  final TripModel trip;
  final List<AssetEntity> photos;
  final int initialIndex;

  const PhotoGalleryScreen({
    super.key,
    required this.trip,
    required this.photos,
    this.initialIndex = 0,
  });

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.trip.name} Photos'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: widget.photos.isEmpty
          ? _buildEmptyState()
          : GridView.builder(
              padding: const EdgeInsets.all(4),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: widget.photos.length,
              itemBuilder: (context, index) {
                return _buildPhotoGridItem(widget.photos[index], index);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
            'No photos',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGridItem(AssetEntity photo, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PhotoViewerScreen(
              photos: widget.photos,
              initialIndex: index,
            ),
          ),
        );
      },
      child: FutureBuilder<Widget>(
        future: _buildThumbnail(photo),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: snapshot.data!,
            );
          }
          return Container(
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      ),
    );
  }

  Future<Widget> _buildThumbnail(AssetEntity photo) async {
    try {
      final thumbnail = await photo.thumbnailDataWithSize(
        const ThumbnailSize(400, 400),
      );
      if (thumbnail != null) {
        return Image.memory(
          thumbnail,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load thumbnail', e, stackTrace);
    }
    return Icon(
      Icons.broken_image,
      color: Colors.grey[400],
      size: 32,
    );
  }
}
