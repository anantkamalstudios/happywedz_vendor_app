import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api_services/storefront_completion_service.dart';
import '../utils/common_app_bar.dart';
import '../api_services/api_service_vendor.dart';
import '../widgets/app_shimmer.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  // ---------------- Controllers ----------------
  final addressController = TextEditingController();
  final stateController = TextEditingController();
  final pincodeController = TextEditingController();
 // final landmarkController = TextEditingController();
  final latitudeController = TextEditingController();
  final longitudeController = TextEditingController();

  // ---------------- Location ----------------
  /// Centre of India — the fallback until the vendor's saved coordinates load.
  static const LatLng _indiaCentre = LatLng(20.5937, 78.9629);
  LatLng selectedLocation = _indiaCentre;

  // ---------------- Country / City ----------------
  List<String> countries = [];
  String? selectedCountry;
  List<String> citySuggestions = [];
  String? selectedCity;

  // ---------------- Flags ----------------
  bool loadingCountries = true;
  bool loadingCities = false;
  bool loadingVendorData = true;
  bool savingLocation = false;

  // ---------------- IDs ----------------
  int? vendorId;
  int? vendorSubcategoryId; // OPTIONAL
  int? serviceId;
  String? token;

  Map<String, dynamic> currentAttributes = {};

  final VendorServiceApi _vendorApi = VendorServiceApi();

  /// AUDIT NOTE (resolved): this used to be a flutter_map `MapController` that
  /// was never attached to anything. It is now the live GoogleMap handle and is
  /// used by `_recentreMap` to re-centre on the vendor's saved coordinates once
  /// they arrive — the behaviour the old note said the screen should have.
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// Moves the camera onto [selectedLocation]. Safe to call before the map has
  /// been created — `onMapCreated` calls it again once the controller exists.
  void _recentreMap({double zoom = 14}) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: selectedLocation, zoom: zoom),
      ),
    );
  }

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    _loadCredentials();
    fetchCountries();
  }

  // ================= LOAD CREDS =================
  Future<void> _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();

    vendorId = prefs.getInt('vendorId');
    vendorSubcategoryId = prefs.getInt('vendor_subcategory_id'); // MAY BE NULL
    serviceId = prefs.getInt('serviceId');
    token = prefs.getString('token');

    debugPrint("🔍 vendorId=$vendorId, subCat=$vendorSubcategoryId, serviceId=$serviceId");

    if (vendorId != null && token != null) {
      await _ensureServiceId();
      await _fetchLocationFromApi();
    }

    setState(() => loadingVendorData = false);
  }

  // ================= ENSURE SERVICE =================
  Future<void> _ensureServiceId() async {
    if (serviceId != null) return;

    final prefs = await SharedPreferences.getInstance();

    final existing = await _vendorApi.getByVendorId(
      vendorId: vendorId!,
      token: token!,
    );

    if (existing != null) {
      serviceId = existing['id'];
      await prefs.setInt('serviceId', serviceId!);
      return;
    }

    await _vendorApi.createService(
      token: token!,
      body: {
        "vendor_id": vendorId,
        if (vendorSubcategoryId != null)
          "vendor_subcategory_id": vendorSubcategoryId,
        "attributes": {},
      },
    );

    final fresh = await _vendorApi.getByVendorId(
      vendorId: vendorId!,
      token: token!,
    );

    serviceId = fresh?['id'];
    if (serviceId != null) {
      await prefs.setInt('serviceId', serviceId!);
    }
  }


  Future<String?> _openSearchBottomSheet({
    required String title,
    required List<String> items,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        TextEditingController searchCtrl = TextEditingController();
        List<String> filtered = List.from(items);

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.65,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: searchCtrl,
                      decoration: InputDecoration(
                        hintText: "Search...",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          filtered = items
                              .where((e) =>
                              e.toLowerCase().contains(val.toLowerCase()))
                              .toList();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text("No results found"))
                          : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final value = filtered[index];
                          return ListTile(
                            title: Text(value),
                            onTap: () =>
                                Navigator.pop(context, value),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  // ================= FETCH LOCATION =================
  Future<void> _fetchLocationFromApi() async {
    if (serviceId == null) return;

    final res = await _vendorApi.getByServiceId(
      serviceId: serviceId!,
      token: token!,
    );

    currentAttributes =
    Map<String, dynamic>.from(res?['attributes'] ?? {});

    final location =
    Map<String, dynamic>.from(currentAttributes['location'] ?? {});

    setState(() {
      addressController.text = currentAttributes['address'] ?? '';
      selectedCity = currentAttributes['city'];
      selectedCountry = currentAttributes['country'] ?? 'India';

      stateController.text = location['state'] ?? '';
      pincodeController.text = location['pincode'] ?? '';

     // landmarkController.text = currentAttributes['landmark'] ?? '';
      latitudeController.text = currentAttributes['latitude'] ?? '';
      longitudeController.text = currentAttributes['longitude'] ?? '';

      final lat = double.tryParse(latitudeController.text);
      final lng = double.tryParse(longitudeController.text);
      if (lat != null && lng != null) {
        selectedLocation = LatLng(lat, lng);
      }
    });

    // The camera is only seeded from `initialCameraPosition` at creation time,
    // so the saved pin has to be pushed to the map explicitly when it arrives.
    _recentreMap();

    if (selectedCountry != null) {
      fetchCities(selectedCountry!);
    }
  }


  // ================= COUNTRIES API =================
  Future<void> fetchCountries() async {
    try {
      final res = await http.get(
        Uri.parse('https://restcountries.com/v3.1/all?fields=name'),
      );
      final List data = jsonDecode(res.body);
      countries =
      data.map((c) => c['name']['common'] as String).toList()..sort();
    } catch (_) {}
    setState(() => loadingCountries = false);
  }

  // ================= CITIES API =================
  Future<void> fetchCities(String country) async {
    setState(() => loadingCities = true);
    try {
      final res = await http.get(
        Uri.parse('https://countriesnow.space/api/v0.1/countries'),
      );
      final data = jsonDecode(res.body);
      final c = data['data'].firstWhere((e) => e['country'] == country);
      citySuggestions = List<String>.from(c['cities']);
    } catch (_) {
      citySuggestions = [];
    }
    setState(() => loadingCities = false);
  }

  Future<void> saveLocation() async {
    if (savingLocation) return;

    if (vendorId == null || token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Vendor not logged in")),
      );
      return;
    }

    if (addressController.text.isEmpty ||
        selectedCity == null ||
        selectedCountry == null ||
        stateController.text.isEmpty ||
        pincodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    setState(() => savingLocation = true);

    try {
      await _ensureServiceId();

      final latest = await _vendorApi.getByServiceId(
        serviceId: serviceId!,
        token: token!,
      );

      currentAttributes =
      Map<String, dynamic>.from(latest?['attributes'] ?? {});

      // 🔥 location object (IMPORTANT)
      currentAttributes['location'] = {
        "state": stateController.text.trim(),
        "pincode": pincodeController.text.trim(),
      };

      currentAttributes.addAll({
        "address": addressController.text.trim(),
        "city": selectedCity,
        "country": selectedCountry,
       // "landmark": landmarkController.text.trim(),
        "latitude": latitudeController.text.trim(),
        "longitude": longitudeController.text.trim(),
      });

      final success = await _vendorApi.updateService(
        serviceId: serviceId!,
        token: token!,
        body: {
          "vendor_id": vendorId,
          if (vendorSubcategoryId != null)
            "vendor_subcategory_id": vendorSubcategoryId,
          "attributes": currentAttributes,
        },
      );

      if (success) {
        await StorefrontCompletionService.refreshCompletion(
          serviceId: serviceId!,
        );
        // AUDIT FIX: context used after an await — guard added.
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location saved successfully")),
        );
      }
    } catch (e) {
      debugPrint("❌ Save error: $e");
      // AUDIT FIX: context used after an await — guard added.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save location")),
      );
    }

    setState(() => savingLocation = false);
  }


  // ================= UI HELPERS =================
  Widget field(String label, TextEditingController c,
      {bool required = false, TextInputType type = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label + (required ? " *" : ""),
            style: TextStyle(fontWeight: FontWeight.w600)),
        SizedBox(height: 6),
        TextField(
          controller: c,
          keyboardType: type,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        SizedBox(height: 14),
      ],
    );
  }

  Widget countryDropdown() {
    return GestureDetector(
      onTap: () async {
        final selected = await _openSearchBottomSheet(
          title: "Select Country",
          items: countries,
        );

        if (selected != null) {
          setState(() {
            selectedCountry = selected;
            selectedCity = null;
            fetchCities(selectedCountry!);
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(selectedCountry ?? "Select Country *"),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget cityPicker() {
    return GestureDetector(
      onTap: () async {
        final selected = await _openSearchBottomSheet(
          title: "Select City",
          items: citySuggestions,
        );

        if (selected != null) {
          setState(() => selectedCity = selected);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(selectedCity ?? "Select City *"),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(title: "Location & Service Areas"),
      body: loadingVendorData
          ? const FormShimmer(fields: 4)
          : Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                        padding: EdgeInsets.all(16),
                        child: Column(
                children: [
                  field("Address", addressController, required: true),
                  loadingCountries
                      ? CircularProgressIndicator()
                      : countryDropdown(),
                  SizedBox(height: 14),
                  loadingCities ? CircularProgressIndicator() : cityPicker(),
                  SizedBox(height: 14),
                  field("State", stateController, required: true),
                  field("Pincode", pincodeController,
                      required: true, type: TextInputType.number),
                 // field("Landmark", landmarkController),
                  field("Latitude", latitudeController,
                      type: TextInputType.number),
                  field("Longitude", longitudeController,
                      type: TextInputType.number),
                  SizedBox(height: 10),
                  SizedBox(
                    height: 250,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: selectedLocation,
                        // Country-wide until a real pin is known, then
                        // `_recentreMap` zooms in on it.
                        zoom: selectedLocation == _indiaCentre ? 5 : 14,
                      ),
                      onMapCreated: (controller) {
                        _mapController = controller;
                        if (selectedLocation != _indiaCentre) _recentreMap();
                      },
                      onTap: (p) {
                        setState(() {
                          selectedLocation = p;
                          latitudeController.text = p.latitude.toString();
                          longitudeController.text = p.longitude.toString();
                        });
                      },
                      markers: {
                        Marker(
                          markerId: const MarkerId('selected-location'),
                          position: selectedLocation,
                          draggable: true,
                          onDragEnd: (p) {
                            setState(() {
                              selectedLocation = p;
                              latitudeController.text = p.latitude.toString();
                              longitudeController.text = p.longitude.toString();
                            });
                          },
                        ),
                      },
                      // The map sits inside a SingleChildScrollView; without
                      // this the parent steals the vertical drag and the map
                      // cannot be panned.
                      gestureRecognizers: {
                        Factory<OneSequenceGestureRecognizer>(
                          EagerGestureRecognizer.new,
                        ),
                      },
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                    ),
                  ),
                  SizedBox(height: 20),
                ],
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: savingLocation ? null : saveLocation,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Color(0xFF00509D),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    child: savingLocation
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text("Save Location Details",
                        style: TextStyle(
                            fontSize: 16,color: Colors.white
                            )),
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
