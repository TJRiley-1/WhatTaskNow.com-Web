import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/points_calculator.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/screen_scaffold.dart';
import '../../../data/models/task.dart';

class AcceptedScreen extends ConsumerWidget {
  const AcceptedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = ref.watch(acceptedTaskProvider) as Task?;

    if (task == null) {
      // Safety fallback
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/home');
      });
      return const SizedBox.shrink();
    }

    return ScreenScaffold(
      title: '',
      onBack: () => context.pop(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 32),

            // Checkmark icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withValues(alpha: 0.15),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.success,
                size: 44,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Let\'s do it!',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 24),

            // Task details card
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.getTypeColor(task.type).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      task.type,
                      style: TextStyle(
                        color: AppColors.getTypeColor(task.type),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    task.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  if (task.description != null && task.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      task.description!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Task meta
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildMeta(Icons.timer_rounded, '${task.time} min'),
                      const SizedBox(width: 16),
                      _buildMeta(Icons.bolt_rounded, task.energy),
                      const SizedBox(width: 16),
                      _buildMeta(Icons.people_rounded, task.social),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Start Timer
            GlassButton(
              label: 'Start Timer',
              variant: GlassButtonVariant.primary,
              isLarge: true,
              icon: const Icon(Icons.timer_rounded, color: Colors.white, size: 22),
              onPressed: () {
                ref.read(timerSecondsProvider.notifier).state = 0;
                ref.read(timerRunningProvider.notifier).state = false;
                context.push('/timer');
              },
            ),
            const SizedBox(height: 12),

            // Mark as Done
            GlassButton(
              label: 'Mark as Done',
              variant: GlassButtonVariant.secondary,
              isLarge: true,
              icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
              onPressed: () => _completeTask(context, ref, task),
            ),
            const SizedBox(height: 12),

            // Not now
            GlassButton(
              label: 'Not now',
              variant: GlassButtonVariant.outline,
              onPressed: () {
                ref.read(taskRepositoryProvider).skipTask(task);
                ref.read(currentCardIndexProvider.notifier).state++;
                context.pop();
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMeta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.textMuted, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  void _completeTask(BuildContext context, WidgetRef ref, Task task) {
    final taskRepo = ref.read(taskRepositoryProvider);
    final statsBefore = taskRepo.getStats();
    final previousRank = getRank(statsBefore.totalPoints);

    ref.read(previousRankProvider.notifier).state = previousRank.name;

    final completed = taskRepo.completeTask(task);
    ref.read(lastPointsEarnedProvider.notifier).state = completed.points;

    context.go('/celebration');
  }
}
