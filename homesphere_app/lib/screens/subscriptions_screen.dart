import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/stat_card.dart';
import '../services/firestore_service.dart';
import 'gmail_import_screen.dart';

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
          _buildDateField(
            ctx: ctx,
            label: 'Next Billing',
            date: billingDate,
            onPicked: (d) => setModalState(() => billingDate = d),
          ),
          const SizedBox(height: 14),
          _buildCategoryDropdown(ctx, selectedCategory, (v) {
            setModalState(() => selectedCategory = v!);
          }),
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

  Widget _buildCategoryDropdown(
    BuildContext ctx,
    String value,
    ValueChanged<String?> onChanged,
  ) {
    final cs = Theme.of(ctx).colorScheme;
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: cs.surfaceContainerHigh,
      style: TextStyle(color: cs.onSurface, fontSize: 15),
      decoration: InputDecoration(
        labelText: 'Category',
      ),
      items: ['Entertainment', 'Productivity', 'Cloud', 'Music', 'Other']
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: onChanged,
    );
  }

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

  Color _getCategoryColor(String category, ColorScheme cs) {
    switch (category) {
      case 'Entertainment':
        return cs.primary;
      case 'Productivity':
        return cs.secondary;
      case 'Cloud':
        return cs.tertiary;
      case 'Music':
        return AppTheme.success;
      default:
        return cs.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Gmail import mini FAB
          FloatingActionButton.small(
            heroTag: 'gmail_import',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GmailImportScreen(),
                ),
              );
            },
            backgroundColor: cs.secondaryContainer,
            foregroundColor: cs.onSecondaryContainer,
            child: const Icon(Icons.email_rounded, size: 20),
          ),
          const SizedBox(height: 12),
          // Manual add FAB
          FloatingActionButton(
            heroTag: 'add_sub',
            onPressed: _showAddDialog,
            child: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: StreamBuilder<List<Subscription>>(
        stream: _firestoreService.streamSubscriptions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: cs.primary),
            );
          }
          final subs = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero summary card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient(context),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${subs.where((s) => s.isActive).length}',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: cs.onPrimary,
                          letterSpacing: -2,
                        ),
                      ),
                      Text(
                        'ACTIVE SUBSCRIPTIONS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: cs.onPrimary.withValues(alpha: 0.7),
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Import from Gmail button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GmailImportScreen(),
                        ),
                      );
                    },
                    icon: Icon(Icons.email_rounded, size: 18, color: cs.primary),
                    label: Text(
                      'Import from Gmail',
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: cs.primary.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
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
                            color: cs.outline.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No subscriptions yet',
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap + to add one',
                            style: TextStyle(
                              color: cs.outline.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SectionHeader(title: 'All Subscriptions'),

                ...subs.map((sub) {
                  final color = _getCategoryColor(sub.category, cs);
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
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${sub.category} · ${sub.nextBilling}',
                                    style: TextStyle(
                                      color: cs.onSurfaceVariant
                                          .withValues(alpha: 0.6),
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
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: cs.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                StatusBadge(
                                  text: sub.isActive ? 'Active' : 'Paused',
                                  color: sub.isActive
                                      ? AppTheme.success
                                      : cs.onSurfaceVariant,
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
