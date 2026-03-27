import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../services/firestore_service.dart';
import '../models/models.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _firestoreService = FirestoreService();

  String _getUserName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'User';
    final email = user.email ?? '';
    final name = email.split('@').first;
    if (name.isEmpty) return 'User';
    return name[0].toUpperCase() + name.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Text(
            'Welcome back,',
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondary.withValues(alpha: 0.7),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getUserName(),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Stats
          const SectionHeader(title: 'Overview'),
          _buildStatsGrid(),
          const SizedBox(height: 36),

          // Recent Subscriptions
          const SectionHeader(title: 'Recent Activity'),
          _buildRecentSubscriptions(),
          const SizedBox(height: 36),

          // Alerts
          const SectionHeader(title: 'Alerts'),
          _buildAlerts(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return StreamBuilder<List<Subscription>>(
      stream: _firestoreService.streamSubscriptions(),
      builder: (context, subSnap) {
        final subs = subSnap.data ?? [];
        final activeSubs = subs.where((s) => s.isActive).length;

        return StreamBuilder<List<Vehicle>>(
          stream: _firestoreService.streamVehicles(),
          builder: (context, vehSnap) {
            final vehicles = vehSnap.data ?? [];

            return StreamBuilder<List<Appliance>>(
              stream: _firestoreService.streamAppliances(),
              builder: (context, appSnap) {
                final appliances = appSnap.data ?? [];

                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.95,
                  children: [
                    StatCard(
                      label: 'Active Subs',
                      value: '$activeSubs',
                      color: AppTheme.accentGold,
                      icon: Icons.receipt_long_rounded,
                    ),
                    StatCard(
                      label: 'Appliances',
                      value: '${appliances.length}',
                      color: AppTheme.accentSilver,
                      icon: Icons.devices_rounded,
                    ),
                    StatCard(
                      label: 'Vehicles',
                      value: '${vehicles.length}',
                      color: AppTheme.success,
                      icon: Icons.directions_car_rounded,
                    ),
                    StatCard(
                      label: 'Total',
                      value:
                          '${subs.length + appliances.length + vehicles.length}',
                      color: AppTheme.accentChampagne,
                      icon: Icons.inventory_2_rounded,
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRecentSubscriptions() {
    return StreamBuilder<List<Subscription>>(
      stream: _firestoreService.streamSubscriptions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.accentGold),
          );
        }
        final subs = snapshot.data ?? [];
        if (subs.isEmpty) {
          return _buildEmptyCard(
            icon: Icons.receipt_long_rounded,
            title: 'No subscriptions yet',
            subtitle: 'Add one from the Subscriptions tab',
          );
        }
        final recent = subs.take(3).toList();
        return Column(
          children: recent.map((sub) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                child: Row(
                  children: [
                    // Color dot
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.accentGold,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sub.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sub.category,
                            style: TextStyle(
                              color: AppTheme.textSecondary.withValues(
                                alpha: 0.6,
                              ),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      sub.price,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppTheme.accentGold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildAlerts() {
    return StreamBuilder<List<Vehicle>>(
      stream: _firestoreService.streamVehicles(),
      builder: (context, snapshot) {
        final vehicles = snapshot.data ?? [];
        if (vehicles.isEmpty) {
          return _buildEmptyCard(
            icon: Icons.check_circle_rounded,
            title: 'All clear',
            subtitle: 'No alerts at this time',
            color: AppTheme.success,
          );
        }
        return Column(
          children: vehicles.map((v) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Insurance: ${v.insuranceExpiry}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${v.name} — ${v.regNumber}',
                            style: TextStyle(
                              color: AppTheme.textSecondary.withValues(
                                alpha: 0.6,
                              ),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildEmptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Color color = const Color(0xFF6B6B6B),
  }) {
    return GlassCard(
      child: Row(
        children: [
          Icon(icon, color: color.withValues(alpha: 0.5), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.textSecondary.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
