import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/stat_card.dart';
import '../services/firestore_service.dart';
import '../services/nearby_service_discovery.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final _firestoreService = FirestoreService();
  final _nearbyDiscovery = NearbyServiceDiscovery();
  String _selectedCategory = 'All';
  bool _isLoadingNearby = false;
  String? _nearbyMessage;
  String? _nearbyError;
  String? _nearbyLocationLabel;
  DateTime? _lastNearbyRefresh;
  List<ServiceProvider> _nearbyProviders = [];

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
    _showProviderForm();
  }

  void _showEditProviderDialog(ServiceProvider provider) {
    _showProviderForm(existing: provider);
  }

  void _showProviderForm({ServiceProvider? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final locationCtrl = TextEditingController(text: existing?.location ?? '');
    final ratingCtrl = TextEditingController(
      text: existing != null ? '${existing.rating}' : '4.5',
    );
    final customCategoryCtrl = TextEditingController();
    // If the existing category is not in the preset list, show as custom
    final presetCategories = ['Electrician', 'Plumber', 'Mechanic', 'AC Technician', 'Other'];
    String category = existing != null && presetCategories.contains(existing.category)
        ? existing.category
        : (existing != null ? 'Other' : 'Electrician');
    // Pre-fill custom category if needed
    if (existing != null && !presetCategories.sublist(0, 4).contains(existing.category)) {
      customCategoryCtrl.text = existing.category;
    }
    final isEdit = existing != null;

    CREDBottomSheet.show(
      context: context,
      title: isEdit ? 'Edit Provider' : 'Add Provider',
      builder: (ctx, setModalState) {
        final cs = Theme.of(ctx).colorScheme;
        final isOther = category == 'Other';
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
                value: category,
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
              // Show custom category field when "Other" is selected
              AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeInOut,
                child: isOther
                    ? Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.label_outline_rounded,
                                  size: 16,
                                  color: cs.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'New Category Name',
                                  style: TextStyle(
                                    color: cs.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            credTextField(
                              customCategoryCtrl,
                              'Category Name',
                              'e.g. Carpenter, Painter...',
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
              credButton(
                label: isEdit ? 'Save Changes' : 'Add Provider',
                onPressed: () async {
                  if (nameCtrl.text.isEmpty) return;
                  // Use custom category name if "Other" was selected
                  final finalCategory = (category == 'Other' &&
                          customCategoryCtrl.text.trim().isNotEmpty)
                      ? customCategoryCtrl.text.trim()
                      : category;
                  try {
                    final updated = ServiceProvider(
                      id: existing?.id,
                      name: nameCtrl.text.trim(),
                      category: finalCategory,
                      rating: double.tryParse(ratingCtrl.text) ?? 4.5,
                      phone: phoneCtrl.text.trim(),
                      location: locationCtrl.text.trim(),
                    );
                    if (isEdit) {
                      await _firestoreService.updateServiceProvider(updated);
                    } else {
                      await _firestoreService.addServiceProvider(updated);
                    }
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

  Future<void> _refreshNearbyProviders() async {
    if (_isLoadingNearby) return;

    setState(() {
      _isLoadingNearby = true;
      _nearbyError = null;
      _nearbyMessage = 'Finding nearby providers within 15 km...';
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
          'Location services are turned off. Please enable GPS and try again.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception('Location permission was denied.');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is permanently denied. Open app settings and allow location access.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final result = await _nearbyDiscovery.fetchNearbyProviders(
        latitude: position.latitude,
        longitude: position.longitude,
        category: _selectedCategory,
        radiusKm: 15,
      );

      if (!mounted) return;

      setState(() {
        _nearbyProviders = result.providers;
        _nearbyMessage = result.message;
        _nearbyLocationLabel =
            'Lat ${position.latitude.toStringAsFixed(4)}, Lng ${position.longitude.toStringAsFixed(4)}';
        _lastNearbyRefresh = DateTime.now();
        _isLoadingNearby = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _nearbyProviders = [];
        _nearbyError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingNearby = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_nearbyError!),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient(context),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: cs.onPrimary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.my_location_rounded,
                              color: cs.onPrimary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nearby service providers',
                                  style: TextStyle(
                                    color: cs.onPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap location to refresh businesses and phone numbers within 15 km.',
                                  style: TextStyle(
                                    color: cs.onPrimary.withValues(alpha: 0.78),
                                    fontSize: 12,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isLoadingNearby
                              ? null
                              : _refreshNearbyProviders,
                          style: FilledButton.styleFrom(
                            backgroundColor: cs.onPrimary,
                            foregroundColor: cs.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: _isLoadingNearby
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: cs.primary,
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded, size: 18),
                          label: Text(
                            _isLoadingNearby
                                ? 'Refreshing location...'
                                : 'Use My Location',
                          ),
                        ),
                      ),
                      if (_nearbyLocationLabel != null ||
                          _lastNearbyRefresh != null ||
                          _nearbyMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _nearbyError ??
                              _nearbyMessage ??
                              _nearbyLocationLabel ??
                              '',
                          style: TextStyle(
                            color: cs.onPrimary.withValues(alpha: 0.85),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                        if (_lastNearbyRefresh != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Last refreshed: ${TimeOfDay.fromDateTime(_lastNearbyRefresh!).format(context)}',
                            style: TextStyle(
                              color: cs.onPrimary.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (_nearbyProviders.isNotEmpty) ...[
                  SectionHeader(
                    title: 'Nearby Results',
                    trailing: _nearbyLocationLabel != null ? '15 km' : null,
                  ),
                  if (_nearbyLocationLabel != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _nearbyLocationLabel!,
                        style: TextStyle(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ..._nearbyProviders.map((provider) {
                    final color = _getCategoryColor(provider.category, cs);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
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
                                        provider.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        provider.location,
                                        style: TextStyle(
                                          color: cs.onSurfaceVariant
                                              .withValues(alpha: 0.55),
                                          fontSize: 12,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    StatusBadge(
                                      text: provider.category,
                                      color: color,
                                    ),
                                    if (provider.distanceKm != null) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        '${provider.distanceKm!.toStringAsFixed(1)} km away',
                                        style: TextStyle(
                                          color: cs.onSurfaceVariant
                                              .withValues(alpha: 0.5),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            if (provider.phone.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Container(
                                height: 1,
                                color:
                                    cs.outlineVariant.withValues(alpha: 0.2),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone_rounded,
                                    size: 14,
                                    color: cs.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    provider.phone,
                                    style: TextStyle(
                                      color: cs.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                ],

                if (_nearbyProviders.isEmpty && _nearbyMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      _nearbyMessage!,
                      style: TextStyle(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                        fontSize: 12,
                      ),
                    ),
                  ),

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
                          onSelected: (_) => setState(() {
                            _selectedCategory = cat;
                            if (_nearbyProviders.isNotEmpty) {
                              _nearbyProviders = [];
                              _nearbyLocationLabel = null;
                              _nearbyMessage =
                                  'Tap Use My Location to refresh $cat providers.';
                            }
                          }),
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
                      direction: DismissDirection.horizontal,
                      // Left: edit (blue)
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 24),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.edit_rounded,
                          color: cs.primary,
                        ),
                      ),
                      // Right: delete (red)
                      secondaryBackground: Container(
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
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          _showEditProviderDialog(provider);
                          return false;
                        }
                        return true;
                      },
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
