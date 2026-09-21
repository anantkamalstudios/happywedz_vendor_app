import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_services/api_service_vendor.dart';
import '../api_services/storefront_completion_service.dart';
import '../utils/common_app_bar.dart';
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
  // UI
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CommonAppBar(title: "Upload Gallery"),
      body: loading
          ? const GridShimmer(itemCount: 9)
          : Column(
            children: [
              Expanded(
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
                      const Text(
                        "Saved Images",
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: savedImages.length,
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
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: img.startsWith("http")
                                    ? Image.network(
                                  img,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                )
                                    : Image.memory(
                                  base64Decode(
                                      img.split(',').last),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
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
                    ],

                    const SizedBox(height: 30),

                  ],
                ),
                        ),
                      ),
              ),
              Padding(
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
            ],

          ),

    );
  }
}
