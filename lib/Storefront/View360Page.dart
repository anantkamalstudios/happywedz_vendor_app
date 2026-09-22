import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api_services/api_service_vendor.dart';
import '../api_services/storefront_completion_service.dart';
import '../utils/common_app_bar.dart';
import '../utils/subcategory_selection.dart';
import '../utils/view360_assets.dart';
import '../widgets/app_shimmer.dart';

/// 360° View — the venue-only storefront section.
///
/// The website offers three tabs but keeps "Pano Images" commented out, so the
/// live feature is Videos + URL. This page matches that: already-uploaded pano
/// images are still listed (older records carry them) but there is no way to
/// add more, exactly as on the website.
class View360Page extends StatefulWidget {
  const View360Page({super.key});

  @override
  State<View360Page> createState() => _View360PageState();
}

class _View360PageState extends State<View360Page>
    with SingleTickerProviderStateMixin {
  final VendorServiceApi _vendorApi = VendorServiceApi();
  final TextEditingController _urlController = TextEditingController();

  late final TabController _tabs;

  int? vendorId;
  int? serviceId;
  int? vendorSubcategoryId;
  String? token;

  /// Videos already stored on the server, by URL.
  List<String> savedVideos = [];

  /// Pano images already stored. Read-only, as on the website.
  List<String> savedImages = [];

  /// Videos picked on this device and not uploaded yet.
  List<File> pendingVideos = [];

  Map<String, dynamic> currentAttributes = {};

  bool loading = true;
  bool saving = false;
  String? urlError;

  @override
  void initState() {
    super.initState();
    // The website opens on Videos.
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    vendorId = prefs.getInt('vendorId');
    token = prefs.getString('token');
    serviceId = prefs.getInt('serviceId');
    vendorSubcategoryId = prefs.getInt('vendor_subcategory_id');

    if (vendorId == null || token == null) {
      setState(() => loading = false);
      return;
    }

    await _fetch();
    if (mounted) setState(() => loading = false);
  }

  Future<void> _fetch() async {
    final data = await _vendorApi.getByVendorId(
      vendorId: vendorId!,
      token: token!,
    );
    if (data == null) return;

    serviceId = data['id'] ?? serviceId;
    vendorSubcategoryId ??= data['vendor_subcategory_id'];
    currentAttributes = Map<String, dynamic>.from(data['attributes'] ?? {});

    if (!mounted) return;
    setState(() {
      savedVideos = View360Assets.videos(data);
      savedImages = View360Assets.images(data);
      _urlController.text =
          currentAttributes['view360_url']?.toString() ?? '';
    });
  }

  // --------------------------------------------------------------------------
  // ACTIONS
  // --------------------------------------------------------------------------

  Future<void> _pickVideos() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => pendingVideos = [...pendingVideos, File(picked.path)]);
  }

  Future<void> _openUrl() async {
    final safe = View360Assets.safeUrl(_urlController.text);
    if (safe == null) return;
    await launchUrl(Uri.parse(safe), mode: LaunchMode.externalApplication);
  }

  Future<void> _save() async {
    if (serviceId == null || vendorId == null || token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete Basic Info first.")),
      );
      return;
    }

    final typed = _urlController.text.trim();
    // Same rule as the website: a link that is not plain http(s) is refused
    // rather than stored.
    if (typed.isNotEmpty && View360Assets.safeUrl(typed) == null) {
      setState(() => urlError =
          "Enter a full link starting with http:// or https://");
      _tabs.animateTo(1);
      return;
    }

    setState(() {
      saving = true;
      urlError = null;
    });

    // Re-read so this save cannot roll back another screen's edits.
    final latest = await _vendorApi.getByServiceId(
      serviceId: serviceId!,
      token: token!,
    );
    final attributes = Map<String, dynamic>.from(
      latest?['attributes'] ?? currentAttributes,
    );

    if (typed.isEmpty) {
      attributes.remove('view360_url');
    } else {
      attributes['view360_url'] = typed;
    }

    final subcategory =
        await SubcategorySelection.payloadForPrimary(vendorSubcategoryId);

    final bool success;
    if (pendingVideos.isEmpty) {
      // Nothing to upload, so the ordinary JSON update is enough.
      success = await _vendorApi.updateService(
        serviceId: serviceId!,
        token: token!,
        body: {
          "vendor_id": vendorId,
          "vendor_subcategory_id": subcategory,
          "attributes": attributes,
        },
      );
    } else {
      success = await _vendorApi.updateServiceWith360Videos(
        serviceId: serviceId!,
        token: token!,
        vendorId: vendorId!,
        vendorSubcategoryId: subcategory,
        attributes: attributes,
        keptVideoUrls: savedVideos,
        newVideoPaths: pendingVideos.map((f) => f.path).toList(),
      );
    }

    if (!mounted) return;

    if (success) {
      currentAttributes = attributes;
      pendingVideos = [];
      await StorefrontCompletionService.refreshCompletion(
        serviceId: serviceId!,
      );
      await _fetch();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("360° assets saved")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save 360° assets")),
      );
    }

    setState(() => saving = false);
  }

  // --------------------------------------------------------------------------
  // UI
  // --------------------------------------------------------------------------

  Widget _emptyNote(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        text,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
      ),
    );
  }

  Widget _fileRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.grey.shade700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              tooltip: "Remove",
              onPressed: onRemove,
              icon: const Icon(Icons.close),
            ),
        ],
      ),
    );
  }

  Widget _videosTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          "Upload 360° videos of your venue.",
          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _pickVideos,
            icon: const Icon(Icons.video_library_outlined, size: 18),
            label: const Text("Add video"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (pendingVideos.isNotEmpty) ...[
          const Text("Ready to upload",
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (int i = 0; i < pendingVideos.length; i++)
            _fileRow(
              icon: Icons.videocam_outlined,
              title: pendingVideos[i].path.split(Platform.pathSeparator).last,
              subtitle: "Not uploaded yet — press Save",
              onRemove: () => setState(
                () => pendingVideos = [...pendingVideos]..removeAt(i),
              ),
            ),
          const SizedBox(height: 8),
        ],

        const Text("Uploaded", style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (savedVideos.isEmpty)
          _emptyNote("No 360° videos yet.")
        else
          for (final url in savedVideos)
            _fileRow(
              icon: Icons.videocam,
              title: url.split('/').last,
              subtitle: "Uploaded",
              // Removing an uploaded video is not offered on the website
              // either, so it is left out rather than guessed at.
              onRemove: null,
            ),

        if (savedImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text("Pano images",
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            "Saved earlier. These can no longer be added from here.",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          for (final url in savedImages)
            _fileRow(
              icon: Icons.panorama_horizontal_outlined,
              title: url.split('/').last,
              subtitle: "Uploaded",
              onRemove: null,
            ),
        ],
      ],
    );
  }

  Widget _urlTab() {
    final safe = View360Assets.safeUrl(_urlController.text);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          "Paste a link to your 360° tour or video — a Matterport or Kuula "
          "tour, or a YouTube 360° video.",
          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _urlController,
          keyboardType: TextInputType.url,
          autocorrect: false,
          onChanged: (_) => setState(() => urlError = null),
          decoration: InputDecoration(
            hintText: "https://",
            errorText: urlError,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (safe != null) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _openUrl,
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text("Open link to check it"),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: const CommonAppBar(title: "360° View"),
      body: loading
          ? const FormShimmer(fields: 3)
          : Column(
              children: [
                Material(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabs,
                    labelColor: const Color(0xFF00509D),
                    indicatorColor: const Color(0xFF00509D),
                    unselectedLabelColor: Colors.grey.shade600,
                    tabs: const [
                      Tab(text: "Videos"),
                      Tab(text: "URL"),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [_videosTab(), _urlTab()],
                  ),
                ),
                // Edge to edge (targetSdk 36): without this the button sits under
                // the 3-button navigation bar.
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00509D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text("Save 360° Assets",
                                style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
