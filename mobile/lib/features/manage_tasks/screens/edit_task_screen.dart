import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_modal.dart';
import '../../../core/widgets/screen_scaffold.dart';

class EditTaskScreen extends ConsumerStatefulWidget {
  final String taskId;

  const EditTaskScreen({super.key, required this.taskId});

  @override
  ConsumerState<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends ConsumerState<EditTaskScreen> {
  TextEditingController? _nameController;
  TextEditingController? _descriptionController;
  String? _selectedType;
  int? _selectedTime;
  String? _selectedSocial;
  String? _selectedEnergy;
  String? _dueDate;
  String _recurring = 'none';
  bool _initialized = false;
  bool _taskNotFound = false;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  @override
  void dispose() {
    _nameController?.dispose();
    _descriptionController?.dispose();
    super.dispose();
  }

  void _loadTask() {
    final hive = ref.read(hiveDatasourceProvider);
    final task = hive.getTask(widget.taskId);

    if (task == null) {
      _taskNotFound = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/manage');
      });
      return;
    }

    _nameController = TextEditingController(text: task.name);
    _descriptionController = TextEditingController(text: task.description ?? '');
    _selectedType = task.type;
    _selectedTime = task.time;
    _selectedSocial = task.social;
    _selectedEnergy = task.energy;
    _dueDate = task.dueDate;
    _recurring = task.recurring;
    _initialized = true;
  }

  void _saveChanges() {
    final name = _nameController?.text.trim() ?? '';
    if (name.isEmpty) return;

    final taskRepo = ref.read(taskRepositoryProvider);
    taskRepo.updateTask(widget.taskId, {
      'name': name,
      'description': (_descriptionController?.text.trim().isEmpty ?? true)
          ? null
          : _descriptionController!.text.trim(),
      'type': _selectedType,
      'time': _selectedTime,
      'social': _selectedSocial,
      'energy': _selectedEnergy,
      'dueDate': _dueDate,
      'recurring': _recurring,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task updated!'),
        backgroundColor: AppColors.success,
      ),
    );
    context.go('/manage');
  }

  void _deleteTask() {
    showGlassModal(
      context: context,
      title: 'Delete Task?',
      content: const Text(
        'This action cannot be undone.',
        style: TextStyle(
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
            final taskRepo = ref.read(taskRepositoryProvider);
            taskRepo.deleteTask(widget.taskId);
            Navigator.of(context).pop();
            context.go('/manage');
          },
        ),
      ],
    );
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate != null ? DateTime.parse(_dueDate!) : now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
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
      setState(() {
        _dueDate = picked.toIso8601String().split('T')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_taskNotFound) {
      return ScreenScaffold(
        title: 'Edit Task',
        onBack: () => context.go('/manage'),
        body: const Center(
          child: Text(
            'Task not found. It may have been deleted.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ),
      );
    }

    if (!_initialized) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final taskRepo = ref.read(taskRepositoryProvider);
    final types = taskRepo.getTaskTypes();

    return ScreenScaffold(
      title: 'Edit Task',
      onBack: () => context.go('/manage'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Name
            const Text(
              'Name',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            GlassCard(
              borderRadius: 12,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _nameController!,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Task name',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Description
            const Text(
              'Description (optional)',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            GlassCard(
              borderRadius: 12,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _descriptionController!,
                maxLines: 3,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'Add a description...',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Type
            const Text(
              'Type',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: types.map((type) {
                final isSelected = _selectedType == type;
                final color = AppColors.getTypeColor(type);
                return GlassCard(
                  borderRadius: 12,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  color: isSelected ? color : null,
                  borderOpacity: isSelected ? 0.5 : 0.15,
                  onTap: () => setState(() => _selectedType = type),
                  child: Text(
                    type,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Time
            const Text(
              'Time',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [5, 15, 30, 60].map((minutes) {
                final isSelected = _selectedTime == minutes;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GlassCard(
                      borderRadius: 12,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      color: isSelected ? AppColors.primary : null,
                      borderOpacity: isSelected ? 0.5 : 0.15,
                      onTap: () => setState(() => _selectedTime = minutes),
                      child: Center(
                        child: Text(
                          '$minutes min',
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Social
            const Text(
              'Social',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: ['low', 'medium', 'high'].map((level) {
                final isSelected = _selectedSocial == level;
                final label = level[0].toUpperCase() + level.substring(1);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GlassCard(
                      borderRadius: 12,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      color: isSelected ? AppColors.primary : null,
                      borderOpacity: isSelected ? 0.5 : 0.15,
                      onTap: () => setState(() => _selectedSocial = level),
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Energy
            const Text(
              'Energy',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: ['low', 'medium', 'high'].map((level) {
                final isSelected = _selectedEnergy == level;
                final label = level[0].toUpperCase() + level.substring(1);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GlassCard(
                      borderRadius: 12,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      color: isSelected ? AppColors.primary : null,
                      borderOpacity: isSelected ? 0.5 : 0.15,
                      onTap: () => setState(() => _selectedEnergy = level),
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Due date
            const Text(
              'Due Date',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              borderRadius: 12,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              onTap: _pickDueDate,
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, color: AppColors.textSecondary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    _dueDate ?? 'No due date',
                    style: TextStyle(
                      color: _dueDate != null ? AppColors.textPrimary : AppColors.textMuted,
                      fontSize: 15,
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

            const SizedBox(height: 20),

            // Recurring
            const Text(
              'Recurring',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: ['none', 'daily', 'weekly', 'monthly'].map((option) {
                final isSelected = _recurring == option;
                final label = option[0].toUpperCase() + option.substring(1);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GlassCard(
                      borderRadius: 12,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      color: isSelected ? AppColors.primary : null,
                      borderOpacity: isSelected ? 0.5 : 0.15,
                      onTap: () => setState(() => _recurring = option),
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            GlassButton(
              label: 'Save Changes',
              variant: GlassButtonVariant.primary,
              isLarge: true,
              onPressed: _saveChanges,
            ),
            const SizedBox(height: 12),
            GlassButton(
              label: 'Delete Task',
              variant: GlassButtonVariant.danger,
              onPressed: _deleteTask,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
