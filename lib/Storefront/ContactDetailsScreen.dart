import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api_services/api_service_vendor.dart';
import '../api_services/storefront_completion_service.dart';
import '../utils/common_app_bar.dart';
class ContactDetailsPage extends StatefulWidget {
  final int? vendorId;
  final int? vendorSubcategoryId;

  const ContactDetailsPage({
    Key? key,
    this.vendorId,
    this.vendorSubcategoryId,
  }) : super(key: key);

  @override
  _ContactDetailsPageState createState() => _ContactDetailsPageState();
}

class _ContactDetailsPageState extends State<ContactDetailsPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController contactPersonController = TextEditingController();
  final TextEditingController primaryPhoneController = TextEditingController();
  final TextEditingController alternativePhoneController = TextEditingController();
  final TextEditingController whatsappController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;

  String? token;
  int? vendorId;
  int? vendorSubcategoryId;
  int? serviceId;
  final VendorServiceApi _vendorApi = VendorServiceApi();

  Map<String, dynamic> currentAttributes = {}; // <-- store existing attributes

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  Future<void> _initPage() async {
    await _saveConstructorValues();
    await _loadCredentials();
  }

  Future<void> _saveConstructorValues() async {
    final prefs = await SharedPreferences.getInstance();

    if (widget.vendorId != null) {
      await prefs.setInt("vendorId", widget.vendorId!);
    }

    if (widget.vendorSubcategoryId != null) {
      await prefs.setInt("vendor_subcategory_id", widget.vendorSubcategoryId!);
    }

    print("✔ Constructor values saved");
  }

  Future<void> _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();

    token = prefs.getString("token");
    vendorId = prefs.getInt("vendorId");
    vendorSubcategoryId = prefs.getInt("vendor_subcategory_id");
    serviceId = prefs.getInt("serviceId");

    print("🔐 Token: $token");
    print("🆔 VendorId: $vendorId");
    print("🏷 SubcategoryId: $vendorSubcategoryId");
    print("📌 ServiceId: $serviceId");

    if (token == null || serviceId == null) {
      print("⚠ ERROR: Token or ServiceId missing. Contact details cannot be loaded.");
      setState(() => isLoading = false);
      return;
    }

    await fetchContactDetails();
    setState(() => isLoading = false);
  }


  Future<void> fetchContactDetails() async {
    try {
      final data = await _vendorApi.getByServiceId(
        serviceId: serviceId!,
        token: token!,
      );

      if (data == null) return;

      currentAttributes = Map<String, dynamic>.from(data["attributes"] ?? {});

      final contact = currentAttributes["contact"] ?? {};

      contactPersonController.text =
          contact["name"] ?? currentAttributes["name"] ?? "";

      primaryPhoneController.text = contact["phone"] ?? "";
      alternativePhoneController.text = contact["altPhone"] ?? "";
      whatsappController.text = contact["whatsapp"] ?? "";
    } catch (e) {
      debugPrint("❌ fetchContactDetails error: $e");
    }
  }

  Future<void> saveContactDetails() async {
    if (!_formKey.currentState!.validate()) {
      return; // ❌ stop if validation fails
    }
    if (token == null || serviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Missing Token or Service ID please fill your basic info details ")),
      );
      return;
    }

    setState(() => isSaving = true);

    // 🔥 Fetch latest attributes again (safety)
    final latest = await _vendorApi.getByServiceId(
      serviceId: serviceId!,
      token: token!,
    );

    currentAttributes =
    Map<String, dynamic>.from(latest?["attributes"] ?? currentAttributes);

    // ✅ update ONLY contact section
    currentAttributes["contact"] = {
      "name": contactPersonController.text.trim(),
      "phone": primaryPhoneController.text.trim(),
      "altPhone": alternativePhoneController.text.trim(),
      "whatsapp": whatsappController.text.trim(),
    };

    final body = {
      "vendor_id": vendorId,
      "vendor_subcategory_id": vendorSubcategoryId,
      "attributes": currentAttributes,
    };

    final success = await _vendorApi.updateService(
      serviceId: serviceId!,
      token: token!,
      body: body,
    );

    if (success) {
      await StorefrontCompletionService.refreshCompletion(
        serviceId: serviceId!,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Contact updated successfully")),
      );

    }


    setState(() => isSaving = false);
  }

  Widget field(
      String label,
      TextEditingController controller, {
        bool required = false,
        TextInputType keyboardType = TextInputType.text,
      }) {
    final isPhone = keyboardType == TextInputType.phone;
    final isName = label.toLowerCase().contains("contact person");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (required ? " *" : ""),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              )
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,

            // 🔥 INPUT RESTRICTIONS
            inputFormatters: isPhone
                ? [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ]
                : isName
                ? [
              FilteringTextInputFormatter.allow(
                RegExp(r"[a-zA-Z\s]"),
              ),
            ]
                : null,

            // 🔥 LIVE VALIDATION
            validator: (value) {
              final text = value?.trim() ?? "";

              if (required && text.isEmpty) {
                return "$label is required";
              }

              if (isName && text.isNotEmpty) {
                if (text.length < 3) {
                  return "Name must be at least 3 characters";
                }
                if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(text)) {
                  return "Only letters allowed";
                }
              }

              if (isPhone && text.isNotEmpty) {
                if (text.length < 10) {
                  return "Enter 10-digit number";
                }
              }

              return null;
            },

            decoration: const InputDecoration(
              contentPadding:
              EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }


  // Widget field(String label, TextEditingController controller,
  //     {bool required = false, TextInputType keyboardType = TextInputType.text}) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(label + (required ? " *" : ""), style: TextStyle(fontWeight: FontWeight.w600)),
  //       SizedBox(height: 5),
  //       Container(
  //         decoration: BoxDecoration(
  //           color: Colors.white,
  //           borderRadius: BorderRadius.circular(10),
  //           boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
  //         ),
  //         child: TextFormField(
  //           controller: controller,
  //           keyboardType: keyboardType,
  //           decoration: InputDecoration(
  //             contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  //             border: InputBorder.none,
  //           ),
  //         ),
  //       ),
  //       SizedBox(height: 14),
  //     ],
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: CommonAppBar(title:"Contact Details"),
      backgroundColor: Color(0xffF2F2F2),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                        padding: EdgeInsets.all(16),
                        child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
                ),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction, // 🔥 LIVE validation

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      field("Contact Person Name             ", contactPersonController, required: true),
                      field("Primary Phone", primaryPhoneController, required: true, keyboardType: TextInputType.phone),
                      field("Alternative Phone", alternativePhoneController, keyboardType: TextInputType.phone),
                      field("WhatsApp Number", whatsappController, keyboardType: TextInputType.phone),

                      SizedBox(height: 20),

                    ],
                  ),
                ),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : saveContactDetails,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Color(0xFF00509D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: isSaving
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text("Save Contact Details", style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
