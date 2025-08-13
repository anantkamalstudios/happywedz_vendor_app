import 'package:flutter/material.dart';

import 'SignUp.dart';
import 'home.dart';

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

  @override
  void dispose() {
    _emailC.dispose();
    _passwordC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[300],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              /// Logo
              Image.asset("assets/images/logoo.png", height: 80),
              const SizedBox(height: 8),
              const Text(
                "Vendor Login",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              /// Card-style login form
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
                        _buildTextField(_emailC, "Email / Phone", Icons.person),
                        const SizedBox(height: 12),
                        _buildTextField(
                          _passwordC,
                          "Password",
                          Icons.lock,
                          obscureText: true,
                        ),
                        const SizedBox(height: 8),

                        /// Remember Me
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (val) =>
                                  setState(() => _rememberMe = val!),
                            ),
                            const Text("Remember me"),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                // Forgot password logic
                              },
                              child: const Text(
                                "Forgot Password?",
                                style: TextStyle(
                                  color: Color(0xFFE91E63),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        /// Login button
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
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HomeScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              "Login",
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

              /// Sign up redirect
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
}
