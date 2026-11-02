import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_services/api_service_vendor.dart';
import '../api_services/storefront_completion_service.dart';
import '../utils/api_config.dart';
import '../utils/common_app_bar.dart';
import '../utils/subcategory_selection.dart';
import '../utils/view360_assets.dart';
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
  int? vendorSubcategoryId;
  String? token;

  bool loading = true;
  bool uploading = false;

  @override
  void initState() {
    super.initState();
    _loadCredentialsAndGallery();
  }

  // ----------------------------------------------------------
  // READING THE GALLERY (same rules as the website's Storefront.jsx)
  // ----------------------------------------------------------

  /// The gallery URLs on a service record.
  ///
  /// `media` arrives in more than one shape depending on how the record was
  /// last saved: a list of strings, a list of `{url}` / `{path}` objects, or
  /// the legacy `{gallery: [...], videos: [...]}` object. The old
  /// `List<String>.from(media)` threw on everything but the first, which is
  /// why photos added on the website never showed up here.
  static List<String> _galleryFrom(Map<String, dynamic>? service) {
    final media = service?["media"];
    final List items;
    if (media is List) {
      items = media;
    } else if (media is Map && media["gallery"] is List) {
      items = media["gallery"];
    } else {
      return [];
    }

    final seen = <String>{};
    for (final item in items) {
      final raw = item is Map
          ? (item["url"] ?? item["path"] ?? item["location"])
          : item;
      final url = _absoluteUrl(raw);
      if (url != null) seen.add(url);
    }
    return seen.toList();
  }

  /// Cleans one entry and prefixes relative `/uploads/...` paths with the API
  /// host, as the website does with IMAGE_BASE_URL. Inline `data:`/`blob:`
  /// values are dropped — the website never keeps them either.
  static String? _absoluteUrl(dynamic value) {
    if (value is! String) return null;
    final cleaned = value.replaceAll(RegExp(r'^\s*`|`\s*$'), '').trim();
    if (cleaned.isEmpty) return null;
    final lower = cleaned.toLowerCase();
    if (lower == 'null' || lower == 'undefined') return null;
    if (lower.startsWith('data:') || lower.startsWith('blob:')) return null;
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return cleaned;
    }
    final path = cleaned.startsWith('/') ? cleaned : '/$cleaned';
    return '${ApiConfig.baseUrl.replaceAll(RegExp(r'/+$'), '')}$path';
  }

  // ----------------------------------------------------------
  // LOAD TOKEN + IDS + EXISTING GALLERY FROM SERVER
  // ----------------------------------------------------------
  Future<void> _loadCredentialsAndGallery() async {
    final prefs = await SharedPreferences.getInstance();

    vendorId = prefs.getInt('vendorId');
    serviceId = prefs.getInt('serviceId');
    vendorSubcategoryId = prefs.getInt('vendor_subcategory_id');
    token = prefs.getString('token');

    if (vendorId == null || token == null) {
      if (mounted) setState(() => loading = false);
      return;
    }

    try {
      // A vendor whose storefront was created on the website may not have the
      // service id cached yet — look it up the same way the website does.
      if (serviceId == null) {
        serviceId = await _vendorApi.getServiceIdByVendorId(
          vendorId: vendorId!,
          token: token!,
        );
        if (serviceId != null) await prefs.setInt('serviceId', serviceId!);
      }

      if (serviceId != null) await _refreshFromServer();
    } catch (e) {
      debugPrint("❌ Load gallery error: $e");
    }

    if (mounted) setState(() => loading = false);
  }

  /// Fetches the record and shows exactly what the server holds.
  Future<Map<String, dynamic>?> _refreshFromServer() async {
    final latest = await _vendorApi.getByServiceId(
      serviceId: serviceId!,
      token: token!,
    );
    final images = _galleryFrom(latest);
    vendorSubcategoryId ??= _toInt(latest?["vendor_subcategory_id"]);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList("images_$vendorId", images);

    if (mounted) setState(() => savedImages = images);
    return latest;
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  /// Sends the gallery the way the website does: kept URLs in `media`, new
  /// files under `gallery`. `latest` must be a fresh read so this save keeps
  /// whatever another screen (or the website) changed meanwhile.
  Future<bool> _saveGallery({
    required Map<String, dynamic>? latest,
    required List<String> keep,
    List<String> newPaths = const [],
  }) async {
    final attributes = latest?["attributes"] is Map
        ? Map<String, dynamic>.from(latest!["attributes"])
        : <String, dynamic>{};
    attributes.remove("media");

    return _vendorApi.updateServiceGallery(
      serviceId: serviceId!,
      token: token!,
      vendorId: vendorId!,
      vendorSubcategoryId:
          await SubcategorySelection.payloadForPrimary(vendorSubcategoryId),
      attributes: attributes,
      keptImageUrls: keep,
      newImagePaths: newPaths,
      keptView360ImageUrls: View360Assets.images(latest),
      keptView360VideoUrls: View360Assets.videos(latest),
    );
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
  // UPLOAD GALLERY (multipart, same contract as the website)
  // ----------------------------------------------------------
  Future<void> uploadGallery() async {
    if (vendorId == null || serviceId == null || token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please complete your storefront basic info first"),
        ),
      );
      return;
    }

    if (selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select images")),
      );
      return;
    }

    setState(() => uploading = true);

    try {
      final latest = await _vendorApi.getByServiceId(
        serviceId: serviceId!,
        token: token!,
      );

      final success = await _saveGallery(
        latest: latest,
        keep: _galleryFrom(latest),
        newPaths: selectedImages.map((f) => f.path).toList(),
      );

      if (success) {
        await StorefrontCompletionService.refreshCompletion(
          serviceId: serviceId!,
        );

        // Re-read so the tiles show the stored URLs the server just created.
        selectedImages.clear();
        await _refreshFromServer();

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

    if (mounted) setState(() => uploading = false);
  }

  // ----------------------------------------------------------
  // DELETE IMAGE FROM SERVER
  // ----------------------------------------------------------
  Future<void> deleteSavedImage(int index) async {
    if (vendorId == null || serviceId == null || token == null) return;

    // Removed by URL, not position: the server's list may have changed since
    // this screen loaded, and an index would then delete the wrong photo.
    final target = savedImages[index];

    try {
      final latest = await _vendorApi.getByServiceId(
        serviceId: serviceId!,
        token: token!,
      );

      final keep = _galleryFrom(latest)..remove(target);

      final success = await _saveGallery(latest: latest, keep: keep);

      if (success) {
        await StorefrontCompletionService.refreshCompletion(
          serviceId: serviceId!,
        );
        await _refreshFromServer();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete photo")),
        );
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

  /// A saved tile is always a stored URL — `_galleryFrom` has already made
  /// relative `/uploads/` paths absolute.
  Widget _savedImageTile(String img) {
    // Shimmers per tile while the fetch is in flight, caches the result, and
    // falls back to a placeholder on an expired or broken link.
    return AppNetworkImage(
      url: img,
      fit: BoxFit.cover,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      placeholderLabel: "Image unavailable",
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
