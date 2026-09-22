import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_services/api_service_vendor.dart';
import '../api_services/storefront_completion_service.dart';
import '../utils/common_app_bar.dart';
import '../widgets/app_network_image.dart';
import '../widgets/app_shimmer.dart';
import '../utils/pricing_attributes.dart';
import '../utils/subcategory_selection.dart';

class PricingPage extends StatefulWidget {
  const PricingPage({super.key});

  @override
  State<PricingPage> createState() => _PricingPageState();
}

class _PricingPageState extends State<PricingPage> {
  final TextEditingController _startingPriceController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _photoPackageController = TextEditingController();
  final TextEditingController _photoVideoPackageController =
      TextEditingController();
  final VendorServiceApi _vendorApi = VendorServiceApi();
  bool loading = true;
  bool saving = false;
  int? vendorId;
  int? serviceId;
  int? vendorSubcategoryId;
  String? token;

  /// Whatever `PriceRange` already held on the server.
  ///
  /// Migrated vendors carry free text there — "Rs. Price on Request",
  /// "Rs. 35,000" — with no min/max to parse out of it. The website keeps that
  /// string when the two inputs are empty, so this page has to as well;
  /// rebuilding the string unconditionally wiped it.
  String _serverPriceRange = '';

  /// The two package fields the website only shows for these types.
  String vendorTypeName = '';

  /// Pricing brochure. Images are compressed and stored inline as base64;
  /// a PDF keeps its name only, because the column cannot hold one.
  String? _brochureBase64;
  String? _brochureName;

  /// Set server side; read only, and carried through untouched on save.
  String? _brochureUrl;

  String? get _brochureType => PricingAttributes.brochureType(
        base64: _brochureBase64,
        name: _brochureName,
      );

  bool get _showPhotoPackages {
    final name = vendorTypeName.trim().toLowerCase();
    return name == 'photographers' || name == 'pre wedding shoot';
  }


  @override
  void initState() {
    super.initState();
    _loadCredentialsAndData();
  }

  /// Load local cached data and fetch from API
  Future<void> _loadCredentialsAndData() async {
    final prefs = await SharedPreferences.getInstance();
    vendorId = prefs.getInt('vendorId');
    token = prefs.getString('token');
    serviceId = prefs.getInt('serviceId');
    vendorSubcategoryId = prefs.getInt('vendor_subcategory_id');

    // Load local cache first
    final local = prefs.getString('pricingData');
    if (local != null) {
      try {
        final Map<String, dynamic> parsed = jsonDecode(local);
        _startingPriceController.text = parsed['startingPrice'] ?? '';
        _minPriceController.text = parsed['minPrice'] ?? '';
        _maxPriceController.text = parsed['maxPrice'] ?? '';
        _descriptionController.text = parsed['description'] ?? '';
        _photoPackageController.text = parsed['photoPackage'] ?? '';
        _photoVideoPackageController.text = parsed['photoVideoPackage'] ?? '';
      } catch (_) {}
    }

    // Fetch latest data from API
    if (vendorId != null && token != null) {
      await _fetchPricingFromApi();
    }

    setState(() => loading = false);
  }

  /// Fetch pricing from API
  Future<void> _fetchPricingFromApi() async {
    try {
      final data = await _vendorApi.getByVendorId(
        vendorId: vendorId!,
        token: token!,
      );

      if (data == null) return;

      serviceId = data['id'];
      vendorSubcategoryId ??= data['vendor_subcategory_id'];

      final attrs = Map<String, dynamic>.from(data['attributes'] ?? {});

      final startingPrice = attrs['starting_price']?.toString() ?? '';
      final priceRange = attrs['PriceRange']?.toString() ?? '';

      // Prefers the structured `price_range` pair, and only splits the display
      // string when there is no pair to read.
      final range = PricingAttributes.readRange(attrs);

      setState(() {
        vendorTypeName =
            (data['vendor']?['vendorType']?['name'] ?? '').toString();
        _serverPriceRange = priceRange;
        _startingPriceController.text = startingPrice;
        _minPriceController.text = range.min;
        _maxPriceController.text = range.max;
        _descriptionController.text =
            attrs['pricing_description']?.toString() ?? '';
        _photoPackageController.text =
            attrs['photo_package_price']?.toString() ?? '';
        _photoVideoPackageController.text =
            attrs['photo_video_package_price']?.toString() ?? '';
        _brochureBase64 = attrs['pricing_brochure_base64']?.toString();
        _brochureName = attrs['pricing_brochure_name']?.toString();
        _brochureUrl = attrs['pricing_brochure_url']?.toString();
      });

      await _saveLocally();
    } catch (e) {
      debugPrint("❌ Fetch pricing error: $e");
    }
  }


  /// Save locally in SharedPreferences
  Future<void> _saveLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      "startingPrice": _startingPriceController.text,
      "minPrice": _minPriceController.text,
      "maxPrice": _maxPriceController.text,
      "description": _descriptionController.text,
      "photoPackage": _photoPackageController.text,
      "photoVideoPackage": _photoVideoPackageController.text,
    };
    await prefs.setString('pricingData', jsonEncode(data));
  }

  // --------------------------------------------------------------------------
  // PRICING BROCHURE
  // --------------------------------------------------------------------------

  /// Base64 longer than this is refused rather than sent, so a too-large
  /// brochure fails here with a clear message instead of at the API. The
  /// website aims for ~80 KB after compression; this leaves headroom.
  static const int _maxBrochureBase64 = 300 * 1024;

  /// Picks an image and compresses it the way the website's canvas step does —
  /// longest side 600px, JPEG quality 65 — then stores it inline as base64.
  Future<void> _pickBrochureImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 65,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final encoded = "data:image/jpeg;base64,${base64Encode(bytes)}";

    if (!mounted) return;
    if (encoded.length > _maxBrochureBase64) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("That image is too large. Try a smaller one."),
        ),
      );
      return;
    }

    setState(() {
      _brochureBase64 = encoded;
      _brochureName = picked.name;
      _brochureUrl = null;
    });
  }

  /// PDFs are not stored inline — the column cannot hold one — so only the
  /// filename is kept, exactly as the website does it.
  Future<void> _pickBrochurePdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    final files = result?.files ?? const [];
    if (files.isEmpty) return;
    final name = files.first.name;

    setState(() {
      _brochureBase64 = null;
      _brochureName = name;
      _brochureUrl = null;
    });
  }

  Widget _brochureSection() {
    final type = _brochureType;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text("Pricing Brochure",
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(width: 6),
            Text("(PDF or Image)",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
        const SizedBox(height: 6),
        if (type == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Column(
              children: [
                Icon(Icons.upload_file,
                    size: 32, color: Colors.grey.shade600),
                const SizedBox(height: 10),
                Text(
                  "Images are saved to your listing · PDFs are noted by name",
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickBrochureImage,
                      icon: const Icon(Icons.image_outlined, size: 18),
                      label: const Text("Image"),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _pickBrochurePdf,
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: const Text("PDF"),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                _brochurePreview(type),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _brochureName ?? "Brochure",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        type == 'pdf'
                            // Be honest about what a PDF actually does here.
                            ? "PDF — only the file name is stored"
                            : "Image",
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: "Remove",
                  onPressed: _removeBrochure,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _brochurePreview(String type) {
    final base64Image = _brochureBase64;
    if (type == 'image' &&
        base64Image != null &&
        base64Image.startsWith('data:image')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          base64Decode(base64Image.split(',').last),
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          // A stored string that will not decode should show the fallback
          // rather than throw out of build.
          errorBuilder: (_, __, ___) => _brochureIcon(type),
        ),
      );
    }

    final url = _brochureUrl;
    if (type == 'image' && url != null && url.startsWith('http')) {
      return AppNetworkImage(
        url: url,
        width: 64,
        height: 64,
        borderRadius: BorderRadius.circular(8),
      );
    }

    return _brochureIcon(type);
  }

  Widget _brochureIcon(String type) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        type == 'pdf' ? Icons.picture_as_pdf : Icons.image_outlined,
        color: Colors.grey.shade700,
      ),
    );
  }

  void _removeBrochure() {
    setState(() {
      _brochureBase64 = null;
      _brochureName = null;
      _brochureUrl = null;
    });
  }

  /// Save to server via PUT
  Future<void> _saveToServer() async {
    if (vendorId == null || token == null || serviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vendor info missing.")),
      );
      return;
    }

    setState(() => saving = true);

    // 🔥 Fetch latest attributes first (SAFETY)
    final latest = await _vendorApi.getByServiceId(
      serviceId: serviceId!,
      token: token!,
    );

    Map<String, dynamic> attributes =
    Map<String, dynamic>.from(latest?['attributes'] ?? {});

    // ✅ Update ONLY pricing-related fields. The rules — and why an empty box
    // must not become 0 or " - " — live in PricingAttributes.
    attributes = PricingAttributes.merge(
      attributes: attributes,
      starting: _startingPriceController.text,
      min: _minPriceController.text,
      max: _maxPriceController.text,
      description: _descriptionController.text,
      serverPriceRange: _serverPriceRange,
      // null for vendor types that never see these, so their keys are left be.
      photoPackage: _showPhotoPackages ? _photoPackageController.text : null,
      photoVideoPackage:
          _showPhotoPackages ? _photoVideoPackageController.text : null,
      brochureBase64: _brochureBase64,
      brochureName: _brochureName,
    );

    final body = {
      "vendor_id": vendorId,
      "vendor_subcategory_id": await SubcategorySelection.payloadForPrimary(vendorSubcategoryId),
      "attributes": attributes,
    };

    await _saveLocally();

    final success = await _vendorApi.updateService(
      serviceId: serviceId!,
      token: token!,
      body: body,
    );

    if (success) {
      await  StorefrontCompletionService.refreshCompletion(
        serviceId: serviceId!,
      );
      // AUDIT FIX: context used after an await — guard added.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pricing saved successfully.")),
      );
    } else {
      // AUDIT FIX: context used after an await — guard added.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save pricing.")),
      );
    }

    setState(() => saving = false);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
    appBar: CommonAppBar(title: 'Pricing & Packages'),
      body: loading
          ? const FormShimmer(fields: 4)
          : Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Pricing & Packages",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text("Add your starting price & package price range",
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  const Text("Starting Price", style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _startingPriceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "5000",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("Price Range", style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minPriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: "2000",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text("-", style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _maxPriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: "40000",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Only Photographers and Pre Wedding Shoot get these on the
                  // website, so the same two types get them here.
                  if (_showPhotoPackages) ...[
                    const SizedBox(height: 20),
                    const Text("Photo Package Price",
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _photoPackageController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "24000",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text("Photo + Video Package Price",
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _photoVideoPackageController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "40000",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  const Text("Pricing Description",
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText:
                          "Describe your packages, inclusions, taxes, payment "
                          "terms, cancellation policy, etc.",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _brochureSection(),
                  const SizedBox(height: 30),
                ],
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00509D),
                        foregroundColor: Colors.white,
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: saving ? null : _saveToServer,
                      child: saving
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                          : const Text("Save Pricing Details", style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
