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
import 'pages/admin_users_page.dart';

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
enum AppScreen { landing, loginUser, registerUser, user, admin }

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  AppScreen _screen = AppScreen.landing;
  int? _userId;
  String? _pseudo;
  String _role = 'user';

  void _goTo(AppScreen s) => setState(() => _screen = s);

  void _onLoginSuccess(int id, String pseudo, String role) {
    setState(() {
      _userId = id;
      _pseudo = pseudo;
      _role = role;
      _screen = role == 'admin' ? AppScreen.admin : AppScreen.user;
    });
  }

  void _logout() {
    setState(() { _userId = null; _pseudo = null; _role = 'user'; _screen = AppScreen.landing; });
  }

  /// Admin can switch to user view
  void _switchToUserView() {
    setState(() => _screen = AppScreen.user);
  }

  /// Switch back to admin view
  void _switchToAdminView() {
    setState(() => _screen = AppScreen.admin);
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
          onLoginSuccess: _onLoginSuccess,
          onBack: () => _goTo(AppScreen.landing),
        );
      case AppScreen.registerUser:
        return AuthPage(
          onLoginSuccess: _onLoginSuccess,
          onBack: () => _goTo(AppScreen.landing),
          startOnRegister: true,
        );
      case AppScreen.user:
        return UserHomePage(
          userId: _userId!,
          pseudo: _pseudo!,
          onLogout: _logout,
          isAdmin: _role == 'admin',
          onSwitchToAdmin: _role == 'admin' ? _switchToAdminView : null,
        );
      case AppScreen.admin:
        return _AdminShell(onLogout: _logout, onSwitchToUser: _switchToUserView);
    }
  }
}

// ─── ADMIN SHELL (existing dashboard) ───

const _navItems = [
  SidebarItemData(icon: Icons.dashboard_outlined, label: 'Dashboard'),
  SidebarItemData(icon: Icons.admin_panel_settings_outlined, label: 'Admin'),
  SidebarItemData(icon: Icons.people_outline_rounded, label: 'Utilisateurs'),
  SidebarItemData(icon: Icons.movie_outlined, label: 'Films'),
  SidebarItemData(icon: Icons.rate_review_outlined, label: 'Notes'),
  SidebarItemData(icon: Icons.settings_outlined, label: 'Parametres'),
];

const _pageTitles = ['Dashboard', 'Administration', 'Utilisateurs', 'Films', 'Notes', 'Parametres'];
const _pageSubtitles = [
  'Vue d\'ensemble de votre plateforme',
  'Gestion des utilisateurs et leurs notes',
  'Gestion des comptes utilisateurs',
  'Catalogue et gestion des films',
  'Notes et avis des utilisateurs',
  'Configuration de l\'application',
];

class _AdminShell extends StatefulWidget {
  final VoidCallback onLogout;
  final VoidCallback onSwitchToUser;
  const _AdminShell({required this.onLogout, required this.onSwitchToUser});

  @override
  State<_AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<_AdminShell> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Widget _getPage(int index) {
    switch (index) {
      case 0: return DashboardPage(onNavigate: (i) => setState(() => _selectedIndex = i));
      case 1: return const AdminUsersPage();
      case 2: return const UsersPage();
      case 3: return const MoviesPage();
      case 4: return const RatingsPage();
      case 5: return const SettingsPage();
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
                  onSettingsTap: () => setState(() => _selectedIndex = 5),
                  onNotificationsTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Aucune notification'), backgroundColor: AppColors.primary, duration: Duration(seconds: 1)),
                    );
                  },
                  onProfileTap: widget.onLogout,
                  trailing: TextButton.icon(
                    onPressed: widget.onSwitchToUser,
                    icon: const Icon(Icons.person_outline, size: 16, color: AppColors.accent),
                    label: const Text('Vue utilisateur', style: TextStyle(fontSize: 12, color: AppColors.accent)),
                  ),
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
