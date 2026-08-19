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
import 'SignUp.dart';
import 'HomeScreen.dart';
import 'new_screens/forget_password_screen.dart';

/// ============================================================================
/// Login — vendor authentication
/// ============================================================================
///
/// API INTEGRATION IS UNCHANGED:
///   POST https://happywedz.com/api/vendor/login
///        headers: {"Content-Type": "application/json"}
///        body:    {"email": …, "password": …}
///   GET  https://happywedz.com/api/vendor-types/{vendor_type_id}
///
/// Same URLs, same methods, same headers, same request bodies, same response
/// keys, same SharedPreferences keys. Only the handling of those responses was
/// hardened.
///
/// AUDIT NOTE — BUGS FIXED
///
/// 1. CRASH ON A PARTIAL LOGIN RESPONSE (high severity).
///        await prefs.setInt('vendorId', vendorData['id']);
///        await prefs.setInt('vendorTypeId', vendorData['vendor_type_id']);
///    `setInt` is typed `Future<bool> setInt(String, int)`. When the API omits
///    either field — or returns it as a String, which the register endpoint
///    does — this throws `type 'Null' is not a subtype of type 'int'`. The
///    throw happened AFTER `isLoggedIn` had already been written to true, so
///    the vendor ended up flagged as logged in, stranded on the Login screen,
///    and one restart away from a Dashboard with no vendorId. Values are now
///    coerced defensively and the token is validated before anything is saved.
///
/// 2. `setState` AFTER `dispose` (crash in debug, red screen).
///    The old `finally { setState(() => _isLoading = false); }` ran after
///    `Navigator.pushReplacement` had already disposed this route on the
///    success path. Now guarded with `mounted`.
///
/// 3. LOGIN SUCCEEDED WITH NO TOKEN.
///    The success branch keyed only off `message.contains("success")`, so a
///    200 whose body carried a message but no token still set
///    `isLoggedIn = true` and pushed the Dashboard — the exact tokenless
///    session described in SessionManager. A token is now mandatory.
///
/// 4. RAW EXCEPTIONS AND `use_build_context_synchronously`.
///    `_showSnack` was called after awaits without a `mounted` check.
///
/// 5. `_checkIfLoggedIn` REDIRECTED ON A BOOL ALONE — same bypass as Splash.
/// ----------------------------------------------------------------------------
class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final _emailC = TextEditingController();
  final _passwordC = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _rememberMe = false;
  bool _isLoading = false;
  bool _isPasswordHidden = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _checkIfLoggedIn();
  }

  @override
  void dispose() {
    // AUDIT FIX: none of these controllers were disposed before — every visit
    // to the Login screen leaked two TextEditingControllers.
    _emailC.dispose();
    _passwordC.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ---------------- Load saved email/password ----------------
  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();

    // AUDIT FIX: was `void ... async` with an unguarded setState, which threw
    // if the user backed out of Login before prefs resolved.
    if (!mounted) return;

    setState(() {
      _emailC.text = prefs.getString(SessionManager.kEmail) ?? '';
      _passwordC.text = prefs.getString(SessionManager.kSavedPassword) ?? '';
      _rememberMe = _emailC.text.isNotEmpty && _passwordC.text.isNotEmpty;
    });
  }

  // ---------------- Check if user is already logged in ----------------
  Future<void> _checkIfLoggedIn() async {
    // AUDIT FIX: previously `prefs.getBool('isLoggedIn')` only. See the class
    // doc — a flag without a token is not a session.
    final isAuthenticated = await SessionManager.isAuthenticated();
    if (!isAuthenticated || !mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const AuthGuard(debugLabel: 'HomeScreen', child: HomeScreen()),
        ),
      );
    });
  }

  // ---------------- Login API (UNCHANGED ENDPOINT / METHOD / BODY) ----------
  Future<void> _loginVendor() async {
    if (_isLoading) return; // guard against a double tap
    if (!_formKey.currentState!.validate()) return;

    // Dismiss the keyboard so the response snackbar is visible.
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    final url = Uri.parse('https://happywedz.com/api/vendor/login');
    final body = {
      "email": _emailC.text.trim(),
      "password": _passwordC.text.trim(),
    };

    try {
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: json.encode(body),
          )
          // AUDIT FIX: no timeout existed. On a captive-portal / stalled
          // connection the button span forever with no way out.
          .timeout(const Duration(seconds: 30));

      final Map<String, dynamic> data = _decodeBody(response.body);
      debugPrint("🔸 Login status: ${response.statusCode}");

      final message = data["message"]?.toString() ?? '';
      final isSuccessMessage = message.toLowerCase().contains("success");

      final vendorData = Map<String, dynamic>.from(
        (data['vendor'] ?? data['data'] ?? const {}) as Map,
      );
      final token = data['token']?.toString().trim() ?? '';

      // AUDIT FIX (bug 3): a 200 + "success" is NOT enough — without a token
      // there is no usable session.
      if (response.statusCode == 200 && isSuccessMessage && token.isNotEmpty) {
        await _persistSession(vendorData: vendorData, token: token);
        await _fetchAndSaveVendorTypeName(vendorData['vendor_type_id']);

        if (!mounted) return;
        AppSnackbar.success(context, message.isEmpty ? "Login successful" : message);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const AuthGuard(debugLabel: 'HomeScreen', child: HomeScreen()),
          ),
        );
        // Deliberately no setState after this point — the route is gone.
        return;
      }

      if (!mounted) return;

      if (response.statusCode == 200 && isSuccessMessage && token.isEmpty) {
        // Distinct copy: the credentials were right but the server did not
        // return a token, which is a backend problem, not a user error.
        AppSnackbar.error(
          context,
          "Signed in, but the server didn't return a session. Please try again.",
        );
        debugPrint("❌ Login: 200 + success message but NO token in response");
      } else {
        AppSnackbar.error(
          context,
          message.isNotEmpty ? message : _loginErrorFor(response.statusCode),
        );
      }
    } on SocketException {
      if (mounted) {
        AppSnackbar.error(
          context,
          "No internet connection. Check your network and try again.",
        );
      }
    } on http.ClientException {
      if (mounted) {
        AppSnackbar.error(context, "Couldn't reach the server. Please try again.");
      }
    } catch (e) {
      // AUDIT FIX: never surface the raw exception text to the vendor.
      debugPrint("❌ Login error: $e");
      if (mounted) {
        AppSnackbar.error(context, "Something went wrong. Please try again.");
      }
    } finally {
      // AUDIT FIX (bug 2): guarded so this cannot fire on a disposed State.
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Maps an HTTP status from the login endpoint to user-facing copy.
  String _loginErrorFor(int statusCode) {
    if (statusCode == 401 || statusCode == 403) {
      return "Incorrect email or password.";
    }
    if (statusCode == 404) return "No account found with this email.";
    if (statusCode == 429) return "Too many attempts. Please wait and try again.";
    if (statusCode >= 500) {
      return "The server is not responding right now. Please try again shortly.";
    }
    return "Login failed. Please try again.";
  }

  /// Decodes a response body without letting a malformed payload throw a raw
  /// FormatException into the UI.
  Map<String, dynamic> _decodeBody(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (_) {
      debugPrint("⚠️ Login: response body was not valid JSON");
      return {};
    }
  }

  /// Writes the session using the SAME SharedPreferences keys as before.
  ///
  /// AUDIT FIX (bug 1): every field is coerced instead of being passed
  /// straight into a typed setter, so a missing or differently-typed field in
  /// the API response can no longer abort the login half-way through.
  Future<void> _persistSession({
    required Map<String, dynamic> vendorData,
    required String token,
  }) async {
    await SessionManager.saveSession(
      token: token,
      vendorId: _asInt(vendorData['id']),
      vendorTypeId: _asInt(vendorData['vendor_type_id']),
      businessName: vendorData['businessName']?.toString(),
      phone: vendorData['phone']?.toString(),
      profileImage: vendorData['profileImage']?.toString(),
      profileCompleted: vendorData['profile_completed'] == true,
    );

    if (_asInt(vendorData['id']) == null) {
      // Surfaced loudly in logs because most Storefront/Statistics endpoints
      // are keyed on vendorId — see the Backend Requirements section of the
      // audit report.
      debugPrint(
        "⚠️ Login response contained no usable vendor id — "
        "vendorId-dependent screens (Storefront, Statistics) will be limited",
      );
    }

    // ================= REMEMBER ME (behaviour unchanged) =================
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString(SessionManager.kEmail, _emailC.text.trim());
      await prefs.setString(
        SessionManager.kSavedPassword,
        _passwordC.text.trim(),
      );
    } else {
      await prefs.remove(SessionManager.kEmail);
      await prefs.remove(SessionManager.kSavedPassword);
    }
  }

  /// GET /api/vendor-types/{id} — unchanged endpoint, unchanged purpose
  /// (keeps "florist" a florist). Only made failure-tolerant.
  Future<void> _fetchAndSaveVendorTypeName(dynamic vendorTypeId) async {
    final id = _asInt(vendorTypeId);
    if (id == null) {
      debugPrint("⚠️ No vendor_type_id in login response — skipping type lookup");
      return;
    }

    try {
      final typeRes = await http
          .get(Uri.parse('https://happywedz.com/api/vendor-types/$id'))
          .timeout(const Duration(seconds: 15));

      if (typeRes.statusCode == 200) {
        final typeData = json.decode(typeRes.body);
        final name = (typeData is Map ? typeData['name'] : null)?.toString();
        if (name != null && name.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(SessionManager.kVendorTypeName, name);
          debugPrint("🌸 Vendor Type Name: $name");
        }
      } else {
        debugPrint("⚠️ Could not fetch vendor type name (${typeRes.statusCode})");
      }
    } catch (e) {
      // Non-fatal: the vendor type ID is already saved, and the FAQ routing in
      // Storefront keys off the ID rather than the name.
      debugPrint("❌ Vendor type fetch failed: $e");
    }
  }

  /// Accepts int, num or numeric String and returns null for anything else.
  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  // ---------------- Validators ----------------
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return "Please enter Email";
    if (!RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(value.trim())) {
      return "Please enter a valid Email";
    }
    return null;
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      // AUDIT FIX: `resizeToAvoidBottomInset` defaults true, but the previous
      // layout had no bottom padding for the keyboard inset, so on short
      // devices the Sign-Up link sat under the keyboard with no way to scroll
      // to it. The viewInsets padding below fixes that.
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                left: AppTheme.spaceLg,
                right: AppTheme.spaceLg,
                top: AppTheme.spaceXl,
                bottom: AppTheme.spaceXl +
                    MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  // Keeps the card vertically centred on tall screens and
                  // scrollable on short ones.
                  minHeight: constraints.maxHeight - (AppTheme.spaceXl * 2),
                  // AUDIT FIX (responsive): on tablets the card previously
                  // stretched edge to edge and looked broken.
                  maxWidth: 480,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      Image.asset(
                        "assets/images/logoo.png",
                        height: 80,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.storefront_rounded,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Vendor Login",
                        style: AppTextStyles.h2.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Sign in to manage your business",
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceXl),
                      _loginCard(),
                      const SizedBox(height: AppTheme.spaceXl),
                      _signUpLink(),
                      const SizedBox(height: AppTheme.spaceLg),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _loginCard() {
    return Card(
      color: AppColors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _emailC,
                focusNode: _emailFocus,
                hint: "Email",
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: _validateEmail,
                onSubmitted: (_) => _passwordFocus.requestFocus(),
              ),
              const SizedBox(height: AppTheme.spaceMd),
              _buildTextField(
                controller: _passwordC,
                focusNode: _passwordFocus,
                hint: "Password",
                icon: Icons.lock_outline,
                obscureText: _isPasswordHidden,
                // AUDIT FIX: submitting from the keyboard did nothing before.
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _isLoading ? null : _loginVendor(),
                suffixIcon: IconButton(
                  tooltip: _isPasswordHidden ? "Show password" : "Hide password",
                  icon: Icon(
                    _isPasswordHidden
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textTertiary,
                  ),
                  onPressed: () => setState(
                    () => _isPasswordHidden = !_isPasswordHidden,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spaceSm),

              // AUDIT FIX (RenderFlex overflow): "Remember me" and "Forgot
              // Password?" previously sat in a Column with
              // crossAxisAlignment.end, which right-aligned the checkbox row
              // and pushed its label off-centre. They are now a single Row —
              // checkbox left, link right — with the link wrapped so a long
              // translation cannot overflow.
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: (val) async {
                        final next = val ?? false;
                        setState(() => _rememberMe = next);

                        if (!next) {
                          // Unchecking clears the stored credentials
                          // immediately — behaviour preserved from before.
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.remove(SessionManager.kSavedPassword);
                          await prefs.remove(SessionManager.kEmail);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _rememberMe = !_rememberMe),
                      child: Text("Remember me", style: AppTextStyles.body),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen(),
                      ),
                    ),
                    child: Text(
                      "Forgot Password?",
                      style: AppTextStyles.captionMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppTheme.spaceXl),

              // AUDIT FIX: the button is disabled while the request is in
              // flight, so the login endpoint cannot be hit twice.
              AppButton(
                label: "Login",
                isLoading: _isLoading,
                onPressed: _loginVendor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _signUpLink() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: AppTextStyles.body.copyWith(color: Colors.white70),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SignUp()),
          ),
          child: Text(
            "Sign Up",
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    FocusNode? focusNode,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      enabled: !_isLoading, // fields lock while the request runs
      style: AppTextStyles.input,
      onFieldSubmitted: onSubmitted,
      validator: validator ??
          (value) {
            if (value == null || value.trim().isEmpty) {
              return "Please enter $hint";
            }
            return null;
          },
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.textTertiary),
        suffixIcon: suffixIcon,
        hintText: hint,
        filled: true,
        fillColor: AppColors.inputFill,
      ),
    );
  }
}