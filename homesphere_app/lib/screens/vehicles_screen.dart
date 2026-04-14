import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/stat_card.dart';
import '../services/firestore_service.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  final _firestoreService = FirestoreService();

  Widget _buildDateField({
    required BuildContext ctx,
    required String label,
    required DateTime? date,
    required void Function(DateTime) onPicked,
  }) {
    final cs = Theme.of(ctx).colorScheme;
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: ctx,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2040),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
              size: 18,
            ),
            const SizedBox(width: 12),
            Text(
              date != null ? DateFormat('MMM dd, yyyy').format(date) : label,
              style: TextStyle(
                color: date != null
                    ? cs.onSurface
                    : cs.onSurfaceVariant.withValues(alpha: 0.5),
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
    final regCtrl = TextEditingController();
    final serviceCtrl = TextEditingController();
    DateTime? insuranceDate;
    DateTime? pucDate;

    CREDBottomSheet.show(
      context: context,
      title: 'Add Vehicle',
      builder: (ctx, setModalState) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            credTextField(nameCtrl, 'Vehicle Name', 'e.g. Honda City'),
            const SizedBox(height: 14),
            credTextField(regCtrl, 'Registration No.', 'e.g. KA-09-AB-1234'),
            const SizedBox(height: 14),
            _buildDateField(
              ctx: ctx,
              label: 'Insurance Expiry',
              date: insuranceDate,
              onPicked: (d) => setModalState(() => insuranceDate = d),
            ),
            const SizedBox(height: 14),
            _buildDateField(
              ctx: ctx,
              label: 'PUC Expiry',
              date: pucDate,
              onPicked: (d) => setModalState(() => pucDate = d),
            ),
            const SizedBox(height: 14),
            credTextField(
              serviceCtrl,
              'Next Service (km)',
              'e.g. 15000',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            credButton(
              label: 'Add Vehicle',
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                try {
                  await _firestoreService.addVehicle(
                    Vehicle(
                      name: nameCtrl.text.trim(),
                      regNumber: regCtrl.text.trim(),
                      mileage: '',
                      insuranceExpiry: insuranceDate != null
                          ? DateFormat('MMM dd, yyyy').format(insuranceDate!)
                          : '',
                      pucExpiry: pucDate != null
                          ? DateFormat('MMM dd, yyyy').format(pucDate!)
                          : '',
                      nextService: serviceCtrl.text.trim(),
                    ),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppTheme.danger,
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add_rounded),
      ),
      body: StreamBuilder<List<Vehicle>>(
        stream: _firestoreService.streamVehicles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: cs.primary),
            );
          }
          final vehicles = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Count header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.directions_car_rounded,
                          color: cs.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${vehicles.length}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                              letterSpacing: -1,
                            ),
                          ),
                          Text(
                            'REGISTERED VEHICLES',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                if (vehicles.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        children: [
                          Icon(
                            Icons.directions_car_rounded,
                            size: 56,
                            color: cs.outline.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No vehicles yet',
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (vehicles.isNotEmpty)
                  const SectionHeader(title: 'Your Vehicles'),

                ...vehicles.map((vehicle) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Dismissible(
                      key: Key(vehicle.id ?? vehicle.name),
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
                        if (vehicle.id != null) {
                          _firestoreService.deleteVehicle(vehicle.id!);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
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
                                        vehicle.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 17,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        vehicle.regNumber,
                                        style: TextStyle(
                                          color: cs.primary
                                              .withValues(alpha: 0.7),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              height: 1,
                              color: cs.outlineVariant
                                  .withValues(alpha: 0.2),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                _infoItem('Insurance', vehicle.insuranceExpiry),
                                const SizedBox(width: 32),
                                _infoItem('PUC', vehicle.pucExpiry),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _infoItem(
                              'Next Service',
                              vehicle.nextService.isNotEmpty
                                  ? '${vehicle.nextService} km'
                                  : '—',
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

  Widget _infoItem(String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.isNotEmpty ? value : '—',
          style: TextStyle(
            fontSize: 13,
            color: cs.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
