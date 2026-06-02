import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_services/api_service_vendor.dart';
import '../api_services/storefront_completion_service.dart';
import '../utils/common_app_bar.dart';

class FacilitiesPage extends StatefulWidget {
  const FacilitiesPage({super.key});

  @override
  State<FacilitiesPage> createState() => _FacilitiesPageState();
}

class _FacilitiesPageState extends State<FacilitiesPage> {

  // ================= Controllers =================
  final roomsController = TextEditingController();
  final parkingController = TextEditingController();
  final cateringController = TextEditingController();
  final decorController = TextEditingController();
  final offeringsController = TextEditingController();
  final deliveryController = TextEditingController();
  final travelController = TextEditingController();
  final happyWedzSinceController = TextEditingController();
  final areaController = TextEditingController();
  final outsideAlcoholController = TextEditingController();
  final startVenueController = TextEditingController();
  final djPolicyController = TextEditingController();
  final spacesController = TextEditingController();

  // ================= State =================
  bool loading = false;
  bool saving = false;

  int? vendorId;
  int? serviceId;
  int? vendorSubcategoryId;
  int? vendorTypeId;
  String? token;

  bool isFullFacilitiesVendor = false; // 🔥 KEY FLAG

  final VendorServiceApi _vendorApi = VendorServiceApi();

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    _loadCredentialsAndData();
  }

  @override
  void dispose() {
    roomsController.dispose();
    parkingController.dispose();
    cateringController.dispose();
    decorController.dispose();
    offeringsController.dispose();
    deliveryController.dispose();
    travelController.dispose();
    happyWedzSinceController.dispose();
    areaController.dispose();
    outsideAlcoholController.dispose();
    startVenueController.dispose();
    djPolicyController.dispose();
    spacesController.dispose();
    super.dispose();
  }

  // ================= LOAD =================
  Future<void> _loadCredentialsAndData() async {
    final prefs = await SharedPreferences.getInstance();

    vendorId = prefs.getInt('vendorId');
    serviceId = prefs.getInt('serviceId');
    vendorSubcategoryId = prefs.getInt('vendor_subcategory_id');
    vendorTypeId = prefs.getInt('vendorTypeId'); // 🔥 IMPORTANT
    token = prefs.getString('token');

    // 🔥 Vendor type check
    isFullFacilitiesVendor = vendorTypeId == 2;

    if (vendorId != null && token != null) {
      await _fetchExistingDataFromAPI();
    }

    setState(() {});
  }

  // ================= FETCH =================
  Future<void> _fetchExistingDataFromAPI() async {
    setState(() => loading = true);

    try {
      final data = await _vendorApi.getByVendorId(
        vendorId: vendorId!,
        token: token!,
      );

      if (data == null) return;

      final attributes =
      Map<String, dynamic>.from(data['attributes'] ?? {});

      _setFieldsFromMap(attributes);
    } catch (e) {
      debugPrint("❌ Facilities fetch error: $e");
    }

    setState(() => loading = false);
  }

  // ================= SET UI =================
  void _setFieldsFromMap(Map<String, dynamic> data) {
    roomsController.text = data['rooms']?.toString() ?? '';
    parkingController.text = data['parking'] ?? '';
    cateringController.text = data['catering_policy'] ?? '';
    decorController.text = data['decor_policy'] ?? '';
    offeringsController.text = data['offerings'] ?? '';
    deliveryController.text = data['delivery_time'] ?? '';
    travelController.text = data['travel_info'] ?? '';
    happyWedzSinceController.text = data['happywedz_since'] ?? '';
    areaController.text = data['area'] ?? '';
    outsideAlcoholController.text = data['outside_alcohol'] ?? '';
    startVenueController.text = data['start_venue'] ?? '';
    spacesController.text = data['space'] ?? '';
    djPolicyController.text = data['dJ_policy'] ?? '';
  }

  Future<void> _saveData() async {
    if (vendorId == null || token == null) return;

    setState(() => saving = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      // 🔥 STEP 1: If serviceId missing → fetch/create
      if (serviceId == null) {
        final byVendor = await _vendorApi.getByVendorId(
          vendorId: vendorId!,
          token: token!,
        );

        if (byVendor != null) {
          serviceId = byVendor['id'];
          await prefs.setInt('serviceId', serviceId!);
        } else {
          // 🔥 Create empty service first
          final created = await _vendorApi.createService(
            token: token!,
            body: {
              "vendor_id": vendorId,
              "vendor_subcategory_id": vendorSubcategoryId,
              "attributes": {},
            },
          );

          if (!created) {
            throw "Service create failed";
          }

          final fresh = await _vendorApi.getByVendorId(
            vendorId: vendorId!,
            token: token!,
          );

          serviceId = fresh?['id'];
          if (serviceId != null) {
            await prefs.setInt('serviceId', serviceId!);
          }
        }
      }

      // 🔥 STEP 2: fetch latest attributes
      final latest = await _vendorApi.getByServiceId(
        serviceId: serviceId!,
        token: token!,
      );

      Map<String, dynamic> attributes =
      Map<String, dynamic>.from(latest?['attributes'] ?? {});

      // 🔥 STEP 3: update visible fields only
      if (isFullFacilitiesVendor) {
        attributes["rooms"] = int.tryParse(roomsController.text);
        attributes["parking"] = parkingController.text;
        attributes["outside_alcohol"] = outsideAlcoholController.text;
        attributes["catering_policy"] = cateringController.text;
        attributes["decor_policy"] = decorController.text;
        attributes["start_venue"] = startVenueController.text;
        attributes["dJ_policy"] = djPolicyController.text;
        attributes["space"] = spacesController.text;
        attributes["area"] = areaController.text;
        attributes["happywedz_since"] = happyWedzSinceController.text;
      }
      else {
        // 🔥 Other vendors → all 4 fields
        attributes["offerings"] = offeringsController.text;
        attributes["delivery_time"] = deliveryController.text;
        attributes["travel_info"] = travelController.text;
        attributes["happywedz_since"] = happyWedzSinceController.text;
      }
      // attributes["offerings"] = offeringsController.text;
      // attributes["delivery_time"] = deliveryController.text;
      // attributes["travel_info"] = travelController.text;
      // attributes["happywedz_since"] = happyWedzSinceController.text;

      // 🔥 STEP 4: update service
      final success = await _vendorApi.updateService(
        serviceId: serviceId!,
        token: token!,
        body: {
          "vendor_id": vendorId,
          "vendor_subcategory_id": vendorSubcategoryId,
          "attributes": attributes,
        },
      );

      if (success) {

        await StorefrontCompletionService.refreshCompletion(
          serviceId: serviceId!,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Facilities saved successfully")),
        );
      }
    } catch (e) {
      debugPrint("❌ Facilities save error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save facilities")),
      );
    }

    setState(() => saving = false);
  }

  // ================= UI HELPERS =================
  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.grey.shade100,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );

  Widget _field(String title, TextEditingController c,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(controller: c, maxLines: maxLines, decoration: _dec("")),
        const SizedBox(height: 20),
      ],
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: "Facilities & Features"),
      backgroundColor: Colors.white,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔥 FULL FIELDS (vendorTypeId == 2)
            if (isFullFacilitiesVendor) ...[
              _field("Number of Rooms", roomsController),
              _field("Car Parking", parkingController),
              _field("Outside Alcohol Policy", outsideAlcoholController),
              _field("Catering Policy", cateringController),
              _field("Decor Policy", decorController),
              _field("HappyWedz Since", happyWedzSinceController),
              _field("Start Venue", startVenueController),
              _field("DJ Policy", djPolicyController),
              _field("Space", spacesController),
              _field("Area / Capacity", areaController, maxLines: 3),
            ],

            // 🔥 COMMON FOR ALL VENDORS
            // _field("Offerings", offeringsController),
            // _field("Delivery Time", deliveryController),
            // _field("Travel Info", travelController),
            // _field("HappyWedz Since", happyWedzSinceController),
            if (!isFullFacilitiesVendor) ...[
              _field("Offerings", offeringsController),
              _field("Delivery Time", deliveryController),
              _field("Travel Info", travelController),
              _field("HappyWedz Since", happyWedzSinceController),
            ],

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving ? null : _saveData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00509D),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "Save Facilities Details",
                  style: TextStyle(
                      fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
