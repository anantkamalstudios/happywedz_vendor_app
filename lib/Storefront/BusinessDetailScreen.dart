// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../utils/common_app_bar.dart';
//
// class BusinessDetailsPage extends StatefulWidget {
//   @override
//   _BusinessDetailsPageState createState() => _BusinessDetailsPageState();
// }
//
// class _BusinessDetailsPageState extends State<BusinessDetailsPage> {
//   TextEditingController businessName = TextEditingController();
//   TextEditingController email = TextEditingController();
//   TextEditingController phone = TextEditingController();
//   TextEditingController city = TextEditingController();
//   TextEditingController stateCtrl = TextEditingController();
//   TextEditingController zip = TextEditingController();
//   TextEditingController website = TextEditingController();
//   TextEditingController yearsInBusi = TextEditingController();
//   TextEditingController firstName = TextEditingController();
//   TextEditingController lastName = TextEditingController();
//
//   TextEditingController currentPassword = TextEditingController();
//   TextEditingController newPassword = TextEditingController();
//   TextEditingController confirmPassword = TextEditingController();
//
//   String? profileImageUrl;
//   bool showPasswordSection = false;
//   File? profileImage;
//
//   @override
//   void initState() {
//     super.initState();
//     loadData();
//   }
//
//   Future<void> loadData() async {
//     final prefs = await SharedPreferences.getInstance();
//     final vendorId = prefs.getInt("vendorId");
//
//     if (vendorId == null) return;
//
//     final url = Uri.parse("https://happywedz.com/api/vendor/$vendorId");
//
//     try {
//       final response = await http.get(url);
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//
//         setState(() {
//           businessName.text = data["businessName"] ?? "";
//           email.text = data["email"] ?? "";
//           phone.text = data["phone"] ?? "";
//           city.text = data["city"] ?? "";
//           stateCtrl.text = data["state"] ?? "";
//           zip.text = data["zip"] ?? "";
//           website.text = data["website"] ?? "";
//           yearsInBusi.text = data["years_in_business"]?.toString() ?? "";
//           firstName.text = data["firstName"] ?? "";
//           lastName.text = data["lastName"] ?? "";
//           profileImageUrl = data["profileImage"];
//         });
//       }
//     } catch (e) {
//       debugPrint("❌ Error loading data: $e");
//     }
//   }
//
//   Future<void> saveData() async {
//     final prefs = await SharedPreferences.getInstance();
//     final vendorId = prefs.getInt("vendorId");
//     if (vendorId == null) return;
//
//     final url = Uri.parse("https://happywedz.com/api/vendor/$vendorId");
//
//     final body = {
//       "businessName": businessName.text.trim(),
//       "city": city.text.trim(),
//       "email": email.text.trim(),
//       "facebook_link": "",
//       "firstName": firstName.text.trim(),
//       "lastName": lastName.text.trim(),
//       "instagram_link": "",
//       "phone": phone.text.trim(),
//       "state": stateCtrl.text.trim(),
//       "vendor_type_id": 2,
//       "website": website.text.trim(),
//       "years_in_business": int.tryParse(yearsInBusi.text.trim()) ?? 0,
//       "zip": zip.text.trim(),
//       "profileImage": profileImageUrl,
//     };
//
//     try {
//       final response = await http.put(
//         url,
//         headers: {"Content-Type": "application/json"},
//         body: json.encode(body),
//       );
//
//       if (response.statusCode == 200) {
//         ScaffoldMessenger.of(context)
//             .showSnackBar(SnackBar(content: Text("Profile Updated")));
//       } else {
//         ScaffoldMessenger.of(context)
//             .showSnackBar(SnackBar(content: Text("Update failed")));
//       }
//     } catch (e) {
//       debugPrint("❌ Error: $e");
//     }
//   }
//
//   pickImage() async {
//     final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
//     if (picked != null) {
//       final file = File(picked.path);
//       final url = await uploadImage(file);
//       if (url != null) {
//         setState(() {
//           profileImageUrl = url;
//           profileImage = null;
//         });
//       }
//     }
//   }
//
//   Future<String?> uploadImage(File img) async {
//     final prefs = await SharedPreferences.getInstance();
//     final vendorId = prefs.getInt("vendorId");
//
//     var request = http.MultipartRequest(
//         "POST",
//         Uri.parse("https://happywedz.com/api/vendor/uploadProfile"));
//
//     request.fields["vendorId"] = vendorId.toString();
//     request.files.add(await http.MultipartFile.fromPath("image", img.path));
//
//     final response = await request.send();
//     final res = await http.Response.fromStream(response);
//
//     if (response.statusCode == 200) {
//       final data = json.decode(res.body);
//       return data["imageUrl"];
//     }
//     return null;
//   }
//
//   Future<void> changePassword() async {
//     final prefs = await SharedPreferences.getInstance();
//     final vendorId = prefs.getInt("vendorId");
//
//     if (vendorId == null) return;
//
//     final url = Uri.parse("https://happywedz.com/api/vendor/change-password");
//
//     final body = {
//       "vendorId": vendorId,
//       "oldPassword": currentPassword.text,
//       "newPassword": newPassword.text,
//     };
//
//     try {
//       final response = await http.post(
//         url,
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode(body),
//       );
//
//       if (response.statusCode == 200) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Password Updated Successfully")),
//         );
//         currentPassword.clear();
//         newPassword.clear();
//         confirmPassword.clear();
//         setState(() => showPasswordSection = false);
//       } else {
//         ScaffoldMessenger.of(context)
//             .showSnackBar(SnackBar(content: Text("Password update failed")));
//       }
//     } catch (e) {
//       debugPrint("❌ ERROR: $e");
//     }
//   }
//
//   Widget field(String label, TextEditingController controller) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
//         SizedBox(height: 5),
//         Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(10),
//             boxShadow: [
//               BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
//             ],
//           ),
//           child: TextFormField(
//             controller: controller,
//             decoration: InputDecoration(
//               contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//               border: InputBorder.none,
//             ),
//           ),
//         ),
//         SizedBox(height: 14),
//       ],
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     ImageProvider? imageProvider;
//     if (profileImage != null) {
//       imageProvider = FileImage(profileImage!);
//     } else if (profileImageUrl != null) {
//       imageProvider = NetworkImage(profileImageUrl!);
//     }
//
//     return Scaffold(
//       backgroundColor: Color(0xffF2F2F2),
//       appBar: CommonAppBar(title: 'Business Details'),
//
//       body: Column(
//         children: [
//           Expanded(
//             child: SingleChildScrollView(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Container(
//                   padding: EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(14),
//                     boxShadow: [
//                       BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))
//                     ],
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           CircleAvatar(
//                             radius: 45,
//                             backgroundImage: imageProvider,
//                             child: imageProvider == null
//                                 ? Icon(Icons.person, size: 45)
//                                 : null,
//                           ),
//                           SizedBox(width: 15),
//                           ElevatedButton(
//                             onPressed: pickImage,
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Color(0xFF00509D),// button background
//                               foregroundColor: Colors.white,      // button text color
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                             ),
//                             child: Text("Choose File"),
//                           )
//
//                         ],
//                       ),
//                       SizedBox(height: 20),
//
//                       field("Business Name", businessName),
//                       field("Email", email),
//                       field("Mobile Number", phone),
//                       field("City", city),
//                       field("State", stateCtrl),
//                       field("Zip", zip),
//                       field("Website", website),
//                       field("Years in Business", yearsInBusi),
//                       field("First Name", firstName),
//                       field("Last Name", lastName),
//
//                       SizedBox(height: 10),
//
//                       GestureDetector(
//                         onTap: () =>
//                             setState(() => showPasswordSection = !showPasswordSection),
//                         child: Container(
//                           padding: EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(10),
//                             boxShadow: [
//                               BoxShadow(
//                                   color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
//                             ],
//                           ),
//                           child: Row(
//                             children: [
//                               Expanded(
//                                   child: Text("Change Password",
//                                       style: TextStyle(fontWeight: FontWeight.w600))),
//                               Icon(
//                                 showPasswordSection
//                                     ? Icons.keyboard_arrow_up
//                                     : Icons.keyboard_arrow_down,
//                               )
//                             ],
//                           ),
//                         ),
//                       ),
//
//                       if (showPasswordSection) ...[
//                         SizedBox(height: 10),
//                         field("Current Password", currentPassword),
//                         field("New Password", newPassword),
//                         field("Confirm Password", confirmPassword),
//
//                         Align(
//                           alignment: Alignment.bottomRight,
//                           child: ElevatedButton(
//                             onPressed: changePassword,
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Color(0xFF00509D),
//                               foregroundColor: Colors.white,
//
//
//
//                             ),
//                             child: Text("Update Password"),
//                           ),
//                         ),
//                       ],
//
//                       SizedBox(height: 20),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: saveData,
//                 style: ElevatedButton.styleFrom(
//                   padding: EdgeInsets.symmetric(vertical: 14),
//                   backgroundColor: Color(0xFF00509D),
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(15)),
//                 ),
//                 child: Text("Save Business Details",
//                     style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold)),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Screens/ViewPlanScreen.dart';
import '../api_services/vendor_access_api.dart';
import '../api_services/vendor_verification_api.dart';
import '../providers/vendor_access_provider.dart';
import '../utils/common_app_bar.dart';
import '../widgets/app_shimmer.dart';
import '../widgets/verification_status_banner.dart';
import 'kyc_documents_section.dart';
import 'package:happy_weds_vendors/utils/api_config.dart';

class BusinessDetailsPage extends ConsumerStatefulWidget {
  const BusinessDetailsPage({super.key});

  @override
  /// AUDIT NOTE: `createState` returning the private State type is the
  /// pattern Flutter's own `flutter create` template uses. Making the State
  /// public purely to satisfy `library_private_types_in_public_api` would be
  /// a wider refactor than this audit's brief allows, so the lint is silenced
  /// locally with this note rather than left as unexplained noise.
  // ignore: library_private_types_in_public_api
  _BusinessDetailsPageState createState() => _BusinessDetailsPageState();
}

class _BusinessDetailsPageState extends ConsumerState<BusinessDetailsPage> {
  TextEditingController businessName = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController city = TextEditingController();
  TextEditingController stateCtrl = TextEditingController();
  TextEditingController zip = TextEditingController();
  TextEditingController website = TextEditingController();
  TextEditingController yearsInBusi = TextEditingController();
  TextEditingController firstName = TextEditingController();
  TextEditingController lastName = TextEditingController();

  TextEditingController currentPassword = TextEditingController();
  TextEditingController newPassword = TextEditingController();
  TextEditingController confirmPassword = TextEditingController();

  String? profileImageUrl;
  File? profileImage;
  bool showPasswordSection = false;
  bool isSaving = false;
  bool isLoading = true;

  // ---------------- KYC / VERIFICATION STATE ----------------
  final VendorVerificationApi _verificationApi = VendorVerificationApi();
  VendorAccess? _access;
  Map<String, dynamic> _existingDocs = {};
  File? _aadhaar;
  File? _pan;
  List<BusinessDocEntry> _businessDocs = [BusinessDocEntry()];
  Map<String, String> _kycErrors = {};
  bool _submittingVerification = false;

  bool get _isUnderReview => _access?.stage == 'kyc_pending';
  bool get _needsVerification => _access?.canSubmitVerification ?? false;

  /// Lets the verification banner's button scroll to the documents section.
  final GlobalKey _kycSectionKey = GlobalKey();

  /// What the banner's button does, by stage. Verification stages have nothing
  /// to navigate to — the vendor is already on the right screen — so those
  /// scroll to the upload section instead; everything else is a plan problem.
  void _handleBannerAction() {
    final stage = _access?.stage;

    if (stage == 'kyc_required' || stage == 'kyc_rejected') {
      final target = _kycSectionKey.currentContext;
      if (target != null) {
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          alignment: 0.1,
        );
      }
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ViewPlansScreen()),
    );
  }

  @override
  void initState() {
    super.initState();
    loadData();
    _loadVerificationStatus();
  }

  Future<void> _loadVerificationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final data = await _verificationApi.getStatus(token);
    if (!mounted) return;

    final access = data['access'] as Map<String, dynamic>?;
    final documents = List<dynamic>.from(data['documents'] ?? const []);
    final grouped = <String, dynamic>{'business': <dynamic>[]};
    for (final doc in documents) {
      if (doc['doc_type'] == 'business') {
        (grouped['business'] as List).add(doc);
      } else {
        grouped[doc['doc_type']] = doc;
      }
    }

    setState(() {
      _access = access != null ? VendorAccess.fromJson(access) : null;
      _existingDocs = grouped;
    });
  }

  /// Returns field -> message; empty when the submission is valid.
  Map<String, String> _validateKyc() {
    final errors = <String, String>{};
    final filled = _businessDocs.where((d) => d.file != null || d.label.trim().isNotEmpty).toList();

    if (_aadhaar == null && _existingDocs['aadhaar'] == null) {
      errors['aadhaar'] = 'Please upload your Aadhaar card.';
    }
    if (_pan == null && _existingDocs['pan'] == null) {
      errors['pan'] = 'Please upload your PAN card.';
    }

    final hasExistingBusiness = (_existingDocs['business'] as List? ?? const []).isNotEmpty;
    if (filled.isEmpty && !hasExistingBusiness) {
      errors['businessDocs'] = 'Please add at least one business document.';
    }

    for (int i = 0; i < _businessDocs.length; i++) {
      final doc = _businessDocs[i];
      final hasLabel = doc.label.trim().isNotEmpty;
      final hasFile = doc.file != null;
      if (hasFile && !hasLabel) errors['businessDocLabel-$i'] = 'Give this document a name.';
      if (hasLabel && !hasFile) errors['businessDocFile-$i'] = 'Choose a file for this document.';
    }

    return errors;
  }

  Future<void> _submitVerification() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;
    if (!mounted) return;

    final requiredFieldErrors = <String, String>{};
    if (businessName.text.trim().isEmpty) requiredFieldErrors['businessName'] = 'This field is required';
    if (email.text.trim().isEmpty) requiredFieldErrors['email'] = 'This field is required';
    if (phone.text.trim().isEmpty) requiredFieldErrors['phone'] = 'This field is required';
    if (city.text.trim().isEmpty) requiredFieldErrors['city'] = 'This field is required';

    final docErrors = _validateKyc();

    if (requiredFieldErrors.isNotEmpty || docErrors.isNotEmpty) {
      setState(() => _kycErrors = docErrors);
      final first = requiredFieldErrors.values.isNotEmpty
          ? requiredFieldErrors.values.first
          : docErrors.values.first;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(first)));
      return;
    }

    setState(() => _submittingVerification = true);

    try {
      final labeledDocs = _businessDocs
          .where((d) => d.file != null && d.label.trim().isNotEmpty)
          .map((d) => LabeledDocument(label: d.label.trim(), file: d.file!))
          .toList();

      final data = await _verificationApi.submit(
        token: token,
        fields: {
          'businessName': businessName.text.trim(),
          'phone': phone.text.trim(),
          'city': city.text.trim(),
          'state': stateCtrl.text.trim(),
          'zip': zip.text.trim(),
          'firstName': firstName.text.trim(),
          'lastName': lastName.text.trim(),
          'website': website.text.trim(),
        },
        aadhaar: _aadhaar,
        pan: _pan,
        businessDocs: labeledDocs,
      );

      if (!mounted) return;
      setState(() {
        _aadhaar = null;
        _pan = null;
        _businessDocs = [BusinessDocEntry()];
        _kycErrors = {};
      });

      await _loadVerificationStatus();
      ref.invalidate(vendorAccessProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Documents submitted for verification')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _submittingVerification = false);
    }
  }

  // ---------------- LOAD DATA ----------------
  /// Drives `isLoading`, and so the skeleton, off the real request. It used to
  /// be a fixed one-second `Future.delayed`, which meant the page revealed
  /// itself on a timer whether or not the vendor's details had arrived.
  Future<void> loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final vendorId = prefs.getInt("vendorId");
      final token = prefs.getString("token");

      if (vendorId == null || token == null) return;

      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/vendor/$vendorId"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          businessName.text = data["businessName"] ?? "";
          email.text = data["email"] ?? "";
          phone.text = data["phone"] ?? "";
          city.text = data["city"] ?? "";
          stateCtrl.text = data["state"] ?? "";
          zip.text = data["zip"] ?? "";
          website.text = data["website"] ?? "";
          yearsInBusi.text = data["years_in_business"]?.toString() ?? "";
          firstName.text = data["firstName"] ?? "";
          lastName.text = data["lastName"] ?? "";
          profileImageUrl = data["profileImage"];
        });
      }
    } catch (e) {
      debugPrint("❌ Business details load failed: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ---------------- PICK IMAGE ----------------
  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        profileImage = File(picked.path);
      });
    }
  }

  // ---------------- SAVE DATA (FIXED LOGIC) ----------------
  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final vendorId = prefs.getInt("vendorId");
    final token = prefs.getString("token");

    if (vendorId == null || token == null) return;

    setState(() => isSaving = true);

    final request = http.MultipartRequest(
      "PUT",
      Uri.parse("${ApiConfig.baseUrl}/vendor/$vendorId"),
    );

    request.headers["Authorization"] = "Bearer $token";

    // TEXT FIELDS
    request.fields.addAll({
      "businessName": businessName.text.trim(),
      "email": email.text.trim(),
      "phone": phone.text.trim(),
      "city": city.text.trim(),
      "state": stateCtrl.text.trim(),
      "zip": zip.text.trim(),
      "website": website.text.trim(),
      "years_in_business": yearsInBusi.text.trim(),
      "firstName": firstName.text.trim(),
      "lastName": lastName.text.trim(),
      "vendor_type_id": "2",
      "facebook_link": "",
      "instagram_link": "",
    });

    // IMAGE FILE (KEY MUST BE profileImage)
    if (profileImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          "profileImage",
          profileImage!.path,
        ),
      );
    }

    final response = await request.send();
    final res = await http.Response.fromStream(response);

    setState(() => isSaving = false);

    if (response.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() {
        profileImageUrl = data["vendor"]["profileImage"];
        profileImage = null;
      });

      // AUDIT FIX: context used after an await — guard added.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Profile Updated Successfully")),
      );
    } else {
      debugPrint(res.body);
      // AUDIT FIX: context used after an await — guard added.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update Failed")),
      );
    }
  }

  // ---------------- CHANGE PASSWORD (NO CHANGE) ----------------
  Future<void> changePassword() async {
    final prefs = await SharedPreferences.getInstance();
    final vendorId = prefs.getInt("vendorId");
    final token = prefs.getString("token");

    if (vendorId == null || token == null) return;

    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/vendor/change-password"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "vendorId": vendorId,
        "oldPassword": currentPassword.text,
        "newPassword": newPassword.text,
      }),
    );

    if (response.statusCode == 200) {
      // AUDIT FIX: context used after an await — guard added.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password Updated Successfully")),
      );
      currentPassword.clear();
      newPassword.clear();
      confirmPassword.clear();
      setState(() => showPasswordSection = false);
    }
  }

  // ---------------- UI (EXACT SAME AS YOUR CODE) ----------------
  Widget field(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
        SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
            ],
          ),
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: InputBorder.none,
            ),
          ),
        ),
        SizedBox(height: 14),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    if (profileImage != null) {
      imageProvider = FileImage(profileImage!);
    } else if (profileImageUrl != null) {
      imageProvider = NetworkImage(profileImageUrl!);
    }

    return Scaffold(
      backgroundColor: Color(0xffF2F2F2),
      appBar: CommonAppBar(title: 'Business Details'),
      body:isLoading
          ? const FormShimmer(fields: 8, avatarHeader: true)
          :





      Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VerificationStatusBanner(
                        access: _access,
                        onAction: _handleBannerAction,
                      ),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 45,
                            backgroundImage: imageProvider,
                            child: imageProvider == null
                                ? Icon(Icons.person, size: 45)
                                : null,
                          ),
                          SizedBox(width: 15),
                          ElevatedButton(
                            onPressed: pickImage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF00509D),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text("Choose File"),
                          )
                        ],
                      ),

                      SizedBox(height: 20),

                      field("Business Name", businessName),
                      field("Email", email),
                      field("Mobile Number", phone),
                      field("City", city),
                      field("State", stateCtrl),
                      field("Zip", zip),
                      field("Website", website),
                      field("Years in Business", yearsInBusi),
                      field("First Name", firstName),
                      field("Last Name", lastName),

                      if (_access != null && _access!.verificationStatus != 'approved')
                        KycDocumentsSection(
                          key: _kycSectionKey,
                          aadhaar: _aadhaar,
                          pan: _pan,
                          businessDocs: _businessDocs,
                          existing: _existingDocs,
                          errors: _kycErrors,
                          disabled: _isUnderReview || _submittingVerification,
                          onAadhaarChange: (f) => setState(() => _aadhaar = f),
                          onPanChange: (f) => setState(() => _pan = f),
                          onBusinessDocsChange: (docs) => setState(() => _businessDocs = docs),
                        ),

                      SizedBox(height: 10),

                      GestureDetector(
                        onTap: () =>
                            setState(() => showPasswordSection = !showPasswordSection),
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2))
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Change Password",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              Icon(
                                showPasswordSection
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                              )
                            ],
                          ),
                        ),
                      ),

                      if (showPasswordSection) ...[
                        SizedBox(height: 10),
                        field("Current Password", currentPassword),
                        field("New Password", newPassword),
                        field("Confirm Password", confirmPassword),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: ElevatedButton(
                            onPressed: changePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF00509D),
                              foregroundColor: Colors.white,
                            ),
                            child: Text("Update Password"),
                          ),
                        ),
                      ],

                      SizedBox(height: 20),
                    ],
                  ),
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
                  // One button, three meanings: while onboarding is outstanding,
                  // saving business fields and submitting for verification are
                  // the same action from the vendor's point of view.
                  onPressed: _isUnderReview
                      ? null
                      : (isSaving || _submittingVerification)
                          ? null
                          : (_needsVerification ? _submitVerification : saveData),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Color(0xFF00509D),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  child: (isSaving || _submittingVerification)
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                    _isUnderReview
                        ? "Under review"
                        : (_needsVerification ? "Submit for verification" : "Save Business Details"),
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
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
