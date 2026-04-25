import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
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
import 'services/firestore_service.dart';
import 'models/models.dart';

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
            body: Center(child: CircularProgressIndicator(color: cs.primary)),
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
  String? _cachedInitials;

  final List<String> _titles = <String>[
    'Home',
    'Subscriptions',
    'Appliances',
    'Vehicles',
    'Services',
  ];

  static final List<Widget> _screens = <Widget>[
    const DashboardScreen(),
    const SubscriptionsScreen(),
    const AppliancesScreen(),
    const VehiclesScreen(),
    const ServicesScreen(),
  ];

  static final List<IconData> _icons = <IconData>[
    Icons.grid_view_rounded,
    Icons.receipt_long_rounded,
    Icons.devices_rounded,
    Icons.directions_car_rounded,
    Icons.build_rounded,
  ];

  String _getUserInitials() {
    _cachedInitials ??= _computeInitials();
    return _cachedInitials!;
  }

  String _computeInitials() {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      final nameParts = displayName
          .replaceAll(RegExp(r'[._]'), ' ')
          .split(RegExp(r'\s+'))
          .where((part) => part.isNotEmpty)
          .toList();
      if (nameParts.length >= 2) {
        return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
      }
      return nameParts.isNotEmpty ? nameParts.first[0].toUpperCase() : '?';
    }

    if (user == null || user.email == null) return '?';
    final email = user.email!;
    final parts = email.split('@').first.trim();
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
        title: Text(
          _titles[_currentIndex],
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                _buildIconBtn(icon: Icons.search_rounded, onTap: _showSearch),
                const SizedBox(width: 8),
                _buildIconBtn(
                  icon: Icons.notifications_none_rounded,
                  onTap: _showNotifications,
                  hasDot: true,
                ),
                const SizedBox(width: 12),
                _buildAvatar(),
              ],
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

  // ── Search ────────────────────────────────────────────────────────────────
  void _showSearch() {
    showSearch(context: context, delegate: _HomeSearchDelegate());
  }

  // ── Notifications ─────────────────────────────────────────────────────────
  Future<void> _showNotifications() async {
    final firestoreService = FirestoreService();
    final cs = Theme.of(context).colorScheme;

    // Gather data
    final subs = await firestoreService.streamSubscriptions().first;
    final vehicles = await firestoreService.streamVehicles().first;
    final appliances = await firestoreService.streamAppliances().first;

    if (!mounted) return;

    final now = DateTime.now();
    final soon = now.add(const Duration(days: 30));

    DateTime? _tryParse(String s) {
      if (s.isEmpty) return null;
      try {
        return DateFormat('MMM dd, yyyy').parse(s);
      } catch (_) {
        return null;
      }
    }

    final List<_NotifItem> items = [];

    // Upcoming subscription billings
    for (final sub in subs) {
      final date = _tryParse(sub.nextBilling);
      if (date != null && !date.isBefore(now) && !date.isAfter(soon)) {
        final daysLeft = date.difference(now).inDays;
        items.add(_NotifItem(
          icon: Icons.receipt_long_rounded,
          color: cs.primary,
          title: '${sub.name} renewal',
          subtitle: daysLeft == 0
              ? 'Due today · ${sub.price}'
              : 'In $daysLeft day${daysLeft == 1 ? '' : 's'} · ${sub.price}',
        ));
      }
    }

    // Vehicle insurance / PUC expiry
    for (final v in vehicles) {
      final ins = _tryParse(v.insuranceExpiry);
      if (ins != null && !ins.isBefore(now) && !ins.isAfter(soon)) {
        final d = ins.difference(now).inDays;
        items.add(_NotifItem(
          icon: Icons.directions_car_rounded,
          color: AppTheme.warning,
          title: '${v.name} insurance',
          subtitle: d == 0 ? 'Expires today' : 'Expires in $d day${d == 1 ? '' : 's'}',
        ));
      }
      final puc = _tryParse(v.pucExpiry);
      if (puc != null && !puc.isBefore(now) && !puc.isAfter(soon)) {
        final d = puc.difference(now).inDays;
        items.add(_NotifItem(
          icon: Icons.directions_car_rounded,
          color: AppTheme.warning,
          title: '${v.name} PUC',
          subtitle: d == 0 ? 'Expires today' : 'Expires in $d day${d == 1 ? '' : 's'}',
        ));
      }
    }

    // Appliance warranty expiry
    for (final a in appliances) {
      final date = _tryParse(a.warrantyExpiry);
      if (date != null && !date.isBefore(now) && !date.isAfter(soon)) {
        final d = date.difference(now).inDays;
        items.add(_NotifItem(
          icon: Icons.devices_rounded,
          color: cs.secondary,
          title: '${a.name} warranty',
          subtitle: d == 0 ? 'Expires today' : 'Expires in $d day${d == 1 ? '' : 's'}',
        ));
      }
    }

    // Sort by urgency (soonest first)
    items.sort((a, b) {
      final aD = int.tryParse(RegExp(r'\d+').firstMatch(a.subtitle)?.group(0) ?? '999') ?? 999;
      final bD = int.tryParse(RegExp(r'\d+').firstMatch(b.subtitle)?.group(0) ?? '999') ?? 999;
      return aD.compareTo(bD);
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          builder: (_, controller) => Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      if (items.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${items.length}',
                            style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 52,
                                color: AppTheme.success.withValues(alpha: 0.6),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'All clear!',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'No upcoming events in the next 30 days.',
                                style: TextStyle(
                                  color: cs.onSurfaceVariant
                                      .withValues(alpha: 0.6),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          controller: controller,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 4,
                          ),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final item = items[i];
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: cs.outlineVariant
                                      .withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color:
                                          item.color.withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      item.icon,
                                      color: item.color,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          item.subtitle,
                                          style: TextStyle(
                                            color: cs.onSurfaceVariant
                                                .withValues(alpha: 0.65),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIconBtn({
    required IconData icon,
    required VoidCallback onTap,
    bool hasDot = false,
  }) {
    return Builder(
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return Stack(
          children: [
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(icon, color: cs.onSurfaceVariant, size: 22),
              ),
            ),
            if (hasDot)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: cs.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: cs.surface, width: 1.5),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAvatar() {
    return Builder(
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        final user = FirebaseAuth.instance.currentUser;
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ).then((_) {
            _cachedInitials = null;
            setState(() {});
          }),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient(context),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: cs.surface,
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : null,
              child: user?.photoURL == null
                  ? Text(
                      _getUserInitials(),
                      style: TextStyle(
                        color: cs.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavBar(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.only(top: 12, bottom: 24, left: 16, right: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2)),
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

// ─────────────────────────────────────────────────────────────────────────────
// Notification item model
// ─────────────────────────────────────────────────────────────────────────────
class _NotifItem {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _NotifItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Search delegate
// ─────────────────────────────────────────────────────────────────────────────
class _HomeSearchDelegate extends SearchDelegate<String> {
  final _firestore = FirestoreService();

  @override
  String get searchFieldLabel => 'Search subscriptions, vehicles, appliances…';

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear_rounded),
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => close(context, ''),
      );

  @override
  Widget buildResults(BuildContext context) => _buildSearchBody(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchBody(context);

  Widget _buildSearchBody(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final q = query.trim().toLowerCase();

    if (q.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_rounded,
              size: 52,
              color: cs.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'Type to search',
              style: TextStyle(
                color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<List<Subscription>>(
      stream: _firestore.streamSubscriptions(),
      builder: (context, subSnap) {
        return StreamBuilder<List<Appliance>>(
          stream: _firestore.streamAppliances(),
          builder: (context, appSnap) {
            return StreamBuilder<List<Vehicle>>(
              stream: _firestore.streamVehicles(),
              builder: (context, vehSnap) {
                return StreamBuilder<List<ServiceProvider>>(
                  stream: _firestore.streamServiceProviders(),
                  builder: (context, svcSnap) {
                    final results = <_SearchResult>[];

                    for (final s in subSnap.data ?? []) {
                      if (s.name.toLowerCase().contains(q) ||
                          s.category.toLowerCase().contains(q) ||
                          s.price.toLowerCase().contains(q)) {
                        results.add(_SearchResult(
                          icon: Icons.receipt_long_rounded,
                          color: cs.primary,
                          title: s.name,
                          subtitle: '${s.category} · ${s.price}',
                          tag: 'Subscription',
                        ));
                      }
                    }

                    for (final a in appSnap.data ?? []) {
                      if (a.name.toLowerCase().contains(q) ||
                          a.brand.toLowerCase().contains(q) ||
                          a.category.toLowerCase().contains(q)) {
                        results.add(_SearchResult(
                          icon: Icons.devices_rounded,
                          color: cs.secondary,
                          title: a.name,
                          subtitle:
                              '${a.brand.isNotEmpty ? a.brand : a.category} · ${a.status}',
                          tag: 'Appliance',
                        ));
                      }
                    }

                    for (final v in vehSnap.data ?? []) {
                      if (v.name.toLowerCase().contains(q) ||
                          v.regNumber.toLowerCase().contains(q)) {
                        results.add(_SearchResult(
                          icon: Icons.directions_car_rounded,
                          color: AppTheme.success,
                          title: v.name,
                          subtitle: v.regNumber,
                          tag: 'Vehicle',
                        ));
                      }
                    }

                    for (final p in svcSnap.data ?? []) {
                      if (p.name.toLowerCase().contains(q) ||
                          p.category.toLowerCase().contains(q) ||
                          p.location.toLowerCase().contains(q)) {
                        results.add(_SearchResult(
                          icon: Icons.build_rounded,
                          color: cs.tertiary,
                          title: p.name,
                          subtitle: '${p.category} · ${p.location}',
                          tag: 'Service',
                        ));
                      }
                    }

                    if (results.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 52,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No results for "$query"',
                              style: TextStyle(
                                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final r = results[i];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: cs.outlineVariant.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: r.color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(r.icon, color: r.color, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      r.subtitle,
                                      style: TextStyle(
                                        color: cs.onSurfaceVariant
                                            .withValues(alpha: 0.6),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: r.color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  r.tag,
                                  style: TextStyle(
                                    color: r.color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _SearchResult {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String tag;

  const _SearchResult({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.tag,
  });
}
