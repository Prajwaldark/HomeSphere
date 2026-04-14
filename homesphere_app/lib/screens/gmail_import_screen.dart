import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/gmail_service.dart';
import '../services/firestore_service.dart';
import '../widgets/stat_card.dart';

class GmailImportScreen extends StatefulWidget {
  const GmailImportScreen({super.key});

  @override
  State<GmailImportScreen> createState() => _GmailImportScreenState();
}

class _GmailImportScreenState extends State<GmailImportScreen>
    with SingleTickerProviderStateMixin {
  final _gmailService = GmailService();
  final _firestoreService = FirestoreService();

  List<DetectedSubscription>? _detected;
  bool _isScanning = false;
  bool _isSaving = false;
  String? _error;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _startScan();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _error = null;
    });
    try {
      final results = await _gmailService.scanForSubscriptions();
      if (mounted) {
        setState(() {
          _detected = results;
          _isScanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _importSelected() async {
    if (_detected == null) return;
    final selected = _detected!.where((d) => d.selected).toList();
    if (selected.isEmpty) return;

    setState(() => _isSaving = true);

    int added = 0;
    for (final sub in selected) {
      try {
        await _firestoreService.addSubscription(sub.toSubscription());
        added++;
      } catch (_) {}
    }

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$added subscription${added == 1 ? '' : 's'} imported!'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context, added);
    }
  }

  void _toggleAll(bool select) {
    setState(() {
      for (final d in _detected!) {
        d.selected = select;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selectedCount = _detected?.where((d) => d.selected).length ?? 0;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Import from Gmail',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: cs.onSurface,
          ),
        ),
        actions: [
          if (_detected != null && _detected!.isNotEmpty)
            TextButton(
              onPressed: () {
                final allSelected = _detected!.every((d) => d.selected);
                _toggleAll(!allSelected);
              },
              child: Text(
                _detected!.every((d) => d.selected) ? 'Deselect All' : 'Select All',
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: _isScanning
          ? _buildScanningState(cs)
          : _error != null
              ? _buildErrorState(cs)
              : _detected == null || _detected!.isEmpty
                  ? _buildEmptyState(cs)
                  : _buildResultsList(cs),
      bottomNavigationBar: (_detected != null && _detected!.isNotEmpty)
          ? Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(
                  top: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: selectedCount > 0 && !_isSaving
                      ? _importSelected
                      : null,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: cs.onPrimary,
                          ),
                        )
                      : Text(
                          'Import $selectedCount Subscription${selectedCount == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildScanningState(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated scanning icon
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.85 + (_pulseController.value * 0.15),
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.email_rounded,
                      size: 44,
                      color: cs.primary.withValues(
                        alpha: 0.5 + (_pulseController.value * 0.5),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Text(
              'Scanning your inbox...',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Looking for subscriptions from the\nlast 6 months',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                borderRadius: BorderRadius.circular(4),
                color: cs.primary,
                backgroundColor: cs.surfaceContainerHighest,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppTheme.danger,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _startScan,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.primary,
                side: BorderSide(color: cs.primary.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_rounded,
                size: 40,
                color: cs.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No subscriptions found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t find any subscription emails\nin the last 6 months',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _startScan,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Scan Again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.primary,
                side: BorderSide(color: cs.primary.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(ColorScheme cs) {
    final categorized = <String, List<DetectedSubscription>>{};
    for (final d in _detected!) {
      categorized.putIfAbsent(d.category, () => []).add(d);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: cs.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: cs.primary, size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Found ${_detected!.length} subscription${_detected!.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Select the ones you want to import',
                        style: TextStyle(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // List by category
          ...categorized.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(title: entry.key),
                ...entry.value.map((sub) => _buildSubscriptionTile(sub, cs)),
                const SizedBox(height: 16),
              ],
            );
          }),

          const SizedBox(height: 80), // space for bottom bar
        ],
      ),
    );
  }

  Widget _buildSubscriptionTile(DetectedSubscription sub, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => setState(() => sub.selected = !sub.selected),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: sub.selected
                ? cs.primaryContainer.withValues(alpha: 0.15)
                : cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: sub.selected
                  ? cs.primary.withValues(alpha: 0.3)
                  : cs.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              // Checkbox
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: sub.selected ? cs.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: sub.selected
                        ? cs.primary
                        : cs.outlineVariant.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: sub.selected
                    ? Icon(Icons.check_rounded, size: 16, color: cs.onPrimary)
                    : null,
              ),
              const SizedBox(width: 14),
              // Service info
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
                      sub.emailSubject.length > 50
                          ? '${sub.emailSubject.substring(0, 50)}...'
                          : sub.emailSubject,
                      style: TextStyle(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Price & date
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (sub.price.isNotEmpty)
                    Text(
                      sub.price,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: cs.primary,
                      ),
                    ),
                  if (sub.date.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      sub.date,
                      style: TextStyle(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
