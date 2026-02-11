import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_modal.dart';
import '../../../core/widgets/screen_scaffold.dart';

class TemplatesScreen extends ConsumerWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskRepo = ref.read(taskRepositoryProvider);
    final templates = taskRepo.getTemplates();

    return ScreenScaffold(
      title: 'Saved Tasks',
      onBack: () => context.go('/home'),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Pick a template to pre-fill your task',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: templates.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bookmark_border_rounded,
                            color: AppColors.textMuted,
                            size: 64,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No saved templates yet.',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: templates.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final template = templates[index];
                        final typeColor = AppColors.getTypeColor(template.type);

                        return GlassCard(
                          borderRadius: 16,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          onTap: () {
                            ref.read(newTaskProvider.notifier).state = {
                              'name': template.name,
                              'description': template.description,
                              'type': template.type,
                              'time': template.time,
                              'social': template.social,
                              'energy': template.energy,
                            };
                            context.go('/add-time');
                          },
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: typeColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      template.name,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: typeColor.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            template.type,
                                            style: TextStyle(
                                              color: typeColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${template.time} min',
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.error,
                                  size: 22,
                                ),
                                onPressed: () {
                                  showGlassModal(
                                    context: context,
                                    title: 'Delete Template?',
                                    content: Text(
                                      'Remove "${template.name}" from your saved templates?',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 15,
                                      ),
                                    ),
                                    actions: [
                                      GlassButton(
                                        label: 'Cancel',
                                        variant: GlassButtonVariant.outline,
                                        isFullWidth: false,
                                        onPressed: () => Navigator.of(context).pop(),
                                      ),
                                      GlassButton(
                                        label: 'Delete',
                                        variant: GlassButtonVariant.danger,
                                        isFullWidth: false,
                                        onPressed: () {
                                          taskRepo.deleteTemplate(template.id);
                                          Navigator.of(context).pop();
                                          (context as Element).markNeedsBuild();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
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
