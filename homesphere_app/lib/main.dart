import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/subscriptions_screen.dart';
import 'screens/appliances_screen.dart';
import 'screens/vehicles_screen.dart';
import 'screens/services_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const HomeSphereApp());
}

class HomeSphereApp extends StatelessWidget {
  const HomeSphereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HomeSphere',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.accentGold),
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
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
          ),
        ),
        actions: [
          // Notification icon
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: AppTheme.textSecondary,
              size: 20,
            ),
          ),
          // Avatar with gold ring
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
                  gradient: AppTheme.premiumGradient,
                ),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.cardBg,
                  child: Text(
                    _getUserInitials(),
                    style: const TextStyle(
                      color: AppTheme.accentGold,
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
      bottomNavigationBar: _buildCREDNavBar(),
    );
  }

  Widget _buildCREDNavBar() {
    return Container(
      padding: const EdgeInsets.only(top: 12, bottom: 24, left: 16, right: 16),
      decoration: const BoxDecoration(
        color: AppTheme.bgColor,
        border: Border(top: BorderSide(color: AppTheme.glassBorder)),
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
                    ? AppTheme.accentGold.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _icons[index],
                color: isSelected ? AppTheme.accentGold : AppTheme.textMuted,
                size: isSelected ? 24 : 22,
              ),
            ),
          );
        }),
      ),
    );
  }
}
