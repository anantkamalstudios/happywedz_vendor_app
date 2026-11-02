import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../api_services/api_service_vendor.dart';
import '../api_services/storefront_completion_service.dart';
import '../utils/common_app_bar.dart';
import 'package:happy_weds_vendors/utils/api_config.dart';

class VideoUploadPage extends StatefulWidget {
  @override
  State<VideoUploadPage> createState() => _VideoUploadPageState();
}

class _VideoUploadPageState extends State<VideoUploadPage> {
  List<String> videoURLs = [];
  Map<String, String?> thumbnails = {}; // URL -> thumbnail path
  int? vendorId;
  int? serviceId;
  String? token;

  final TextEditingController urlController = TextEditingController();
  bool loadingVendorData = true;
  bool saving = false;

  VideoPlayerController? activeController;
  String? activeVideoUrl;

  Map<String, dynamic> currentAttributes = {};

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    vendorId = prefs.getInt("vendorId");
    serviceId = prefs.getInt("serviceId");
    token = prefs.getString("token");

    // A storefront created on the website may not have its id cached yet.
    if (serviceId == null && vendorId != null && token != null) {
      try {
        serviceId = await VendorServiceApi().getServiceIdByVendorId(
          vendorId: vendorId!,
          token: token!,
        );
        if (serviceId != null) await prefs.setInt("serviceId", serviceId!);
      } catch (e) {
        debugPrint("Error looking up service id: $e");
      }
    }

    if (serviceId != null && token != null) {
      await fetchCurrentAttributes();
    }

    // The server is the source of truth. The local list is only a fallback for
    // when the service could not be read at all — it used to run
    // unconditionally and overwrote whatever the server had just returned,
    // which is why videos added on the website showed up as an empty gallery.
    if (videoURLs.isEmpty && vendorId != null) {
      videoURLs = prefs.getStringList("videos_$vendorId") ?? [];
    }

    for (var url in videoURLs) {
      thumbnails[url] = await getThumbnail(url);
    }

    if (mounted) setState(() => loadingVendorData = false);
  }

  /// Videos arrive as plain strings or as `{url}` / `{path}` objects, under
  /// `video`, the legacy misspelling `vedio`, or `media.videos`. The website
  /// reads all three; so does this, or a gallery saved by an older client
  /// looks empty here.
  List<String> _normalizeVideos(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .map((v) {
          if (v is String) return v;
          if (v is Map) return (v['url'] ?? v['path'] ?? '').toString();
          return '';
        })
        // Pasted links often arrive wrapped in backticks.
        .map((v) => v.replaceAll(RegExp(r'^\s*`|`\s*$'), '').trim())
        .where((v) => v.isNotEmpty && v != 'null' && v != 'undefined')
        // Relative upload paths are stored without a host.
        .map((v) => v.startsWith('/uploads/') ? '${ApiConfig.baseUrl}$v' : v)
        .toList();
  }

  Future<void> fetchCurrentAttributes() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/vendor-services/$serviceId'),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        currentAttributes = Map<String, dynamic>.from(parsed["attributes"] ?? {});

        final fromAttributes = <String>[
          ..._normalizeVideos(currentAttributes["video"]),
          ..._normalizeVideos(currentAttributes["vedio"]),
        ];

        final media = parsed["media"];
        final fromMedia = media is Map ? _normalizeVideos(media["videos"]) : <String>[];

        videoURLs = {...fromAttributes, ...fromMedia}.toList();
      }
    } catch (e) {
      debugPrint("Error fetching video attributes: $e");
    }
  }

  Future<String?> getThumbnail(String url) async {
    if (url.contains("youtube") || url.contains("youtu.be")) {
      final id = extractYouTubeId(url);
      if (id != null) return 'https://img.youtube.com/vi/$id/0.jpg';
    } else if (_isDirectFile(url)) {
      try {
        final thumb = await VideoThumbnail.thumbnailFile(
          video: url,
          imageFormat: ImageFormat.JPEG,
          maxWidth: 200,
          quality: 75,
        );
        return thumb;
      } catch (e) {
        print("Thumbnail error: $e");
      }
    }
    return null;
  }

  /// A file the in-app player can stream. YouTube/Vimeo page links are not.
  bool _isDirectFile(String url) {
    final path = (Uri.tryParse(url)?.path ?? url).toLowerCase();
    return RegExp(r'\.(mp4|mov|m4v|webm|3gp|mkv)$').hasMatch(path);
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void addVideoURL() async {
    final url = urlController.text.trim();
    if (url.isEmpty) return;

    final parsed = Uri.tryParse(url);
    if (parsed == null ||
        !(parsed.scheme == 'http' || parsed.scheme == 'https') ||
        parsed.host.isEmpty) {
      _toast("Please enter a valid video link (https://...)");
      return;
    }
    // Same rule as the website's VideoGallery: no duplicates.
    if (videoURLs.any((v) => v.toLowerCase() == url.toLowerCase())) {
      _toast("This video is already added");
      return;
    }
    urlController.clear();

    setState(() {
      videoURLs.add(url);
      thumbnails[url] = null;
    });

    final thumb = await getThumbnail(url);
    if (!mounted) return;
    setState(() {
      thumbnails[url] = thumb;
    });
  }

  void removeVideo(int index) async {
    final url = videoURLs[index];

    if (activeVideoUrl == url) {
      activeController?.pause();
      activeController?.dispose();
      activeController = null;
      activeVideoUrl = null;
    }

    setState(() {
      videoURLs.removeAt(index);
      thumbnails.remove(url);
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList("videos_$vendorId", videoURLs);
  }

  Future<void> saveVideoGallery() async {
    if (vendorId == null || serviceId == null || token == null) return;

    setState(() => saving = true);

    try {
      // Re-read so this save cannot roll back edits made on the website or
      // another screen since this one opened.
      final latest = await VendorServiceApi().getByServiceId(
        serviceId: serviceId!,
        token: token!,
      );
      if (latest?["attributes"] is Map) {
        currentAttributes = Map<String, dynamic>.from(latest!["attributes"]);
      }

      currentAttributes["video"] = videoURLs;
      // The load merges the legacy `vedio` key in, so leaving it behind would
      // bring a deleted video back on the next open.
      currentAttributes.remove("vedio");

      final payload = {
        "vendor_id": vendorId,
        "attributes": currentAttributes,
      };

      final response = await http.put(
        Uri.parse("${ApiConfig.baseUrl}/vendor-services/$serviceId"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        await StorefrontCompletionService.refreshCompletion(
          serviceId: serviceId!,
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList("videos_$vendorId", videoURLs);
        _toast("Videos Saved Successfully");
      } else {
        debugPrint("Save videos → ${response.statusCode}: ${response.body}");
        _toast("Failed to Save");
      }
    } catch (e) {
      debugPrint("Error saving videos: $e");
      _toast("Error saving videos");
    }

    if (mounted) setState(() => saving = false);
  }

  void playVideo(String url) async {
    // YouTube/Vimeo links are web pages, not video files — the in-app player
    // threw on them, so tapping did nothing. Open them in their own app.
    if (!_isDirectFile(url)) {
      final uri = Uri.tryParse(url);
      if (uri == null ||
          !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        _toast("Could not open this video");
      }
      return;
    }

    if (activeVideoUrl == url) {
      if (activeController!.value.isPlaying) {
        activeController!.pause();
      } else {
        activeController!.play();
      }
      setState(() {});
      return;
    }

    activeController?.pause();
    activeController?.dispose();

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    activeController = controller;
    activeVideoUrl = url;
    try {
      await controller.initialize();
      controller.play();
    } catch (e) {
      debugPrint("Video play error: $e");
      controller.dispose();
      if (activeController == controller) {
        activeController = null;
        activeVideoUrl = null;
      }
      _toast("Could not play this video");
    }
    if (mounted) setState(() {});
  }

  String? extractYouTubeId(String url) {
    // Same patterns as the website's VideoGallery, Shorts included.
    final RegExp exp = RegExp(
        r"(?:youtu\.be/|youtube\.com/(?:embed/|v/|shorts/|watch\?v=|watch\?.+&v=))([\w-]{11})");
    final match = exp.firstMatch(url);
    return match != null ? match.group(1) : null;
  }

  Widget buildVideoGrid() {
    return videoURLs.isEmpty
        ? Text("No Videos Added Yet")
        : GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: videoURLs.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1),
      itemBuilder: (context, index) {
        final url = videoURLs[index];
        bool isActive = activeVideoUrl == url;
        final thumb = thumbnails[url];
        return GestureDetector(
          onTap: () => playVideo(url),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: Colors.black12,
                  child: isActive &&
                      activeController != null &&
                      activeController!.value.isInitialized
                      ? AspectRatio(
                    aspectRatio: activeController!.value.aspectRatio,
                    child: VideoPlayer(activeController!),
                  )
                      :
                  thumb != null
                      ? (thumb.startsWith("http")
                      ? Image.network(
                    thumb,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.play_circle,
                      size: 40,
                      color: Colors.white,
                    ),
                  )
                      : Image.file(
                    File(thumb),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.play_circle,
                      size: 40,
                      color: Colors.white,
                    ),
                  ))
                      : const Center(
                    child: Icon(Icons.play_arrow, size: 40, color: Colors.white),
                  ),

                ),
              ),
              Positioned(
                right: 4,
                top: 4,
                child: GestureDetector(
                  onTap: () => removeVideo(index),
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    // Was white on the white circle, so the delete button
                    // could not be seen.
                    child: Icon(Icons.close, size: 16, color: Colors.black),
                  ),
                ),
              ),
              if (isActive)
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: IconButton(
                    icon: Icon(
                      activeController!.value.isPlaying
                          ? Icons.pause_circle
                          : Icons.play_circle,
                      size: 30,
                      color: Colors.white,
                    ),
                    onPressed: () => playVideo(url),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    urlController.dispose();
    activeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(title:"Video Gallery"),
      body: loadingVendorData
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        // Edge to edge (targetSdk 36): keeps Save Gallery clear of the
        // 3-button navigation bar.
        padding: EdgeInsets.fromLTRB(16, 16, 16,
            16 + MediaQuery.of(context).padding.bottom),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: urlController,
                    decoration: InputDecoration(
                      hintText: "Enter Video URL...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                // ElevatedButton(
                //   onPressed: addVideoURL,
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Color(0xFF00509D),
                //   ),
                //   child: Text("Add"),
                // )
                ElevatedButton(
                  onPressed: addVideoURL,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00509D),
                    foregroundColor: Colors.white, // 👈 text + icon color
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "+   Add",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              ],
            ),
            SizedBox(height: 20),
            buildVideoGrid(),
            SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving ? null : saveVideoGallery,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00509D), // Steel Azure
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: saving
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
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
