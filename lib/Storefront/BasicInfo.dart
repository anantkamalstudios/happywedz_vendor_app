import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api_services/api_service_vendor.dart';
import '../api_services/storefront_completion_service.dart';
import '../utils/common_app_bar.dart';
import 'package:happy_weds_vendors/utils/api_config.dart';

class BasicInfoPage extends StatefulWidget {
  @override
  _BasicInfoPageState createState() => _BasicInfoPageState();
}

class _BasicInfoPageState extends State<BasicInfoPage> {
  final TextEditingController businessNameController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();

  bool isBold = false;
  bool isItalic = false;
  bool isUnderline = false;
  String vendorType = '';
  int? vendorTypeId;
  int? vendorSubcategoryId;
  String? primarySubcategory;
  List<Map<String, dynamic>> subcategories = [];

  String adStatus = 'hide';
  final Map<String, String> adStatusOptions = {
    'publish': 'Published',
    'hide': 'Hidden',
  };

  bool isLoading = true;
  bool isSaving = false;

  int? vendorId;
  String? token;

  Map<String, dynamic> currentAttributes = {};
  final VendorServiceApi _vendorApi = VendorServiceApi();

  @override
  void initState() {
    super.initState();
    _loadCredentialsAndData();
  }

  Future<void> _loadCredentialsAndData() async {
    final prefs = await SharedPreferences.getInstance();
    vendorId = prefs.getInt('vendorId');
    token = prefs.getString('token');
    vendorSubcategoryId = prefs.getInt('vendor_subcategory_id');

    print(
      "Loaded vendorId: $vendorId, token: $token, vendorSubcategoryId: $vendorSubcategoryId",
    );

    if (vendorId != null && token != null) {
      await fetchVendorService();
      await fetchVendorData();
    } else {
      setState(() => isLoading = false);
    }
  }



  Future<void> fetchVendorService() async {
    try {
      final data = await _vendorApi.getByVendorId(
        vendorId: vendorId!,
        token: token!,
      );

      if (data == null) return;

      final prefs = await SharedPreferences.getInstance();

      final serviceId = data["id"];
      await prefs.setInt("serviceId", serviceId);

      currentAttributes = Map<String, dynamic>.from(data["attributes"] ?? {});

      businessNameController.text = currentAttributes["name"] ?? "";
      aboutController.text = currentAttributes["about_us"] ?? "";

      vendorSubcategoryId = data["vendor_subcategory_id"];
      if (vendorSubcategoryId != null) {
        await prefs.setInt("vendor_subcategory_id", vendorSubcategoryId!);
      }

      if (data["status"] != null &&
          adStatusOptions.containsKey(data["status"])) {
        adStatus = data["status"];
      }
    } catch (e) {
      debugPrint("❌ fetchVendorService error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchVendorData() async {
    print("Fetching vendor data from API...");
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/vendor/$vendorId'),
        headers: {"Authorization": "Bearer $token"},
      );

      print("Vendor data response code: ${response.statusCode}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Vendor data: $data");

        setState(() {
          businessNameController.text =
              data["businessName"] ?? businessNameController.text;
          if (data['vendorType'] != null) {
            vendorType = data['vendorType']['name'] ?? '';
            vendorTypeId = data['vendorType']['id'];
          }
        });

        await fetchSubcategories();
      }
    } catch (e) {
      print("Error fetching vendor data: $e");
    }
  }

  Future<void> fetchSubcategories() async {
    if (vendorType.isEmpty) return;

    print("Fetching subcategories for vendorType: $vendorType");
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/vendor-types/with-subcategories/all',
        ),
      );

      print("Subcategories response code: ${response.statusCode}");
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final typeData = data.firstWhere(
          (element) =>
              element['name'].toString().toLowerCase() ==
              vendorType.toLowerCase(),
          orElse: () => null,
        );

        if (typeData != null) {
          final List<dynamic> subList = typeData['subcategories'];
          setState(() {
            subcategories = subList
                .map((e) => {'id': e['id'], 'name': e['name']})
                .toList();

            if (vendorSubcategoryId != null) {
              primarySubcategory =
                  subcategories.firstWhere(
                    (s) => s['id'] == vendorSubcategoryId,
                    orElse: () => {'name': null},
                  )['name'];
            } else if (subcategories.isNotEmpty) {
              primarySubcategory = subcategories[0]['name'];
              vendorSubcategoryId = subcategories[0]['id'];
            }
          });

          print(
            "Loaded subcategories: $subcategories, primarySubcategory: $primarySubcategory",
          );
        }
      }
    } catch (e) {
      print("Error fetching subcategories: $e");
    }
  }

  void toggleBold() => setState(() => isBold = !isBold);
  void toggleItalic() => setState(() => isItalic = !isItalic);
  void toggleUnderline() => setState(() => isUnderline = !isUnderline);

  void addBullet() {
    aboutController.text += "\n• ";
    aboutController.selection = TextSelection.fromPosition(
      TextPosition(offset: aboutController.text.length),
    );
  }

  void addHeader() {
    aboutController.text += "\n## ";
    aboutController.selection = TextSelection.fromPosition(
      TextPosition(offset: aboutController.text.length),
    );
  }

  Future<void> saveBasicInfo() async {
    if (vendorId == null || token == null) return;

    if (businessNameController.text.isEmpty || vendorSubcategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    setState(() => isSaving = true);

    final prefs = await SharedPreferences.getInstance();
    int? serviceId = prefs.getInt("serviceId");

    // 🔥 SAFETY: fetch latest attributes again before update
    if (serviceId != null) {
      final latest = await _vendorApi.getByServiceId(
        serviceId: serviceId,
        token: token!,
      );

      currentAttributes = Map<String, dynamic>.from(
        latest?["attributes"] ?? currentAttributes,
      );
    }

    // ✅ update only BASIC INFO fields
    currentAttributes["name"] = businessNameController.text.trim();
    currentAttributes["about_us"] = aboutController.text.trim();

    final body = {
      "vendor_id": vendorId,
      "vendor_subcategory_id": vendorSubcategoryId,
      "status": adStatus,
      "attributes": currentAttributes,
    };

    bool success;

    if (serviceId == null) {
      success = await _vendorApi.createService(token: token!, body: body);
    } else {
      success = await _vendorApi.updateService(
        serviceId: serviceId,
        token: token!,
        body: body,
      );
    }

    // if (success) {
    //   await prefs.setString("businessName", businessNameController.text.trim());
    //   await prefs.setString("aboutUs", aboutController.text.trim());
    //
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text("Basic info saved successfully")),
    //   );
    // }
    if (success) {
      await StorefrontCompletionService.refreshCompletion(
        serviceId: serviceId!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Basic info saved successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save basic info")),
      );
    }

    setState(() => isSaving = false);
  }

  Widget field(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
        SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
        SizedBox(height: 15),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: "Basic Information"),
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
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          field("Vendor Business Name", businessNameController),
                          Text(
                            "About Us",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 5),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.format_bold,
                                  color: isBold ? Colors.blue : Colors.black,
                                ),
                                onPressed: toggleBold,
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.format_italic,
                                  color: isItalic ? Colors.blue : Colors.black,
                                ),
                                onPressed: toggleItalic,
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.format_underline,
                                  color: isUnderline
                                      ? Colors.blue
                                      : Colors.black,
                                ),
                                onPressed: toggleUnderline,
                              ),
                              IconButton(
                                icon: Icon(Icons.format_list_bulleted),
                                onPressed: addBullet,
                              ),
                              IconButton(
                                icon: Icon(Icons.title),
                                onPressed: addHeader,
                              ),
                            ],
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            padding: EdgeInsets.all(8),
                            child: TextFormField(
                              controller: aboutController,
                              maxLines: 8,
                              style: TextStyle(
                                fontWeight: isBold
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontStyle: isItalic
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                                decoration: isUnderline
                                    ? TextDecoration.underline
                                    : TextDecoration.none,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "Write About Us...",
                              ),
                            ),
                          ),
                          SizedBox(height: 15),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Vendor Type",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Text(vendorType),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Ad Status",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    DropdownButtonFormField<String>(
                                      value: adStatus,
                                      isExpanded: true,
                                      items: adStatusOptions.entries
                                          .map(
                                            (e) => DropdownMenuItem<String>(
                                              value: e.key,
                                              child: Text(e.value),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) {
                                        if (value == null) return;
                                        setState(() => adStatus = value);
                                      },
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 15),
                          Text(
                            "Primary Subcategory *",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 5),
                          DropdownButtonFormField<String>(
                            value: primarySubcategory,
                            isExpanded: true,
                            items: subcategories
                                .map(
                                  (sub) => DropdownMenuItem<String>(
                                    value: sub['name'],
                                    child: Text(sub['name']),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                primarySubcategory = value;
                                vendorSubcategoryId = subcategories.firstWhere(
                                  (s) => s['name'] == value,
                                )['id'];
                              });
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : saveBasicInfo,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Color(0xFF00509D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: isSaving
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                              "Save Basic Info",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
