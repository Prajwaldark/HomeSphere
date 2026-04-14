import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../services/appliance_vision_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';

class AppliancesScreen extends StatefulWidget {
  const AppliancesScreen({super.key});

  @override
  State<AppliancesScreen> createState() => _AppliancesScreenState();
}

class _AppliancesScreenState extends State<AppliancesScreen> {
  final _firestoreService = FirestoreService();
  final _visionService = ApplianceVisionService();
  final _imagePicker = ImagePicker();

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

  Future<void> _showApplianceForm({
    required String title,
    required String submitLabel,
    _ApplianceFormSeed? seed,
    XFile? capturedImage,
    String? helperMessage,
  }) async {
    final initial = seed ?? const _ApplianceFormSeed();
    final capturedImageBytes = capturedImage?.readAsBytes();
    final nameCtrl = TextEditingController(text: initial.name);
    final brandCtrl = TextEditingController(text: initial.brand);
    final modelCtrl = TextEditingController(text: initial.model);
    DateTime? purchaseDate = _parseUiDate(initial.purchaseDate);
    DateTime? warrantyDate = _parseUiDate(initial.warrantyExpiry);
    String category = Appliance.categoryOptions.contains(initial.category)
        ? initial.category
        : 'Other';
    String status = Appliance.statusOptions.contains(initial.status)
        ? initial.status
        : Appliance.statusOptions.first;

    await CREDBottomSheet.show(
      context: context,
      title: title,
      builder: (ctx, setModalState) {
        final cs = Theme.of(ctx).colorScheme;
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (capturedImageBytes != null) ...[
                _CapturedAppliancePreview(imageBytes: capturedImageBytes),
                const SizedBox(height: 14),
              ],
              if (helperMessage != null && helperMessage.trim().isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: cs.primary.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(
                    helperMessage,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              credTextField(nameCtrl, 'Appliance Name', 'e.g. Samsung Fridge'),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: category,
                dropdownColor: cs.surfaceContainerHigh,
                style: TextStyle(color: cs.onSurface, fontSize: 15),
                decoration: const InputDecoration(labelText: 'Category'),
                items: Appliance.categoryOptions
                    .map((option) => DropdownMenuItem(
                          value: option,
                          child: Text(option),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setModalState(() => category = value);
                },
              ),
              const SizedBox(height: 14),
              credTextField(brandCtrl, 'Brand', 'e.g. Samsung'),
              const SizedBox(height: 14),
              credTextField(modelCtrl, 'Model', 'e.g. RT28A3453S8'),
              const SizedBox(height: 14),
              _buildDateField(
                ctx: ctx,
                label: 'Purchase Date',
                date: purchaseDate,
                onPicked: (date) =>
                    setModalState(() => purchaseDate = date),
              ),
              const SizedBox(height: 14),
              _buildDateField(
                ctx: ctx,
                label: 'Warranty Expiry',
                date: warrantyDate,
                onPicked: (date) =>
                    setModalState(() => warrantyDate = date),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: status,
                dropdownColor: cs.surfaceContainerHigh,
                style: TextStyle(color: cs.onSurface, fontSize: 15),
                decoration: const InputDecoration(labelText: 'Status'),
                items: Appliance.statusOptions
                    .map((option) => DropdownMenuItem(
                          value: option,
                          child: Text(option),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setModalState(() => status = value);
                },
              ),
              const SizedBox(height: 24),
              credButton(
                label: submitLabel,
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;

                  try {
                    await _firestoreService.addAppliance(
                      Appliance(
                        name: nameCtrl.text.trim(),
                        brand: brandCtrl.text.trim(),
                        category: category,
                        model: modelCtrl.text.trim(),
                        purchaseDate: _formatUiDate(purchaseDate),
                        warrantyExpiry: _formatUiDate(warrantyDate),
                        status: status,
                      ),
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  } catch (e) {
                    if (!ctx.mounted) return;
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppTheme.danger,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddDialog() async {
    await _showApplianceForm(
      title: 'Add Appliance',
      submitLabel: 'Add Appliance',
    );
  }

  Future<void> _scanApplianceFromCamera() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1600,
    );

    if (image == null || !mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          backgroundColor: cs.surface,
          content: Row(
            children: [
              CircularProgressIndicator(color: cs.primary),
              const SizedBox(width: 16),
              const Expanded(
                child: Text('Analyzing appliance photo...'),
              ),
            ],
          ),
        );
      },
    );

    DetectedApplianceDetails detected;
    try {
      detected = await _visionService.analyzeImage(image);
    } catch (e) {
      detected = DetectedApplianceDetails.empty(
        message:
            'The photo could not be analyzed automatically. Review the same appliance form and fill in the missing details manually.\n\n$e',
      );
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    if (!mounted) return;

    await _showApplianceForm(
      title: 'Review Appliance',
      submitLabel: 'Add Appliance',
      seed: _ApplianceFormSeed.fromDetected(detected),
      capturedImage: image,
      helperMessage: detected.message,
    );
  }

  DateTime? _parseUiDate(String value) {
    if (value.trim().isEmpty) return null;
    try {
      return DateFormat('MMM dd, yyyy').parse(value);
    } catch (_) {
      return null;
    }
  }

  String _formatUiDate(DateTime? value) {
    if (value == null) return '';
    return DateFormat('MMM dd, yyyy').format(value);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Healthy':
        return AppTheme.success;
      case 'Needs Repair':
        return AppTheme.danger;
      case 'Under Warranty':
        return Theme.of(context).colorScheme.primary;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  String _buildSecondaryText(Appliance appliance) {
    final parts = [
      appliance.brand.trim(),
      appliance.model.trim(),
    ].where((value) => value.isNotEmpty).toList();
    return parts.join(' | ');
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
          FloatingActionButton.small(
            heroTag: 'scan_appliance_fab',
            onPressed: _scanApplianceFromCamera,
            child: const Icon(Icons.camera_alt_rounded),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'add_appliance_fab',
            onPressed: _showAddDialog,
            child: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: StreamBuilder<List<Appliance>>(
        stream: _firestoreService.streamAppliances(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: cs.primary),
            );
          }
          final appliances = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
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
                            Text(
                              '${appliances.length}',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: cs.secondary,
                                letterSpacing: -1,
                              ),
                            ),
                            Text(
                              'TOTAL',
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
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
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
                                color: cs.onSurfaceVariant
                                    .withValues(alpha: 0.5),
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
                            color: cs.outline.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No appliances yet',
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add one manually or scan it with the camera.',
                            style: TextStyle(
                              color: cs.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                              fontSize: 13,
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
                  final secondaryText = _buildSecondaryText(appliance);
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
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                      if (secondaryText.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          secondaryText,
                                          style: TextStyle(
                                            color: cs.onSurfaceVariant
                                                .withValues(alpha: 0.6),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
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
                            Container(
                              height: 1,
                              color: cs.outlineVariant.withValues(alpha: 0.2),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 24,
                              runSpacing: 12,
                              children: [
                                _infoChip(
                                  'Category',
                                  appliance.category,
                                ),
                                _infoChip(
                                  'Model',
                                  appliance.model,
                                ),
                                _infoChip(
                                  'Purchased',
                                  appliance.purchaseDate,
                                ),
                                _infoChip(
                                  'Warranty',
                                  appliance.warrantyExpiry,
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

  Widget _infoChip(String label, String value) {
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
          value.isNotEmpty ? value : '-',
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

class _ApplianceFormSeed {
  const _ApplianceFormSeed({
    this.name = '',
    this.brand = '',
    this.category = 'Other',
    this.model = '',
    this.purchaseDate = '',
    this.warrantyExpiry = '',
    this.status = 'Healthy',
  });

  factory _ApplianceFormSeed.fromDetected(DetectedApplianceDetails detected) {
    return _ApplianceFormSeed(
      name: detected.name,
      brand: detected.brand,
      category: detected.category,
      model: detected.model,
    );
  }

  final String name;
  final String brand;
  final String category;
  final String model;
  final String purchaseDate;
  final String warrantyExpiry;
  final String status;
}

class _CapturedAppliancePreview extends StatelessWidget {
  const _CapturedAppliancePreview({required this.imageBytes});

  final Future<Uint8List> imageBytes;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FutureBuilder<Uint8List>(
      future: imageBytes,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: 180,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: CircularProgressIndicator(color: cs.primary),
            ),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.memory(
            snapshot.data!,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}
