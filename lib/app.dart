import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/colors.dart';
import 'services/auth_service.dart';
import 'models/user_model.dart';

// Auth Screens
import 'screen/login_screen.dart';
import 'screen/register_screen.dart';

// User Screens
import 'screen/home_screen.dart';
import 'screen/profile_screen.dart';
import 'screen/search_screen.dart';
import 'screen/recommendation_screen.dart';
import 'screen/recommendation_full_screen.dart';
import 'screen/specific_choices_screen.dart';
import 'screen/materials_screen.dart';
import 'screen/material_detail_screen.dart';

// Admin Screens
import 'screen/admin/admin_dashboard_screen.dart';
import 'screen/admin/subject_admin.dart';
import 'screen/admin/material_admin.dart';
import 'screen/admin/rule_admin.dart';
import 'screen/admin/admin_user_screen.dart';

class SageMindApp extends StatelessWidget {
  const SageMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "SageMind",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // Auth check
      home: FutureBuilder<UserModel?>(
        future: AuthService().getUserFromPrefs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Not logged in → Login page
          if (!snapshot.hasData || snapshot.data == null) {
            return const LoginScreen();
          }

          final user = snapshot.data!;

          // Admin redirects to dashboard
          if (user.role == "admin") {
            return const AdminDashboardScreen();
          }

          // User → Main app shell with navigation bar
          return const MainUserShell();
        },
      ),

      routes: {
        "/user": (_) => const MainUserShell(),
        "/login": (_) => const LoginScreen(),
        "/register": (_) => const RegisterScreen(),
        "/recommendation": (_) => const RecommendationScreen(),
        "/recommendation/full": (_) => const RecommendationFullScreen(),
        "/specific_choices": (_) => const SpecificChoicesScreen(),
        "/materials": (_) => const MaterialsScreen(),
        "/material_detail": (_) => const MaterialDetailScreen(),

        // Admin Routes
        "/admin": (_) => const AdminDashboardScreen(),
        "/admin/subjects": (_) => const AdminSubjectScreen(),
        "/admin/materials": (_) => const AdminMaterialScreen(),
        "/admin/rules": (_) => const AdminRuleScreen(),
        "/admin/users": (_) => const AdminUserScreen(),
      },
    );
  }
}

class MainUserShell extends StatefulWidget {
  const MainUserShell({super.key});

  @override
  State<MainUserShell> createState() => _MainUserShellState();
}

class _MainUserShellState extends State<MainUserShell> {
  int _index = 0;

  // ⚡ No rebuild of entire MaterialApp
  final List<Widget> _pages = [
    HomeScreen(),
    const SearchScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack( // keeps state, smooth & fast
        index: _index,
        children: _pages,
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        backgroundColor: SMColors.blue,
        selectedItemColor: SMColors.white,
        unselectedItemColor: SMColors.black,
        showSelectedLabels: true,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: "Cari",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profil",
          ),
        ],
      ),
    );
  }
}
