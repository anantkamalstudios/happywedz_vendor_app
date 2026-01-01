// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import '../api_services/api_service_vendor.dart';
// import '../utils/common_app_bar.dart';
//
// class FacilitiesPage extends StatefulWidget {
//   const FacilitiesPage({super.key});
//
//   @override
//   State<FacilitiesPage> createState() => _FacilitiesPageState();
// }
//
// class _FacilitiesPageState extends State<FacilitiesPage> {
//   TextEditingController roomsController = TextEditingController();
//   TextEditingController parkingController = TextEditingController();
//   TextEditingController cateringController = TextEditingController();
//   TextEditingController decorController = TextEditingController();
//   TextEditingController offeringsController = TextEditingController();
//   TextEditingController deliveryController = TextEditingController();
//   TextEditingController travelController = TextEditingController();
//   TextEditingController happyWedzSinceController = TextEditingController();
//   TextEditingController areaController = TextEditingController();
//
//   String? indoorOutdoor;
//   String? alcoholPolicy;
//
//   bool loading = false;
//   bool saving = false;
//
//   int? vendorId;
//   int? serviceId;
//   int? vendorSubcategoryId;
//   String? token;
//   final VendorServiceApi _vendorApi = VendorServiceApi();
//
//
//   final allowedIndoorOutdoor = ["Indoor", "Outdoor", "Both"];
//   final allowedAlcohol = ["allowed", "not_allowed", "own_alcohol"];
//
//   @override
//   void initState() {
//     super.initState();
//     _loadCredentialsAndData();
//
//     // Autosave fields on change
//     roomsController.addListener(_autosaveLocally);
//     parkingController.addListener(_autosaveLocally);
//     cateringController.addListener(_autosaveLocally);
//     decorController.addListener(_autosaveLocally);
//     offeringsController.addListener(_autosaveLocally);
//     deliveryController.addListener(_autosaveLocally);
//     travelController.addListener(_autosaveLocally);
//     happyWedzSinceController.addListener(_autosaveLocally);
//     areaController.addListener(_autosaveLocally);
//   }
//
//   @override
//   void dispose() {
//     roomsController.dispose();
//     parkingController.dispose();
//     cateringController.dispose();
//     decorController.dispose();
//     offeringsController.dispose();
//     deliveryController.dispose();
//     travelController.dispose();
//     happyWedzSinceController.dispose();
//     areaController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _loadCredentialsAndData() async {
//     final prefs = await SharedPreferences.getInstance();
//     vendorId = prefs.getInt('vendorId');
//     serviceId = prefs.getInt('serviceId');
//     vendorSubcategoryId = prefs.getInt('vendor_subcategory_id');
//     token = prefs.getString('token');
//
//     // Load locally saved facilities first
//     if (vendorId != null) {
//       final savedJson = prefs.getString('facilitiesData_$vendorId');
//       if (savedJson != null) {
//         final Map<String, dynamic> data = jsonDecode(savedJson);
//         _setFieldsFromMap(data);
//       }
//     }
//
//     // Fetch latest from API and merge
//     if (serviceId != null && token != null) {
//       await _fetchExistingDataFromAPI();
//     }
//
//     setState(() {});
//   }
//
//   void _setFieldsFromMap(Map<String, dynamic> data) {
//     roomsController.text = data['rooms']?.toString() ?? '';
//     parkingController.text = data['parking'] ?? '';
//     cateringController.text = data['catering_policy'] ?? '';
//     decorController.text = data['decor_policy'] ?? '';
//     offeringsController.text = data['offerings'] ?? '';
//     deliveryController.text = data['delivery_time'] ?? '';
//     travelController.text = data['travel_info'] ?? '';
//     happyWedzSinceController.text = data['happywedz_since'] ?? '';
//     areaController.text = data['area'] ?? '';
//     indoorOutdoor = allowedIndoorOutdoor.contains(data['indoor_outdoor']) ? data['indoor_outdoor'] : null;
//     alcoholPolicy = allowedAlcohol.contains(data['alcohol_policy']) ? data['alcohol_policy'] : null;
//   }
//
//
//   Future<void> _fetchExistingDataFromAPI() async {
//     setState(() => loading = true);
//
//     try {
//       final data = await _vendorApi.getByServiceId(
//         serviceId: serviceId!,
//         token: token!,
//       );
//
//       if (data == null) return;
//
//       final Map<String, dynamic> attributes =
//       Map<String, dynamic>.from(data['attributes'] ?? {});
//
//       // ✅ Merge only if local fields empty
//       final merged = {
//         "rooms": roomsController.text.isEmpty
//             ? attributes['rooms']
//             : int.tryParse(roomsController.text),
//         "parking": parkingController.text.isEmpty
//             ? attributes['parking']
//             : parkingController.text,
//         "catering_policy": cateringController.text.isEmpty
//             ? attributes['catering_policy']
//             : cateringController.text,
//         "decor_policy": decorController.text.isEmpty
//             ? attributes['decor_policy']
//             : decorController.text,
//         "offerings": offeringsController.text.isEmpty
//             ? attributes['offerings']
//             : offeringsController.text,
//         "delivery_time": deliveryController.text.isEmpty
//             ? attributes['delivery_time']
//             : deliveryController.text,
//         "travel_info": travelController.text.isEmpty
//             ? attributes['travel_info']
//             : travelController.text,
//         "happywedz_since": happyWedzSinceController.text.isEmpty
//             ? attributes['happywedz_since']
//             : happyWedzSinceController.text,
//         "area": areaController.text.isEmpty
//             ? attributes['area']
//             : areaController.text,
//         "indoor_outdoor": indoorOutdoor ?? attributes['indoor_outdoor'],
//         "alcohol_policy": alcoholPolicy ?? attributes['alcohol_policy'],
//       };
//
//       _setFieldsFromMap(merged);
//       await _autosaveLocally();
//     } catch (e) {
//       debugPrint("❌ Facilities fetch error: $e");
//     }
//
//     setState(() => loading = false);
//   }
//
//   InputDecoration _inputDecoration(String hint) {
//     return InputDecoration(
//       hintText: hint,
//       contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//       filled: true,
//       fillColor: Colors.grey.shade100,
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: BorderSide.none,
//       ),
//     );
//   }
//
//   Future<void> _autosaveLocally() async {
//     if (vendorId == null) return;
//     final prefs = await SharedPreferences.getInstance();
//     final Map<String, dynamic> data = {
//       "rooms": int.tryParse(roomsController.text),
//       "parking": parkingController.text,
//       "catering_policy": cateringController.text,
//       "decor_policy": decorController.text,
//       "offerings": offeringsController.text,
//       "delivery_time": deliveryController.text,
//       "travel_info": travelController.text,
//       "happywedz_since": happyWedzSinceController.text,
//       "area": areaController.text,
//       "indoor_outdoor": indoorOutdoor,
//       "alcohol_policy": alcoholPolicy,
//     };
//     await prefs.setString('facilitiesData_$vendorId', jsonEncode(data));
//   }
//
//   Future<void> _saveData() async {
//     if (vendorId == null || serviceId == null || token == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please complete Basic Info first.")),
//       );
//       return;
//     }
//
//     setState(() => saving = true);
//
//     // 🔥 Fetch latest attributes again (SAFETY)
//     final latest = await _vendorApi.getByServiceId(
//       serviceId: serviceId!,
//       token: token!,
//     );
//
//     Map<String, dynamic> attributes =
//     Map<String, dynamic>.from(latest?["attributes"] ?? {});
//
//     // ✅ Update ONLY facilities-related fields
//     attributes.addAll({
//       "rooms": int.tryParse(roomsController.text),
//       "parking": parkingController.text,
//       "catering_policy": cateringController.text,
//       "decor_policy": decorController.text,
//       "offerings": offeringsController.text,
//       "delivery_time": deliveryController.text,
//       "travel_info": travelController.text,
//       "happywedz_since": happyWedzSinceController.text,
//       "area": areaController.text,
//       "indoor_outdoor": indoorOutdoor,
//       "alcohol_policy": alcoholPolicy,
//     });
//
//     final body = {
//       "vendor_id": vendorId,
//       if (vendorSubcategoryId != null)
//         "vendor_subcategory_id": vendorSubcategoryId,
//       "attributes": attributes,
//     };
//
//     final success = await _vendorApi.updateService(
//       serviceId: serviceId!,
//       token: token!,
//       body: body,
//     );
//
//     if (success) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Facilities details saved successfully")),
//       );
//       await _autosaveLocally();
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Failed to save facilities details")),
//       );
//     }
//
//     setState(() => saving = false);
//   }
//
//
//   Widget _buildTextField(String title, TextEditingController controller, String hint,
//       {int maxLines = 1}) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
//         const SizedBox(height: 8),
//         TextField(controller: controller, maxLines: maxLines, decoration: _inputDecoration(hint)),
//         const SizedBox(height: 20),
//       ],
//     );
//   }
//
//   Widget _buildDropdown({
//     required String title,
//     required String? value,
//     required List<String> items,
//     required Function(String?) onChanged,
//     Map<String, String>? labels,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
//         const SizedBox(height: 8),
//         DropdownButtonFormField<String>(
//           value: items.contains(value) ? value : null,
//           decoration: _inputDecoration("Choose"),
//           items: items.map((e) => DropdownMenuItem(value: e, child: Text(labels?[e] ?? e))).toList(),
//           onChanged: onChanged,
//         ),
//         const SizedBox(height: 20),
//       ],
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: CommonAppBar(title:"Facilities & Features"),
//       body: loading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Container(
//           padding: const EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(14),
//             boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text("Facilities & Features", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
//               const SizedBox(height: 20),
//
//               _buildTextField("Number of Rooms", roomsController, "Enter number of rooms"),
//               _buildTextField("Car Parking", parkingController, "There is sufficient parking available"),
//
//               _buildDropdown(
//                 title: "Indoor/Outdoor",
//                 value: indoorOutdoor,
//                 items: allowedIndoorOutdoor,
//                 onChanged: (v) => setState(() {
//                   indoorOutdoor = v;
//                   _autosaveLocally();
//                 }),
//               ),
//
//               _buildDropdown(
//                 title: "Alcohol Policy",
//                 value: alcoholPolicy,
//                 items: allowedAlcohol,
//                 labels: const {
//                   "allowed": "Allowed",
//                   "not_allowed": "Not Allowed",
//                   "own_alcohol": "Own Alcohol"
//                 },
//                 onChanged: (v) => setState(() {
//                   alcoholPolicy = v;
//                   _autosaveLocally();
//                 }),
//               ),
//
//               _buildTextField("Catering Policy", cateringController, "Inhouse catering only"),
//               _buildTextField("Decor Policy", decorController, "Outside Decorators Permitted"),
//               _buildTextField("Offerings (comma-separated)", offeringsController, "Photographer, DJ, Catering, etc."),
//               _buildTextField("Delivery Time", deliveryController, "e.g. 2–3 weeks"),
//               _buildTextField("Travel Info", travelController, "e.g. Travel within city, All over India"),
//               _buildTextField("HappyWedz Since", happyWedzSinceController, "since 6 years"),
//               _buildTextField("Area / Capacity Details", areaController, "Lawn 800 Seating | 1000 Floating", maxLines: 3),
//
//               const SizedBox(height: 30),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: saving ? null : _saveData,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Color(0xFF00509D),
//                     foregroundColor: Colors.white,
//
//                     padding: const EdgeInsets.symmetric(vertical: 14),
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                   ),
//                   child: saving
//                       ? const CircularProgressIndicator(color: Colors.white)
//                       : const Text("Save Facilities Details", style: TextStyle(fontSize: 16)),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
// class VendorServiceApi {
//   final String baseUrl = "https://happywedz.com/api";
//
//   // ================= GET BY VENDOR ID =================
//   Future<Map<String, dynamic>?> getByVendorId({
//     required int vendorId,
//     required String token,
//   }) async {
//     final res = await http.get(
//       Uri.parse("$baseUrl/vendor-services/vendor/$vendorId"),
//       headers: {
//         "Authorization": "Bearer $token",
//         "Content-Type": "application/json",
//       },
//     );
//
//     if (res.statusCode == 200) {
//       final List list = jsonDecode(res.body);
//       if (list.isNotEmpty) return list.first;
//     }
//     return null;
//   }
//
//   // ================= GET BY SERVICE ID (🔥 IMPORTANT) =================
//   Future<Map<String, dynamic>?> getByServiceId({
//     required int serviceId,
//     required String token,
//   }) async {
//     final res = await http.get(
//       Uri.parse("$baseUrl/vendor-services/$serviceId"),
//       headers: {
//         "Authorization": "Bearer $token",
//         "Content-Type": "application/json",
//       },
//     );
//
//     if (res.statusCode == 200) {
//       return jsonDecode(res.body);
//     }
//     return null;
//   }
//
//   // ================= CREATE =================
//   Future<bool> createService({
//     required String token,
//     required Map<String, dynamic> body,
//   }) async {
//     final res = await http.post(
//       Uri.parse("$baseUrl/vendor-services"),
//       headers: {
//         "Authorization": "Bearer $token",
//         "Content-Type": "application/json",
//       },
//       body: jsonEncode(body),
//     );
//
//     return res.statusCode == 201 || res.statusCode == 200;
//   }
//
//   // ================= UPDATE =================
//   Future<bool> updateService({
//     required int serviceId,
//     required String token,
//     required Map<String, dynamic> body,
//   }) async {
//     final res = await http.put(
//       Uri.parse("$baseUrl/vendor-services/$serviceId"),
//       headers: {
//         "Authorization": "Bearer $token",
//         "Content-Type": "application/json",
//       },
//       body: jsonEncode(body),
//     );
//
//     return res.statusCode == 200;
//   }
// }
//
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../api_services/api_service_vendor.dart';
// import '../utils/common_app_bar.dart';
// class FacilitiesPage extends StatefulWidget {
//   const FacilitiesPage({super.key});
//
//   @override
//   State<FacilitiesPage> createState() => _FacilitiesPageState();
// }
//
// class _FacilitiesPageState extends State<FacilitiesPage> {
//   TextEditingController roomsController = TextEditingController();
//   TextEditingController parkingController = TextEditingController();
//   TextEditingController cateringController = TextEditingController();
//   TextEditingController decorController = TextEditingController();
//   TextEditingController offeringsController = TextEditingController();
//   TextEditingController deliveryController = TextEditingController();
//   TextEditingController travelController = TextEditingController();
//   TextEditingController happyWedzSinceController = TextEditingController();
//   TextEditingController areaController = TextEditingController();
//   TextEditingController outsideAlcoholController = TextEditingController();
//   TextEditingController startVenueController = TextEditingController();
//   TextEditingController djPolicyController = TextEditingController();
//   TextEditingController spacesController = TextEditingController();
//
//   bool loading = false;
//   bool saving = false;
//
//   int? vendorId;
//   int? serviceId;
//   int? vendorSubcategoryId;
//   String? token;
//
//   final VendorServiceApi _vendorApi = VendorServiceApi();
//
//   // ================= INIT =================
//   @override
//   void initState() {
//     super.initState();
//     _loadCredentialsAndData();
//
//     roomsController.addListener(_autosaveLocally);
//     parkingController.addListener(_autosaveLocally);
//     cateringController.addListener(_autosaveLocally);
//     decorController.addListener(_autosaveLocally);
//     offeringsController.addListener(_autosaveLocally);
//     deliveryController.addListener(_autosaveLocally);
//     travelController.addListener(_autosaveLocally);
//     happyWedzSinceController.addListener(_autosaveLocally);
//     areaController.addListener(_autosaveLocally);
//     outsideAlcoholController.addListener(_autosaveLocally);
//     startVenueController.addListener(_autosaveLocally);
//     djPolicyController.addListener(_autosaveLocally);
//     spacesController.addListener(_autosaveLocally);
//   }
//
//   @override
//   void dispose() {
//     roomsController.dispose();
//     parkingController.dispose();
//     cateringController.dispose();
//     decorController.dispose();
//     offeringsController.dispose();
//     deliveryController.dispose();
//     travelController.dispose();
//     happyWedzSinceController.dispose();
//     areaController.dispose();
//     outsideAlcoholController.dispose();
//     startVenueController.dispose();
//     djPolicyController.dispose();
//     spacesController.dispose();
//     super.dispose();
//   }
//
//   // ================= LOAD =================
//   Future<void> _loadCredentialsAndData() async {
//     final prefs = await SharedPreferences.getInstance();
//     vendorId = prefs.getInt('vendorId');
//     serviceId = prefs.getInt('serviceId');
//     vendorSubcategoryId = prefs.getInt('vendor_subcategory_id');
//     token = prefs.getString('token');
//
//     if (vendorId != null && token != null) {
//       await _fetchExistingDataFromAPI();
//     }
//
//     setState(() {});
//   }
//
//   // ================= FETCH =================
//   Future<void> _fetchExistingDataFromAPI() async {
//     setState(() => loading = true);
//
//     try {
//       final data = await _vendorApi.getByVendorId(
//         vendorId: vendorId!,
//         token: token!,
//       );
//
//       if (data == null) return;
//
//       final attributes =
//       Map<String, dynamic>.from(data['attributes'] ?? {});
//
//       _setFieldsFromMap(attributes);
//       await _overwriteLocalCache(attributes);
//     } catch (e) {
//       debugPrint("❌ Facilities fetch error: $e");
//     }
//
//     setState(() => loading = false);
//   }
//
//   // ================= SET UI =================
//   void _setFieldsFromMap(Map<String, dynamic> data) {
//     roomsController.text = data['rooms']?.toString() ?? '';
//     parkingController.text = data['parking'] ?? '';
//     cateringController.text = data['catering_policy'] ?? '';
//     decorController.text = data['decor_policy'] ?? '';
//     offeringsController.text = data['offerings'] ?? '';
//     deliveryController.text = data['delivery_time'] ?? '';
//     travelController.text = data['travel_info'] ?? '';
//     happyWedzSinceController.text = data['happywedz_since'] ?? '';
//     areaController.text = data['area'] ?? '';
//     outsideAlcoholController.text = data['outside_alcohol'] ?? '';
//     startVenueController.text = data['start_venue'] ?? '';
//     spacesController.text = data['space'] ?? '';
//     djPolicyController.text = data['dJ_policy'] ?? '';
//   }
//
//   // ================= LOCAL CACHE =================
//   Future<void> _overwriteLocalCache(Map<String, dynamic> data) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(
//       'facilitiesData_$vendorId',
//       jsonEncode(data),
//     );
//   }
//
//   Future<void> _autosaveLocally() async {
//     if (vendorId == null) return;
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(
//       'facilitiesData_$vendorId',
//       jsonEncode({
//         "rooms": int.tryParse(roomsController.text),
//         "parking": parkingController.text,
//         "catering_policy": cateringController.text,
//         "decor_policy": decorController.text,
//         "offerings": offeringsController.text,
//         "delivery_time": deliveryController.text,
//         "travel_info": travelController.text,
//         "happywedz_since": happyWedzSinceController.text,
//         "area": areaController.text,
//         "outside_alcohol": outsideAlcoholController.text,
//         "start_venue": startVenueController.text,
//         "space": spacesController.text,
//         "dJ_policy": djPolicyController.text,
//       }),
//     );
//   }
//
//   // ================= 🔥 FIXED SAVE LOGIC =================
//   Future<void> _saveData() async {
//     if (vendorId == null || serviceId == null || token == null) return;
//
//     setState(() => saving = true);
//
//     try {
//       // 🔥 Fetch latest attributes (VERY IMPORTANT)
//       final latest = await _vendorApi.getByServiceId(
//         serviceId: serviceId!,
//         token: token!,
//       );
//
//       Map<String, dynamic> attributes =
//       Map<String, dynamic>.from(latest?['attributes'] ?? {});
//
//       // 🔥 Update ONLY facilities fields
//       attributes["rooms"] = int.tryParse(roomsController.text);
//       attributes["parking"] = parkingController.text;
//       attributes["catering_policy"] = cateringController.text;
//       attributes["decor_policy"] = decorController.text;
//       attributes["offerings"] = offeringsController.text;
//       attributes["delivery_time"] = deliveryController.text;
//       attributes["travel_info"] = travelController.text;
//       attributes["happywedz_since"] = happyWedzSinceController.text;
//       attributes["area"] = areaController.text;
//       attributes["outside_alcohol"] = outsideAlcoholController.text;
//       attributes["start_venue"] = startVenueController.text;
//       attributes["space"] = spacesController.text;
//       attributes["dJ_policy"] = djPolicyController.text;
//
//       final body = {
//         "vendor_id": vendorId,
//         if (vendorSubcategoryId != null)
//           "vendor_subcategory_id": vendorSubcategoryId,
//         "attributes": attributes,
//       };
//
//       final success = await _vendorApi.updateService(
//         serviceId: serviceId!,
//         token: token!,
//         body: body,
//       );
//
//       if (success) {
//         await _fetchExistingDataFromAPI();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Facilities details saved successfully"),
//           ),
//         );
//       }
//     } catch (e) {
//       debugPrint("❌ Facilities save error: $e");
//     }
//
//     setState(() => saving = false);
//   }
//
//   // ================= UI (UNCHANGED) =================
//   InputDecoration _inputDecoration(String hint) {
//     return InputDecoration(
//       hintText: hint,
//       contentPadding:
//       const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//       filled: true,
//       fillColor: Colors.grey.shade100,
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: BorderSide.none,
//       ),
//     );
//   }
//
//   Widget _buildTextField(
//       String title,
//       TextEditingController controller,
//       String hint, {
//         int maxLines = 1,
//       }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
//         const SizedBox(height: 8),
//         TextField(
//           controller: controller,
//           maxLines: maxLines,
//           decoration: _inputDecoration(hint),
//         ),
//         const SizedBox(height: 20),
//       ],
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: CommonAppBar(title: "Facilities & Features"),
//       body: loading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Container(
//           padding: const EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(14),
//             boxShadow: const [
//               BoxShadow(
//                 color: Colors.black12,
//                 blurRadius: 8,
//                 offset: Offset(0, 4),
//               )
//             ],
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 "Facilities & Features",
//                 style:
//                 TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
//               ),
//               const SizedBox(height: 20),
//
//               _buildTextField("Number of Rooms", roomsController, ""),
//               _buildTextField("Car Parking", parkingController, ""),
//               _buildTextField(
//                   "Outside Alcohol Policy", outsideAlcoholController, ""),
//               _buildTextField("Catering Policy", cateringController, ""),
//               _buildTextField("Decor Policy", decorController, ""),
//               _buildTextField("Offerings", offeringsController, ""),
//               _buildTextField("Delivery Time", deliveryController, ""),
//               _buildTextField("Travel Info", travelController, ""),
//               _buildTextField(
//                   "HappyWedz Since", happyWedzSinceController, ""),
//               _buildTextField(
//                   "Start Venue", startVenueController, ""),
//               _buildTextField("DJ Policy", djPolicyController, ""),
//               _buildTextField("Space", spacesController, ""),
//               _buildTextField("Area / Capacity", areaController, "",
//                   maxLines: 3),
//
//               const SizedBox(height: 30),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: saving ? null : _saveData,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF00509D),
//                     foregroundColor: Colors.white,
//                     padding:
//                     const EdgeInsets.symmetric(vertical: 14),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   child: saving
//                       ? const CircularProgressIndicator(
//                       color: Colors.white)
//                       : const Text(
//                     "Save Facilities Details",
//                     style: TextStyle(fontSize: 16),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'dart:convert';
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
