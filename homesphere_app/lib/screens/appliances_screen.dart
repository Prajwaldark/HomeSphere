import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/stat_card.dart';
import '../services/firestore_service.dart';

class AppliancesScreen extends StatefulWidget {
  const AppliancesScreen({super.key});

  @override
  State<AppliancesScreen> createState() => _AppliancesScreenState();
}

class _AppliancesScreenState extends State<AppliancesScreen> {
  final _firestoreService = FirestoreService();

  Widget _buildDateField({
    required BuildContext ctx,
    required String label,
    required DateTime? date,
    required void Function(DateTime) onPicked,
    required StateSetter setModalState,
  }) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: ctx,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2040),
          builder: (context, child) {
            return Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: AppTheme.accentGold,
                  surface: AppTheme.panelBg,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppTheme.surfaceLight.withValues(alpha: 0.5),
          border: Border.all(color: AppTheme.glassBorder),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
              size: 18,
            ),
            const SizedBox(width: 12),
            Text(
              date != null ? DateFormat('MMM dd, yyyy').format(date) : label,
              style: TextStyle(
                color: date != null
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary.withValues(alpha: 0.5),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    DateTime? purchaseDate;
    DateTime? warrantyDate;
    String status = 'Healthy';

    CREDBottomSheet.show(
      context: context,
      title: 'Add Appliance',
      builder: (ctx, setModalState) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            credTextField(nameCtrl, 'Appliance Name', 'e.g. Samsung Fridge'),
            const SizedBox(height: 14),
            credTextField(brandCtrl, 'Brand', 'e.g. Samsung'),
            const SizedBox(height: 14),
            _buildDateField(
              ctx: ctx,
              label: 'Purchase Date',
              date: purchaseDate,
              onPicked: (d) => setModalState(() => purchaseDate = d),
              setModalState: setModalState,
            ),
            const SizedBox(height: 14),
            _buildDateField(
              ctx: ctx,
              label: 'Warranty Expiry',
              date: warrantyDate,
              onPicked: (d) => setModalState(() => warrantyDate = d),
              setModalState: setModalState,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: status,
              dropdownColor: AppTheme.panelBg,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                labelText: 'Status',
                labelStyle: TextStyle(
                  color: AppTheme.textSecondary.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
                filled: true,
                fillColor: AppTheme.surfaceLight.withValues(alpha: 0.5),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppTheme.accentGold.withValues(alpha: 0.4),
                  ),
                ),
              ),
              items: [
                'Healthy',
                'Needs Repair',
                'Under Warranty',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setModalState(() => status = v!),
            ),
            const SizedBox(height: 24),
            credButton(
              label: 'Add Appliance',
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                try {
                  await _firestoreService.addAppliance(
                    Appliance(
                      name: nameCtrl.text.trim(),
                      brand: brandCtrl.text.trim(),
                      purchaseDate: purchaseDate != null
                          ? DateFormat('MMM dd, yyyy').format(purchaseDate!)
                          : '',
                      warrantyExpiry: warrantyDate != null
                          ? DateFormat('MMM dd, yyyy').format(warrantyDate!)
                          : '',
                      status: status,
                    ),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppTheme.danger,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Healthy':
        return AppTheme.success;
      case 'Needs Repair':
        return AppTheme.danger;
      case 'Under Warranty':
        return AppTheme.accentGold;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppTheme.accentGold,
        elevation: 0,
        child: const Icon(Icons.add_rounded, color: Colors.black),
      ),
      body: StreamBuilder<List<Appliance>>(
        stream: _firestoreService.streamAppliances(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accentGold),
            );
          }
          final appliances = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.glassBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${appliances.length}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.accentSilver,
                                letterSpacing: -1,
                              ),
                            ),
                            Text(
                              'TOTAL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary.withValues(
                                  alpha: 0.5,
                                ),
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.glassBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${appliances.where((a) => a.status == 'Healthy').length}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.success,
                                letterSpacing: -1,
                              ),
                            ),
                            Text(
                              'HEALTHY',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary.withValues(
                                  alpha: 0.5,
                                ),
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                if (appliances.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        children: [
                          Icon(
                            Icons.devices_rounded,
                            size: 56,
                            color: AppTheme.textMuted.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No appliances yet',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (appliances.isNotEmpty)
                  const SectionHeader(title: 'Your Appliances'),

                ...appliances.map((appliance) {
                  final statusColor = _getStatusColor(appliance.status);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Dismissible(
                      key: Key(appliance.id ?? appliance.name),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.delete_rounded,
                          color: AppTheme.danger,
                        ),
                      ),
                      onDismissed: (_) {
                        if (appliance.id != null) {
                          _firestoreService.deleteAppliance(appliance.id!);
                        }
                      },
                      child: GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        appliance.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        appliance.brand,
                                        style: TextStyle(
                                          color: AppTheme.textSecondary
                                              .withValues(alpha: 0.6),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                StatusBadge(
                                  text: appliance.status,
                                  color: statusColor,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(height: 1, color: AppTheme.glassBorder),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _infoChip('Purchased', appliance.purchaseDate),
                                const SizedBox(width: 24),
                                _infoChip('Warranty', appliance.warrantyExpiry),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary.withValues(alpha: 0.4),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.isNotEmpty ? value : '—',
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
