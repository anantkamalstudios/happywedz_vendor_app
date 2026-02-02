import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'gallery_screen.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:gal/gal.dart';
Future<bool> requestStoragePermission() async {
  if (Platform.isAndroid) {
    if (await Permission.storage.isGranted) return true;

    final status = await Permission.storage.request();
    return status.isGranted;
  }
  return true;
}

Future<void> downloadAndSaveImage(
    BuildContext context,
    String imageUrl,
    ) async {
  try {
    final hasPermission = await requestStoragePermission();

    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Storage permission denied")),
      );
      return;
    }

    final response = await http.get(Uri.parse(imageUrl));

    if (response.statusCode != 200) {
      throw Exception("Download failed");
    }

    await Gal.putImageBytes(
      response.bodyBytes,
      name: "image_${DateTime.now().millisecondsSinceEpoch}.jpg",
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Image saved to gallery")),
    );
  } catch (e) {
    debugPrint("❌ DOWNLOAD ERROR: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Failed to save image")),
    );
  }
}

class FullScreenGalleryView extends StatefulWidget {
  final List<MediaItem> mediaList;
  final int initialIndex;

  const FullScreenGalleryView({
    super.key,
    required this.mediaList,
    required this.initialIndex,
  });

  @override
  State<FullScreenGalleryView> createState() => _FullScreenGalleryViewState();
}

class _FullScreenGalleryViewState extends State<FullScreenGalleryView> {
  late PageController _pageController;
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.mediaList[currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          /// IMAGE SWIPE VIEW
          PageView.builder(
            controller: _pageController,
            itemCount: widget.mediaList.length,
            onPageChanged: (index) {
              setState(() => currentIndex = index);
            },
            itemBuilder: (context, index) {
              final media = widget.mediaList[index];
              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: CachedNetworkImage(
                  imageUrl:
                  'https://happywedz-s3-bucket.s3.ap-south-1.amazonaws.com/${media.s3Key}',
                  fit: BoxFit.contain,
                ),
              );
            },
          ),

          /// TOP BAR (CLOSE + VISIBILITY)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  /// CLOSE
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 26,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  /// VISIBILITY BADGE
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: item.visibility == 'private'
                          ? Colors.red[700]
                          : Colors.green[700],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.visibility == 'private'
                              ? Icons.lock
                              : Icons.public,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.visibility.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// BOTTOM INFO BAR
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// COLLECTION + DOWNLOAD
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.collection,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            downloadAndSaveImage(
                              context,
                              "https://happywedz-s3-bucket.s3.ap-south-1.amazonaws.com/${item.s3Key}",
                            );
                          },
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('Download'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    /// SIZE + COUNTER
                    Row(
                      children: [
                        Text(
                          '${item.fileSizeMb} MB',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${currentIndex + 1} / ${widget.mediaList.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}