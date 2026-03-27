import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/stat_card.dart';

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
    // Capitalize and replace separators with spaces
    return name
        .replaceAll(RegExp(r'[._]'), ' ')
        .split(' ')
        .map(
          (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
        )
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
                setState(() {}); // Refresh UI
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Name updated successfully'),
                      backgroundColor: AppTheme.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  );
                }
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
                    content: const Text(
                      'Password must be at least 6 characters',
                    ),
                    backgroundColor: AppTheme.danger,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              if (newPassCtrl.text != confirmPassCtrl.text) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: const Text('Passwords do not match'),
                    backgroundColor: AppTheme.danger,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              try {
                // Re-authenticate first
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
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.panelBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppTheme.glassBorder),
        ),
        title: const Text(
          'Delete Account',
          style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'This action is permanent and cannot be undone. All your data will be lost.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
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
                      content: Text(
                        'Error: $e. Please sign in again and retry.',
                      ),
                      backgroundColor: AppTheme.danger,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: AppTheme.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.panelBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppTheme.glassBorder),
        ),
        title: const Text(
          'Sign Out',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _authService.signOut();
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(
                color: AppTheme.accentGold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
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
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.premiumGradient,
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: AppTheme.cardBg,
                      child: Text(
                        _getInitials(),
                        style: const TextStyle(
                          color: AppTheme.accentGold,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getDisplayName(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _user?.email ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withValues(alpha: 0.08),
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
                        foregroundColor: AppTheme.accentGold,
                        side: BorderSide(
                          color: AppTheme.accentGold.withValues(alpha: 0.3),
                        ),
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

            // ── Account Section ──
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
              trailing: const Icon(
                Icons.verified_rounded,
                size: 16,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(height: 32),

            // ── Preferences Section ──
            const SectionHeader(title: 'Preferences'),
            _buildSettingsTile(
              icon: Icons.notifications_none_rounded,
              title: 'Push Notifications',
              subtitle: 'Reminders & alerts',
              trailing: Switch(
                value: _notificationsEnabled,
                onChanged: (v) => setState(() => _notificationsEnabled = v),
                activeColor: AppTheme.accentGold,
                activeTrackColor: AppTheme.accentGold.withValues(alpha: 0.3),
                inactiveThumbColor: AppTheme.textMuted,
                inactiveTrackColor: AppTheme.surfaceLight,
              ),
            ),
            const SizedBox(height: 8),
            _buildSettingsTile(
              icon: Icons.dark_mode_rounded,
              title: 'Theme',
              subtitle: 'Dark (CRED style)',
              trailing: Icon(
                Icons.palette_rounded,
                size: 18,
                color: AppTheme.accentGold.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 32),

            // ── About Section ──
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.glassBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (iconColor ?? AppTheme.textSecondary).withValues(
                  alpha: 0.08,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: (iconColor ?? AppTheme.textSecondary).withValues(
                  alpha: 0.7,
                ),
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
                      color: titleColor ?? AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.textSecondary.withValues(alpha: 0.5),
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
                color: AppTheme.textMuted.withValues(alpha: 0.5),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
