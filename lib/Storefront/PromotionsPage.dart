
//
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../api_services/api_service_vendor.dart';
// import '../utils/common_app_bar.dart';
//
// class PromotionsPage extends StatefulWidget {
//   const PromotionsPage({super.key});
//
//   @override
//   State<PromotionsPage> createState() => _PromotionsPageState();
// }
//
// class _PromotionsPageState extends State<PromotionsPage> {
//   final _formKey = GlobalKey<FormState>();
//
//   final TextEditingController _offerTitleController = TextEditingController();
//   final TextEditingController _codeController = TextEditingController();
//   final TextEditingController _valueController = TextEditingController();
//   final TextEditingController _descriptionController = TextEditingController();
//
//   bool _isActive = false;
//   bool _termsAccepted = false;
//   DateTime? _startDate;
//   DateTime? _endDate;
//
//   final VendorServiceApi _vendorApi = VendorServiceApi();
//
//   int? vendorId;
//   int? serviceId;
//   int? vendorSubcategoryId;
//   String? token;
//
//   bool loading = false;
//   bool saving = false;
//
//   List<Map<String, dynamic>> existingPromotions = [];
//   int? editIndex;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadCredentialsAndData();
//   }
//
//   /// 🔹 Rounded Border
//   OutlineInputBorder _roundedBorder() {
//     return OutlineInputBorder(
//       borderRadius: BorderRadius.circular(12),
//     );
//   }
//
//   /// 🔹 Compact Input Decoration
//   InputDecoration _inputDecoration(String label,
//       {Widget? suffixIcon, String? suffixText}) {
//     return InputDecoration(
//       labelText: label,
//       border: _roundedBorder(),
//       enabledBorder: _roundedBorder(),
//       focusedBorder: _roundedBorder(),
//       suffixIcon: suffixIcon,
//       suffixText: suffixText,
//       contentPadding:
//       const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
//     );
//   }
//
//   Future<void> _loadCredentialsAndData() async {
//     final prefs = await SharedPreferences.getInstance();
//     vendorId = prefs.getInt('vendorId');
//     token = prefs.getString('token');
//     serviceId = prefs.getInt('serviceId');
//     vendorSubcategoryId = prefs.getInt('vendor_subcategory_id');
//
//     if (serviceId != null && token != null) {
//       await _fetchExistingPromotions();
//     }
//   }
//
//   Future<void> _fetchExistingPromotions() async {
//     setState(() => loading = true);
//     try {
//       final data = await _vendorApi.getByServiceId(
//         serviceId: serviceId!,
//         token: token!,
//       );
//
//       final attributes = Map<String, dynamic>.from(data?['attributes'] ?? {});
//       final deals = attributes['deals'] ?? [];
//
//       setState(() {
//         existingPromotions = List<Map<String, dynamic>>.from(deals);
//       });
//     } catch (e) {
//       debugPrint("❌ Fetch promotions error: $e");
//     }
//     setState(() => loading = false);
//   }
//
//   Future<void> _savePromotion() async {
//     if (!_termsAccepted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please accept terms")),
//       );
//       return;
//     }
//
//     setState(() => saving = true);
//
//     final latest = await _vendorApi.getByServiceId(
//       serviceId: serviceId!,
//       token: token!,
//     );
//
//     Map<String, dynamic> attributes =
//     Map<String, dynamic>.from(latest?["attributes"] ?? {});
//
//     final promotionData = {
//       "title": _offerTitleController.text.trim(),
//       "code": _codeController.text.trim(),
//       "value": int.tryParse(_valueController.text.trim()),
//       "description": _descriptionController.text.trim(),
//       "active": _isActive,
//       "startDate": _startDate?.toIso8601String(),
//       "endDate": _endDate?.toIso8601String(),
//     };
//
//     List<Map<String, dynamic>> deals =
//     List<Map<String, dynamic>>.from(attributes["deals"] ?? []);
//
//     if (editIndex == null) {
//       deals.add(promotionData);
//     } else {
//       deals[editIndex!] = promotionData;
//       editIndex = null;
//     }
//
//     attributes["deals"] = deals;
//
//     final success = await _vendorApi.updateService(
//       serviceId: serviceId!,
//       token: token!,
//       body: {
//         "vendor_id": vendorId,
//         "vendor_subcategory_id": vendorSubcategoryId,
//         "attributes": attributes,
//       },
//     );
//
//     if (success) {
//       setState(() => existingPromotions = deals);
//       _resetForm();
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Promotion saved successfully")),
//       );
//     }
//
//     setState(() => saving = false);
//   }
//
//   Future<void> _deletePromotion(int index) async {
//     setState(() => saving = true);
//
//     final latest = await _vendorApi.getByServiceId(
//       serviceId: serviceId!,
//       token: token!,
//     );
//
//     Map<String, dynamic> attributes =
//     Map<String, dynamic>.from(latest?["attributes"] ?? {});
//     List<Map<String, dynamic>> deals =
//     List<Map<String, dynamic>>.from(attributes["deals"] ?? []);
//
//     deals.removeAt(index);
//     attributes["deals"] = deals;
//
//     final success = await _vendorApi.updateService(
//       serviceId: serviceId!,
//       token: token!,
//       body: {
//         "vendor_id": vendorId,
//         "vendor_subcategory_id": vendorSubcategoryId,
//         "attributes": attributes,
//       },
//     );
//
//     if (success) {
//       setState(() => existingPromotions = deals);
//     }
//
//     setState(() => saving = false);
//   }
//
//   void _resetForm() {
//     _offerTitleController.clear();
//     _codeController.clear();
//     _valueController.clear();
//     _descriptionController.clear();
//     setState(() {
//       _isActive = false;
//       _termsAccepted = false;
//       _startDate = null;
//       _endDate = null;
//       editIndex = null;
//     });
//   }
//
//   Future<void> _pickDate({required bool isStart}) async {
//     DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(2023),
//       lastDate: DateTime(2035),
//     );
//
//     if (picked != null) {
//       setState(() {
//         if (isStart) {
//           _startDate = picked;
//         } else {
//           _endDate = picked;
//         }
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: CommonAppBar(title: 'Promotion Details'),
//       body: loading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             /// Existing Promotions
//             if (existingPromotions.isNotEmpty) ...[
//               const Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(
//                   "Existing Offers",
//                   style: TextStyle(
//                       fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//               ),
//               const SizedBox(height: 10),
//               ...existingPromotions.asMap().entries.map((entry) {
//                 int index = entry.key;
//                 var promo = entry.value;
//                 return Card(
//                   elevation: 3,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(14),
//                   ),
//                   child: ListTile(
//                     title: Text(promo["title"] ?? ""),
//                     subtitle:
//                     Text("Code: ${promo["code"] ?? ""}"),
//                     trailing: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         IconButton(
//                           icon: const Icon(Icons.edit,
//                               color: Colors.blue),
//                           onPressed: () {
//                             setState(() {
//                               editIndex = index;
//                               _offerTitleController.text =
//                                   promo["title"] ?? "";
//                               _codeController.text =
//                                   promo["code"] ?? "";
//                               _valueController.text =
//                                   promo["value"]?.toString() ?? "";
//                               _descriptionController.text =
//                                   promo["description"] ?? "";
//                               _isActive = promo["active"] ?? false;
//                               _termsAccepted = true;
//                             });
//                           },
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.delete,
//                               color: Colors.red),
//                           onPressed: () => _deletePromotion(index),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               }),
//               const SizedBox(height: 20),
//             ],
//
//             TextFormField(
//               controller: _offerTitleController,
//               decoration: _inputDecoration("Offer Title"),
//             ),
//             const SizedBox(height: 12),
//
//             TextFormField(
//               controller: _codeController,
//               decoration: _inputDecoration("Promo Code"),
//             ),
//             const SizedBox(height: 12),
//
//             Row(
//               children: [
//                 Switch(
//                   value: _isActive,
//                   onChanged: (v) =>
//                       setState(() => _isActive = v),
//                 ),
//                 Text(_isActive ? "Active" : "Inactive"),
//               ],
//             ),
//
//             const SizedBox(height: 12),
//             TextFormField(
//               controller: _valueController,
//               keyboardType: TextInputType.number,
//               decoration: _inputDecoration(
//                 "Discount Value",
//                 suffixText: "%",
//               ),
//             ),
//
//             const SizedBox(height: 12),
//             TextFormField(
//               readOnly: true,
//               decoration: _inputDecoration(
//                 "Start Date",
//                 suffixIcon: IconButton(
//                   icon: const Icon(Icons.calendar_today, size: 20),
//                   onPressed: () => _pickDate(isStart: true),
//                 ),
//               ),
//               controller: TextEditingController(
//                 text: _startDate != null
//                     ? DateFormat("dd-MM-yyyy")
//                     .format(_startDate!)
//                     : "",
//               ),
//             ),
//
//             const SizedBox(height: 12),
//             TextFormField(
//               readOnly: true,
//               decoration: _inputDecoration(
//                 "End Date",
//                 suffixIcon: IconButton(
//                   icon: const Icon(Icons.calendar_today, size: 20),
//                   onPressed: () => _pickDate(isStart: false),
//                 ),
//               ),
//               controller: TextEditingController(
//                 text: _endDate != null
//                     ? DateFormat("dd-MM-yyyy")
//                     .format(_endDate!)
//                     : "",
//               ),
//             ),
//
//             const SizedBox(height: 12),
//             TextFormField(
//               controller: _descriptionController,
//               maxLines: 3,
//               decoration: _inputDecoration("Description"),
//             ),
//
//             CheckboxListTile(
//               value: _termsAccepted,
//               onChanged: (v) =>
//                   setState(() => _termsAccepted = v ?? false),
//               title:
//               const Text("I confirm this offer and its terms"),
//             ),
//             SizedBox(
//               width: double.infinity,
//               child: OutlinedButton.icon(
//                 onPressed: () {
//                   _resetForm();
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text("Form reset successfully")),
//                   );
//                 },
//                 icon: const Icon(Icons.refresh, color: Color(0xFF00509D)),
//                 label: const Text(
//                   "Reset Form",
//                   style: TextStyle(
//                     color: Color(0xFF00509D),
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 style: OutlinedButton.styleFrom(
//                   side: const BorderSide(color: Color(0xFF00509D)),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   padding: const EdgeInsets.symmetric(vertical: 14),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 12),
//
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: saving ? null : _savePromotion,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF00509D),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   padding:
//                   const EdgeInsets.symmetric(vertical: 14),
//                 ),
//                 child: saving
//                     ? const SizedBox(
//                   height: 22,
//                   width: 22,
//                   child: CircularProgressIndicator(
//                     color: Colors.white,
//                     strokeWidth: 2,
//                   ),
//                 )
//                     : Text(
//                   editIndex == null
//                       ? "Save Promotion"
//                       : "Update Promotion",
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_services/api_service_vendor.dart';
import '../api_services/storefront_completion_service.dart';
import '../utils/common_app_bar.dart';
import '../widgets/app_shimmer.dart';

class PromotionsPage extends StatefulWidget {
  const PromotionsPage({super.key});

  @override
  State<PromotionsPage> createState() => _PromotionsPageState();
}

class _PromotionsPageState extends State<PromotionsPage> {
  /// AUDIT NOTE: this promotions form declares a form key but never wraps
  /// its fields in a `Form`, so `validate()` is never called and the fields
  /// have no validation at all (flagged `unused_field`). KEPT so the key is
  /// in place when the fields are wrapped in a Form — see the audit report's
  /// Forms section. Do not delete without project-owner approval.
  // ignore: unused_field
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _offerTitleController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isActive = false;
  bool _termsAccepted = false;
  DateTime? _startDate;
  DateTime? _endDate;

  final VendorServiceApi _vendorApi = VendorServiceApi();

  int? vendorId;
  int? serviceId;
  int? vendorSubcategoryId;
  String? token;

  bool loading = false;
  bool saving = false;

  List<Map<String, dynamic>> existingPromotions = [];
  int? editIndex;

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    _loadCredentialsAndData();
  }

  /// 🔥 VERY IMPORTANT
  /// Page open / revisit par fresh promotions load honge
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (serviceId != null && token != null) {
      _fetchExistingPromotions();
    }
  }

  // ================= LOAD CREDENTIALS =================
  Future<void> _loadCredentialsAndData() async {
    final prefs = await SharedPreferences.getInstance();
    vendorId = prefs.getInt('vendorId');
    token = prefs.getString('token');
    serviceId = prefs.getInt('serviceId');
    vendorSubcategoryId = prefs.getInt('vendor_subcategory_id');

    if (serviceId != null && token != null) {
      await _fetchExistingPromotions();
    }
  }

  // ================= FETCH PROMOTIONS =================
  Future<void> _fetchExistingPromotions() async {
    setState(() => loading = true);

    try {
      final data = await _vendorApi.getByServiceId(
        serviceId: serviceId!,
        token: token!,
      );

      final attributes =
      Map<String, dynamic>.from(data?['attributes'] ?? {});

      /// 🔥 WEBSITE + APP SAME KEY
      final deals = attributes['deals'] ?? [];

      setState(() {
        existingPromotions =
        List<Map<String, dynamic>>.from(deals);
      });
    } catch (e) {
      debugPrint("❌ Fetch promotions error: $e");
    }

    setState(() => loading = false);
  }

  // ================= SAVE / UPDATE PROMOTION =================
  Future<void> _savePromotion() async {
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please accept terms")),
      );
      return;
    }

    setState(() => saving = true);

    try {
      /// 🔥 fetch latest attributes (SAFE MERGE)
      final latest = await _vendorApi.getByServiceId(
        serviceId: serviceId!,
        token: token!,
      );

      Map<String, dynamic> attributes =
      Map<String, dynamic>.from(latest?["attributes"] ?? {});

      final promotionData = {
        "title": _offerTitleController.text.trim(),
        "code": _codeController.text.trim(),
        "value": int.tryParse(_valueController.text.trim()),
        "description": _descriptionController.text.trim(),
        "active": _isActive,
        "startDate": _startDate?.toIso8601String(),
        "endDate": _endDate?.toIso8601String(),
      };

      List<Map<String, dynamic>> deals =
      List<Map<String, dynamic>>.from(attributes["deals"] ?? []);

      if (editIndex == null) {
        deals.add(promotionData);
      } else {
        deals[editIndex!] = promotionData;
        editIndex = null;
      }

      attributes["deals"] = deals;

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
        setState(() => existingPromotions = deals);
        _resetForm();
        // AUDIT FIX: context used after an await — guard added.
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Promotion saved successfully")),
        );
      }
    } catch (e) {
      debugPrint("❌ Save promotion error: $e");
    }

    setState(() => saving = false);
  }

  // ================= DELETE =================
  Future<void> _deletePromotion(int index) async {
    setState(() => saving = true);

    try {
      final latest = await _vendorApi.getByServiceId(
        serviceId: serviceId!,
        token: token!,
      );

      Map<String, dynamic> attributes =
      Map<String, dynamic>.from(latest?["attributes"] ?? {});
      List<Map<String, dynamic>> deals =
      List<Map<String, dynamic>>.from(attributes["deals"] ?? []);

      deals.removeAt(index);
      attributes["deals"] = deals;

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
        setState(() => existingPromotions = deals);
      }
    } catch (e) {
      debugPrint("❌ Delete promotion error: $e");
    }

    setState(() => saving = false);
  }

  // ================= HELPERS =================
  void _resetForm() {
    _offerTitleController.clear();
    _codeController.clear();
    _valueController.clear();
    _descriptionController.clear();
    setState(() {
      _isActive = false;
      _termsAccepted = false;
      _startDate = null;
      _endDate = null;
      editIndex = null;
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() {
        isStart ? _startDate = picked : _endDate = picked;
      });
    }
  }

  OutlineInputBorder _border() =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(12));

  InputDecoration _dec(String label,
      {Widget? suffixIcon, String? suffixText}) {
    return InputDecoration(
      labelText: label,
      border: _border(),
      enabledBorder: _border(),
      focusedBorder: _border(),
      suffixIcon: suffixIcon,
      suffixText: suffixText,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(title: 'Promotion Details'),
      body: loading
          ? const FormShimmer(fields: 4)
          : RefreshIndicator(
        onRefresh: _fetchExistingPromotions,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    /// EXISTING PROMOTIONS
                    if (existingPromotions.isNotEmpty) ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Existing Offers",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...existingPromotions.asMap().entries.map((entry) {
                        int index = entry.key;
                        var promo = entry.value;
                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ListTile(
                            title: Text(promo["title"] ?? ""),
                            subtitle:
                            Text("Code: ${promo["code"] ?? ""}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blue),
                                  onPressed: () {
                                    setState(() {
                                      editIndex = index;
                                      _offerTitleController.text =
                                          promo["title"] ?? "";
                                      _codeController.text =
                                          promo["code"] ?? "";
                                      _valueController.text =
                                          promo["value"]?.toString() ?? "";
                                      _descriptionController.text =
                                          promo["description"] ?? "";
                                      _isActive = promo["active"] ?? false;
                                      _termsAccepted = true;
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () =>
                                      _deletePromotion(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
                    ],

                    TextFormField(
                      controller: _offerTitleController,
                      decoration: _dec("Offer Title"),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _codeController,
                      decoration: _dec("Promo Code"),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Switch(
                          value: _isActive,
                          onChanged: (v) =>
                              setState(() => _isActive = v),
                        ),
                        Text(_isActive ? "Active" : "Inactive"),
                      ],
                    ),

                    TextFormField(
                      controller: _valueController,
                      keyboardType: TextInputType.number,
                      decoration: _dec("Discount Value", suffixText: "%"),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      readOnly: true,
                      controller: TextEditingController(
                        text: _startDate != null
                            ? DateFormat("dd-MM-yyyy")
                            .format(_startDate!)
                            : "",
                      ),
                      decoration: _dec(
                        "Start Date",
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () =>
                              _pickDate(isStart: true),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      readOnly: true,
                      controller: TextEditingController(
                        text: _endDate != null
                            ? DateFormat("dd-MM-yyyy")
                            .format(_endDate!)
                            : "",
                      ),
                      decoration: _dec(
                        "End Date",
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () =>
                              _pickDate(isStart: false),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: _dec("Description"),
                    ),

                    CheckboxListTile(
                      value: _termsAccepted,
                      onChanged: (v) =>
                          setState(() => _termsAccepted = v ?? false),
                      title: const Text(
                          "I confirm this offer and its terms"),
                    ),

                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saving ? null : _savePromotion,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Color(0xFF00509D),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  child: saving
                      ? const CircularProgressIndicator(
                      color: Colors.white)
                      : Text(
                    editIndex == null
                        ? "Save Promotion"
                        : "Update Promotion",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16),
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
