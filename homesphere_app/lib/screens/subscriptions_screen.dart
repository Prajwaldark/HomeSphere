import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/stat_card.dart';
import '../services/firestore_service.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final _firestoreService = FirestoreService();

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String selectedCategory = 'Entertainment';
    DateTime? billingDate;

    CREDBottomSheet.show(
      context: context,
      title: 'Add Subscription',
      builder: (ctx, setModalState) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          credTextField(nameCtrl, 'Name', 'e.g. Netflix'),
          const SizedBox(height: 14),
          credTextField(priceCtrl, 'Price', 'e.g. ₹499/mo'),
          const SizedBox(height: 14),
          // Date picker
          _buildDateField(
            ctx: ctx,
            label: 'Next Billing',
            date: billingDate,
            onPicked: (d) => setModalState(() => billingDate = d),
          ),
          const SizedBox(height: 14),
          // Category dropdown
          DropdownButtonFormField<String>(
            value: selectedCategory,
            dropdownColor: AppTheme.panelBg,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              labelText: 'Category',
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
              'Entertainment',
              'Productivity',
              'Cloud',
              'Music',
              'Other',
            ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setModalState(() => selectedCategory = v!),
          ),
          const SizedBox(height: 24),
          credButton(
            label: 'Add Subscription',
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              try {
                await _firestoreService.addSubscription(
                  Subscription(
                    name: nameCtrl.text.trim(),
                    price: priceCtrl.text.trim(),
                    nextBilling: billingDate != null
                        ? DateFormat('MMM dd, yyyy').format(billingDate!)
                        : '',
                    category: selectedCategory,
                    isActive: true,
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
    );
  }

  Widget _buildDateField({
    required BuildContext ctx,
    required String label,
    required DateTime? date,
    required void Function(DateTime) onPicked,
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

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Entertainment':
        return AppTheme.accentGold;
      case 'Productivity':
        return AppTheme.accentSilver;
      case 'Cloud':
        return AppTheme.accentChampagne;
      case 'Music':
        return AppTheme.success;
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
      body: StreamBuilder<List<Subscription>>(
        stream: _firestoreService.streamSubscriptions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accentGold),
            );
          }
          final subs = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero summary
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppTheme.premiumGradient,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${subs.where((s) => s.isActive).length}',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                          letterSpacing: -2,
                        ),
                      ),
                      const Text(
                        'ACTIVE SUBSCRIPTIONS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.black54,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                if (subs.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_rounded,
                            size: 56,
                            color: AppTheme.textMuted.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No subscriptions yet',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap + to add one',
                            style: TextStyle(
                              color: AppTheme.textMuted.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SectionHeader(title: 'All Subscriptions'),

                ...subs.map((sub) {
                  final color = _getCategoryColor(sub.category);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Dismissible(
                      key: Key(sub.id ?? sub.name),
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
                        if (sub.id != null) {
                          _firestoreService.deleteSubscription(sub.id!);
                        }
                      },
                      child: GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            // Category dot
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
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
                                      fontSize: 16,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${sub.category} · ${sub.nextBilling}',
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  sub.price,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                StatusBadge(
                                  text: sub.isActive ? 'Active' : 'Paused',
                                  color: sub.isActive
                                      ? AppTheme.success
                                      : AppTheme.textSecondary,
                                ),
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
}
