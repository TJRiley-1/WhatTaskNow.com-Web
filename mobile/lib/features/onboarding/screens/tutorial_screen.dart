import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_button.dart';

class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({super.key});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  int _currentStep = 0;
  bool _isReviewMode = false;

  static const _steps = [
    _TutorialStep(
      icon: Icons.add_task_rounded,
      title: 'Add Your Tasks',
      description:
          'Tag each task with how much time it takes (5-60 min), the energy it needs '
          '(low/medium/high), and your social battery level. This helps match tasks to '
          'how you\'re feeling right now.',
      color: AppColors.primary,
    ),
    _TutorialStep(
      icon: Icons.auto_awesome_rounded,
      title: 'Get Smart Suggestions',
      description:
          'Tap "What Next" and tell the app your current energy, social battery, and '
          'available time. Select what fits \u2014 tap again to deselect. The app filters '
          'your tasks to find the best match for right now.',
      color: AppColors.secondary,
    ),
    _TutorialStep(
      icon: Icons.swipe_rounded,
      title: 'Swipe to Decide',
      description:
          'Matching tasks appear as cards. Swipe right to commit, left to skip. '
          'Once accepted, start a timer to stay focused. No more decision paralysis!',
      color: AppColors.swipeAccept,
    ),
    _TutorialStep(
      icon: Icons.emoji_events_rounded,
      title: 'Earn Points & Level Up',
      description:
          'Complete tasks to earn points. Rank up from Task Newbie through Apprentice, '
          'Slayer, Master, Champion, to Legend! Join groups and compete with friends '
          'on weekly leaderboards.',
      color: AppColors.secondaryLight,
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if we arrived from profile (review mode)
    final extra = GoRouterState.of(context).extra;
    if (extra is Map && extra['review'] == true) {
      _isReviewMode = true;
    }
  }

  void _next() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _skip() {
    _finish();
  }

  Future<void> _finish() async {
    if (_isReviewMode) {
      if (mounted) context.pop();
    } else {
      final hive = ref.read(hiveDatasourceProvider);
      await hive.setOnboardingComplete();
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    final isLastStep = _currentStep == _steps.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // Top bar with skip button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _skip,
                  child: Text(
                    _isReviewMode ? 'Close' : 'Skip',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // Step illustration / icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      step.color.withValues(alpha: 0.3),
                      step.color.withValues(alpha: 0.1),
                    ],
                  ),
                  border: Border.all(
                    color: step.color.withValues(alpha: 0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: step.color.withValues(alpha: 0.2),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Icon(step.icon, size: 56, color: step.color),
              ),

              const SizedBox(height: 40),

              // Title
              Text(
                step.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Description
              GlassCard(
                padding: const EdgeInsets.all(24),
                child: Text(
                  step.description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(flex: 3),

              // Progress dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_steps.length, (index) {
                  final isActive = index == _currentStep;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: isActive
                          ? step.color
                          : AppColors.textMuted.withValues(alpha: 0.3),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 32),

              // Navigation buttons
              Row(
                children: [
                  if (_currentStep > 0) ...[
                    Expanded(
                      child: GlassButton(
                        label: 'Back',
                        variant: GlassButtonVariant.outline,
                        onPressed: _back,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: _currentStep > 0 ? 2 : 1,
                    child: GlassButton(
                      label: isLastStep ? 'Get Started' : 'Next',
                      isLarge: true,
                      onPressed: _next,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _TutorialStep {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _TutorialStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
