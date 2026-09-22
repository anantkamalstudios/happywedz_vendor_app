import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_services/api_service_vendor.dart';
import '../api_services/storefront_completion_service.dart';
import '../utils/common_app_bar.dart';
import '../widgets/app_network_image.dart';
import '../widgets/app_shimmer.dart';

class GalleryUploadPage extends StatefulWidget {
  const GalleryUploadPage({super.key});

  @override
  State<GalleryUploadPage> createState() => _GalleryUploadPageState();
}

class _GalleryUploadPageState extends State<GalleryUploadPage> {
  final ImagePicker picker = ImagePicker();
  final VendorServiceApi _vendorApi = VendorServiceApi();

  List<File> selectedImages = [];
  List<String> savedImages = [];

  int? vendorId;
  int? serviceId;
  String? token;

  bool loading = true;
  bool uploading = false;

  @override
  void initState() {
    super.initState();
    _loadCredentialsAndGallery();
  }

  // ----------------------------------------------------------
  // LOAD TOKEN + IDS + EXISTING GALLERY FROM SERVER
  // ----------------------------------------------------------
  Future<void> _loadCredentialsAndGallery() async {
    final prefs = await SharedPreferences.getInstance();

    vendorId = prefs.getInt('vendorId');
    serviceId = prefs.getInt('serviceId');
    token = prefs.getString('token');

    if (vendorId == null || serviceId == null || token == null) {
      setState(() => loading = false);
      return;
    }

    try {
      final latest = await _vendorApi.getByServiceId(
        serviceId: serviceId!,
        token: token!,
      );

      savedImages = List<String>.from(latest?["media"] ?? []);

      await prefs.setStringList("images_$vendorId", savedImages);
    } catch (e) {
      debugPrint("❌ Load gallery error: $e");
    }

    setState(() => loading = false);
  }

  // ----------------------------------------------------------
  // PICK IMAGES
  // ----------------------------------------------------------
  Future<void> pickImages() async {
    // AUDIT FIX: `pickMultiImage()` returns a non-nullable List<XFile>, so the
    // `?` type and the `!= null` half of the guard were dead code. The
    // emptiness check is what actually matters — the picker returns an EMPTY
    // list (not null) when the user cancels.
    final List<XFile> files = await picker.pickMultiImage(imageQuality: 80);

    if (files.isNotEmpty) {
      setState(() {
        selectedImages.addAll(files.map((e) => File(e.path)));
      });
    }
  }

  void removeSelectedImage(int index) {
    setState(() => selectedImages.removeAt(index));
  }

  // ----------------------------------------------------------
  // UPLOAD GALLERY (ROOT LEVEL media)
  // ----------------------------------------------------------
  Future<void> uploadGallery() async {
    if (vendorId == null || serviceId == null || token == null) return;

    if (selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select images")),
      );
      return;
    }

    setState(() => uploading = true);

    try {
      /// 🔥 FETCH LATEST SERVICE
      final latest = await _vendorApi.getByServiceId(
        serviceId: serviceId!,
        token: token!,
      );

      /// 🔥 EXISTING MEDIA (ROOT LEVEL)
      List<String> media =
      List<String>.from(latest?["media"] ?? []);

      /// 🔥 CONVERT NEW IMAGES
      for (var file in selectedImages) {
        final bytes = await file.readAsBytes();
        final base64Str = base64Encode(bytes);
        media.add("data:image/jpeg;base64,$base64Str");
      }

      /// 🔥 UPDATE SERVICE
      final success = await _vendorApi.updateService(
        serviceId: serviceId!,
        token: token!,
        body: {
          "vendor_id": vendorId,
          "media": media,
        },
      );

      if (success) {
        await StorefrontCompletionService.refreshCompletion(
          serviceId: serviceId!,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList("images_$vendorId", media);

        setState(() {
          savedImages = media;
          selectedImages.clear();
        });

        // AUDIT FIX: context used after an await — guard added.
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gallery saved successfully")),
        );
      } else {
        // AUDIT FIX: context used after an await — guard added.
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to save gallery")),
        );
      }
    } catch (e) {
      debugPrint("❌ Upload error: $e");
      // AUDIT FIX: context used after an await — guard added.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Upload failed")),
      );
    }

    setState(() => uploading = false);
  }

  // ----------------------------------------------------------
  // DELETE IMAGE FROM SERVER
  // ----------------------------------------------------------
  Future<void> deleteSavedImage(int index) async {
    if (vendorId == null || serviceId == null || token == null) return;

    try {
      final latest = await _vendorApi.getByServiceId(
        serviceId: serviceId!,
        token: token!,
      );

      List<String> media =
      List<String>.from(latest?["media"] ?? []);

      media.removeAt(index);

      final success = await _vendorApi.updateService(
        serviceId: serviceId!,
        token: token!,
        body: {
          "vendor_id": vendorId,
          "media": media,
        },
      );

      if (success) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList("images_$vendorId", media);

        setState(() => savedImages = media);
      }
    } catch (e) {
      debugPrint("❌ Delete error: $e");
    }
  }

  // ----------------------------------------------------------
  // SAVED IMAGE TILES
  // ----------------------------------------------------------

  /// How many saved tiles are rendered right now.
  ///
  /// The grid `shrinkWrap`s inside a scroll view, which means it builds EVERY
  /// child up front — there is no laziness to fall back on. Vendors migrated
  /// from the website have galleries in the hundreds (one has 378 photos), so
  /// opening this screen kicked off that many image fetches at once and the
  /// first screenful had to queue behind all of them. Rendering a page at a
  /// time keeps the visible photos first in line.
  static const int _savedPageSize = 20;
  int _visibleSavedCount = _savedPageSize;

  int get _savedShown => math.min(_visibleSavedCount, savedImages.length);
  bool get _hasMoreSaved => _savedShown < savedImages.length;

  void _showMoreSaved() {
    if (!_hasMoreSaved) return;
    setState(() => _visibleSavedCount = _savedShown + _savedPageSize);
  }

  /// Decoded base64 previews, keyed by the raw string.
  ///
  /// The grid is `shrinkWrap`ped inside a scroll view, so every tile is built
  /// on every `setState` — decoding inline meant re-decoding each freshly
  /// uploaded photo on each rebuild, which is what made the list crawl right
  /// after a save.
  final Map<String, Uint8List?> _decodedPreviews = {};

  Uint8List? _decodeBase64(String value) {
    return _decodedPreviews.putIfAbsent(value, () {
      try {
        return base64Decode(value.split(',').last);
      } catch (e) {
        // A malformed string used to throw from inside build and take the
        // whole screen down with it.
        debugPrint("❌ Could not decode preview: $e");
        return null;
      }
    });
  }

  /// A saved tile is an S3 URL, or — for the moments between saving and the
  /// next reload — the base64 we just uploaded.
  Widget _savedImageTile(String img) {
    const radius = BorderRadius.all(Radius.circular(12));

    if (!img.startsWith("data:")) {
      // Shimmers per tile while the fetch is in flight, caches the result, and
      // falls back to a placeholder on an expired or broken link.
      return AppNetworkImage(
        url: img,
        fit: BoxFit.cover,
        borderRadius: radius,
        placeholderLabel: "Image unavailable",
      );
    }

    final bytes = _decodeBase64(img);
    if (bytes == null) {
      // Reuse the same placeholder the network variant shows.
      return const AppNetworkImage(
        url: null,
        borderRadius: radius,
        placeholderLabel: "Image unavailable",
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: Image.memory(bytes, fit: BoxFit.cover),
    );
  }

  // ----------------------------------------------------------
  // UI
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CommonAppBar(title: "Upload Gallery"),
      body: loading
          // Two columns, matching the real grid below — the skeleton was on
          // three, so the page reflowed the moment the gallery landed.
          ? const GridShimmer(itemCount: 6, crossAxisCount: 2)
          : Column(
            children: [
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  // Appends the next page as the end comes into view. Cheaper
                  // than a ScrollController here: nothing to create, dispose
                  // or keep in sync with the widget tree.
                  onNotification: (notification) {
                    final m = notification.metrics;
                    if (m.axis == Axis.vertical &&
                        m.pixels >= m.maxScrollExtent - 400) {
                      _showMoreSaved();
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        "Upload Images",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Center(
                      child: ElevatedButton(
                        onPressed: pickImages,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00509D),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Browse Images"),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// SELECTED IMAGES
                    if (selectedImages.isNotEmpty)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: selectedImages.length,
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                        itemBuilder: (_, i) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                selectedImages[i],
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: GestureDetector(
                                onTap: () => removeSelectedImage(i),
                                child: const CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.white,
                                  child: Icon(Icons.close,
                                      size: 14, color: Colors.black),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    /// SAVED IMAGES
                    if (savedImages.isNotEmpty) ...[
                      const SizedBox(height: 30),
                      Text(
                        _hasMoreSaved
                            ? "Saved Images ($_savedShown of ${savedImages.length})"
                            : "Saved Images",
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _savedShown,
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                        itemBuilder: (_, i) {
                          final img = savedImages[i];
                          return Stack(
                            children: [
                              // Fills the square tile, so a portrait photo and
                              // its shimmer placeholder occupy the same box and
                              // the grid does not reflow as images arrive.
                              Positioned.fill(
                                child: _savedImageTile(img),
                              ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: GestureDetector(
                                  onTap: () => deleteSavedImage(i),
                                  child: const CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.white,
                                    child: Icon(Icons.close,
                                        size: 14, color: Colors.black),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      /// Skeleton row for the page still to come, so scrolling
                      /// to the end reads as "more loading" rather than "end".
                      if (_hasMoreSaved) ...[
                        const SizedBox(height: 10),
                        const AppShimmer(
                          child: Row(
                            children: [
                              Expanded(
                                child: ShimmerBox(height: 150, radius: 12),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: ShimmerBox(height: 150, radius: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],

                    const SizedBox(height: 30),

                  ],
                ),
                        ),
                      ),
                ),
              ),
              // Edge to edge (targetSdk 36): without this the button sits under
              // the 3-button navigation bar.
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: uploading ? null : uploadGallery,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00509D),
                        foregroundColor: Colors.white,
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: uploading
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Text(
                        "Save Gallery",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ),
            ],

          ),

    );
  }
}
