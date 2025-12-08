import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final auth = AuthService();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "Logout",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await auth.logout();

      if (context.mounted) {
      Navigator.pushReplacementNamed(context, "/login");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- Admin Info Card ---
            Card(
              color: Colors.blue.shade50,
              child: ListTile(
                leading: const Icon(
                  Icons.admin_panel_settings,
                  size: 40,
                  color: Colors.blue,
                ),
                title: const Text(
                  "Administrator Panel",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle:
                    const Text("Manage subjects, materials, rules"),
              ),
            ),

            const SizedBox(height: 16),

            // --- Dashboard Menu ---
            Expanded(
              child: ListView(
                children: [
                  _menuCard(
                    context,
                    title: "Manage Subjects",
                    icon: Icons.menu_book_rounded,
                    route: "/admin/subjects",
                  ),
                  const SizedBox(height: 12),
                  _menuCard(
                    context,
                    title: "Manage Materials",
                    icon: Icons.library_books,
                    route: "/admin/materials",
                  ),
                  const SizedBox(height: 12),
                  _menuCard(
                    context,
                    title: "Manage Rules",
                    icon: Icons.rule_folder,
                    route: "/admin/rules",
                  ),

                  // --- Switch to User View (NEW BUTTON) ---
                  Card(
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.switch_account, size: 32),
                      title: const Text(
                        "Switch to User View",
                        style: TextStyle(fontSize: 18),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.pushReplacementNamed(context, "/user");
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- Logout Button ---
            ElevatedButton(
              onPressed: () => _logout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text("Logout"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String route,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }
}
