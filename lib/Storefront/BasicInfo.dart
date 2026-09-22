import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api_services/api_service_vendor.dart';
import '../api_services/storefront_completion_service.dart';
import '../utils/common_app_bar.dart';
import '../utils/subcategory_selection.dart';
import 'package:happy_weds_vendors/utils/api_config.dart';

class BasicInfoPage extends StatefulWidget {
  @override
  _BasicInfoPageState createState() => _BasicInfoPageState();
}

String stripHtmlTags(String value) {
  return value
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .trim();
}

class _BasicInfoPageState extends State<BasicInfoPage> {
  final TextEditingController businessNameController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();

  bool isBold = false;
  bool isItalic = false;
  bool isUnderline = false;
  String vendorType = '';
  int? vendorTypeId;
  List<Map<String, dynamic>> subcategories = [];

  // Primary Subcategory is a multi-select, same as the website. The first id
  // is the primary one the single-id API field carries.
  List<int> selectedSubcategoryIds = [];
  bool showSubcategoryPicker = false;

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
    selectedSubcategoryIds = await SubcategorySelection.load();

    print(
      "Loaded vendorId: $vendorId, token: $token, subcategoryIds: $selectedSubcategoryIds",
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
      aboutController.text = stripHtmlTags(currentAttributes["about_us"] ?? "");

      // The service carries the primary in `vendor_subcategory_id` and the
      // whole multi-select in `subcategories`.
      final saved = SubcategorySelection.fromService(data);
      if (saved.isNotEmpty) {
        selectedSubcategoryIds = saved;
        await SubcategorySelection.save(saved);
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

            // Only default to the first option when nothing is selected yet.
            // An id that this vendor type no longer lists is still kept, the
            // way the single-select did and the way the website does — losing
            // it here would quietly reassign the vendor on the next save.
            if (selectedSubcategoryIds.isEmpty && subcategories.isNotEmpty) {
              final first = subcategoryIdOf(subcategories.first);
              if (first != null) selectedSubcategoryIds = [first];
            }
          });

          print(
            "Loaded subcategories: $subcategories, selected: $selectedSubcategoryIds",
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

    if (businessNameController.text.isEmpty ||
        selectedSubcategoryIds.isEmpty) {
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
      // Comma separated when more than one is picked — the backend keeps the
      // first as the primary and stores the rest alongside it.
      "vendor_subcategory_id":
          SubcategorySelection.payload(selectedSubcategoryIds),
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
      // Keep the other storefront screens in step, so their saves carry the
      // full set instead of collapsing it back to the primary.
      await SubcategorySelection.save(selectedSubcategoryIds);

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

  /// Subcategory ids arrive as numbers today, but a string id would throw on
  /// a plain cast, so parse rather than cast.
  int? subcategoryIdOf(Map<String, dynamic> sub) {
    final id = sub['id'];
    if (id is int) return id;
    if (id is num) return id.toInt();
    return int.tryParse("$id");
  }

  void toggleSubcategory(int id) {
    setState(() {
      final next = List<int>.from(selectedSubcategoryIds);
      if (next.contains(id)) {
        next.remove(id);
      } else {
        next.add(id);
      }
      selectedSubcategoryIds = next;
    });
  }

  String subcategoryNameFor(int id) {
    final match = subcategories.firstWhere(
      (s) => subcategoryIdOf(s) == id,
      orElse: () => {'name': '$id'},
    );
    return "${match['name'] ?? id}";
  }

  /// Multi-select subcategories, mirroring the website. The first pick is the
  /// primary one.
  Widget subcategoryPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(
            () => showSubcategoryPicker = !showSubcategoryPicker,
          ),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade500),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedSubcategoryIds.isEmpty
                        ? "-- Select subcategories --"
                        : "${selectedSubcategoryIds.length} selected",
                    style: TextStyle(
                      color: selectedSubcategoryIds.isEmpty
                          ? Colors.grey.shade600
                          : Colors.black,
                    ),
                  ),
                ),
                Icon(
                  showSubcategoryPicker
                      ? Icons.arrow_drop_up
                      : Icons.arrow_drop_down,
                ),
              ],
            ),
          ),
        ),
        if (showSubcategoryPicker)
          Container(
            margin: EdgeInsets.only(top: 6),
            constraints: BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: subcategories.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      "No subcategories available",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.symmetric(vertical: 4),
                    children: subcategories.map((sub) {
                      final id = subcategoryIdOf(sub);
                      if (id == null) return SizedBox.shrink();
                      return CheckboxListTile(
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        activeColor: Color(0xFF00509D),
                        value: selectedSubcategoryIds.contains(id),
                        title: Text("${sub['name']}"),
                        onChanged: (_) => toggleSubcategory(id),
                      );
                    }).toList(),
                  ),
          ),
        if (selectedSubcategoryIds.isNotEmpty) ...[
          SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: selectedSubcategoryIds.map((id) {
              final isPrimary = id == selectedSubcategoryIds.first;
              return Chip(
                backgroundColor: isPrimary
                    ? Color(0xFF00509D)
                    : Colors.grey.shade600,
                label: Text(
                  isPrimary
                      ? "${subcategoryNameFor(id)} • Primary"
                      : subcategoryNameFor(id),
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                deleteIcon: Icon(Icons.close, size: 16, color: Colors.white),
                onDeleted: () => toggleSubcategory(id),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
        ],
      ],
    );
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
                          subcategoryPicker(),
                          SizedBox(height: 20),
                        ],
                      ),
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
                ),
              ],
            ),
    );
  }
}
