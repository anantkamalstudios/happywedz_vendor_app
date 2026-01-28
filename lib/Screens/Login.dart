import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'SignUp.dart';
import 'HomeScreen.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final _emailC = TextEditingController();
  final _passwordC = TextEditingController();

  bool _rememberMe = false;
  bool _isLoading = false;
  bool _isPasswordHidden = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _checkIfLoggedIn();
  }

  // ---------------- Load saved email/password ----------------
  void _loadSavedCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailC.text = prefs.getString('email') ?? '';
      _passwordC.text = prefs.getString('savedPassword') ?? '';
      _rememberMe = _emailC.text.isNotEmpty && _passwordC.text.isNotEmpty;
    });
  }

  // ---------------- Check if user is already logged in ----------------
  void _checkIfLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      });
    }
  }

  // ---------------- Login API ----------------
  Future<void> _loginVendor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final url = Uri.parse('https://happywedz.com/api/vendor/login');
    final body = {
      "email": _emailC.text.trim(),
      "password": _passwordC.text.trim(),
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      );

      final data = json.decode(response.body);
      print("🔸 Login Response: ${response.body}");

      if (response.statusCode == 200 &&
          (data["message"]?.toLowerCase().contains("success") ?? false)) {
        final prefs = await SharedPreferences.getInstance();
        final vendorData = data['vendor'] ?? data['data'] ?? {};

        // 🟢 Debug Prints
        print("📢 Vendor ID: ${vendorData['id']}");
        print("📢 Vendor Type ID: ${vendorData['vendor_type_id']}");
        print("📢 Business Name: ${vendorData['businessName']}");
        print("📢 Profile Completed: ${vendorData['profile_completed']}");

        // ✅ Save all vendor details (same keys as SignUp)
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('authToken', data['token'] ?? "");
        await prefs.setString('token', data['token'] ?? "");
        await prefs.setInt('vendorId', vendorData['id']);
        await prefs.setInt('vendorTypeId', vendorData['vendor_type_id']);
        await prefs.setString('businessName', vendorData['businessName'] ?? "");
        await prefs.setString('email', vendorData['email'] ?? "");
        await prefs.setString('phone', vendorData['phone'] ?? "");
        await prefs.setString('profileImage', vendorData['profileImage'] ?? "");
        await prefs.setBool(
          'profileCompleted',
          vendorData['profile_completed'] ?? false,
        );

        // ✅ Get Vendor Type Name from API (so florist stays florist)
        try {
          final typeRes = await http.get(
            Uri.parse(
              'https://happywedz.com/api/vendor-types/${vendorData['vendor_type_id']}',
            ),
          );
          if (typeRes.statusCode == 200) {
            final typeData = json.decode(typeRes.body);
            await prefs.setString(
              'vendorTypeName',
              typeData['name'].toString(),
            );
            print("🌸 Vendor Type Name: ${typeData['name']}");
          } else {
            print("⚠️ Could not fetch vendor type name, saving ID only");
          }
        } catch (e) {
          print("❌ Vendor type fetch failed: $e");
        }

        // ✅ Navigate properly
        _showSnack(data["message"] ?? "Login successful");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        _showSnack(data["message"] ?? "Login failed");
      }
    } catch (e) {
      print("❌ Login error: $e");
      _showSnack("An error occurred. Please try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return "Please enter Email";
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return "Please enter a valid Email";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00509D),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Image.asset("assets/images/logoo.png", height: 80),
              const SizedBox(height: 8),
              const Text(
                "Vendor Login",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
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
                          _emailC,
                          "Email",
                          Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          _passwordC,
                          "Password",
                          Icons.lock,
                          obscureText: _isPasswordHidden,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordHidden
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordHidden = !_isPasswordHidden;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 8),
                        // Row(
                        //   children: [
                        //     Checkbox(
                        //       value: _rememberMe,
                        //       onChanged: (val) =>
                        //           setState(() => _rememberMe = val!),
                        //     ),
                        //     const Text("Remember me"),
                        //     const Spacer(),
                        //   ],
                        // ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                "Forgot Password?",
                                style: TextStyle(
                                  color: Color(0xFF00509D),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                             // const SizedBox(height: 2),
                            // Row(
                            //   children: [
                            //     Checkbox(
                            //       value: _rememberMe,
                            //       onChanged: (val) =>
                            //           setState(() => _rememberMe = val!),
                            //     ),
                            //     const Text("Remember me"),
                            //   ],
                            // ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00509D),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _isLoading ? null : _loginVendor,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "Login",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white, // added white color
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
                    MaterialPageRoute(builder: (context) => const SignUp()),
                  );
                },
                child: const Text(
                  "Don't have an account? Sign Up",
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
      validator:
          validator ??
          (value) {
            if (value == null || value.isEmpty) return "Please enter $hint";
            return null;
          },
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
    );
  }
}





class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailC = TextEditingController();
  bool _loading = false;

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final response = await http.post(
        Uri.parse("https://happywedz.com/api/vendor/forgot-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _emailC.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["status"] == "success") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"])),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(
              email: _emailC.text.trim(),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Something went wrong")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Server error, try again later")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF00509D),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Image.asset(
              "assets/images/logoo.png",
              height: 80,
            ),

            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Reset Your Password",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 6),
                            const Text(
                              "Enter your email to receive a password reset link",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),

                            const SizedBox(height: 20),

                            TextFormField(
                              controller: _emailC,
                              keyboardType: TextInputType.emailAddress,
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return "Email required";
                                }
                                if (!val.contains("@")) {
                                  return "Enter valid email";
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: "Email Address",
                                prefixIcon: const Icon(Icons.email),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                  const Color(0xFF00509D),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed:
                                _loading ? null : _sendResetLink,
                                child: _loading
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                    : const Text(
                                  "Send Reset Link",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Text(
                                "Remember your password? Login",
                                style: TextStyle(
                                  color: Color(0xFF00509D),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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






class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _otpC = TextEditingController();
  final TextEditingController _newPassC = TextEditingController();
  final TextEditingController _confirmPassC = TextEditingController();

  bool _loading = false;
  bool _hideNew = true;
  bool _hideConfirm = true;

  // 🔐 Strong password validation
  String? validatePassword(String value) {
    if (value.length < 8) {
      return "Minimum 8 characters required";
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return "At least 1 uppercase letter";
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return "At least 1 lowercase letter";
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return "At least 1 number";
    }
    if (!RegExp(r'[@$!%*?&]').hasMatch(value)) {
      return "At least 1 special character (@\$!%*?&)";
    }
    return null;
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final res = await http.post(
        Uri.parse("https://happywedz.com/api/vendor/reset-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": widget.email,
          "otp": _otpC.text.trim(),
          "newPassword": _newPassC.text.trim(),
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data["status"] == "success") {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", data["token"]);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"])),
        );

        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Reset failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Server error")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF00509D),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Image.asset(
              "assets/images/logoo.png",
              height: 80,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Text(
                                "Verify Your Account",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            const SizedBox(height: 6),
                            Center(
                              child: Text(
                                "OTP sent to ${widget.email}",
                                style:
                                const TextStyle(color: Colors.grey),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // OTP
                            TextFormField(
                              controller: _otpC,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              validator: (v) =>
                              v == null || v.length != 6
                                  ? "Enter valid 6 digit OTP"
                                  : null,
                              decoration: const InputDecoration(
                                labelText: "Verification Code",
                                counterText: "",
                              ),
                            ),

                            const SizedBox(height: 12),

                            // New Password
                            TextFormField(
                              controller: _newPassC,
                              obscureText: _hideNew,
                              validator: (v) =>
                                  validatePassword(v ?? ""),
                              decoration: InputDecoration(
                                labelText: "New Password",
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _hideNew
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () => setState(
                                          () => _hideNew = !_hideNew),
                                ),
                              ),
                            ),

                            const SizedBox(height: 6),

                            // Password rules hint
                            const Text(
                              "• Minimum 8 characters\n"
                                  "• At least 1 uppercase letter\n"
                                  "• At least 1 lowercase letter\n"
                                  "• At least 1 number\n"
                                  "• At least 1 special character (@\$!%*?&)",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Confirm Password
                            TextFormField(
                              controller: _confirmPassC,
                              obscureText: _hideConfirm,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return "Confirm password required";
                                }
                                if (v != _newPassC.text) {
                                  return "Passwords do not match";
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: "Confirm New Password",
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _hideConfirm
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () => setState(() =>
                                  _hideConfirm = !_hideConfirm),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                  const Color(0xFF00509D),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                ),
                                onPressed:
                                _loading ? null : _resetPassword,
                                child: _loading
                                    ? const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                )
                                    : const Text(
                                  "Reset Password",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            Center(
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Text(
                                  "← Back to Email",
                                  style: TextStyle(
                                    color: Color(0xFF00509D),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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