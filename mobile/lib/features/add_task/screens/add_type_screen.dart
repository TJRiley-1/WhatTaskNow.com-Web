import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/screen_scaffold.dart';

class AddTypeScreen extends ConsumerStatefulWidget {
  const AddTypeScreen({super.key});

  @override
  ConsumerState<AddTypeScreen> createState() => _AddTypeScreenState();
}

class _AddTypeScreenState extends ConsumerState<AddTypeScreen> {
  static const _defaultTypes = [
    'Chores', 'Work', 'Health', 'Admin',
    'Errand', 'Self-care', 'Creative', 'Social',
  ];

  @override
  Widget build(BuildContext context) {
    final taskRepo = ref.read(taskRepositoryProvider);
    final types = taskRepo.getTaskTypes();

    return ScreenScaffold(
      title: 'What type of task?',
      stepIndicator: '1 of 6',
      onBack: () => context.go('/home'),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Quick action row
            Row(
              children: [
                Expanded(
                  child: GlassButton(
                    label: 'Saved Tasks',
                    variant: GlassButtonVariant.outline,
                    icon: const Icon(Icons.bookmark_rounded, color: AppColors.textSecondary, size: 18),
                    onPressed: () => context.push('/templates'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GlassButton(
                    label: 'Multiple',
                    variant: GlassButtonVariant.outline,
                    icon: const Icon(Icons.playlist_add_rounded, color: AppColors.textSecondary, size: 18),
                    onPressed: () => context.push('/multi-type'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GlassButton(
                    label: 'Import',
                    variant: GlassButtonVariant.outline,
                    icon: const Icon(Icons.file_upload_rounded, color: AppColors.textSecondary, size: 18),
                    onPressed: () => context.push('/import'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Task type grid
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.4,
                ),
                itemCount: types.length + 1, // +1 for "Add Custom Type"
                itemBuilder: (context, index) {
                  if (index == types.length) {
                    return GlassCard(
                      borderRadius: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      borderOpacity: 0.15,
                      onTap: () => _showAddTypeDialog(context, ref),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded, color: AppColors.textSecondary, size: 20),
                          SizedBox(width: 6),
                          Text(
                            'Add Custom Type',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final type = types[index];
                  final typeColor = AppColors.getTypeColor(type);
                  final isCustom = !_defaultTypes.contains(type);

                  return GestureDetector(
                    onLongPress: isCustom
                        ? () => _showDeleteTypeDialog(context, ref, type)
                        : null,
                    child: GlassCard(
                      borderRadius: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      color: typeColor,
                      borderOpacity: 0.25,
                      onTap: () {
                        final newTask = Map<String, dynamic>.from(
                          ref.read(newTaskProvider),
                        );
                        newTask['type'] = type;
                        ref.read(newTaskProvider.notifier).state = newTask;
                        context.push('/add-time');
                      },
                      child: Center(
                        child: Text(
                          type,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
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

  void _showAddTypeDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Add Custom Type',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Type name',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.glassBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(taskRepositoryProvider).addCustomType(name);
                Navigator.of(ctx).pop();
                setState(() {}); // Refresh the grid
              }
            },
            child: const Text('Add', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showDeleteTypeDialog(BuildContext context, WidgetRef ref, String type) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Custom Type?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "$type"?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              ref.read(taskRepositoryProvider).removeCustomType(type);
              Navigator.of(ctx).pop();
              setState(() {}); // Refresh the grid
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
