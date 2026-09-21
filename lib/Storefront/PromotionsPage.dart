
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
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
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

  bool _isActive = true;
  bool _termsAccepted = false;
  DateTime? _startDate;
  DateTime? _endDate;

  /// "percentage" or "fixed" — the website stores this on every deal and
  /// renders "10% OFF" or "₹5,000 OFF" from it. Without it a fixed-amount
  /// offer cannot be created here at all.
  String _discountType = 'percentage';

  /// Field name -> message, shown under the field it belongs to.
  Map<String, String> _errors = {};

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

  /// Mirrors the website's `validate()` — every rule it enforces, enforced here.
  bool _validate() {
    final errs = <String, String>{};

    if (_offerTitleController.text.trim().isEmpty) {
      errs['title'] = 'Offer title is required.';
    }
    if (_codeController.text.trim().isEmpty) {
      errs['code'] = 'Promo code is required.';
    }

    final value = num.tryParse(_valueController.text.trim());
    if (value == null || value <= 0) {
      errs['value'] = 'Enter a valid positive discount value.';
    }

    if (_startDate == null) errs['startDate'] = 'Start date is required.';
    if (_endDate == null) errs['endDate'] = 'End date is required.';
    if (_startDate != null && _endDate != null && _startDate!.isAfter(_endDate!)) {
      errs['endDate'] = 'End date cannot be earlier than start date.';
    }

    if (!_termsAccepted) errs['terms'] = 'You must confirm this offer.';

    setState(() => _errors = errs);
    return errs.isEmpty;
  }

  // ================= SAVE / UPDATE PROMOTION =================
  Future<void> _savePromotion() async {
    if (!_validate()) return;

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
        "type": _discountType,
        // Kept as typed: `int.tryParse` turned "10.5" into null, silently
        // dropping the discount.
        "value": _valueController.text.trim(),
        "description": _descriptionController.text.trim(),
        "active": _isActive,
        // Plain YYYY-MM-DD, the shape the website writes and prints. A full
        // ISO timestamp showed up as "2026-03-05T00:00:00.000" in its table.
        "startDate": _formatDate(_startDate),
        "endDate": _formatDate(_endDate),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this promotion?'),
        content: const Text('This will remove the offer from your storefront.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Yes, delete it'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

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
  String? _formatDate(DateTime? d) =>
      d == null ? null : DateFormat('yyyy-MM-dd').format(d);

  /// Accepts both the website's `YYYY-MM-DD` and the full ISO timestamps this
  /// screen used to write, so older promotions still open for editing.
  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  String _discountLabel(Map promo) {
    final value = promo['value']?.toString() ?? '';
    if (value.isEmpty) return '—';
    if (promo['type'] == 'fixed') {
      final n = num.tryParse(value);
      final pretty = n == null ? value : NumberFormat.decimalPattern('en_IN').format(n);
      return '₹$pretty OFF';
    }
    return '$value% OFF';
  }

  /// Loads an existing offer into the form. The old version copied the title,
  /// code, value, description and status but NOT the dates — so editing an
  /// offer and saving wiped its validity period.
  void _startEditing(int index, Map<String, dynamic> promo) {
    setState(() {
      editIndex = index;
      _offerTitleController.text = promo['title']?.toString() ?? '';
      _codeController.text =
          (promo['code'] ?? promo['promoCode'] ?? '').toString();
      _valueController.text = promo['value']?.toString() ?? '';
      _descriptionController.text = promo['description']?.toString() ?? '';
      _discountType = promo['type']?.toString() == 'fixed' ? 'fixed' : 'percentage';
      _isActive = promo['active'] != false;
      _startDate = _parseDate(promo['startDate']);
      _endDate = _parseDate(promo['endDate']);
      _termsAccepted = true;
      _errors = {};
    });
  }

  void _resetForm() {
    _offerTitleController.clear();
    _codeController.clear();
    _valueController.clear();
    _descriptionController.clear();
    setState(() {
      _isActive = true;
      _termsAccepted = false;
      _startDate = null;
      _endDate = null;
      _discountType = 'percentage';
      _errors = {};
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
      {Widget? suffixIcon,
      String? suffixText,
      String? prefixText,
      String? hintText,
      String? errorText}) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      errorText: errorText,
      border: _border(),
      enabledBorder: _border(),
      focusedBorder: _border(),
      suffixIcon: suffixIcon,
      suffixText: suffixText,
      prefixText: prefixText,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  /// One saved offer: title, code, discount, validity and status — the same
  /// columns the website's Existing Offers table shows, stacked for mobile.
  Widget _offerCard(int index, Map<String, dynamic> promo) {
    final isEditing = editIndex == index;
    final active = promo['active'] != false;
    final code = (promo['code'] ?? promo['promoCode'] ?? '-').toString();
    final start = _parseDate(promo['startDate']);
    final end = _parseDate(promo['endDate']);
    String pretty(DateTime? d) =>
        d == null ? '—' : DateFormat('d MMM yyyy').format(d);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isEditing ? AppColors.primaryTint : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isEditing ? AppColors.primary : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  (promo['title'] ?? promo['name'] ?? 'Offer ${index + 1}')
                      .toString(),
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    color: AppColors.primary, size: 20),
                tooltip: 'Edit offer',
                onPressed: () => _startEditing(index, promo),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.error, size: 20),
                tooltip: 'Delete offer',
                onPressed: () => _deletePromotion(index),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(code,
                    style: AppTextStyles.caption.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successTint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_discountLabel(promo),
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: active ? AppColors.primaryTint : AppColors.inputFill,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(active ? 'Active' : 'Inactive',
                    style: AppTextStyles.caption.copyWith(
                        color: active
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('${pretty(start)} — ${pretty(end)}',
              style: AppTextStyles.caption),
        ],
      ),
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
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Existing Offers", style: AppTextStyles.h3),
                      ),
                      const SizedBox(height: 10),
                      ...existingPromotions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final promo = entry.value;
                        return _offerCard(index, promo);
                      }),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 8),
                    ],

                    /// Which offer the form is currently editing, so a filled
                    /// form is never mistaken for a new one.
                    if (editIndex != null) ...[
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTint,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('Editing Offer #${editIndex! + 1}',
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700)),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _resetForm,
                            child: const Text('Cancel Edit'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    TextFormField(
                      controller: _offerTitleController,
                      decoration: _dec("Offer Title *",
                          errorText: _errors['title']),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: _dec("Promo Code *",
                          hintText: "e.g. WEDDING10",
                          errorText: _errors['code']),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _discountType,
                      decoration: _dec("Discount Type"),
                      items: const [
                        DropdownMenuItem(
                            value: 'percentage', child: Text('Percentage (%)')),
                        DropdownMenuItem(
                            value: 'fixed', child: Text('Fixed Amount (₹)')),
                      ],
                      onChanged: (v) =>
                          setState(() => _discountType = v ?? 'percentage'),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _valueController,
                      keyboardType: TextInputType.number,
                      decoration: _dec(
                        "Discount Value *",
                        hintText: _discountType == 'percentage' ? '10' : '5000',
                        prefixText: _discountType == 'percentage' ? null : '₹ ',
                        suffixText: _discountType == 'percentage' ? '%' : null,
                        errorText: _errors['value'],
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Switch(
                          value: _isActive,
                          onChanged: (v) => setState(() => _isActive = v),
                        ),
                        Text(_isActive ? "Active" : "Inactive",
                            style: AppTextStyles.bodySecondary),
                      ],
                    ),
                    const SizedBox(height: 4),

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
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text(
                          "I confirm this offer and its terms"),
                    ),
                    if (_errors['terms'] != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(_errors['terms']!,
                            style: AppTextStyles.errorText),
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
