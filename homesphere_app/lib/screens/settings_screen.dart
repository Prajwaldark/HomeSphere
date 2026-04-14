import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../widgets/stat_card.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  final _user = FirebaseAuth.instance.currentUser;
  bool _notificationsEnabled = true;

  String _getDisplayName() {
    if (_user == null) return 'User';
    if (_user.displayName != null && _user.displayName!.isNotEmpty) {
      return _user.displayName!;
    }
    final email = _user.email ?? '';
    final name = email.split('@').first;
    if (name.isEmpty) return 'User';
    return name
        .replaceAll(RegExp(r'[._]'), ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  String _getInitials() {
    final name = _getDisplayName();
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  void _showEditNameDialog() {
    final nameCtrl = TextEditingController(text: _user?.displayName ?? '');
    CREDBottomSheet.show(
      context: context,
      title: 'Edit Profile',
      builder: (ctx, setModalState) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          credTextField(nameCtrl, 'Display Name', 'Enter your name'),
          const SizedBox(height: 24),
          credButton(
            label: 'Save',
            onPressed: () async {
              final newName = nameCtrl.text.trim();
              if (newName.isEmpty) return;
              try {
                await _user?.updateDisplayName(newName);
                await _user?.reload();
                if (ctx.mounted) Navigator.pop(ctx);
                setState(() {});
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Name updated successfully'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
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

  void _showChangePasswordDialog() {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();

    CREDBottomSheet.show(
      context: context,
      title: 'Change Password',
      builder: (ctx, setModalState) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          credTextField(currentPassCtrl, 'Current Password', '••••••••'),
          const SizedBox(height: 14),
          credTextField(newPassCtrl, 'New Password', '••••••••'),
          const SizedBox(height: 14),
          credTextField(confirmPassCtrl, 'Confirm New Password', '••••••••'),
          const SizedBox(height: 24),
          credButton(
            label: 'Update Password',
            onPressed: () async {
              if (newPassCtrl.text.isEmpty || newPassCtrl.text.length < 6) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: const Text('Password must be at least 6 characters'),
                    backgroundColor: AppTheme.danger,
                  ),
                );
                return;
              }
              if (newPassCtrl.text != confirmPassCtrl.text) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: const Text('Passwords do not match'),
                    backgroundColor: AppTheme.danger,
                  ),
                );
                return;
              }
              try {
                final cred = EmailAuthProvider.credential(
                  email: _user!.email!,
                  password: currentPassCtrl.text,
                );
                await _user.reauthenticateWithCredential(cred);
                await _user.updatePassword(newPassCtrl.text);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Password updated successfully'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error: ${e.toString().contains('wrong-password') ? 'Current password is incorrect' : e}',
                      ),
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

  void _showDeleteAccountDialog() {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete Account',
          style: TextStyle(color: cs.error, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This action is permanent and cannot be undone. All your data will be lost.',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _user?.delete();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e. Please sign in again and retry.'),
                      backgroundColor: AppTheme.danger,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Delete',
              style: TextStyle(color: cs.error, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog() {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Sign Out',
          style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _authService.signOut();
            },
            child: Text(
              'Sign Out',
              style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final themeProvider = HomeSphereApp.of(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
            color: cs.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile Card ──
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
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.primaryGradient(context),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: cs.surfaceContainerHigh,
                      child: Text(
                        _getInitials(),
                        style: TextStyle(
                          color: cs.primary,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getDisplayName(),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _user?.email ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: (_user?.emailVerified == true
                              ? AppTheme.success
                              : AppTheme.warning)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _user?.emailVerified == true ? 'Verified' : 'Unverified',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _user?.emailVerified == true
                            ? AppTheme.success
                            : AppTheme.warning,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showEditNameDialog,
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Edit Name'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cs.primary,
                        side: BorderSide(color: cs.primary.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Account ──
            const SectionHeader(title: 'Account'),
            _buildSettingsTile(
              icon: Icons.lock_outline_rounded,
              title: 'Change Password',
              subtitle: 'Update your account password',
              onTap: _showChangePasswordDialog,
            ),
            const SizedBox(height: 8),
            _buildSettingsTile(
              icon: Icons.email_outlined,
              title: 'Email',
              subtitle: _user?.email ?? 'Not set',
              trailing: Icon(Icons.verified_rounded, size: 16, color: AppTheme.success),
            ),
            const SizedBox(height: 32),

            // ── Preferences ──
            const SectionHeader(title: 'Preferences'),
            _buildSettingsTile(
              icon: Icons.notifications_none_rounded,
              title: 'Push Notifications',
              subtitle: 'Reminders & alerts',
              trailing: Switch(
                value: _notificationsEnabled,
                onChanged: (v) async {
                  setState(() => _notificationsEnabled = v);
                  if (v) {
                    await NotificationService().requestPermissions();
                  } else {
                    await NotificationService().cancelAll();
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            // Theme toggle
            _buildSettingsTile(
              icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              title: 'Appearance',
              subtitle: isDark ? 'Dark mode' : 'Light mode',
              trailing: GestureDetector(
                onTap: () => themeProvider.toggleTheme(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 64,
                  height: 32,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: isDark
                        ? cs.surfaceContainerHighest
                        : cs.primaryContainer,
                    border: Border.all(
                      color: isDark
                          ? cs.outlineVariant.withValues(alpha: 0.3)
                          : Colors.transparent,
                    ),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    alignment:
                        isDark ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? cs.primary : cs.onPrimaryContainer,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                        size: 14,
                        color: isDark ? cs.onPrimary : cs.primaryContainer,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── About ──
            const SectionHeader(title: 'About'),
            _buildSettingsTile(
              icon: Icons.info_outline_rounded,
              title: 'App Version',
              subtitle: '1.0.0',
            ),
            const SizedBox(height: 8),
            _buildSettingsTile(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              subtitle: 'Read our terms',
              onTap: () {},
            ),
            const SizedBox(height: 8),
            _buildSettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'How we handle your data',
              onTap: () {},
            ),
            const SizedBox(height: 32),

            // ── Danger Zone ──
            const SectionHeader(title: 'Danger Zone'),
            _buildSettingsTile(
              icon: Icons.logout_rounded,
              title: 'Sign Out',
              subtitle: 'Sign out of your account',
              iconColor: AppTheme.warning,
              onTap: _showSignOutDialog,
            ),
            const SizedBox(height: 8),
            _buildSettingsTile(
              icon: Icons.delete_forever_rounded,
              title: 'Delete Account',
              subtitle: 'Permanently delete your account',
              iconColor: AppTheme.danger,
              titleColor: AppTheme.danger,
              onTap: _showDeleteAccountDialog,
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    final cs = Theme.of(context).colorScheme;
    final effectiveIconColor = iconColor ?? cs.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: effectiveIconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: effectiveIconColor.withValues(alpha: 0.7),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: titleColor ?? cs.onSurface,
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
            if (trailing != null)
              trailing
            else if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                color: cs.outline.withValues(alpha: 0.5),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
