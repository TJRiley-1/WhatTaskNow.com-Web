import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/points_calculator.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_modal.dart';
import '../../../core/widgets/screen_scaffold.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  void _showEditProfileDialog() {
    final supabase = ref.read(supabaseDatasourceProvider);
    final user = supabase.currentUser;
    final nameController = TextEditingController(
      text: user?.userMetadata?['full_name'] as String? ?? '',
    );

    showGlassModal(
      context: context,
      title: 'Edit Profile',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlassCard(
            borderRadius: 12,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: nameController,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
              decoration: const InputDecoration(
                hintText: 'Display name',
                hintStyle: TextStyle(color: AppColors.textMuted),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
      actions: [
        GlassButton(
          label: 'Cancel',
          variant: GlassButtonVariant.outline,
          isFullWidth: false,
          onPressed: () => Navigator.of(context).pop(),
        ),
        GlassButton(
          label: 'Save',
          variant: GlassButtonVariant.primary,
          isFullWidth: false,
          onPressed: () async {
            final name = nameController.text.trim();
            if (name.isNotEmpty && user != null) {
              await supabase.updateProfile(user.id, {'display_name': name});
            }
            if (mounted) {
              Navigator.of(context).pop();
              setState(() {});
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final supabase = ref.read(supabaseDatasourceProvider);
    final hive = ref.read(hiveDatasourceProvider);
    final taskRepo = ref.read(taskRepositoryProvider);
    final stats = taskRepo.getStats();

    final user = supabase.currentUser;
    final isLoggedIn = user != null;
    final email = user?.email ?? 'Guest';
    final displayName = user?.userMetadata?['full_name'] as String? ?? 'Guest User';
    final totalPoints = stats.totalPoints;
    final tasksDone = stats.completed;
    final rank = getRank(totalPoints);
    final biometricEnabled = hive.biometricEnabled;

    return ScreenScaffold(
      title: 'Profile',
      onBack: () => context.go('/home'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primaryLight,
                  ],
                ),
                border: Border.all(
                  color: AppColors.glassBorder,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              displayName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 24),

            // Stats row
            GlassCard(
              borderRadius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(label: 'Points', value: '$totalPoints'),
                  Container(width: 1, height: 36, color: AppColors.glassBorder),
                  _StatItem(label: 'Tasks Done', value: '$tasksDone'),
                  Container(width: 1, height: 36, color: AppColors.glassBorder),
                  _StatItem(label: 'Rank', value: rank.name),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            if (isLoggedIn) ...[
              _buildMenuButton(
                icon: Icons.edit_rounded,
                label: 'Edit Profile',
                onTap: _showEditProfileDialog,
              ),
              const SizedBox(height: 10),
            ],

            _buildMenuButton(
              icon: Icons.group_rounded,
              label: 'My Groups',
              onTap: () => context.go('/groups'),
            ),
            const SizedBox(height: 10),

            _buildMenuButton(
              icon: Icons.school_rounded,
              label: 'User Guide',
              onTap: () => context.go('/tutorial'),
            ),
            const SizedBox(height: 10),

            _buildMenuButton(
              icon: Icons.help_outline_rounded,
              label: 'Help & FAQ',
              onTap: () => context.push('/help'),
            ),
            const SizedBox(height: 10),

            _buildMenuButton(
              icon: Icons.notifications_rounded,
              label: 'Enable Notifications',
              onTap: () async {
                final granted = await NotificationService.requestPermission();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      granted
                          ? 'Notifications enabled!'
                          : 'Notification permission denied.',
                    ),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            // Biometric toggle
            GlassCard(
              borderRadius: 14,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.fingerprint_rounded, color: AppColors.textSecondary, size: 22),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Biometric Lock',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Switch(
                    value: biometricEnabled,
                    activeColor: AppColors.primary,
                    onChanged: (value) async {
                      if (value) {
                        // Enabling: verify biometrics are available first.
                        final available = await BiometricService.isAvailable();
                        if (!available) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Biometric authentication not available on this device',
                              ),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                          return;
                        }

                        // Verify the user can authenticate before enabling.
                        final authenticated = await BiometricService.authenticate();
                        if (!authenticated) return;

                        await hive.setBiometricEnabled(true);
                      } else {
                        // Disabling: just turn it off.
                        await hive.setBiometricEnabled(false);
                      }
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (isLoggedIn)
              GlassButton(
                label: 'Sign Out',
                variant: GlassButtonVariant.danger,
                onPressed: () async {
                  await supabase.signOut();
                  if (mounted) {
                    context.go('/welcome');
                  }
                },
              )
            else
              GlassButton(
                label: 'Sign In to Sync',
                variant: GlassButtonVariant.primary,
                onPressed: () => context.go('/welcome'),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
