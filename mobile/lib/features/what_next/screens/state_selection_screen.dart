import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/screen_scaffold.dart';
import '../../../core/utils/analytics.dart';

class StateSelectionScreen extends ConsumerStatefulWidget {
  const StateSelectionScreen({super.key});

  @override
  ConsumerState<StateSelectionScreen> createState() => _StateSelectionScreenState();
}

class _StateSelectionScreenState extends ConsumerState<StateSelectionScreen> {
  String? _energy;
  String? _social;
  int? _time;

  @override
  void initState() {
    super.initState();
    final state = ref.read(currentStateProvider);
    _energy = state['energy'] as String?;
    _social = state['social'] as String?;
    _time = state['time'] as int?;
  }

  bool get _hasAnySelection => _energy != null || _social != null || _time != null;

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'How are you feeling?',
      onBack: () => context.pop(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            // Energy level
            const Text(
              'Energy level',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildToggleOption('Low', _energy == 'low', () {
                  setState(() => _energy = _energy == 'low' ? null : 'low');
                }),
                const SizedBox(width: 8),
                _buildToggleOption('Medium', _energy == 'medium', () {
                  setState(() => _energy = _energy == 'medium' ? null : 'medium');
                }),
                const SizedBox(width: 8),
                _buildToggleOption('High', _energy == 'high', () {
                  setState(() => _energy = _energy == 'high' ? null : 'high');
                }),
              ],
            ),

            const SizedBox(height: 24),

            // Social battery
            const Text(
              'Social battery',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildToggleOption('Low', _social == 'low', () {
                  setState(() => _social = _social == 'low' ? null : 'low');
                }),
                const SizedBox(width: 8),
                _buildToggleOption('Medium', _social == 'medium', () {
                  setState(() => _social = _social == 'medium' ? null : 'medium');
                }),
                const SizedBox(width: 8),
                _buildToggleOption('High', _social == 'high', () {
                  setState(() => _social = _social == 'high' ? null : 'high');
                }),
              ],
            ),

            const SizedBox(height: 24),

            // Time available
            const Text(
              'Time available',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildToggleOption('5 min', _time == 5, () {
                  setState(() => _time = _time == 5 ? null : 5);
                }),
                const SizedBox(width: 8),
                _buildToggleOption('15 min', _time == 15, () {
                  setState(() => _time = _time == 15 ? null : 15);
                }),
                const SizedBox(width: 8),
                _buildToggleOption('30 min', _time == 30, () {
                  setState(() => _time = _time == 30 ? null : 30);
                }),
                const SizedBox(width: 8),
                _buildToggleOption('1 hr+', _time == 60, () {
                  setState(() => _time = _time == 60 ? null : 60);
                }),
              ],
            ),

            const Spacer(),

            // Find me a task button
            GlassButton(
              label: 'Find Me a Task',
              variant: GlassButtonVariant.primary,
              isLarge: true,
              icon: const Icon(Icons.search_rounded, color: Colors.white, size: 22),
              onPressed: _hasAnySelection ? _findTasks : null,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleOption(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GlassOptionCard(
        label: label,
        isSelected: isSelected,
        onTap: onTap,
      ),
    );
  }

  void _findTasks() {
    final taskRepo = ref.read(taskRepositoryProvider);

    // Update state provider
    ref.read(currentStateProvider.notifier).state = {
      'energy': _energy,
      'social': _social,
      'time': _time,
    };

    // Find matching tasks
    var tasks = taskRepo.findMatchingTasks(
      energy: _energy,
      social: _social,
      time: _time,
    );

    // Fall back to fallback tasks if none found
    if (tasks.isEmpty) {
      tasks = taskRepo.getFallbackTasks(
        energy: _energy,
        social: _social,
        time: _time,
      );
    }

    ref.read(matchingTasksProvider.notifier).state = tasks;
    ref.read(currentCardIndexProvider.notifier).state = 0;

    Analytics.swipeSessionStarted(tasks.length);

    context.push('/swipe');
  }
}
