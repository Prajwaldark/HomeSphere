import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/subscriptions_screen.dart';
import 'screens/appliances_screen.dart';
import 'screens/vehicles_screen.dart';
import 'screens/services_screen.dart';
import 'screens/settings_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService().init();
  runApp(const HomeSphereApp());
}

class HomeSphereApp extends StatefulWidget {
  const HomeSphereApp({super.key});

  static ThemeProvider of(BuildContext context) {
    final state = context.findAncestorStateOfType<_HomeSphereAppState>();
    return state!.themeProvider;
  }

  @override
  State<HomeSphereApp> createState() => _HomeSphereAppState();
}

class _HomeSphereAppState extends State<HomeSphereApp> {
  final ThemeProvider themeProvider = ThemeProvider();

  @override
  void initState() {
    super.initState();
    themeProvider.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    themeProvider.removeListener(_onThemeChanged);
    themeProvider.dispose();
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HomeSphere',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: cs.primary),
            ),
          );
        }
        if (snapshot.hasData) {
          return const MainNavigation();
        }
        return const LoginScreen();
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<String> _titles = [
    'Home',
    'Subscriptions',
    'Appliances',
    'Vehicles',
    'Services',
  ];

  final List<Widget> _screens = [
    const DashboardScreen(),
    const SubscriptionsScreen(),
    const AppliancesScreen(),
    const VehiclesScreen(),
    const ServicesScreen(),
  ];

  final List<IconData> _icons = [
    Icons.grid_view_rounded,
    Icons.receipt_long_rounded,
    Icons.devices_rounded,
    Icons.directions_car_rounded,
    Icons.build_rounded,
  ];

  String _getUserInitials() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return '?';
    final email = user.email!;
    final parts = email.split('@').first;
    if (parts.isEmpty) return '?';
    final nameParts = parts.split(RegExp(r'[._]'));
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return parts[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          // Notification icon
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              color: cs.onSurfaceVariant,
              size: 20,
            ),
          ),
          // Avatar
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.primaryGradient(context),
                ),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: cs.surfaceContainerHigh,
                  child: Text(
                    _getUserInitials(),
                    style: TextStyle(
                      color: cs.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: _buildNavBar(cs),
    );
  }

  Widget _buildNavBar(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.only(top: 12, bottom: 24, left: 16, right: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_icons.length, (index) {
          final isSelected = _currentIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _currentIndex = index),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 20 : 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? cs.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _icons[index],
                color: isSelected ? cs.primary : cs.outline,
                size: isSelected ? 24 : 22,
              ),
            ),
          );
        }),
      ),
    );
  }
}
