import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    _currentUser = await _authService.getCurrentUser();
    setState(() {});
  }

  Future<void> _logout() async {
    await _authService.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // ⬅ LEFT ALIGN INFO
            children: [
              const SizedBox(height: 16),

              // Centered title ONLY
              const Center(
                child: Text(
                  "Profil",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // User Info (Left aligned)
              if (_currentUser != null) ...[
                _infoTile("Username", _currentUser!.username),
                const SizedBox(height: 12),

                _infoTile("Email", _currentUser!.email),
                const SizedBox(height: 12),

                _infoTile("Role", _currentUser!.role),
                const SizedBox(height: 32),

                if (_currentUser!.role == 'admin')
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/admin');
                    },
                    child: const Text("Masuk Admin Panel"),
                  ),

                const SizedBox(height: 16),

                // Centered logout button ONLY
                Center(
                  child: ElevatedButton(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text("Logout"),
                  ),
                ),
              ] else ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 24),

                Center(
                  child: ElevatedButton(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Logout"),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  // Reusable info item (still left aligned)
  Widget _infoTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // ⬅ LEFT ALIGN TEXT
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
