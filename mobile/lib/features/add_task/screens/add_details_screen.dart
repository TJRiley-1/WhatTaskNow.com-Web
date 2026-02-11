import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/screen_scaffold.dart';

class AddDetailsScreen extends ConsumerStatefulWidget {
  const AddDetailsScreen({super.key});

  @override
  ConsumerState<AddDetailsScreen> createState() => _AddDetailsScreenState();
}

class _AddDetailsScreenState extends ConsumerState<AddDetailsScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _saveAsTemplate = false;

  @override
  void initState() {
    super.initState();
    final newTask = ref.read(newTaskProvider);
    _nameController.text = (newTask['name'] as String?) ?? '';
    _descriptionController.text = (newTask['description'] as String?) ?? '';
    _saveAsTemplate = (newTask['saveAsTemplate'] as bool?) ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Name your task',
      stepIndicator: '5 of 6',
      onBack: () => context.pop(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            // Task name
            const Text(
              'Task name',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              maxLength: 50,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'What do you need to do?',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                counterStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.glassWhite,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Description
            const Text(
              'Description (optional)',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLength: 150,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Any details to remember?',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                counterStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.glassWhite,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Save as template checkbox
            GestureDetector(
              onTap: () => setState(() => _saveAsTemplate = !_saveAsTemplate),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _saveAsTemplate ? AppColors.primary : AppColors.glassBorder,
                        width: 1.5,
                      ),
                      color: _saveAsTemplate
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : Colors.transparent,
                    ),
                    child: _saveAsTemplate
                        ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 18)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Save as template for reuse',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Next button
            GlassButton(
              label: 'Next',
              variant: GlassButtonVariant.primary,
              isLarge: true,
              onPressed: _nameController.text.trim().isEmpty
                  ? null
                  : () {
                      final newTask = Map<String, dynamic>.from(
                        ref.read(newTaskProvider),
                      );
                      newTask['name'] = _nameController.text.trim();
                      newTask['description'] = _descriptionController.text.trim().isEmpty
                          ? null
                          : _descriptionController.text.trim();
                      newTask['saveAsTemplate'] = _saveAsTemplate;
                      ref.read(newTaskProvider.notifier).state = newTask;
                      context.push('/add-schedule');
                    },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
