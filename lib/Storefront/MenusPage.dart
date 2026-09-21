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
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/common_app_bar.dart';
import '../widgets/app_shimmer.dart';

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
  final TextEditingController vegDescController = TextEditingController();
  final TextEditingController nonVegDescController = TextEditingController();

  /// One controller per dish. The server stores these as a plain list of
  /// strings inside `attributes.menus[n].items`.
  List<TextEditingController> vegItemControllers = [TextEditingController()];
  List<TextEditingController> nonVegItemControllers = [TextEditingController()];

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
    vegDescController.dispose();
    nonVegDescController.dispose();
    for (final c in vegItemControllers) {
      c.dispose();
    }
    for (final c in nonVegItemControllers) {
      c.dispose();
    }
    super.dispose();
  }

  /// Picks the veg / non-veg entry out of `attributes.menus`, falling back to
  /// position when the rows have no `type` — the same lookup the website does.
  Map<String, dynamic> _menuOfType(List<dynamic> menus, String type, int index) {
    for (final m in menus) {
      if (m is Map && m['type'] == type) return Map<String, dynamic>.from(m);
    }
    if (menus.length > index && menus[index] is Map) {
      return Map<String, dynamic>.from(menus[index] as Map);
    }
    return {};
  }

  List<TextEditingController> _itemControllers(dynamic items) {
    final list = (items is List ? items : const [])
        .map((e) => '$e')
        .where((e) => e.trim().isNotEmpty)
        .toList();
    if (list.isEmpty) return [TextEditingController()];
    return list.map((e) => TextEditingController(text: e)).toList();
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

      final menus = List<dynamic>.from(attributes["menus"] ?? const []);
      final veg = _menuOfType(menus, "veg", 0);
      final nonVeg = _menuOfType(menus, "non-veg", 1);

      vegPriceController.text =
          (attributes["veg_price"] ?? veg["price"] ?? "").toString();
      nonVegPriceController.text =
          (attributes["non_veg_price"] ?? nonVeg["price"] ?? "").toString();

      vegDescController.text = (attributes["veg_description"] ??
              veg["description"] ??
              attributes["menu_description"] ??
              "")
          .toString();
      nonVegDescController.text =
          (attributes["non_veg_description"] ?? nonVeg["description"] ?? "")
              .toString();

      for (final c in vegItemControllers) {
        c.dispose();
      }
      for (final c in nonVegItemControllers) {
        c.dispose();
      }
      vegItemControllers = _itemControllers(veg["items"]);
      nonVegItemControllers = _itemControllers(nonVeg["items"]);
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

      final vegPrice = vegPriceController.text.trim();
      final nonVegPrice = nonVegPriceController.text.trim();
      final vegDesc = vegDescController.text.trim();
      final nonVegDesc = nonVegDescController.text.trim();

      // Blank rows are dropped rather than saved as empty dishes.
      List<String> dishes(List<TextEditingController> controllers) => controllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      attributes.addAll({
        "veg_price": vegPrice,
        "non_veg_price": nonVegPrice,
        "veg_description": vegDesc,
        "non_veg_description": nonVegDesc,
        // Kept for older readers that only know about a single description.
        "menu_description": vegDesc.isNotEmpty ? vegDesc : nonVegDesc,
        "menus": [
          {
            "title": "Veg Menu",
            "type": "veg",
            "price": vegPrice,
            "description": vegDesc,
            "items": dishes(vegItemControllers),
          },
          {
            "title": "Non-Veg Menu",
            "type": "non-veg",
            "price": nonVegPrice,
            "description": nonVegDesc,
            "items": dishes(nonVegItemControllers),
          },
        ],
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

  /// One menu (veg or non-veg): price, description and the list of dishes —
  /// the same three blocks the website's `VendorMenus.jsx` renders per card.
  Widget _menuCard({
    required String badge,
    required String title,
    required Color accent,
    required Color accentTint,
    required String priceLabel,
    required String priceHint,
    required TextEditingController priceController,
    required String descLabel,
    required String descHint,
    required TextEditingController descController,
    required String itemsLabel,
    required String itemHint,
    required String addLabel,
    required List<TextEditingController> controllers,
    required VoidCallback onAdd,
    required void Function(int) onRemove,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentTint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(badge,
                    style: AppTextStyles.caption
                        .copyWith(color: accent, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: AppTextStyles.h3.copyWith(color: accent)),
            ],
          ),
          const SizedBox(height: 16),

          Text(priceLabel, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 8),
          TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration(priceHint),
          ),
          const SizedBox(height: 16),

          Text(descLabel, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 8),
          TextField(
            controller: descController,
            maxLines: 3,
            decoration: _inputDecoration(descHint),
          ),
          const SizedBox(height: 16),

          Text(itemsLabel, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 8),
          for (int i = 0; i < controllers.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controllers[i],
                      decoration: _inputDecoration(itemHint),
                    ),
                  ),
                  IconButton(
                    onPressed: () => onRemove(i),
                    tooltip: 'Remove',
                    icon: const Icon(Icons.close, color: AppColors.error),
                  ),
                ],
              ),
            ),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: Text(addLabel),
            style: OutlinedButton.styleFrom(
              foregroundColor: accent,
              side: BorderSide(color: accent),
              minimumSize: const Size(0, 40),
            ),
          ),
        ],
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
          ? const FormShimmer(fields: 5)
          : SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _menuCard(
              badge: "Veg",
              title: "Veg Menu",
              accent: AppColors.success,
              accentTint: AppColors.successTint,
              priceLabel: "Veg Price Per Plate",
              priceHint: "e.g. 565",
              priceController: vegPriceController,
              descLabel: "Veg Menu Description",
              descHint:
                  "Enter description for vegetarian menu, cuisine offerings, specialties, courses included...",
              descController: vegDescController,
              itemsLabel: "Veg Menu Items",
              itemHint: "e.g. Paneer Butter Masala, Dal Makhani, Gulab Jamun",
              addLabel: "Add Veg Item",
              controllers: vegItemControllers,
              onAdd: () => setState(
                  () => vegItemControllers.add(TextEditingController())),
              onRemove: (i) => setState(() {
                vegItemControllers.removeAt(i).dispose();
                if (vegItemControllers.isEmpty) {
                  vegItemControllers.add(TextEditingController());
                }
              }),
            ),

            const SizedBox(height: 18),

            _menuCard(
              badge: "Non-Veg",
              title: "Non-Veg Menu",
              accent: AppColors.error,
              accentTint: AppColors.errorTint,
              priceLabel: "Non-Veg Price Per Plate",
              priceHint: "e.g. 665",
              priceController: nonVegPriceController,
              descLabel: "Non-Veg Menu Description",
              descHint:
                  "Enter description for non-vegetarian menu, chicken/mutton dishes, seafood, courses included...",
              descController: nonVegDescController,
              itemsLabel: "Non-Veg Menu Items",
              itemHint: "e.g. Chicken Tikka, Mutton Rogan Josh, Biryani",
              addLabel: "Add Non-Veg Item",
              controllers: nonVegItemControllers,
              onAdd: () => setState(
                  () => nonVegItemControllers.add(TextEditingController())),
              onRemove: (i) => setState(() {
                nonVegItemControllers.removeAt(i).dispose();
                if (nonVegItemControllers.isEmpty) {
                  nonVegItemControllers.add(TextEditingController());
                }
              }),
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
