import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/screen_scaffold.dart';

class MultiTypeScreen extends ConsumerWidget {
  const MultiTypeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskRepo = ref.read(taskRepositoryProvider);
    final types = taskRepo.getTaskTypes();

    return ScreenScaffold(
      title: 'Add Multiple Tasks',
      stepIndicator: '1 of 5',
      onBack: () => context.go('/home'),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Add up to 5 tasks that share the same settings',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'What type of tasks?',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.5,
                ),
                itemCount: types.length,
                itemBuilder: (context, index) {
                  final type = types[index];
                  final color = AppColors.getTypeColor(type);
                  return GlassCard(
                    borderRadius: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: color,
                    onTap: () {
                      ref.read(multiAddTaskProvider.notifier).state = {
                        ...ref.read(multiAddTaskProvider),
                        'type': type,
                      };
                      context.go('/multi-time');
                    },
                    child: Center(
                      child: Text(
                        type,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
