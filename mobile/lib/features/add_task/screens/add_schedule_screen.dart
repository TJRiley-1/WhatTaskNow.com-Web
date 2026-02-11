import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/screen_scaffold.dart';
import '../../../core/utils/analytics.dart';

class AddScheduleScreen extends ConsumerStatefulWidget {
  const AddScheduleScreen({super.key});

  @override
  ConsumerState<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends ConsumerState<AddScheduleScreen> {
  DateTime? _dueDate;
  String _recurring = 'none';
  bool _isSaving = false;

  static const _recurringOptions = [
    {'label': 'None', 'value': 'none'},
    {'label': 'Daily', 'value': 'daily'},
    {'label': 'Weekly', 'value': 'weekly'},
    {'label': 'Monthly', 'value': 'monthly'},
  ];

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'When is it due?',
      stepIndicator: '6 of 6',
      onBack: () => context.pop(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            // Due date picker
            const Text(
              'Due date (optional)',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            GlassCard(
              borderRadius: 14,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppColors.primary,
                          surface: AppColors.surfaceDark,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() => _dueDate = picked);
                }
              },
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, color: AppColors.primaryLight, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    _dueDate != null
                        ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                        : 'Select a date',
                    style: TextStyle(
                      color: _dueDate != null ? AppColors.textPrimary : AppColors.textMuted,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  if (_dueDate != null)
                    GestureDetector(
                      onTap: () => setState(() => _dueDate = null),
                      child: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Recurring options
            const Text(
              'Recurring',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: _recurringOptions.map((option) {
                final isSelected = _recurring == option['value'];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GlassOptionCard(
                      label: option['label'] as String,
                      isSelected: isSelected,
                      onTap: () => setState(() => _recurring = option['value'] as String),
                    ),
                  ),
                );
              }).toList(),
            ),

            const Spacer(),

            // Save button
            GlassButton(
              label: 'Save Task',
              variant: GlassButtonVariant.primary,
              isLarge: true,
              isLoading: _isSaving,
              icon: const Icon(Icons.check_rounded, color: Colors.white, size: 22),
              onPressed: _isSaving ? null : () => _saveTask(withSchedule: true),
            ),
            const SizedBox(height: 12),

            // Skip for now
            Center(
              child: TextButton(
                onPressed: _isSaving ? null : () => _saveTask(withSchedule: false),
                child: const Text(
                  'Skip for now',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _saveTask({required bool withSchedule}) {
    final taskRepo = ref.read(taskRepositoryProvider);

    // Check free task limit
    if (!taskRepo.canAddTask) {
      context.push('/subscription');
      return;
    }

    setState(() => _isSaving = true);

    final newTask = ref.read(newTaskProvider);

    final task = taskRepo.addTask(
      name: newTask['name'] as String,
      description: newTask['description'] as String?,
      type: newTask['type'] as String,
      time: newTask['time'] as int,
      social: newTask['social'] as String,
      energy: newTask['energy'] as String,
      dueDate: withSchedule && _dueDate != null
          ? _dueDate!.toIso8601String().split('T')[0]
          : null,
      recurring: withSchedule ? _recurring : 'none',
    );

    Analytics.taskCreated(task.type, task.time);

    // Save as template if requested
    if (newTask['saveAsTemplate'] == true) {
      taskRepo.createTemplate(
        name: task.name,
        description: task.description,
        type: task.type,
        time: task.time,
        social: task.social,
        energy: task.energy,
      );
    }

    // Reset wizard state
    ref.read(newTaskProvider.notifier).state = {};

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Task saved!'),
          backgroundColor: AppColors.success.withValues(alpha: 0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      context.go('/home');
    }
  }
}
