# HomeSphere — Full Project Context

> **Purpose**: This file contains the entire codebase of the HomeSphere Flutter app. Share it with any LLM to give it full context without transferring individual files.

## Project Overview
- **Name**: HomeSphere
- **Type**: Flutter mobile app (cross-platform, currently targeting Android)
- **Package**: `com.homesphere.homesphere`
- **SDK**: Dart ^3.10.8
- **Design**: "Premium Midnight" dark theme with glassmorphism
- **Auth**: Firebase email/password authentication
- **Screens**: Login, Signup, Dashboard, Subscriptions, Appliances, Vehicles, Services

## Project Structure
```
homesphere_app/
├── android/
│   ├── app/
│   │   ├── build.gradle.kts          # App-level Gradle (minSdk=23, google-services)
│   │   └── google-services.json      # Firebase config (user-provided)
│   ├── build.gradle.kts              # Root Gradle
│   └── settings.gradle.kts           # Plugin declarations
├── lib/
│   ├── main.dart                     # Entry point, Firebase init, auth gating, navigation
│   ├── models/
│   │   └── models.dart               # Data classes + sample data
│   ├── screens/
│   │   ├── login_screen.dart         # Email/password login
│   │   ├── signup_screen.dart        # Email/password registration
│   │   ├── dashboard_screen.dart     # Home overview with stats
│   │   ├── subscriptions_screen.dart # Subscription list
│   │   ├── appliances_screen.dart    # Appliance tracker
│   │   ├── vehicles_screen.dart      # Vehicle details
│   │   └── services_screen.dart      # Service provider directory
│   ├── services/
│   │   └── auth_service.dart         # Firebase Auth wrapper
│   ├── theme/
│   │   └── app_theme.dart            # Colors, ThemeData, glass decoration
│   └── widgets/
│       └── stat_card.dart            # StatCard, GlassCard, StatusBadge
├── test/
│   └── widget_test.dart
└── pubspec.yaml
```

---

## pubspec.yaml
```yaml
name: homesphere
description: "A new Flutter project."
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.10.8

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  firebase_core: ^3.13.0
  firebase_auth: ^5.6.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true
```

---

## Android Config

### android/settings.gradle.kts
```kotlin
pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
}

include(":app")
```

### android/app/build.gradle.kts
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.homesphere.homesphere"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.homesphere.homesphere"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
```

---

## Source Code

### lib/main.dart
```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/subscriptions_screen.dart';
import 'screens/appliances_screen.dart';
import 'screens/vehicles_screen.dart';
import 'screens/services_screen.dart';

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
              child: CircularProgressIndicator(color: AppTheme.accentColor),
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
  final _authService = AuthService();

  final List<String> _titles = [
    'Dashboard', 'Subscriptions', 'Appliances', 'Vehicles', 'Services',
  ];

  final List<Widget> _screens = const [
    DashboardScreen(), SubscriptionsScreen(), AppliancesScreen(),
    VehiclesScreen(), ServicesScreen(),
  ];

  void _handleSignOut() async {
    await _authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppTheme.textSecondary),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppTheme.panelBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: AppTheme.glassBorder),
                    ),
                    title: const Text('Sign Out', style: TextStyle(color: AppTheme.textPrimary)),
                    content: const Text('Are you sure you want to sign out?',
                        style: TextStyle(color: AppTheme.textSecondary)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () { Navigator.pop(ctx); _handleSignOut(); },
                        child: const Text('Sign Out', style: TextStyle(color: AppTheme.danger)),
                      ),
                    ],
                  ),
                );
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.accentColor,
                child: const Text('PN',
                    style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.glassBorder)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.subscriptions_rounded), label: 'Subs'),
            BottomNavigationBarItem(icon: Icon(Icons.devices_rounded), label: 'Appliances'),
            BottomNavigationBarItem(icon: Icon(Icons.directions_car_rounded), label: 'Vehicles'),
            BottomNavigationBarItem(icon: Icon(Icons.handyman_rounded), label: 'Services'),
          ],
        ),
      ),
    );
  }
}
```

### lib/services/auth_service.dart
```dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signIn({required String email, required String password}) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUp({required String email, required String password}) async {
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
```

### lib/theme/app_theme.dart
```dart
import 'package:flutter/material.dart';

class AppTheme {
  static const Color bgColor = Color(0xFF0D1117);
  static const Color panelBg = Color(0xFF161B22);
  static const Color accentColor = Color(0xFF58A6FF);
  static const Color accentPurple = Color(0xFFBC8CF2);
  static const Color textPrimary = Color(0xFFF0F6FC);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color glassBorder = Color(0x1AFFFFFF);
  static const Color success = Color(0xFF3FB950);
  static const Color warning = Color(0xFFD29922);
  static const Color danger = Color(0xFFFF7B72);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgColor,
      fontFamily: 'Outfit',
      colorScheme: const ColorScheme.dark(
        primary: accentColor, secondary: accentPurple, surface: panelBg, error: danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: panelBg, elevation: 0, centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Outfit', fontSize: 22, fontWeight: FontWeight.w700,
          color: textPrimary, letterSpacing: -0.5,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: panelBg, selectedItemColor: accentColor,
        unselectedItemColor: textSecondary, type: BottomNavigationBarType.fixed, elevation: 0,
        selectedLabelStyle: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontFamily: 'Outfit', fontSize: 12),
      ),
      cardTheme: CardThemeData(
        color: panelBg, elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: glassBorder),
        ),
        margin: const EdgeInsets.only(bottom: 16),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentColor, foregroundColor: Colors.black,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.5),
        headlineMedium: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.5),
        titleLarge: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: TextStyle(fontFamily: 'Outfit', color: textPrimary),
        bodyMedium: TextStyle(fontFamily: 'Outfit', color: textSecondary),
        labelSmall: TextStyle(fontFamily: 'Outfit', color: textSecondary, fontSize: 12),
      ),
    );
  }

  static LinearGradient get premiumGradient => const LinearGradient(
    colors: [accentColor, accentPurple],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static BoxDecoration get glassDecoration => BoxDecoration(
    color: panelBg.withValues(alpha: 0.7),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: glassBorder),
    boxShadow: [
      BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 24, offset: const Offset(0, 8)),
    ],
  );
}
```

### lib/widgets/stat_card.dart
```dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const StatCard({super.key, required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: color, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const GlassCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration,
      child: child,
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  const StatusBadge({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
```

### lib/models/models.dart
```dart
class Subscription {
  final String name;
  final String price;
  final String nextBilling;
  final String category;
  final bool isActive;
  const Subscription({required this.name, required this.price, required this.nextBilling, required this.category, this.isActive = true});
}

class Appliance {
  final String name;
  final String brand;
  final String status;
  final String warrantyExpiry;
  final String purchaseDate;
  const Appliance({required this.name, required this.brand, required this.status, required this.warrantyExpiry, required this.purchaseDate});
}

class Vehicle {
  final String name;
  final String regNumber;
  final String mileage;
  final String nextService;
  final String insuranceExpiry;
  final String pucExpiry;
  const Vehicle({required this.name, required this.regNumber, required this.mileage, required this.nextService, required this.insuranceExpiry, required this.pucExpiry});
}

class ServiceProvider {
  final String name;
  final String category;
  final double rating;
  final String phone;
  final String location;
  const ServiceProvider({required this.name, required this.category, required this.rating, required this.phone, required this.location});
}

// ── Sample Data ──

final List<Subscription> sampleSubscriptions = [
  const Subscription(name: 'Netflix', price: '₹649/mo', nextBilling: 'Feb 15, 2026', category: 'Entertainment'),
  const Subscription(name: 'Spotify Premium', price: '₹119/mo', nextBilling: 'Feb 20, 2026', category: 'Music'),
  const Subscription(name: 'ACT Fibernet', price: '₹1,149/mo', nextBilling: 'Feb 28, 2026', category: 'Internet'),
  const Subscription(name: 'Amazon Prime', price: '₹1,499/yr', nextBilling: 'Jun 10, 2026', category: 'Shopping'),
  const Subscription(name: 'YouTube Premium', price: '₹149/mo', nextBilling: 'Mar 1, 2026', category: 'Entertainment'),
  const Subscription(name: 'BESCOM Electricity', price: '₹1,800/mo', nextBilling: 'Feb 25, 2026', category: 'Utility'),
];

final List<Appliance> sampleAppliances = [
  const Appliance(name: 'Refrigerator', brand: 'Samsung', status: 'Healthy', warrantyExpiry: 'Dec 2027', purchaseDate: 'Dec 2022'),
  const Appliance(name: 'Split AC', brand: 'LG', status: 'Service Due', warrantyExpiry: 'May 2026', purchaseDate: 'May 2023'),
  const Appliance(name: 'Washing Machine', brand: 'Whirlpool', status: 'Healthy', warrantyExpiry: 'Aug 2027', purchaseDate: 'Aug 2024'),
  const Appliance(name: 'Microwave Oven', brand: 'IFB', status: 'Healthy', warrantyExpiry: 'Jan 2026', purchaseDate: 'Jan 2024'),
];

final List<Vehicle> sampleVehicles = [
  const Vehicle(name: 'BMW 3 Series', regNumber: 'KA 01 MG 1234', mileage: '12,500 km', nextService: '15,000 km', insuranceExpiry: 'Aug 2026', pucExpiry: 'Nov 2026'),
  const Vehicle(name: 'Yamaha R15 V4', regNumber: 'KA 05 KL 9876', mileage: '4,200 km', nextService: 'Mar 2026', insuranceExpiry: 'Feb 2026', pucExpiry: 'Apr 2026'),
];

final List<ServiceProvider> sampleProviders = [
  const ServiceProvider(name: 'Rajesh Kumar', category: 'Electrician', rating: 4.8, phone: '+91 98765 43210', location: 'Mysuru'),
  const ServiceProvider(name: 'Suresh M', category: 'Plumber', rating: 4.5, phone: '+91 98765 11223', location: 'Mysuru'),
  const ServiceProvider(name: 'AutoCare Garage', category: 'Mechanic', rating: 4.9, phone: '+91 98765 44556', location: 'Mysuru'),
  const ServiceProvider(name: 'CoolBreeze AC Service', category: 'AC Technician', rating: 4.7, phone: '+91 98765 77889', location: 'Mysuru'),
];
```

### lib/screens/login_screen.dart
```dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _authService.signIn(email: _emailController.text.trim(), password: _passwordController.text);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Sign in failed'), backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... Premium glassmorphism login UI with:
    //   - Gradient circle brand icon (home icon)
    //   - "HomeSphere" title + "Welcome back" subtitle
    //   - Glass card containing email + password TextFormFields
    //   - Gradient "Sign In" button with loading indicator
    //   - "Don't have an account? Sign Up" link → SignupScreen
    // (Full implementation in the actual file)
  }
}
```

### lib/screens/signup_screen.dart
```dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _authService.signUp(email: _emailController.text.trim(), password: _passwordController.text);
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Sign up failed'), backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... Same aesthetic as login with:
    //   - person_add icon in gradient circle
    //   - "Create Account" title + "Join HomeSphere today" subtitle
    //   - Glass card with email, password (min 6 chars), confirm password fields
    //   - Gradient "Create Account" button
    //   - "Already have an account? Sign In" link → pops back
    // (Full implementation in the actual file)
  }
}
```

### lib/screens/dashboard_screen.dart
```dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient "Welcome back, Prajwal 👋" header
          // 2x2 grid of StatCards: Active Subscriptions (6), Next Renewal (2 Days), Vehicles (2), Monthly Spend (₹4.2k)
          // Recent Activity list: Netflix Renewal, Car Service Completed, Internet Bill Paid
          // Alerts: Insurance Expiring — Yamaha R15 — 5 days left
        ],
      ),
    );
  }
}
```

### lib/screens/subscriptions_screen.dart
```dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/stat_card.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});
  // Gradient summary card: Total Monthly ₹4,215, 6 active subscriptions
  // List of sampleSubscriptions with category icons/colors, price, next billing, active badge
}
```

### lib/screens/appliances_screen.dart
```dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/stat_card.dart';

class AppliancesScreen extends StatelessWidget {
  const AppliancesScreen({super.key});
  // Summary row: Total Appliances count + Needs Service count
  // Appliance cards with brand, purchase date, warranty expiry, status badge
  // "Book Service" button shown when status is not Healthy
}
```

### lib/screens/vehicles_screen.dart
```dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/stat_card.dart';

class VehiclesScreen extends StatelessWidget {
  const VehiclesScreen({super.key});
  // Vehicle cards: gradient icon, name, reg number
  // Info grid: mileage, next service, insurance expiry, PUC expiry
  // Action buttons: Service History (outline), Book Service (filled)
}
```

### lib/screens/services_screen.dart
```dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/stat_card.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});
  // Search bar with glass decoration
  // Category filter chips: All (gradient), Electrician, Plumber, Mechanic, AC Technician
  // Provider cards: icon, name, category badge, rating, location
  // Action buttons: Call (outline), Book Now (filled)
}
```
