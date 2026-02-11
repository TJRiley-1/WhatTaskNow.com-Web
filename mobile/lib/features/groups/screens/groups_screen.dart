import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_modal.dart';
import '../../../core/widgets/screen_scaffold.dart';
import '../../../data/models/group.dart';
import '../../../core/utils/analytics.dart';

class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  List<Group>? _groups;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final supabase = ref.read(supabaseDatasourceProvider);
    final userId = supabase.userId;
    if (userId == null) {
      setState(() {
        _groups = [];
        _loading = false;
      });
      return;
    }

    try {
      final groups = await supabase.getMyGroups(userId);
      if (mounted) {
        setState(() {
          _groups = groups;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _groups = [];
          _loading = false;
        });
      }
    }
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showGlassModal(
      context: context,
      title: 'Create Group',
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
                hintText: 'Group name',
                hintStyle: TextStyle(color: AppColors.textMuted),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            borderRadius: 12,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: descController,
              maxLines: 2,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
              decoration: const InputDecoration(
                hintText: 'Description (optional)',
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
          label: 'Create',
          variant: GlassButtonVariant.primary,
          isFullWidth: false,
          onPressed: () async {
            final name = nameController.text.trim();
            if (name.isEmpty) return;

            final supabase = ref.read(supabaseDatasourceProvider);
            final userId = supabase.userId;
            if (userId == null) return;

            await supabase.createGroup(
              userId,
              name,
              descController.text.trim().isEmpty ? null : descController.text.trim(),
            );
            Analytics.groupCreated();
            if (mounted) {
              Navigator.of(context).pop();
              _loadGroups();
            }
          },
        ),
      ],
    );
  }

  void _showJoinGroupDialog() {
    final codeController = TextEditingController();

    showGlassModal(
      context: context,
      title: 'Join with Code',
      content: GlassCard(
        borderRadius: 12,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextField(
          controller: codeController,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 4,
          ),
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            hintText: 'INVITE CODE',
            hintStyle: TextStyle(color: AppColors.textMuted),
            border: InputBorder.none,
          ),
        ),
      ),
      actions: [
        GlassButton(
          label: 'Cancel',
          variant: GlassButtonVariant.outline,
          isFullWidth: false,
          onPressed: () => Navigator.of(context).pop(),
        ),
        GlassButton(
          label: 'Join',
          variant: GlassButtonVariant.primary,
          isFullWidth: false,
          onPressed: () async {
            final code = codeController.text.trim();
            if (code.isEmpty) return;

            final supabase = ref.read(supabaseDatasourceProvider);
            final userId = supabase.userId;
            if (userId == null) return;

            final group = await supabase.joinGroup(userId, code);
            if (mounted) {
              Navigator.of(context).pop();
              if (group != null) {
                Analytics.groupJoined();
                _loadGroups();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid invite code'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final supabase = ref.read(supabaseDatasourceProvider);
    final isLoggedIn = supabase.userId != null;

    return ScreenScaffold(
      title: 'My Groups',
      onBack: () => context.go('/profile'),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 16),

            if (!isLoggedIn)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.textMuted,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Sign in to join groups',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                      GlassButton(
                        label: 'Sign In',
                        variant: GlassButtonVariant.primary,
                        isFullWidth: false,
                        onPressed: () => context.go('/welcome'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_loading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else ...[
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: GlassButton(
                      label: 'Create Group',
                      variant: GlassButtonVariant.primary,
                      icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                      onPressed: _showCreateGroupDialog,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassButton(
                      label: 'Join with Code',
                      variant: GlassButtonVariant.outline,
                      icon: const Icon(Icons.vpn_key_rounded, color: AppColors.textSecondary, size: 20),
                      onPressed: _showJoinGroupDialog,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Expanded(
                child: _groups == null || _groups!.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.group_outlined,
                              color: AppColors.textMuted,
                              size: 64,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No groups yet',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Create a group or join with an invite code',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _groups!.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final group = _groups![index];
                          return GlassCard(
                            borderRadius: 16,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            onTap: () {
                              ref.read(currentGroupProvider.notifier).state = group;
                              context.go('/leaderboard/${group.id}');
                            },
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                  ),
                                  child: const Icon(
                                    Icons.group_rounded,
                                    color: AppColors.primaryLight,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        group.name,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (group.description != null &&
                                          group.description!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          group.description!,
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textMuted,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
