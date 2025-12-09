import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_services.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirestoreServices _fs = FirestoreServices();
  
  int _totalSubjects = 0;
  int _totalMaterials = 0;
  int _totalRules = 0;
  int _totalUsers = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final subjects = await _fs.getSubjectsOnce();
      final rules = await _fs.getAllRules();
      final materials = await _fs.getAllKnowledge();
      final users = await _fs.getAllUsers();

      setState(() {
        _totalSubjects = subjects.length;
        _totalMaterials = materials.length;
        _totalRules = rules.length;
        _totalUsers = users.length;
        _loading = false;
      });
    } catch (e) {
      print("Error loading statistics: $e");
      setState(() => _loading = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final auth = AuthService();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Apakah Anda yakin ingin logout?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Batal"),
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
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel Admin"),
        centerTitle: true,
        elevation: 0,
      ),
      drawer: isMobile ? _buildSidebar() : null,
      body: Row(
        children: [
          // Sidebar for desktop
          if (!isMobile)
            Container(
              width: 250,
              color: Colors.grey[100],
              child: _buildSidebar(),
            ),
          // Main content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: ListView(
                      children: [
                        // Header
                        const Text(
                          "Selamat Datang, Admin",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Kelola konten pembelajaran Anda",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Statistics Grid
                        const Text(
                          "Statistik",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          crossAxisCount: isMobile ? 2 : 4,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          children: [
                            _buildStatCard(
                              title: "Mata Pelajaran",
                              count: _totalSubjects,
                              icon: Icons.menu_book_rounded,
                              color: Colors.blue,
                            ),
                            _buildStatCard(
                              title: "Materi",
                              count: _totalMaterials,
                              icon: Icons.library_books,
                              color: Colors.green,
                            ),
                            _buildStatCard(
                              title: "Aturan",
                              count: _totalRules,
                              icon: Icons.rule_folder,
                              color: Colors.orange,
                            ),
                            _buildStatCard(
                              title: "Pengguna",
                              count: _totalUsers,
                              icon: Icons.people,
                              color: Colors.purple,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Panel Admin",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          _buildSidebarItem(
            icon: Icons.menu_book_rounded,
            title: "Kelola Mata Pelajaran",
            route: "/admin/subjects",
          ),
          _buildSidebarItem(
            icon: Icons.library_books,
            title: "Kelola Materi",
            route: "/admin/materials",
          ),
          _buildSidebarItem(
            icon: Icons.rule_folder,
            title: "Kelola Aturan",
            route: "/admin/rules",
          ),
          const Divider(),
          _buildSidebarItem(
            icon: Icons.switch_account,
            title: "Tampilan Pengguna",
            route: "/user",
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    required String route,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        size: 24,
        color: Colors.black87,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Navigator.pushNamed(context, route);
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}