import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/points_calculator.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/utils/analytics.dart';

class CelebrationScreen extends ConsumerStatefulWidget {
  const CelebrationScreen({super.key});

  @override
  ConsumerState<CelebrationScreen> createState() => _CelebrationScreenState();
}

class _CelebrationScreenState extends ConsumerState<CelebrationScreen> {
  late ConfettiController _confettiController;
  late String _message;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _message = kCelebrationMessages[Random().nextInt(kCelebrationMessages.length)];

    // Start confetti after a brief delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final points = ref.watch(lastPointsEarnedProvider);
    final prevRankName = ref.watch(previousRankProvider);
    final acceptedTask = ref.read(acceptedTaskProvider);
    final taskRepo = ref.read(taskRepositoryProvider);
    final stats = taskRepo.getStats();
    final currentRank = getRank(stats.totalPoints);
    final didRankUp = prevRankName != null && prevRankName != currentRank.name;

    if (acceptedTask != null) {
      Analytics.taskCompleted(acceptedTask.type, points);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                AppColors.primary,
                AppColors.secondary,
                AppColors.success,
                AppColors.primaryLight,
                AppColors.secondaryLight,
              ],
              numberOfParticles: 30,
              maxBlastForce: 20,
              minBlastForce: 5,
              gravity: 0.2,
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(),

                  // Celebration icon
                  const Text(
                    '\u{1F389}',
                    style: TextStyle(fontSize: 64),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  const Text(
                    'Amazing!',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Points earned
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    color: AppColors.secondary,
                    child: Column(
                      children: [
                        Text(
                          '+$points points',
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total: ${stats.totalPoints} points',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Motivational message
                  Text(
                    _message,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Rank-up badge
                  if (didRankUp) ...[
                    const SizedBox(height: 24),
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      color: AppColors.secondary,
                      child: Column(
                        children: [
                          const Icon(
                            Icons.military_tech_rounded,
                            color: AppColors.secondary,
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Rank Up!',
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$prevRankName  \u{2192}  ${currentRank.name}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Continue button
                  GlassButton(
                    label: 'Continue',
                    variant: GlassButtonVariant.primary,
                    isLarge: true,
                    onPressed: () {
                      // Clean up state
                      ref.read(acceptedTaskProvider.notifier).state = null;
                      ref.read(timerSecondsProvider.notifier).state = 0;
                      ref.read(timerRunningProvider.notifier).state = false;
                      context.go('/home');
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
