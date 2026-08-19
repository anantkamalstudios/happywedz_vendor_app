import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_guard.dart';
import '../auth/session_manager.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_snackbar.dart';
import 'Login.dart';
import 'HomeScreen.dart';

/// ============================================================================
/// SignUp — vendor registration
/// ============================================================================
///
/// API INTEGRATION IS UNCHANGED:
///   GET  https://happywedz.com/api/vendor-types
///   GET  https://countriesnow.space/api/v0.1/countries      (3rd-party)
///   POST https://happywedz.com/api/vendor/register
///   POST https://happywedz.com/api/faq-answers/save
///
/// AUDIT NOTE — BUGS FIXED
///
/// 1. CRASH ON A PARTIAL REGISTER RESPONSE (high severity).
///        await prefs.setInt('vendorId', data['vendor']['id']);
///        await prefs.setString('authToken', data['token']);
///    Both are typed setters. A response without `vendor`, without `id`, or
///    without `token` threw a TypeError mid-way through persisting the
///    session, leaving a half-written session (`isLoggedIn` true, no token) —
///    exactly the corrupt state described in SessionManager. The same block
///    also wrote `vendorId` TWICE, once before and once after the null check
///    it should have been behind.
///
/// 2. A REJECTED REGISTRATION LOOKED LIKE NOTHING HAPPENED.
///    The success branch was `if (data["success"] == true || …) { … }` with NO
///    else. A 200 response reporting a validation failure fell through
///    silently: the spinner stopped and the screen just sat there.
///
/// 3. THE ERROR MESSAGE WAS A GUESS.
///    Every non-2xx status showed the hard-coded string "User already exists
///    with this email or phone number." — including on a 500, a timeout, or a
///    password-policy rejection. The server's own message is used when present.
///
/// 4. `TextEditingController` CREATED INSIDE `build()`.
///    `_buildCountryCityFields` built two new controllers on every rebuild —
///    leaked on each frame and reset the caret on every setState.
///
/// 5. NO CONTROLLERS WERE DISPOSED.
///
/// 6. NAVIGATION AFTER AN UNGUARDED `Future.delayed`.
///    `Future.delayed(1s, () => Navigator.pushAndRemoveUntil(context, …))` with
///    no `mounted` check — backing out during that second threw on a defunct
///    context.
///
/// 7. THE VENDOR TYPE LIST FAILING WAS INVISIBLE.
///    `_fetchVendorTypes` caught into a `print` and set loading false, so a
///    failed fetch rendered an empty, unexplained dropdown that blocked
///    registration with "Please select Business Category".
///
/// 8. `prefs.setString('vendorType', 'photographers')` HARD-CODED EVERY NEW
///    VENDOR AS A PHOTOGRAPHER, regardless of the category they picked. See
///    the fix below.
/// ----------------------------------------------------------------------------
class VendorType {
  final int id;
  final String name;

  VendorType({required this.id, required this.name});

  /// AUDIT FIX: `id: json['id']` and `name: json['name']` were assigned into
  /// non-nullable `int`/`String` fields. Any vendor-type row with a null name
  /// (or a String id) threw a TypeError inside `.map()`, which aborted the
  /// whole list and left the dropdown empty.
  factory VendorType.fromJson(Map<String, dynamic> json) {
    return VendorType(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? -1,
      name: json['name']?.toString() ?? 'Unknown',
    );
  }
}

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final _formKey = GlobalKey<FormState>();

  final _businessNameC = TextEditingController();
  final _emailC = TextEditingController();
  final _phoneC = TextEditingController();
  final _passwordC = TextEditingController();

  bool _agreeTerms = false;
  bool _isPasswordHidden = true;
  bool _isSubmitting = false;

  List<VendorType> _vendorTypes = [];
  VendorType? _selectedVendorType;
  bool _isLoadingVendorTypes = true;

  String? _selectedCountry;
  String? _selectedCity;
  List<String> _countries = [];
  Map<String, List<String>> _countryCities = {};
  bool _isLoadingCountries = true;

  /// AUDIT FIX (bug 4): the country/city fields used to build a brand new
  /// `TextEditingController` inside `build()` on every frame. These are owned
  /// by the State and disposed properly.
  final _countryCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  /// AUDIT FIX (bug 7): a failed vendor-type fetch is now visible and
  /// retryable instead of leaving an empty dropdown with no explanation.
  bool _vendorTypesFailed = false;
  bool _countriesFailed = false;

  @override
  void initState() {
    super.initState();
    _fetchVendorTypes();
    _fetchCountries();
  }

  @override
  void dispose() {
    // AUDIT FIX (bug 5): none of these were disposed before.
    _businessNameC.dispose();
    _emailC.dispose();
    _phoneC.dispose();
    _passwordC.dispose();
    _countryCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  // ---------------- Fetch Vendor Types (endpoint unchanged) ----------------
  Future<void> _fetchVendorTypes() async {
    if (mounted) {
      setState(() {
        _isLoadingVendorTypes = true;
        _vendorTypesFailed = false;
      });
    }

    try {
      final response = await http
          .get(Uri.parse('https://happywedz.com/api/vendor-types'))
          .timeout(const Duration(seconds: 25));

      if (response.statusCode != 200) {
        throw Exception('Failed to load vendor types (${response.statusCode})');
      }

      final decoded = json.decode(response.body);
      // AUDIT FIX: `final List data = json.decode(...)` threw a raw TypeError
      // when the endpoint returned its error object instead of a list.
      final List data = decoded is List ? decoded : const [];

      if (!mounted) return;
      setState(() {
        _vendorTypes = data
            .whereType<Map>()
            .map((e) => VendorType.fromJson(Map<String, dynamic>.from(e)))
            .where((v) => v.id >= 0)
            .toList();
        _isLoadingVendorTypes = false;
        _vendorTypesFailed = _vendorTypes.isEmpty;
      });
    } catch (e) {
      debugPrint("❌ Error loading vendor types: $e");
      if (!mounted) return;
      setState(() {
        _isLoadingVendorTypes = false;
        _vendorTypesFailed = true;
      });
    }
  }

  // ---------------- Fetch Countries & Cities (endpoint unchanged) ----------
  //
  // AUDIT NOTE — BACKEND/PRODUCT OBSERVATION (not changed here):
  // this hits the public third-party service `countriesnow.space` and pulls
  // EVERY country with EVERY city — a multi-megabyte payload downloaded on
  // each visit to the sign-up screen, on the vendor's mobile data, from a
  // service HappyWedz does not control. It is left in place because replacing
  // it would mean inventing an API, which the audit brief forbids. Flagged in
  // the Backend Requirements section of the audit report.
  Future<void> _fetchCountries() async {
    if (mounted) {
      setState(() {
        _isLoadingCountries = true;
        _countriesFailed = false;
      });
    }

    try {
      final response = await http
          .get(Uri.parse('https://countriesnow.space/api/v0.1/countries'))
          .timeout(const Duration(seconds: 40));

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch countries (${response.statusCode})');
      }

      final data = json.decode(response.body);
      // AUDIT FIX: `final List countriesData = data['data']` threw when the
      // service returned an error object, and `country['country']` /
      // `List<String>.from(country['cities'])` both assumed non-null.
      final countriesData = (data is Map) ? data['data'] : null;
      if (countriesData is! List) {
        throw Exception('Unexpected country list shape');
      }

      final Map<String, List<String>> countryCitiesMap = {};
      final List<String> countryList = [];

      for (final country in countriesData) {
        if (country is! Map) continue;
        final name = country['country']?.toString();
        if (name == null || name.isEmpty) continue;

        final cities = country['cities'];
        countryList.add(name);
        countryCitiesMap[name] = cities is List
            ? cities.map((c) => c.toString()).toList()
            : <String>[];
      }

      if (!mounted) return;
      setState(() {
        _countries = countryList;
        _countryCities = countryCitiesMap;
        _isLoadingCountries = false;
        _countriesFailed = countryList.isEmpty;
      });
    } catch (e) {
      debugPrint("❌ Error fetching countries: $e");
      if (!mounted) return;
      setState(() {
        _isLoadingCountries = false;
        _countriesFailed = true;
      });
    }
  }

  // ---------------- Country / City Selection ----------------
  Future<void> _selectCountry() async {
    // AUDIT FIX: tapping the field while the (large) country list was still
    // downloading did nothing at all, with no feedback.
    if (_isLoadingCountries) {
      AppSnackbar.info(context, "Loading countries… please wait a moment.");
      return;
    }
    if (_countries.isEmpty) {
      AppSnackbar.error(
        context,
        "Couldn't load the country list. Check your connection and try again.",
      );
      _fetchCountries();
      return;
    }

    final selected = await showSearch<String>(
      context: context,
      delegate: _SearchDelegate(_countries, title: "Select Country"),
    );

    // AUDIT FIX: `_SearchDelegate.buildLeading` closes with '' when the user
    // backs out, so `selected` is '' rather than null — the old `!= null`
    // check treated backing out as picking an empty country.
    if (selected != null && selected.isNotEmpty && mounted) {
      setState(() {
        _selectedCountry = selected;
        _countryCtrl.text = selected;
        _selectedCity = null;
        _cityCtrl.clear();
      });
    }
  }

  Future<void> _selectCity() async {
    if (_selectedCountry == null) {
      AppSnackbar.info(context, "Please choose a country first.");
      return;
    }

    final cities = _countryCities[_selectedCountry!] ?? [];
    if (cities.isEmpty) {
      AppSnackbar.info(
        context,
        "No cities are listed for $_selectedCountry.",
      );
      return;
    }

    final selected = await showSearch<String>(
      context: context,
      delegate: _SearchDelegate(cities, title: "Select City"),
    );

    if (selected != null && selected.isNotEmpty && mounted) {
      setState(() {
        _selectedCity = selected;
        _cityCtrl.text = selected;
      });
    }
  }

  // ---------------- Registration (endpoint / method / body unchanged) ------
  Future<void> _registerVendor() async {
    if (_isSubmitting) return; // guard against a double tap

    if (!_agreeTerms) {
      _showSnack("Please agree to the Terms & Conditions");
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    final url = Uri.parse('https://happywedz.com/api/vendor/register');

    debugPrint(
      "📢 Vendor Type Selected: ${_selectedVendorType?.name ?? 'none'}",
    );

    // Request body is byte-for-byte the same as before.
    final body = {
      "businessName": _businessNameC.text.trim(),
      "country": _selectedCountry ?? "",
      "city": _selectedCity ?? "",
      "phone": _phoneC.text.trim(),
      "email": _emailC.text.trim(),
      "password": _passwordC.text.trim(),
      "vendor_type_id": _selectedVendorType?.id.toString() ?? "",
    };

    try {
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 40));

      debugPrint("🔸 Register status: ${response.statusCode}");

      final Map<String, dynamic> data = _decodeBody(response.body);
      final serverMessage = data["message"]?.toString() ?? '';

      final bool reportedSuccess = data["success"] == true ||
          data["status"] == "success" ||
          serverMessage.toLowerCase().contains("success");

      final bool httpOk =
          response.statusCode == 200 || response.statusCode == 201;

      if (httpOk && reportedSuccess) {
        final token = data['token']?.toString().trim() ?? '';

        // AUDIT FIX (bug 1): a registration with no token cannot produce a
        // usable session. Previously `prefs.setString('authToken', null)`
        // threw here, mid-write, after `isLoggedIn` had already been set.
        if (token.isEmpty) {
          debugPrint("❌ Register: success reported but NO token returned");
          if (!mounted) return;
          _showSnack(
            "Account created, but we couldn't sign you in automatically. "
            "Please log in.",
          );
          _goToLogin();
          return;
        }

        final vendor = (data["vendor"] is Map)
            ? Map<String, dynamic>.from(data["vendor"] as Map)
            : const <String, dynamic>{};

        // AUDIT FIX (bug 1): every value is coerced instead of being handed to
        // a typed setter, and `vendorId` is written ONCE (it used to be
        // written twice — before and after the null check guarding it).
        await SessionManager.saveSession(
          token: token,
          vendorId: _asInt(vendor['id']),
          vendorTypeId:
              _asInt(vendor['vendor_type_id']) ?? _selectedVendorType?.id,
          businessName: _businessNameC.text.trim(),
          email: _emailC.text.trim(),
          profileImage: data['profile_image']?.toString(),
          vendorTypeName: _selectedVendorType?.name.trim().toLowerCase(),
        );

        final prefs = await SharedPreferences.getInstance();

        // AUDIT FIX (bug 8): this used to be
        //     await prefs.setString('vendorType', 'photographers');
        // hard-coding EVERY newly registered vendor as a photographer,
        // whatever category they had actually chosen, with an "// optional"
        // comment. The selected category is written instead. (Nothing in the
        // live app reads `vendorType` today — routing uses `vendorTypeId` —
        // so this corrects the stored value without changing behaviour.)
        final chosenType = _selectedVendorType?.name.trim().toLowerCase();
        if (chosenType != null && chosenType.isNotEmpty) {
          await prefs.setString(SessionManager.kVendorType, chosenType);
        }

        debugPrint("✅ Registration complete. vendorId=${vendor['id']}");

        if (!mounted) return;
        _showSnack("Registration successful!");

        // Check if there are pending FAQ answers
        if (prefs.containsKey(SessionManager.kPendingFaqAnswers)) {
          final pending = prefs.getString(SessionManager.kPendingFaqAnswers);
          if (pending != null) {
            try {
              final decoded = jsonDecode(pending);
              if (decoded is List) {
                // AUDIT FIX: was fire-and-forget with no error handling; a
                // malformed cached payload threw an unhandled FormatException.
                await _sendPendingFaqAnswers(
                  decoded,
                  token,
                  prefs.getInt(SessionManager.kVendorId) ?? 0,
                );
              }
            } catch (e) {
              debugPrint("⚠️ Could not replay pending FAQ answers: $e");
            }
          }
        }

        // AUDIT FIX (bug 6): the delay is awaited and the context re-checked,
        // and the Dashboard is pushed through the guard.
        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const AuthGuard(debugLabel: 'HomeScreen', child: HomeScreen()),
          ),
          (route) => false,
        );
        return;
      }

      // AUDIT FIX (bugs 2 + 3): the old code had NO else for a 2xx that
      // reported failure — the spinner simply stopped and nothing was said —
      // and every non-2xx showed the same hard-coded "user already exists"
      // string regardless of the real cause.
      if (!mounted) return;
      _showSnack(
        serverMessage.isNotEmpty
            ? serverMessage
            : _registerErrorFor(response.statusCode),
      );
    } on SocketException {
      if (mounted) {
        _showSnack("No internet connection. Check your network and try again.");
      }
    } on http.ClientException {
      if (mounted) {
        _showSnack("Couldn't reach the server. Please try again.");
      }
    } catch (e) {
      debugPrint("❌ Register error: $e");
      if (mounted) _showSnack("Something went wrong. Please try again.");
    } finally {
      // AUDIT FIX: guarded, so this cannot fire on a disposed State after the
      // success path has navigated away.
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _goToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Login()),
      (route) => false,
    );
  }

  String _registerErrorFor(int statusCode) {
    if (statusCode == 409) {
      return "An account with this email or phone number already exists.";
    }
    if (statusCode == 422 || statusCode == 400) {
      return "Please check your details and try again.";
    }
    if (statusCode == 429) {
      return "Too many attempts. Please wait a moment and try again.";
    }
    if (statusCode >= 500) {
      return "The server is not responding right now. Please try again shortly.";
    }
    return "Registration failed. Please try again.";
  }

  Map<String, dynamic> _decodeBody(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (_) {
      debugPrint("⚠️ Register: response body was not valid JSON");
      return {};
    }
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  Future<void> _sendPendingFaqAnswers(List<dynamic> answers, String token, int vendorId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final body = {
        "vendorId": vendorId,
        "vendorTypeId": prefs.getInt('vendorTypeId') ?? 1,
        "answers": answers,
      };

      final response = await http.post(
        Uri.parse("https://happywedz.com/api/faq-answers/save"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        prefs.remove('pendingFaqAnswers');
        debugPrint("✅ Pending FAQ answers submitted successfully");
      } else {
        debugPrint("❌ Failed to submit pending FAQ answers: ${response.body}");
      }
    } catch (e) {
      debugPrint("⚠️ Error sending pending FAQ answers: $e");
    }
  }
  Future<void> submitFaqAnswer(Map<String, dynamic> answerData) async {
    final prefs = await SharedPreferences.getInstance();

    final vendorId = prefs.getInt('vendorId');
    final token = prefs.getString('authToken');

    if (vendorId == null || token == null) {
      _showSnack("Vendor ID or token missing. Please log in again.");
      return;
    }

    final url = Uri.parse('https://happywedz.com/api/vendor/submit-faq'); // replace with your actual endpoint

    final body = {
      "vendor_id": vendorId,
      ...answerData, // include your FAQ answer data here
    };

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // if your API expects Bearer token
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        _showSnack(data["message"] ?? "FAQ submitted successfully!");
      } else {
        final data = json.decode(response.body);
        _showSnack("Submission failed: ${data['message'] ?? response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ FAQ submission error: $e");
      _showSnack("An error occurred. Please try again.");
    }
  }


  /// AUDIT FIX: routed through the shared snackbar so registration feedback
  /// matches the rest of the app, and guarded against a defunct context.
  void _showSnack(String message) {
    if (!mounted) return;
    final looksLikeError = message.toLowerCase().contains('success') == false;
    if (looksLikeError) {
      AppSnackbar.error(context, message);
    } else {
      AppSnackbar.success(context, message);
    }
  }

  // ---------------- Validators ----------------
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return "Please enter Phone Number";
    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
      return "Phone number must be exactly 10 digits";
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return "Please enter Email";
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return "Please enter a valid Email";
    }
    return null;
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00509D),
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
                color: Colors.white,
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
                        const SizedBox(height: 12),
                        _buildVendorTypeDropdown(),
                        const SizedBox(height: 12),
                        _buildCountryCityFields(),
                        const SizedBox(height: 12),
                        _buildTextField(
                          _emailC,
                          "Email",
                          Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          _phoneC,
                          "Phone Number",
                          Icons.phone,
                          keyboardType: TextInputType.phone,
                          validator: _validatePhone,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          _passwordC,
                          "Password",
                          Icons.lock,
                          obscureText: _isPasswordHidden,
                          suffixIcon: IconButton(
                            icon: Icon(_isPasswordHidden
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () {
                              setState(() {
                                _isPasswordHidden = !_isPasswordHidden;
                              });
                            },
                          ),
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
                        // AUDIT NOTE — PRE-EXISTING COMMENTED-OUT HANDLER,
                        // RETAINED VERBATIM. Already commented out before this
                        // audit; it silently did nothing when the terms box was
                        // unticked. The live handler below explains why instead.
                        // Do not delete without project-owner approval.
                        //
                        // onPressed: _isSubmitting
                        //     ? null
                        //     : () {
                        //   if (_formKey.currentState!.validate() &&
                        //       _agreeTerms) {
                        //     _registerVendor();
                        //   }
                        // }
                        //
                        // AUDIT FIX: the old button rendered an UNSIZED
                        // `CircularProgressIndicator` while submitting, which
                        // expanded the button to roughly three times its
                        // height and made the whole form jump. `AppButton`
                        // keeps a fixed height and blocks re-submission.
                        AppButton(
                          label: "Sign Up",
                          isLoading: _isSubmitting,
                          onPressed: () {
                            if (!_agreeTerms) {
                              _showSnack(
                                "Please accept the Terms & Conditions to continue.",
                              );
                              return;
                            }
                            if (_formKey.currentState!.validate()) {
                              _registerVendor();
                            }
                          },
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
                    MaterialPageRoute(builder: (context) => const Login()),
                  );
                },
                child: const Text(
                  "Already have an account? Log in",
                  style: TextStyle(
                    color: Colors.white,
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

  // ---------------- Helpers ----------------
  Widget _buildTextField(
      TextEditingController controller,
      String hint,
      IconData icon, {
        TextInputType keyboardType = TextInputType.text,
        bool obscureText = false,
        Widget? suffixIcon,
        String? Function(String?)? validator,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        suffixIcon: suffixIcon,
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: validator ??
              (value) {
            if (value == null || value.isEmpty) return "Please enter $hint";
            return null;
          },
    );
  }

  Widget _buildVendorTypeDropdown() {
    // AUDIT FIX: a bare, unsized `CircularProgressIndicator()` inside a Column
    // rendered as a large centred spinner that shifted the whole form when it
    // disappeared. It is now a placeholder the same height as the field it
    // replaces, so the layout does not jump.
    if (_isLoadingVendorTypes) {
      return Container(
        height: AppTheme.controlHeight,
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text("Loading categories…", style: AppTextStyles.hint),
          ],
        ),
      );
    }

    // AUDIT FIX (bug 7): a failed fetch used to leave an empty dropdown that
    // silently blocked registration. It is now explained and retryable.
    if (_vendorTypesFailed) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.errorTint,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Couldn't load business categories.",
                style: AppTextStyles.caption.copyWith(color: AppColors.error),
              ),
            ),
            TextButton(
              onPressed: _fetchVendorTypes,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<VendorType>(
      isExpanded: true,
      initialValue: _selectedVendorType,
      decoration: _dropdownDecoration(),
      hint: Text("Select Business Category", style: AppTextStyles.hint),
      style: AppTextStyles.input,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      items: _vendorTypes
          .map((vendor) => DropdownMenuItem(
                value: vendor,
                child: Text(
                  vendor.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ))
          .toList(),
      onChanged: _isSubmitting
          ? null
          : (val) => setState(() => _selectedVendorType = val),
      validator: (val) => val == null ? "Please select Business Category" : null,
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.inputFill,
      prefixIcon: const Icon(Icons.storefront_outlined,
          color: AppColors.textTertiary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildCountryCityFields() {
    return Column(
      children: [
        TextFormField(
          readOnly: true,
          // AUDIT FIX (bug 4): was `TextEditingController(text: …)` constructed
          // inline in build() — a new controller (and a leak) on every frame.
          controller: _countryCtrl,
          style: AppTextStyles.input,
          decoration: InputDecoration(
            hintText: "Select Country",
            filled: true,
            fillColor: AppColors.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide.none,
            ),
            prefixIcon:
                const Icon(Icons.public, color: AppColors.textTertiary),
            // Progress is visible in the field itself rather than only on tap.
            suffixIcon: _isLoadingCountries
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _countriesFailed
                    ? IconButton(
                        tooltip: "Retry",
                        icon: const Icon(Icons.refresh,
                            color: AppColors.error, size: 20),
                        onPressed: _fetchCountries,
                      )
                    : const Icon(Icons.keyboard_arrow_down,
                        color: AppColors.textTertiary),
          ),
          onTap: _selectCountry,
          validator: (val) =>
              val == null || val.isEmpty ? "Please select country" : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          readOnly: true,
          controller: _cityCtrl,
          style: AppTextStyles.input,
          decoration: InputDecoration(
            hintText: "Select City",
            filled: true,
            fillColor: AppColors.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.location_city,
                color: AppColors.textTertiary),
            suffixIcon: const Icon(Icons.keyboard_arrow_down,
                color: AppColors.textTertiary),
          ),
          onTap: _selectCity,
          validator: (val) =>
              val == null || val.isEmpty ? "Please select city" : null,
        ),
      ],
    );
  }
}

// ---------------- Search Delegate ----------------
class _SearchDelegate extends SearchDelegate<String> {
  final List<String> items;
  final String title;

  _SearchDelegate(this.items, {required this.title})
      : super(searchFieldLabel: title);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results =
    items.where((e) => e.toLowerCase().contains(query.toLowerCase())).toList();
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (_, i) => ListTile(
        title: Text(results[i]),
        onTap: () => close(context, results[i]),
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions =
    items.where((e) => e.toLowerCase().contains(query.toLowerCase())).toList();
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (_, i) => ListTile(
        tileColor: Colors.white,
        title: Text(suggestions[i]),
        onTap: () => close(context, suggestions[i]),
      ),
    );
  }
}
