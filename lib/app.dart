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
import 'dialogs/chat_screen.dart';
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

      initialRoute: "/",
      
      onGenerateRoute: (settings) {
        if (settings.name == "/") {
          return MaterialPageRoute(
            builder: (context) {
              return FutureBuilder<UserModel?>(
                future: AuthService().getUserFromPrefs(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data == null) {
                    return const LoginScreen();
                  }

                  final user = snapshot.data!;

                  if (user.role == "admin") {
                    return const AdminDashboardScreen();
                  }

                  return const MainUserShell();
                },
              );
            },
          );
        }

        Widget screen;
        switch (settings.name) {
          case "/user":
            screen = const MainUserShell();
            break;
          case "/login":
            screen = const LoginScreen();
            break;
          case "/register":
            screen = const RegisterScreen();
            break;
          case "/recommendation":
            screen = const RecommendationScreen();
            break;
          case "/recommendation/full":
            screen = const RecommendationFullScreen();
            break;
          case "/specific_choices":
            screen = const SpecificChoicesScreen();
            break;
          case "/materials":
            screen = const MaterialsScreen();
            break;
          case "/material_detail":
            screen = const MaterialDetailScreen();
            break;
          case "/admin":
            screen = const AdminDashboardScreen();
            break;
          case "/admin/subjects":
            screen = const AdminSubjectScreen();
            break;
          case "/admin/materials":
            screen = const AdminMaterialScreen();
            break;
          case "/admin/rules":
            screen = const AdminRuleScreen();
            break;
          case "/admin/users":
            screen = const AdminUserScreen();
            break;
          default:
            screen = const LoginScreen();
        }

        return MaterialPageRoute(builder: (context) => screen);
      },

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

  final List<Widget> _pages = [
    const HomeScreen(),
    const SearchScreen(),
    const ChatScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
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
        type: BottomNavigationBarType.fixed,
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
            icon: Icon(Icons.chat),
            label: "Konsultasi",
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