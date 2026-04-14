import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/stat_card.dart';
import '../services/firestore_service.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final _firestoreService = FirestoreService();
  String _selectedCategory = 'All';

  Color _getCategoryColor(String category, ColorScheme cs) {
    switch (category) {
      case 'Electrician':
        return cs.primary;
      case 'Plumber':
        return cs.secondary;
      case 'Mechanic':
        return AppTheme.success;
      case 'AC Technician':
        return cs.tertiary;
      default:
        return cs.onSurfaceVariant;
    }
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final ratingCtrl = TextEditingController(text: '4.5');
    String category = 'Electrician';

    CREDBottomSheet.show(
      context: context,
      title: 'Add Provider',
      builder: (ctx, setModalState) {
        final cs = Theme.of(ctx).colorScheme;
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              credTextField(nameCtrl, 'Name', 'e.g. Rajesh Kumar'),
              const SizedBox(height: 14),
              credTextField(phoneCtrl, 'Phone', 'e.g. +91 98765 43210'),
              const SizedBox(height: 14),
              credTextField(locationCtrl, 'Location', 'e.g. Mysuru'),
              const SizedBox(height: 14),
              credTextField(
                ratingCtrl,
                'Rating (1-5)',
                '4.5',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: category,
                dropdownColor: cs.surfaceContainerHigh,
                style: TextStyle(color: cs.onSurface, fontSize: 15),
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  'Electrician',
                  'Plumber',
                  'Mechanic',
                  'AC Technician',
                  'Other',
                ]
                    .map((c) =>
                        DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setModalState(() => category = v!),
              ),
              const SizedBox(height: 24),
              credButton(
                label: 'Add Provider',
                onPressed: () async {
                  if (nameCtrl.text.isEmpty) return;
                  try {
                    await _firestoreService.addServiceProvider(
                      ServiceProvider(
                        name: nameCtrl.text.trim(),
                        category: category,
                        rating: double.tryParse(ratingCtrl.text) ?? 4.5,
                        phone: phoneCtrl.text.trim(),
                        location: locationCtrl.text.trim(),
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
      },
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
      body: StreamBuilder<List<ServiceProvider>>(
        stream: _firestoreService.streamServiceProviders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: cs.primary),
            );
          }
          final allProviders = snapshot.data ?? [];
          final providers = _selectedCategory == 'All'
              ? allProviders
              : allProviders
                    .where((p) => p.category == _selectedCategory)
                    .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      'All',
                      'Electrician',
                      'Plumber',
                      'Mechanic',
                      'AC Technician',
                    ].map((cat) {
                      final isSelected = cat == _selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (_) =>
                              setState(() => _selectedCategory = cat),
                          selectedColor: cs.primaryContainer,
                          checkmarkColor: cs.onPrimaryContainer,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? cs.onPrimaryContainer
                                : cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          side: isSelected
                              ? BorderSide.none
                              : BorderSide(
                                  color: cs.outlineVariant
                                      .withValues(alpha: 0.4),
                                ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 32),

                SectionHeader(
                  title: providers.isEmpty
                      ? 'No Providers'
                      : '${providers.length} Providers',
                ),

                if (providers.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        children: [
                          Icon(
                            Icons.handyman_rounded,
                            size: 56,
                            color: cs.outline.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No service providers yet',
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

                ...providers.map((provider) {
                  final color = _getCategoryColor(provider.category, cs);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Dismissible(
                      key: Key(provider.id ?? provider.name),
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
                        if (provider.id != null) {
                          _firestoreService.deleteServiceProvider(provider.id!);
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
                          children: [
                            Row(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        provider.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        provider.category,
                                        style: TextStyle(
                                          color: cs.onSurfaceVariant
                                              .withValues(alpha: 0.5),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.star_rounded,
                                          color: cs.primary,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${provider.rating}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: cs.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (provider.location.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        provider.location,
                                        style: TextStyle(
                                          color: cs.onSurfaceVariant
                                              .withValues(alpha: 0.4),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            if (provider.phone.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                height: 1,
                                color: cs.outlineVariant
                                    .withValues(alpha: 0.2),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone_rounded,
                                    size: 13,
                                    color: cs.onSurfaceVariant
                                        .withValues(alpha: 0.4),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    provider.phone,
                                    style: TextStyle(
                                      color: cs.onSurfaceVariant
                                          .withValues(alpha: 0.6),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
