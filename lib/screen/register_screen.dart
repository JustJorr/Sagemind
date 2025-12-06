import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../core/theme/colors.dart';
import 'home_screen.dart';
import 'admin/admin_dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  final Color mainBlue = SMColors.blue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // CHANGED
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  "SageMind",
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: mainBlue, // CHANGED
                  ),
                ),
              ),
              const SizedBox(height: 40),

              _buildField("Email", _emailController),
              const SizedBox(height: 16),

              _buildField("Username", _usernameController),
              const SizedBox(height: 16),

              _buildField("Password", _passwordController, obscure: true),
              const SizedBox(height: 16),

              _buildField("Confirm Password", _confirmPasswordController, obscure: true),
              const SizedBox(height: 28),

              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.black))
                  : ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainBlue, // CHANGED
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Register",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),

              const SizedBox(height: 16),

              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Already have an account? Login",
                    style: TextStyle(color: Colors.black87), // CHANGED
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool obscure = false}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.black), // CHANGED
      cursorColor: Colors.black, // CHANGED
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black87), // CHANGED
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black26), // CHANGED
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black), // CHANGED
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return "Please enter $label";
        if (label == "Email" && !v.contains("@")) return "Enter a valid email";
        if (label == "Confirm Password" && v != _passwordController.text) {
          return "Passwords do not match";
        }
        return null;
      },
    );
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      UserModel? user = await _authService.register(
        _emailController.text.trim(),
        _passwordController.text,
        _usernameController.text.trim(),
        "user", // DEFAULT ROLE
      );

      setState(() => _isLoading = false);

      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                user.role == "admin" ? const AdminDashboardScreen() : HomeScreen(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration failed")),
        );
      }
    }
  }
}
