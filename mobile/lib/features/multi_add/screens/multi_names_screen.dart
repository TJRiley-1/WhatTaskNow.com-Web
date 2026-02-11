import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/screen_scaffold.dart';

class MultiNamesScreen extends ConsumerStatefulWidget {
  const MultiNamesScreen({super.key});

  @override
  ConsumerState<MultiNamesScreen> createState() => _MultiNamesScreenState();
}

class _MultiNamesScreenState extends ConsumerState<MultiNamesScreen> {
  final _controllers = List.generate(5, (_) => TextEditingController());
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  int get _filledCount => _controllers.where((c) => c.text.trim().isNotEmpty).length;

  Future<void> _saveAll() async {
    if (_filledCount == 0) return;

    setState(() => _saving = true);

    final settings = ref.read(multiAddTaskProvider);
    final taskRepo = ref.read(taskRepositoryProvider);
    int savedCount = 0;

    for (final controller in _controllers) {
      final name = controller.text.trim();
      if (name.isNotEmpty) {
        taskRepo.addTask(
          name: name,
          type: settings['type'] as String? ?? 'Chores',
          time: settings['time'] as int? ?? 15,
          social: settings['social'] as String? ?? 'low',
          energy: settings['energy'] as String? ?? 'low',
        );
        savedCount++;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$savedCount tasks saved!'),
          backgroundColor: AppColors.success,
        ),
      );
      ref.read(multiAddTaskProvider.notifier).state = {};
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Add Multiple Tasks',
      stepIndicator: '5 of 5',
      onBack: () => context.go('/multi-energy'),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Name your tasks',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Leave any blank to skip them',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                itemCount: 5,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return GlassCard(
                    borderRadius: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: TextField(
                      controller: _controllers[index],
                      maxLength: 50,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Task ${index + 1}',
                        hintStyle: const TextStyle(
                          color: AppColors.textMuted,
                        ),
                        border: InputBorder.none,
                        counterStyle: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            GlassButton(
              label: _saving ? 'Saving...' : 'Save All Tasks',
              variant: GlassButtonVariant.primary,
              isLarge: true,
              isLoading: _saving,
              onPressed: _filledCount > 0 ? _saveAll : null,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
