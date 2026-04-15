import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../services/firestore_service.dart';
import '../models/models.dart';

class _DashboardData {
  final List<Subscription> subscriptions;
  final List<Appliance> appliances;
  final List<Vehicle> vehicles;

  _DashboardData({
    this.subscriptions = const [],
    this.appliances = const [],
    this.vehicles = const [],
  });
}

Stream<_DashboardData> _combineStreams() {
  return FirestoreService().streamSubscriptions().asyncExpand((subs) {
    return FirestoreService().streamAppliances().asyncExpand((apps) {
      return FirestoreService().streamVehicles().map((vehicles) {
        return _DashboardData(
          subscriptions: subs,
          appliances: apps,
          vehicles: vehicles,
        );
      });
    });
  });
}

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
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final email = user.email ?? '';
    final name = email.split('@').first.trim();
    if (name.isEmpty) return 'User';
    return name
        .replaceAll(RegExp(r'[._]'), ' ')
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            _getUserName(),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
              letterSpacing: -1.0,
            ),
          ),
          Text(
            'Welcome back',
            style: TextStyle(
              fontSize: 15,
              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 28),

          _buildStatsGrid(),
          const SizedBox(height: 32),

          const SectionHeader(title: 'Recent'),
          _buildRecentSubscriptions(),
          const SizedBox(height: 24),

          const SectionHeader(title: 'Alerts'),
          _buildAlerts(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final cs = Theme.of(context).colorScheme;
    return StreamBuilder<_DashboardData>(
      stream: _combineStreams(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? _DashboardData();
        final activeSubs = data.subscriptions.where((s) => s.isActive).length;
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
              color: cs.primary,
              icon: Icons.receipt_long_rounded,
            ),
            StatCard(
              label: 'Appliances',
              value: '${data.appliances.length}',
              color: cs.secondary,
              icon: Icons.devices_rounded,
            ),
            StatCard(
              label: 'Vehicles',
              value: '${data.vehicles.length}',
              color: AppTheme.success,
              icon: Icons.directions_car_rounded,
            ),
            StatCard(
              label: 'Total',
              value:
                  '${data.subscriptions.length + data.appliances.length + data.vehicles.length}',
              color: cs.tertiary,
              icon: Icons.inventory_2_rounded,
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentSubscriptions() {
    final cs = Theme.of(context).colorScheme;
    return StreamBuilder<List<Subscription>>(
      stream: _firestoreService.streamSubscriptions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: cs.primary));
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
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: cs.primary,
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
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sub.category,
                            style: TextStyle(
                              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      sub.price,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: cs.primary,
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
    final cs = Theme.of(context).colorScheme;
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
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${v.name} — ${v.regNumber}',
                            style: TextStyle(
                              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
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
    Color? color,
  }) {
    final cs = Theme.of(context).colorScheme;
    final c = color ?? cs.onSurfaceVariant;
    return GlassCard(
      child: Row(
        children: [
          Icon(icon, color: c.withValues(alpha: 0.5), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: c,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5),
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
