import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/points_calculator.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/screen_scaffold.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskRepo = ref.read(taskRepositoryProvider);
    final tasks = taskRepo.getTasks();
    final completed = taskRepo.getCompletedTasks();

    // Tasks with due dates, sorted by due date
    final upcoming = tasks
        .where((t) => t.dueDate != null)
        .toList()
      ..sort((a, b) {
        final dateA = DateTime.parse(a.dueDate!);
        final dateB = DateTime.parse(b.dueDate!);
        return dateA.compareTo(dateB);
      });

    // Last 10 completed tasks
    final recent = completed.toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    final recentCompleted = recent.take(10).toList();

    return ScreenScaffold(
      title: 'Calendar',
      onBack: () => context.go('/home'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Upcoming Tasks
            const Text(
              'Upcoming Tasks',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            if (upcoming.isEmpty)
              _buildEmptyState('No upcoming tasks with due dates')
            else
              ...upcoming.map((task) {
                final daysUntil = getDaysUntilDue(task);
                final overdue = isOverdue(task);
                final typeColor = AppColors.getTypeColor(task.type);

                String dueDateLabel;
                Color dueDateColor;
                if (overdue) {
                  dueDateLabel = 'Overdue by ${daysUntil!.abs()} day${daysUntil.abs() == 1 ? '' : 's'}';
                  dueDateColor = AppColors.error;
                } else if (daysUntil == 0) {
                  dueDateLabel = 'Due today';
                  dueDateColor = AppColors.warning;
                } else if (daysUntil == 1) {
                  dueDateLabel = 'Due tomorrow';
                  dueDateColor = AppColors.warning;
                } else {
                  dueDateLabel = 'Due in $daysUntil days';
                  dueDateColor = AppColors.textSecondary;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    borderRadius: 14,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 40,
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
                              const SizedBox(height: 4),
                              Text(
                                dueDateLabel,
                                style: TextStyle(
                                  color: dueDateColor,
                                  fontSize: 13,
                                  fontWeight: overdue ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          task.dueDate!.split('T')[0],
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 28),

            // Recently Completed
            const Text(
              'Recently Completed',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            if (recentCompleted.isEmpty)
              _buildEmptyState('No completed tasks yet')
            else
              ...recentCompleted.map((task) {
                final typeColor = AppColors.getTypeColor(task.type);
                final completedDate = DateTime.parse(task.completedAt);
                final formattedDate =
                    '${completedDate.day}/${completedDate.month}/${completedDate.year}';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    borderRadius: 14,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success.withValues(alpha: 0.8),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            task.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '+${task.points} pts',
                              style: TextStyle(
                                color: AppColors.secondary.withValues(alpha: 0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
