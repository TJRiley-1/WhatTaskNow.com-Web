import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/points_calculator.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/screen_scaffold.dart';
import '../../../data/models/task.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskRepo = ref.read(taskRepositoryProvider);
    final tasks = taskRepo.getTasks().where((t) => t.dueDate != null).toList();

    // Group tasks by urgency
    final overdue = <Task>[];
    final dueToday = <Task>[];
    final dueTomorrow = <Task>[];
    final upcoming = <Task>[];

    for (final task in tasks) {
      final days = getDaysUntilDue(task);
      if (days == null) continue;

      if (days < 0) {
        overdue.add(task);
      } else if (days == 0) {
        dueToday.add(task);
      } else if (days == 1) {
        dueTomorrow.add(task);
      } else if (days <= 7) {
        upcoming.add(task);
      }
    }

    final hasNotifications =
        overdue.isNotEmpty || dueToday.isNotEmpty || dueTomorrow.isNotEmpty || upcoming.isNotEmpty;

    return ScreenScaffold(
      title: 'Notifications',
      onBack: () => context.go('/home'),
      body: !hasNotifications
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.textMuted,
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  if (overdue.isNotEmpty)
                    _buildSection(
                      title: 'Overdue',
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.error,
                      tasks: overdue,
                    ),

                  if (dueToday.isNotEmpty)
                    _buildSection(
                      title: 'Due Today',
                      icon: Icons.today_rounded,
                      color: AppColors.warning,
                      tasks: dueToday,
                    ),

                  if (dueTomorrow.isNotEmpty)
                    _buildSection(
                      title: 'Due Tomorrow',
                      icon: Icons.event_rounded,
                      color: AppColors.secondary,
                      tasks: dueTomorrow,
                    ),

                  if (upcoming.isNotEmpty)
                    _buildSection(
                      title: 'Upcoming (Next 7 Days)',
                      icon: Icons.upcoming_rounded,
                      color: AppColors.primaryLight,
                      tasks: upcoming,
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Task> tasks,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${tasks.length}',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...tasks.map((task) {
          final typeColor = AppColors.getTypeColor(task.type);
          final daysUntil = getDaysUntilDue(task);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassCard(
              borderRadius: 14,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 36,
                    decoration: BoxDecoration(
                      color: typeColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                task.type,
                                style: TextStyle(
                                  color: typeColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              task.dueDate!.split('T')[0],
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
                  if (daysUntil != null && daysUntil < 0)
                    Text(
                      '${daysUntil.abs()}d late',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}
