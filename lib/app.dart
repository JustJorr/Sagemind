import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/colors.dart';

// User Screens
import 'screen/home_screen.dart';
import 'screen/profile_screen.dart';
import 'screen/search_screen.dart';
import 'screen/recommendation_screen.dart';
import 'screen/recommendation_full_screen.dart';
import 'screen/specific_choices_screen.dart';
import 'screen/materials_screen.dart';
import 'screen/material_detail_screen.dart';

// Admin Screens (correct folders)
import 'screen/admin/admin_dashboard_screen.dart';
import 'screen/admin/admin_subject_screen.dart';
import 'screen/admin/admin_material_screen.dart';
import 'screen/admin/admin_rule_screen.dart';

class SageMindApp extends StatefulWidget {
  const SageMindApp({super.key});

  @override
  State<SageMindApp> createState() => _SageMindAppState();
}

class _SageMindAppState extends State<SageMindApp> {
  int _index = 0;

  static final List<Widget> _pages = [
    HomeScreen(),
    const ProfileScreen(),
    const SearchScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "SageMind",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      home: Scaffold(
        body: _pages[_index],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          backgroundColor: SMColors.blue,
          selectedItemColor: SMColors.white,
          unselectedItemColor: SMColors.black,
          showSelectedLabels: true,
          showUnselectedLabels: false,
          items: [
            BottomNavigationBarItem(
              label: "Home",
              icon: AnimatedScale(
                scale: _index == 0 ? 1.3 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.home),
              ),
            ),
            BottomNavigationBarItem(
              label: "Profil",
              icon: AnimatedScale(
                scale: _index == 1 ? 1.3 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.person),
              ),
            ),
            BottomNavigationBarItem(
              label: "Cari",
              icon: AnimatedScale(
                scale: _index == 2 ? 1.3 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.search),
              ),
            ),
          ],
        ),
      ),

      routes: {
        "/recommendation": (_) => const RecommendationScreen(),
        "/recommendation/full": (_) => const RecommendationFullScreen(),
        "/specific_choices": (_) => const SpecificChoicesScreen(),
        "/materials": (_) => const MaterialsScreen(),
        "/material/detail": (_) => const MaterialDetailScreen(),

        // Admin
        "/admin": (_) => const AdminDashboardScreen(),
        "/admin/subjects": (_) => const AdminSubjectScreen(),
        "/admin/materials": (_) => const AdminMaterialScreen(),
        "/admin/rules": (_) => const AdminRuleScreen(),
      },
    );
  }
}
