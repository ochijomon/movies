import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'theme/design_tokens.dart';
import 'widgets/sidebar.dart';
import 'widgets/top_bar.dart';
import 'widgets/responsive_layout.dart';
import 'pages/landing_page.dart';
import 'pages/auth_page.dart';
import 'pages/user_home_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/users_page.dart';
import 'pages/movies_page.dart';
import 'pages/ratings_page.dart';
import 'pages/settings_page.dart';

void main() {
  runApp(const MoviesApp());
}

class MoviesApp extends StatelessWidget {
  const MoviesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MOVIES',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AppRoot(),
    );
  }
}

/// Root widget managing the app state: landing / auth / user / admin.
enum AppScreen { landing, loginUser, registerUser, loginAdmin, user, admin }

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  AppScreen _screen = AppScreen.landing;
  int? _userId;
  String? _pseudo;

  void _goTo(AppScreen s) => setState(() => _screen = s);

  void _onUserLogin(int id, String pseudo) {
    setState(() { _userId = id; _pseudo = pseudo; _screen = AppScreen.user; });
  }

  void _logout() {
    setState(() { _userId = null; _pseudo = null; _screen = AppScreen.landing; });
  }

  @override
  Widget build(BuildContext context) {
    switch (_screen) {
      case AppScreen.landing:
        return LandingPage(
          onLogin: () => _goTo(AppScreen.loginUser),
          onRegister: () => _goTo(AppScreen.registerUser),
        );
      case AppScreen.loginUser:
        return AuthPage(
          onLoginSuccess: _onUserLogin,
          onBack: () => _goTo(AppScreen.landing),
        );
      case AppScreen.registerUser:
        return AuthPage(
          onLoginSuccess: _onUserLogin,
          onBack: () => _goTo(AppScreen.landing),
          startOnRegister: true,
        );
      case AppScreen.loginAdmin:
        return AuthPage(
          onLoginSuccess: (_, __) => _goTo(AppScreen.admin),
          onBack: () => _goTo(AppScreen.landing),
        );
      case AppScreen.user:
        return UserHomePage(
          userId: _userId!,
          pseudo: _pseudo!,
          onLogout: _logout,
        );
      case AppScreen.admin:
        return _AdminShell(onLogout: _logout);
    }
  }
}

// ─── ADMIN SHELL (existing dashboard) ───

const _navItems = [
  SidebarItemData(icon: Icons.dashboard_outlined, label: 'Dashboard'),
  SidebarItemData(icon: Icons.people_outline_rounded, label: 'Utilisateurs'),
  SidebarItemData(icon: Icons.movie_outlined, label: 'Films'),
  SidebarItemData(icon: Icons.rate_review_outlined, label: 'Notes'),
  SidebarItemData(icon: Icons.settings_outlined, label: 'Parametres'),
];

const _pageTitles = ['Dashboard', 'Utilisateurs', 'Films', 'Notes', 'Parametres'];
const _pageSubtitles = [
  'Vue d\'ensemble de votre plateforme',
  'Gestion des comptes utilisateurs',
  'Catalogue et gestion des films',
  'Notes et avis des utilisateurs',
  'Configuration de l\'application',
];

class _AdminShell extends StatefulWidget {
  final VoidCallback onLogout;
  const _AdminShell({required this.onLogout});

  @override
  State<_AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<_AdminShell> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Widget _getPage(int index) {
    switch (index) {
      case 0: return DashboardPage(onNavigate: (i) => setState(() => _selectedIndex = i));
      case 1: return const UsersPage();
      case 2: return const MoviesPage();
      case 3: return const RatingsPage();
      case 4: return const SettingsPage();
      default: return DashboardPage(onNavigate: (i) => setState(() => _selectedIndex = i));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenType = getScreenType(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: screenType == ScreenType.mobile
          ? Drawer(
              backgroundColor: AppColors.sidebarBg,
              child: AppSidebar(
                selectedIndex: _selectedIndex,
                onItemSelected: (i) { setState(() => _selectedIndex = i); Navigator.pop(context); },
                items: _navItems,
              ),
            )
          : null,
      bottomNavigationBar: screenType == ScreenType.mobile
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) => setState(() => _selectedIndex = i),
              backgroundColor: AppColors.surface,
              indicatorColor: AppColors.primary.withValues(alpha: 0.15),
              destinations: _navItems.map((item) => NavigationDestination(
                icon: Icon(item.icon, color: AppColors.textSecondary),
                selectedIcon: Icon(item.icon, color: AppColors.primary),
                label: item.label,
              )).toList(),
            )
          : null,
      body: Row(
        children: [
          if (screenType == ScreenType.desktop)
            AppSidebar(selectedIndex: _selectedIndex, onItemSelected: (i) => setState(() => _selectedIndex = i), items: _navItems),
          if (screenType == ScreenType.tablet)
            AppNavigationRail(selectedIndex: _selectedIndex, onItemSelected: (i) => setState(() => _selectedIndex = i), items: _navItems),
          Expanded(
            child: Column(
              children: [
                AppTopBar(
                  title: _pageTitles[_selectedIndex],
                  subtitle: _pageSubtitles[_selectedIndex],
                  showMenu: screenType == ScreenType.mobile,
                  onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                  onSettingsTap: () => setState(() => _selectedIndex = 4),
                  onNotificationsTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Aucune notification'), backgroundColor: AppColors.primary, duration: Duration(seconds: 1)),
                    );
                  },
                  onProfileTap: widget.onLogout,
                ),
                Expanded(child: _getPage(_selectedIndex)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
