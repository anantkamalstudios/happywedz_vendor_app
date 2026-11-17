import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api_services/api_service_vendor.dart';
import '../api_services/storefront_completion_service.dart';
import '../widgets/app_network_image.dart';
import '../utils/common_app_bar.dart';
import 'package:happy_weds_vendors/utils/api_config.dart';
import '../utils/subcategory_selection.dart';

class PreferredVendorsPage extends StatefulWidget {
  const PreferredVendorsPage({super.key});

  @override
  State<PreferredVendorsPage> createState() => _PreferredVendorsPageState();
}

class _PreferredVendorsPageState extends State<PreferredVendorsPage> {
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> suggestions = [];
  List<Map<String, dynamic>> selectedVendors = [];
  final VendorServiceApi _vendorApi = VendorServiceApi();

  bool loading = false;
  bool loadingVendorData = true;
  bool saving = false;

  int? vendorId;
  int? serviceId;
  int? vendorSubcategoryId;
  String? token;

  /// Pending search, so typing fires one request per pause like the website.
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadCredentialsAndData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ----------------------------------------------------------
  // SHAPE — identical to the website's PreferredVendors.jsx
  // ----------------------------------------------------------

  /// `attributes.preferred_vendors` is stored as
  /// `[{id, name, rating, image, city}]`. The app used to save bare ids,
  /// which wiped the names and photos the website had stored, so this is the
  /// one shape both clients now read and write.
  static Map<String, dynamic> _entry({
    required dynamic id,
    String? name,
    dynamic rating,
    String? image,
    String? city,
  }) {
    return {
      "id": id,
      "name": (name == null || name.isEmpty) ? "Vendor $id" : name,
      "rating": rating,
      "image": image,
      "city": city ?? "",
    };
  }

  /// A search result (a vendor-service record) → stored entry. Same fallback
  /// chain as the website's `toggleSelect`.
  static Map<String, dynamic> _fromServiceRecord(Map item) {
    final attr = item["attributes"] is Map ? item["attributes"] as Map : {};
    final vendor = item["vendor"] is Map ? item["vendor"] as Map : {};
    final id = item["id"] ?? item["vendor_services_id"];
    return _entry(
      id: id,
      name: (attr["vendor_name"] ?? attr["name"] ?? vendor["businessName"])
          ?.toString(),
      rating: attr["rating"],
      image: (attr["image"] ?? attr["profile_image"] ?? vendor["profileImage"])
          ?.toString(),
      city: (attr["city"] ?? vendor["city"])?.toString(),
    );
  }

  /// Whatever is stored → entries. Bare ids (left by older app saves) come
  /// back with only the id; [_hydrateBareIds] fills in the rest.
  static List<Map<String, dynamic>> _normalize(dynamic raw) {
    if (raw is! List) return [];
    final out = <Map<String, dynamic>>[];
    for (final v in raw) {
      if (v is Map) {
        if (v["id"] == null) continue;
        out.add(_entry(
          id: v["id"],
          name: v["name"]?.toString(),
          rating: v["rating"],
          image: v["image"]?.toString(),
          // Older app saves used "location" for the city.
          city: (v["city"] ?? v["location"])?.toString(),
        ));
      } else if (v != null) {
        out.add({"id": v, "name": "", "rating": null, "image": null, "city": ""});
      }
    }
    return out;
  }

  /// Load saved credentials and vendors
  Future<void> _loadCredentialsAndData() async {
    final prefs = await SharedPreferences.getInstance();
    vendorId = prefs.getInt('vendorId');
    serviceId = prefs.getInt('serviceId');
    vendorSubcategoryId = prefs.getInt('vendor_subcategory_id');
    token = prefs.getString('token');

    if (vendorId != null && token != null) {
      await fetchExistingPreferredVendors();
    }

    if (mounted) setState(() => loadingVendorData = false);
  }

  /// Fetch existing preferred vendors from API. The server is the only
  /// source: the old local cache was merged back in and resurrected vendors
  /// removed on the website.
  Future<void> fetchExistingPreferredVendors() async {
    try {
      final data = await _vendorApi.getByVendorId(
        vendorId: vendorId!,
        token: token!,
      );

      if (data == null) return;

      serviceId = data["id"];
      vendorSubcategoryId ??= data["vendor_subcategory_id"];

      final list = _normalize(data["attributes"]?["preferred_vendors"]);
      await _hydrateBareIds(list);

      if (mounted) setState(() => selectedVendors = list);
    } catch (e) {
      debugPrint("❌ Fetch preferred vendors error: $e");
    }
  }

  /// Entries saved as a bare id lost their name/photo/city. Look each one up
  /// so the next save writes the full entry back and repairs the record.
  Future<void> _hydrateBareIds(List<Map<String, dynamic>> list) async {
    for (var i = 0; i < list.length; i++) {
      if ((list[i]["name"] ?? "").toString().isNotEmpty) continue;
      final id = int.tryParse("${list[i]["id"]}");
      if (id == null) {
        list[i] = _entry(id: list[i]["id"]);
        continue;
      }
      try {
        final record = await _vendorApi.getByServiceId(
          serviceId: id,
          token: token!,
        );
        list[i] = record != null
            ? _fromServiceRecord(record)
            : _entry(id: list[i]["id"]);
      } catch (_) {
        list[i] = _entry(id: list[i]["id"]);
      }
    }
  }

  /// Search box change — 400 ms debounce, as on the website.
  void onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => searchVendors(query),
    );
  }

  /// Search vendors API (min 2 characters, 10 results, like the website)
  Future<void> searchVendors(String query) async {
    final q = query.trim();
    if (q.length < 2) {
      if (mounted) setState(() => suggestions = []);
      return;
    }

    setState(() => loading = true);

    try {
      final uri = Uri.parse("${ApiConfig.baseUrl}/vendor-services")
          .replace(queryParameters: {"search": q, "limit": "10"});
      final response = await http.get(
        uri,
        headers: token != null ? {"Authorization": "Bearer $token"} : {},
      );

      final List items = response.statusCode == 200
          ? (jsonDecode(response.body)['data'] as List? ?? [])
          : [];
      // Ignore a stale response for text the vendor has since changed.
      if (!mounted || searchController.text.trim() != q) return;
      setState(() {
        suggestions = items
            .whereType<Map>()
            .map(_fromServiceRecord)
            // A vendor cannot list their own storefront.
            .where((v) => "${v["id"]}" != "$serviceId")
            .toList();
      });
    } catch (e) {
      debugPrint("Error searching vendors: $e");
      if (mounted) setState(() => suggestions = []);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  bool _isSelected(dynamic id) =>
      selectedVendors.any((v) => "${v['id']}" == "$id");

  /// Add vendor to selected list
  void addVendor(Map<String, dynamic> vendor) {
    if (_isSelected(vendor['id'])) return;
    setState(() {
      selectedVendors.add(vendor);
      suggestions = [];
      searchController.clear();
    });
  }

  /// Remove vendor from selected list
  void removeVendor(Map<String, dynamic> vendor) {
    setState(() {
      selectedVendors.removeWhere((v) => "${v['id']}" == "${vendor['id']}");
    });
  }

  /// Save selected vendors to API
  Future<void> savePreferredVendors() async {
    if (vendorId == null || serviceId == null || token == null) {
      _toast("Cannot save: Missing vendor or service info.");
      return;
    }

    setState(() => saving = true);

    try {
      // Fetch latest attributes first so other tabs' edits are kept.
      final latest = await _vendorApi.getByServiceId(
        serviceId: serviceId!,
        token: token!,
      );

      final attributes =
          Map<String, dynamic>.from(latest?["attributes"] ?? {});

      // Full entries, exactly as the website stores them.
      attributes["preferred_vendors"] = selectedVendors
          .map((v) => {
                "id": v["id"],
                "name": v["name"],
                "rating": v["rating"],
                "image": v["image"],
                "city": v["city"] ?? "",
              })
          .toList();

      final success = await _vendorApi.updateService(
        serviceId: serviceId!,
        token: token!,
        body: {
          "vendor_id": vendorId,
          "vendor_subcategory_id":
              await SubcategorySelection.payloadForPrimary(vendorSubcategoryId),
          "attributes": attributes,
        },
      );

      if (success) {
        await StorefrontCompletionService.refreshCompletion(
          serviceId: serviceId!,
        );
      }
      _toast(success
          ? "Preferred vendors saved successfully."
          : "Failed to save preferred vendors");
    } catch (e) {
      debugPrint("❌ Save preferred vendors error: $e");
      _toast("Failed to save preferred vendors");
    }

    if (mounted) setState(() => saving = false);
  }

  Widget _avatar(Map<String, dynamic> vendor, double size) {
    return SizedBox(
      width: size,
      height: size,
      child: AppNetworkImage(
        url: vendor['image']?.toString(),
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(8),
        placeholderIcon: Icons.storefront_outlined,
      ),
    );
  }

  Widget _ratingRow(Map<String, dynamic> vendor) {
    final rating = vendor['rating'];
    if (rating == null || "$rating".isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 16),
        const SizedBox(width: 4),
        Text("$rating"),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF2F2F2),
      appBar: CommonAppBar(title:"Preferred Vendors"),
      body: loadingVendorData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        // Edge to edge (targetSdk 36): the extra bottom keeps the last item
        // clear of the 3-button navigation bar.
        padding: EdgeInsets.fromLTRB(16, 16, 16,
            16 + MediaQuery.of(context).padding.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Preferred Vendors",
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    decoration: InputDecoration(
                      hintText: "Search vendors by name (min 2 letters)...",
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Center(
                    child: ElevatedButton(
                      onPressed: saving ? null : savePreferredVendors,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF00509D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                      ),
                      child: saving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Save Preferred Vendors",
                          style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (loading) const LinearProgressIndicator(),
                  ...suggestions.map((vendor) {
                    final selected = _isSelected(vendor['id']);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: _avatar(vendor, 44),
                      title: Text(vendor['name'] ?? ''),
                      subtitle: Text(vendor['city'] ?? ''),
                      trailing: selected
                          ? const Icon(Icons.check_circle,
                              color: Color(0xFF00509D))
                          : _ratingRow(vendor),
                      onTap: selected ? null : () => addVendor(vendor),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (selectedVendors.isNotEmpty)
              const Text("Selected Vendors",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            ...selectedVendors.map((vendor) => Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  _avatar(vendor, 52),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(vendor['name'] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16)),
                        if ((vendor['city'] ?? '').toString().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(vendor['city']),
                        ],
                        const SizedBox(height: 4),
                        _ratingRow(vendor),
                      ],
                    ),
                  ),
                  IconButton(
                      onPressed: () => removeVendor(vendor),
                      icon: const Icon(Icons.close, color: Colors.red))
                ],
              ),
            ))
          ],
        ),
      ),
    );
  }
}
