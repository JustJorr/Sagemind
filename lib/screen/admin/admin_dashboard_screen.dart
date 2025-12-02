import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
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
        title: Text(title, style: const TextStyle(fontSize: 18)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }
}
