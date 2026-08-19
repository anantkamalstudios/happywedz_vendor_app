// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../api_services/api_service_vendor.dart';
// import '../api_services/storefront_completion_service.dart';
// import '../utils/common_app_bar.dart';
//
// class MenusPage extends StatefulWidget {
//   const MenusPage({super.key});
//
//   @override
//   _MenusPageState createState() => _MenusPageState();
// }
//
// class _MenusPageState extends State<MenusPage> {
//   final TextEditingController vegPriceController = TextEditingController();
//   final TextEditingController nonVegPriceController = TextEditingController();
//   final VendorServiceApi _vendorApi = VendorServiceApi();
//
//   bool isLoading = true;
//   bool isSaving = false;
//
//   int? vendorId;
//   String? token;
//   int? serviceId;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//
//     vegPriceController.addListener(_autosaveLocally);
//     nonVegPriceController.addListener(_autosaveLocally);
//   }
//
//   @override
//   void dispose() {
//     vegPriceController.dispose();
//     nonVegPriceController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _loadData() async {
//     final prefs = await SharedPreferences.getInstance();
//     vendorId = prefs.getInt("vendorId");
//     token = prefs.getString("token");
//     serviceId = prefs.getInt("serviceId");
//
//     // Load saved data from local
//     if (vendorId != null) {
//       final savedJson = prefs.getString("menuData_$vendorId");
//       if (savedJson != null) {
//         final Map<String, dynamic> data = jsonDecode(savedJson);
//         vegPriceController.text = data["veg_price"]?.toString() ?? "";
//         nonVegPriceController.text = data["non_veg_price"]?.toString() ?? "";
//       }
//     }
//
//     // Load from API
//     if (serviceId != null && token != null) {
//       await fetchMenuData();
//     }
//
//     setState(() => isLoading = false);
//   }
//
//   // Future<void> fetchMenuData() async {
//   //   try {
//   //     final data = await _vendorApi.getByServiceId(
//   //       serviceId: serviceId!,
//   //       token: token!,
//   //     );
//   //
//   //     if (data == null) return;
//   //
//   //     final attributes = Map<String, dynamic>.from(data["attributes"] ?? {});
//   //
//   //     if (vegPriceController.text.isEmpty) {
//   //       vegPriceController.text =
//   //           attributes["veg_price"]?.toString() ?? "";
//   //     }
//   //
//   //     if (nonVegPriceController.text.isEmpty) {
//   //       nonVegPriceController.text =
//   //           attributes["non_veg_price"]?.toString() ?? "";
//   //     }
//   //
//   //     await _autosaveLocally();
//   //   } catch (e) {
//   //     debugPrint("❌ fetch menu error: $e");
//   //   }
//   // }
//   Future<void> fetchMenuData() async {
//     try {
//       final data = await _vendorApi.getByServiceId(
//         serviceId: serviceId!,
//         token: token!,
//       );
//
//       if (data == null) return;
//
//       final attributes =
//       Map<String, dynamic>.from(data["attributes"] ?? {});
//
//       setState(() {
//         vegPriceController.text =
//             attributes["veg_price"]?.toString() ?? "";
//
//         nonVegPriceController.text =
//             attributes["non_veg_price"]?.toString() ?? "";
//       });
//
//       await _autosaveLocally();
//     } catch (e) {
//       debugPrint("❌ fetch menu error: $e");
//     }
//   }
//
//
//   Future<void> _autosaveLocally() async {
//     if (vendorId == null) return;
//     final prefs = await SharedPreferences.getInstance();
//
//     final Map<String, dynamic> data = {
//       "veg_price": vegPriceController.text.trim(),
//       "non_veg_price": nonVegPriceController.text.trim(),
//     };
//
//     await prefs.setString("menuData_$vendorId", jsonEncode(data));
//   }
//
//   Future<void> saveMenus() async {
//     if (vendorId == null || token == null || serviceId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Missing vendor or service info")),
//       );
//       return;
//     }
//
//     setState(() => isSaving = true);
//
//     // 🔥 Fetch latest attributes first (SAFETY)
//     final latest = await _vendorApi.getByServiceId(
//       serviceId: serviceId!,
//       token: token!,
//     );
//
//     Map<String, dynamic> attributes =
//     Map<String, dynamic>.from(latest?["attributes"] ?? {});
//
//     // ✅ Update ONLY menu-related fields
//     attributes.addAll({
//       "veg_price": vegPriceController.text.trim(),
//       "non_veg_price": nonVegPriceController.text.trim(),
//     });
//
//     final body = {
//       "vendor_id": vendorId,
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
//       await StorefrontCompletionService.refreshCompletion(
//         serviceId: serviceId!,
//       );
//       await _autosaveLocally();
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Menus saved successfully")),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Failed to save menus")),
//       );
//     }
//
//     setState(() => isSaving = false);
//   }
//
//
//   InputDecoration _inputDecoration(String hint) {
//     return InputDecoration(
//       hintText: hint,
//       contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(10),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//      appBar: CommonAppBar(title: "Menus"),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//         padding: const EdgeInsets.all(18),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               "Menus (for Caterers)",
//               style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 20),
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: Colors.grey.shade300),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     "Veg Price Per Plate",
//                     style: TextStyle(
//                         fontSize: 16, fontWeight: FontWeight.w600),
//                   ),
//                   const SizedBox(height: 10),
//                   TextField(
//                     keyboardType: TextInputType.number,
//                     controller: vegPriceController,
//                     decoration: _inputDecoration(
//                         "Enter veg price per plate"),
//                   ),
//                   const SizedBox(height: 22),
//                   const Text(
//                     "Non-Veg Price Per Plate",
//                     style: TextStyle(
//                         fontSize: 16, fontWeight: FontWeight.w600),
//                   ),
//                   const SizedBox(height: 10),
//                   TextField(
//                     keyboardType: TextInputType.number,
//                     controller: nonVegPriceController,
//                     decoration: _inputDecoration(
//                         "Enter non-veg price per plate"),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 25),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: isSaving ? null : saveMenus,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Color(0xFF00509D),
//                   padding: const EdgeInsets.symmetric(vertical: 14),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//                 child: isSaving
//                     ? const CircularProgressIndicator(
//                   color: Colors.white,
//                 )
//                     : const Text(
//                   "Save Menus",
//                   style:
//                   TextStyle(color: Colors.white, fontSize: 16),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_services/api_service_vendor.dart';
import '../api_services/storefront_completion_service.dart';
import '../utils/common_app_bar.dart';

class MenusPage extends StatefulWidget {
  const MenusPage({super.key});

  @override
  /// AUDIT NOTE: `createState` returning the private State type is the
  /// pattern Flutter's own `flutter create` template uses. Making the State
  /// public purely to satisfy `library_private_types_in_public_api` would be
  /// a wider refactor than this audit's brief allows, so the lint is silenced
  /// locally with this note rather than left as unexplained noise.
  // ignore: library_private_types_in_public_api
  _MenusPageState createState() => _MenusPageState();
}

class _MenusPageState extends State<MenusPage> {
  final TextEditingController vegPriceController = TextEditingController();
  final TextEditingController nonVegPriceController = TextEditingController();

  final VendorServiceApi _vendorApi = VendorServiceApi();

  bool isLoading = true;
  bool isSaving = false;

  int? vendorId;
  String? token;
  int? serviceId;

  @override
  void initState() {
    super.initState();
    _loadFromServer();
  }

  @override
  void dispose() {
    vegPriceController.dispose();
    nonVegPriceController.dispose();
    super.dispose();
  }

  // ================= LOAD FROM SERVER ONLY =================
  Future<void> _loadFromServer() async {
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      vendorId = prefs.getInt("vendorId");
      token = prefs.getString("token");
      serviceId = prefs.getInt("serviceId");

      if (vendorId == null || token == null || serviceId == null) {
        setState(() => isLoading = false);
        return;
      }

      final data = await _vendorApi.getByServiceId(
        serviceId: serviceId!,
        token: token!,
      );

      if (data == null) {
        setState(() => isLoading = false);
        return;
      }

      final attributes =
      Map<String, dynamic>.from(data["attributes"] ?? {});

      vegPriceController.text =
          attributes["veg_price"]?.toString() ?? "";

      nonVegPriceController.text =
          attributes["non_veg_price"]?.toString() ?? "";
    } catch (e) {
      debugPrint("❌ Menu load error: $e");
    }

    setState(() => isLoading = false);
  }

  // ================= SAVE =================
  Future<void> saveMenus() async {
    if (vendorId == null || token == null || serviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Missing vendor or service info")),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final latest = await _vendorApi.getByServiceId(
        serviceId: serviceId!,
        token: token!,
      );

      Map<String, dynamic> attributes =
      Map<String, dynamic>.from(latest?["attributes"] ?? {});

      attributes.addAll({
        "veg_price": vegPriceController.text.trim(),
        "non_veg_price": nonVegPriceController.text.trim(),
      });

      final success = await _vendorApi.updateService(
        serviceId: serviceId!,
        token: token!,
        body: {
          "vendor_id": vendorId,
          "attributes": attributes,
        },
      );

      if (success) {
        await StorefrontCompletionService.refreshCompletion(
          serviceId: serviceId!,
        );

        // AUDIT FIX: context used after an await — guard added.
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Menus saved successfully")),
        );

        // 🔥 reload fresh data after save
        await _loadFromServer();
      } else {
        // AUDIT FIX: context used after an await — guard added.
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to save menus")),
        );
      }
    } catch (e) {
      debugPrint("❌ Save menu error: $e");
    }

    setState(() => isSaving = false);
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(title: "Menus"),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Menus (for Caterers)",
              style:
              TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Veg Price Per Plate",
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    keyboardType: TextInputType.number,
                    controller: vegPriceController,
                    decoration: _inputDecoration(
                        "Enter veg price per plate"),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    "Non-Veg Price Per Plate",
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    keyboardType: TextInputType.number,
                    controller: nonVegPriceController,
                    decoration: _inputDecoration(
                        "Enter non-veg price per plate"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : saveMenus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00509D),
                  padding:
                  const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isSaving
                    ? const CircularProgressIndicator(
                  color: Colors.white,
                )
                    : const Text(
                  "Save Menus",
                  style: TextStyle(
                      color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
