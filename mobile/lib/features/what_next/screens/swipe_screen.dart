import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/screen_scaffold.dart';
import '../../../data/models/task.dart';
import '../../../core/utils/analytics.dart';

class SwipeScreen extends ConsumerStatefulWidget {
  const SwipeScreen({super.key});

  @override
  ConsumerState<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends ConsumerState<SwipeScreen> {
  double _dragOffset = 0;
  static const _swipeThreshold = 100.0;

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(matchingTasksProvider) as List<dynamic>;
    final currentIndex = ref.watch(currentCardIndexProvider);

    final bool outOfCards = currentIndex >= tasks.length;

    return ScreenScaffold(
      title: 'Swipe to decide',
      onBack: () => context.pop(),
      body: outOfCards ? _buildEmptyState() : _buildSwipeArea(tasks, currentIndex),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inbox_rounded,
              color: AppColors.textMuted,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'No more tasks!',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You\'ve gone through all matching tasks.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            GlassButton(
              label: 'Back to Home',
              variant: GlassButtonVariant.primary,
              onPressed: () => context.go('/home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeArea(List<dynamic> tasks, int currentIndex) {
    final task = tasks[currentIndex] as Task;
    final screenWidth = MediaQuery.of(context).size.width;
    final progress = (_dragOffset / _swipeThreshold).clamp(-1.0, 1.0);
    final rotation = progress * 0.1;

    // Tint colors based on direction
    Color? tintColor;
    if (progress > 0.2) {
      tintColor = AppColors.swipeAccept.withValues(alpha: progress * 0.3);
    } else if (progress < -0.2) {
      tintColor = AppColors.swipeSkip.withValues(alpha: progress.abs() * 0.3);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Card counter
          Text(
            '${currentIndex + 1} of ${tasks.length}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 16),

          // Swipe labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedOpacity(
                opacity: progress < -0.2 ? 1.0 : 0.3,
                duration: const Duration(milliseconds: 100),
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: AppColors.swipeSkip,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              AnimatedOpacity(
                opacity: progress > 0.2 ? 1.0 : 0.3,
                duration: const Duration(milliseconds: 100),
                child: const Text(
                  'Do it',
                  style: TextStyle(
                    color: AppColors.swipeAccept,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Swipeable card
          Expanded(
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() => _dragOffset += details.delta.dx);
              },
              onHorizontalDragEnd: (details) {
                if (_dragOffset.abs() >= _swipeThreshold) {
                  if (_dragOffset > 0) {
                    _acceptTask(task);
                  } else {
                    _skipTask(task);
                  }
                }
                setState(() => _dragOffset = 0);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 50),
                transform: Matrix4.identity()
                  ..translate(_dragOffset, 0)
                  ..rotateZ(rotation),
                transformAlignment: Alignment.center,
                child: Stack(
                  children: [
                    GlassCard(
                      padding: const EdgeInsets.all(24),
                      color: tintColor,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Task type badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.getTypeColor(task.type).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.getTypeColor(task.type).withValues(alpha: 0.4),
                              ),
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
                          const SizedBox(height: 20),

                          // Task name
                          Text(
                            task.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 24,
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
                                fontSize: 15,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Task details row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildDetail(Icons.timer_rounded, '${task.time} min'),
                              const SizedBox(width: 20),
                              _buildDetail(Icons.bolt_rounded, task.energy),
                              const SizedBox(width: 20),
                              _buildDetail(Icons.people_rounded, task.social),
                            ],
                          ),

                          if (task.isFallback) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Suggested task',
                                style: TextStyle(
                                  color: AppColors.secondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Bottom swipe hint
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.arrow_back_rounded, color: AppColors.swipeSkip, size: 18),
                  const SizedBox(width: 4),
                  const Text(
                    'Skip',
                    style: TextStyle(color: AppColors.swipeSkip, fontSize: 14),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text(
                    'Do it',
                    style: TextStyle(color: AppColors.swipeAccept, fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded, color: AppColors.swipeAccept, size: 18),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDetail(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.textMuted, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  void _acceptTask(Task task) {
    ref.read(taskRepositoryProvider).markTaskShown(task);
    ref.read(acceptedTaskProvider.notifier).state = task;
    context.push('/accepted');
  }

  void _skipTask(Task task) {
    Analytics.taskSkipped(task.type);
    ref.read(taskRepositoryProvider).skipTask(task);
    ref.read(currentCardIndexProvider.notifier).state++;
  }
}
