import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/points_calculator.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskRepo = ref.read(taskRepositoryProvider);
    final stats = taskRepo.getStats();
    final totalPoints = stats.totalPoints;
    final rank = getRank(totalPoints);
    final nextRank = getNextRank(totalPoints);

    final double progress;
    if (nextRank != null) {
      final currentMin = rank.minPoints;
      final nextMin = nextRank.minPoints;
      progress = (totalPoints - currentMin) / (nextMin - currentMin);
    } else {
      progress = 1.0;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Rank display
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.secondary,
                                AppColors.secondaryLight,
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.military_tech_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rank.name,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                nextRank != null
                                    ? '$totalPoints / ${nextRank.minPoints} points'
                                    : '$totalPoints points - Max rank!',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        backgroundColor: AppColors.glassWhite,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.secondary,
                        ),
                        minHeight: 8,
                      ),
                    ),
                    if (nextRank != null) ...[
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Next: ${nextRank.name}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const Spacer(),

              // Title
              const Text(
                'What Now?',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Stop overthinking. Start doing.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),

              const Spacer(),

              // Action buttons
              GlassButton(
                label: 'Add Task',
                variant: GlassButtonVariant.primary,
                isLarge: true,
                icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                onPressed: () {
                  ref.read(newTaskProvider.notifier).state = {};
                  context.go('/add-type');
                },
              ),
              const SizedBox(height: 12),
              GlassButton(
                label: 'What Next',
                variant: GlassButtonVariant.secondary,
                isLarge: true,
                icon: const Icon(Icons.shuffle_rounded, color: Colors.white, size: 22),
                onPressed: () {
                  ref.read(currentStateProvider.notifier).state = {
                    'energy': null,
                    'social': null,
                    'time': null,
                  };
                  context.push('/state');
                },
              ),
              const SizedBox(height: 20),

              // Manage tasks link
              TextButton(
                onPressed: () => context.go('/manage'),
                child: const Text(
                  'Manage Tasks',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
