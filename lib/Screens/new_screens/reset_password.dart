import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:happy_weds_vendors/utils/api_config.dart';

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
        Uri.parse("${ApiConfig.baseUrl}/vendor/reset-password"),
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

        // AUDIT FIX: context used after an await — guard added.
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"])),
        );

        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        // AUDIT FIX: context used after an await — guard added.
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Reset failed")),
        );
      }
    } catch (e) {
      // AUDIT FIX: context used after an await — guard added.
      if (!mounted) return;
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
