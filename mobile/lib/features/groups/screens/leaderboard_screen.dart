import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_modal.dart';
import '../../../core/widgets/screen_scaffold.dart';
import '../../../data/models/group.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  final String groupId;

  const LeaderboardScreen({super.key, required this.groupId});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  List<Map<String, dynamic>>? _leaderboard;
  List<Map<String, dynamic>>? _activity;
  bool _loading = true;
  Group? _group;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final supabase = ref.read(supabaseDatasourceProvider);
    final currentGroup = ref.read(currentGroupProvider);

    if (currentGroup is Group) {
      _group = currentGroup;
    }

    try {
      final leaderboard = await supabase.getLeaderboard(widget.groupId);
      final activity = await supabase.getGroupActivity(widget.groupId);
      if (mounted) {
        setState(() {
          _leaderboard = leaderboard;
          _activity = activity;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _leaderboard = [];
          _activity = [];
          _loading = false;
        });
      }
    }
  }

  void _leaveGroup() {
    showGlassModal(
      context: context,
      title: 'Leave Group?',
      content: const Text(
        'You can rejoin later with the invite code.',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 15,
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
          label: 'Leave',
          variant: GlassButtonVariant.danger,
          isFullWidth: false,
          onPressed: () async {
            final supabase = ref.read(supabaseDatasourceProvider);
            final userId = supabase.userId;
            if (userId != null) {
              await supabase.leaveGroup(userId, widget.groupId);
            }
            if (mounted) {
              Navigator.of(context).pop();
              context.go('/groups');
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Leaderboard',
      onBack: () => context.go('/groups'),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // Period label
                  const Center(
                    child: Text(
                      'This Week',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Ranked list
                  if (_leaderboard != null && _leaderboard!.isNotEmpty)
                    ...List.generate(_leaderboard!.length, (index) {
                      final member = _leaderboard![index];
                      final position = index + 1;
                      final name = member['display_name'] as String? ?? 'User';
                      final rank = member['current_rank'] as String? ?? 'Task Newbie';
                      final weeklyPoints = member['weekly_points'] as int? ?? 0;
                      final weeklyTasks = member['weekly_tasks'] as int? ?? 0;

                      Color positionColor;
                      if (position == 1) {
                        positionColor = AppColors.secondary;
                      } else if (position == 2) {
                        positionColor = AppColors.textSecondary;
                      } else if (position == 3) {
                        positionColor = const Color(0xFFCD7F32);
                      } else {
                        positionColor = AppColors.textMuted;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GlassCard(
                          borderRadius: 14,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          color: position <= 3 ? positionColor : null,
                          borderOpacity: position <= 3 ? 0.3 : 0.15,
                          child: Row(
                            children: [
                              // Position
                              SizedBox(
                                width: 32,
                                child: Text(
                                  '#$position',
                                  style: TextStyle(
                                    color: positionColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Avatar
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                ),
                                child: Center(
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Name and rank
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      rank,
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Weekly stats
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$weeklyPoints pts',
                                    style: const TextStyle(
                                      color: AppColors.secondary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '$weeklyTasks tasks',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    })
                  else
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No members yet',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Activity feed
                  const Text(
                    'Recent Activity',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_activity != null && _activity!.isNotEmpty)
                    ...(_activity!.take(10).map((item) {
                      final memberName = item['display_name'] as String? ?? 'User';
                      final taskName = item['task_name'] as String? ?? 'a task';
                      final points = item['points'] as int? ?? 0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GlassCard(
                          borderRadius: 12,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.success,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: memberName,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const TextSpan(
                                        text: ' completed ',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                      TextSpan(
                                        text: taskName,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Text(
                                '+$points',
                                style: const TextStyle(
                                  color: AppColors.secondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }))
                  else
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'No recent activity',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Invite code
                  if (_group != null)
                    GlassCard(
                      borderRadius: 14,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'Invite Code',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _group!.inviteCode,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 6,
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(
                                  Icons.copy_rounded,
                                  color: AppColors.primaryLight,
                                  size: 22,
                                ),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: _group!.inviteCode));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Invite code copied!'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Leave group
                  Center(
                    child: TextButton(
                      onPressed: _leaveGroup,
                      child: const Text(
                        'Leave Group',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
