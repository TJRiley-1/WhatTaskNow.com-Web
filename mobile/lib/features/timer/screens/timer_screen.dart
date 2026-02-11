import 'dart:async';
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

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _seconds = ref.read(timerSecondsProvider);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _isRunning = true);
    ref.read(timerRunningProvider.notifier).state = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds++);
      ref.read(timerSecondsProvider.notifier).state = _seconds;
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
    ref.read(timerRunningProvider.notifier).state = false;
  }

  void _toggleTimer() {
    if (_isRunning) {
      _pauseTimer();
    } else {
      _startTimer();
    }
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final task = ref.watch(acceptedTaskProvider) as Task?;

    if (task == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/home');
      });
      return const SizedBox.shrink();
    }

    return ScreenScaffold(
      title: '',
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 32),

            // Task name
            Text(
              task.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              task.type,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),

            const Spacer(),

            // Timer display
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
              child: Column(
                children: [
                  Text(
                    _formatTime(_seconds),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 72,
                      fontWeight: FontWeight.w300,
                      fontFeatures: [FontFeature.tabularFigures()],
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isRunning ? 'Running' : 'Paused',
                    style: TextStyle(
                      color: _isRunning ? AppColors.success : AppColors.textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Pause/Resume button
            GlassButton(
              label: _isRunning ? 'Pause' : 'Resume',
              variant: GlassButtonVariant.secondary,
              isLarge: true,
              icon: Icon(
                _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 24,
              ),
              onPressed: _toggleTimer,
            ),
            const SizedBox(height: 12),

            // Done button
            GlassButton(
              label: 'Done!',
              variant: GlassButtonVariant.primary,
              isLarge: true,
              icon: const Icon(Icons.check_rounded, color: Colors.white, size: 22),
              onPressed: () => _completeTask(task),
            ),
            const SizedBox(height: 16),

            // Cancel
            TextButton(
              onPressed: () {
                _pauseTimer();
                context.pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _completeTask(Task task) {
    _pauseTimer();

    final taskRepo = ref.read(taskRepositoryProvider);
    final statsBefore = taskRepo.getStats();
    final previousRank = getRank(statsBefore.totalPoints);

    ref.read(previousRankProvider.notifier).state = previousRank.name;

    final timeSpentMinutes = (_seconds / 60).ceil();
    final completed = taskRepo.completeTask(task, timeSpentMinutes: timeSpentMinutes);
    ref.read(lastPointsEarnedProvider.notifier).state = completed.points;

    context.go('/celebration');
  }
}
