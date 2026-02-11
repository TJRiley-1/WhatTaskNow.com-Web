import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/screen_scaffold.dart';

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  String _getTimeComparison(int totalMinutes) {
    final hours = totalMinutes / 60.0;
    String comparison = '';
    for (final tc in kTimeComparisons) {
      if (hours >= tc.hours) {
        comparison = tc.text;
      }
    }
    return comparison;
  }

  String _getTaskComparison(int count) {
    String comparison = '';
    for (final tc in kTaskComparisons) {
      if (count >= tc.count) {
        comparison = tc.text;
      }
    }
    return comparison;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskRepo = ref.read(taskRepositoryProvider);
    final completed = taskRepo.getCompletedTasks();
    final stats = taskRepo.getStats();

    final totalPoints = stats.totalPoints;
    final totalTime = stats.totalTimeSpent;
    final tasksDone = stats.completed;

    final timeComparison = _getTimeComparison(totalTime);
    final taskComparison = _getTaskComparison(tasksDone);

    return ScreenScaffold(
      title: 'Completed Tasks',
      onBack: () => context.go('/home'),
      body: completed.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    color: AppColors.textMuted,
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No completed tasks yet!',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                // Stats bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: GlassCard(
                      borderRadius: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatColumn(label: 'Tasks Done', value: '$tasksDone'),
                          Container(
                            width: 1,
                            height: 36,
                            color: AppColors.glassBorder,
                          ),
                          _StatColumn(label: 'Points', value: '$totalPoints'),
                          Container(
                            width: 1,
                            height: 36,
                            color: AppColors.glassBorder,
                          ),
                          _StatColumn(
                            label: 'Time Spent',
                            value: totalTime >= 60
                                ? '${(totalTime / 60).toStringAsFixed(1)}h'
                                : '${totalTime}m',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Fun comparison text
                if (timeComparison.isNotEmpty || taskComparison.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Text(
                        taskComparison.isNotEmpty
                            ? "That's $taskComparison!"
                            : "That's $timeComparison!",
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // Sticker-bomb grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final task = completed[index];
                        final typeColor = AppColors.getTypeColor(task.type);
                        // Slight random rotation for sticker-bomb effect
                        final rotation = (Random(task.id.hashCode).nextDouble() - 0.5) * 0.08;

                        return Transform.rotate(
                          angle: rotation,
                          child: GlassCard(
                            borderRadius: 14,
                            padding: const EdgeInsets.all(10),
                            color: typeColor,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  task.name,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '+${task.points}',
                                    style: const TextStyle(
                                      color: AppColors.secondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: completed.length,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
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
