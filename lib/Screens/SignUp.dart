import 'package:flutter/material.dart';
import 'package:happy_weds_vendors/Screens/home.dart';

import 'Login.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Future<void> registerVendor({
//   required String businessName,
//   required String city,
//   required String email,
//   required String phone,
//   required String password,
//   required int vendorTypeId,
// }) async {
//   final url = Uri.parse("https://happywedz.com/api/vendor/register");
//
//   final response = await http.post(
//     url,
//     headers: {
//       "Content-Type": "application/json",
//     },
//     body: jsonEncode({
//       "businessName": businessName,
//       "city": city,
//       "phone": phone,
//       "email": email,
//       "password": password,
//       "vendor_type_id": vendorTypeId,
//     }),
//   );
//
//   if (response.statusCode == 200 || response.statusCode == 201) {
//     print("Vendor registered successfully!");
//     print(response.body);
//   } else {
//     print("Failed to register vendor: ${response.body}");
//   }
// }

class SignUp extends StatefulWidget {
  const SignUp({Key? key}) : super(key: key);

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final _formKey = GlobalKey<FormState>();

  final _businessNameC = TextEditingController();
  final _ownerNameC = TextEditingController();
  final _emailC = TextEditingController();
  final _phoneC = TextEditingController();
  final _passwordC = TextEditingController();
  final _gstC = TextEditingController();
  final _websiteC = TextEditingController();

  String? _businessCategory;
  String? _city;
  String? _referral;
  bool _agreeTerms = false;
  List<VendorType> _vendorTypes = [];
  VendorType? _selectedVendorType;
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _loadVendorTypes();
  }

  void _loadVendorTypes() async {
    try {
      _vendorTypes = await fetchVendorTypes();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print(e);
      setState(() {
        _isLoading = false;
      });
    }
  }

  final List<String> _categories = [
    "Photographer",
    "Makeup Artist",
    "Decorator",
    "Caterer",
    "Venue",
    "Other",
  ];

  final List<String> _cities = [
    "Mumbai",
    "Delhi",
    "Bangalore",
    "Chennai",
    "Kolkata",
    "Hyderabad",
  ];

  final List<String> _referrals = [
    "Google Search",
    "Instagram",
    "Facebook",
    "Friend / Family",
    "Other",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[300],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Image.asset("assets/images/logoo.png", height: 80),
              const SizedBox(height: 8),
              const Text(
                "Join as a Vendor",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(
                          _businessNameC,
                          "Business Name",
                          Icons.store,
                        ),
                        // const SizedBox(height: 12),
                        // _buildTextField(
                        //   _ownerNameC,
                        //   "Owner's Name",
                        //   Icons.person,
                        // ),
                        const SizedBox(height: 12),

                        _buildDropdown(
                          hint: "Select Business Category",
                          value: _businessCategory,
                          items: _categories,
                          onChanged: (val) =>
                              setState(() => _businessCategory = val),
                        ),
                        const SizedBox(height: 12),

                        _buildDropdown(
                          hint: "Select City",
                          value: _city,
                          items: _cities,
                          onChanged: (val) => setState(() => _city = val),
                        ),
                        const SizedBox(height: 12),

                        _buildTextField(
                          _emailC,
                          "Email",
                          Icons.email,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          _phoneC,
                          "Phone Number",
                          Icons.phone,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          _passwordC,
                          "Password",
                          Icons.lock,
                          obscureText: true,
                        ),
                        const SizedBox(height: 12),


                        Row(
                          children: [
                            Checkbox(
                              value: _agreeTerms,
                              onChanged: (val) =>
                                  setState(() => _agreeTerms = val!),
                            ),
                            Expanded(
                              child: Text(
                                "I agree to the Terms & Conditions",
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE91E63),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              if (_formKey.currentState!.validate() && _agreeTerms) {
                                // int vendorTypeId = _categories.indexOf(_businessCategory!) + 1; // map category to ID
                                //
                                // await registerVendor(
                                //   businessName: _businessNameC.text,
                                //   city: _city!,
                                //   email: _emailC.text,
                                //   phone: _phoneC.text,
                                //   password: _passwordC.text,
                                //   vendorTypeId: vendorTypeId,
                                // );

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const HomeScreen(),
                                  ),
                                );
                              }
                            },

                            child: const Text(
                              "Sign Up",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Login()),
                  );
                },
                child: const Text(
                  "Already have an account? Log in",
                  style: TextStyle(
                    color: Color(0xFFE91E63),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return "Please enter $hint";
        return null;
      },
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      hint: Text(hint),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
      validator: (val) => val == null ? "Please select $hint" : null,
    );
  }
}
class VendorType {
  final int id;
  final String name;

  VendorType({required this.id, required this.name});

  factory VendorType.fromJson(Map<String, dynamic> json) {
    return VendorType(
      id: json['id'],
      name: json['name'],
    );
  }
}

Future<List<VendorType>> fetchVendorTypes() async {
  final url = Uri.parse("https://happywedz.com/api/vendor-types");
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);
    return data.map((e) => VendorType.fromJson(e)).toList();
  } else {
    throw Exception("Failed to load vendor types");
  }
}
