import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/screen_scaffold.dart';

class ImportSetupScreen extends ConsumerStatefulWidget {
  const ImportSetupScreen({super.key});

  @override
  ConsumerState<ImportSetupScreen> createState() => _ImportSetupScreenState();
}

class _ImportSetupScreenState extends ConsumerState<ImportSetupScreen> {
  String? _selectedType;
  int? _selectedTime;
  String? _selectedSocial;
  String? _selectedEnergy;

  bool get _isComplete =>
      _selectedType != null &&
      _selectedTime != null &&
      _selectedSocial != null &&
      _selectedEnergy != null;

  void _saveTask() {
    if (!_isComplete) return;

    final importTask = ref.read(currentImportTaskProvider);
    if (importTask == null) return;

    final taskRepo = ref.read(taskRepositoryProvider);
    taskRepo.addTask(
      name: importTask['name'] as String,
      type: _selectedType!,
      time: _selectedTime!,
      social: _selectedSocial!,
      energy: _selectedEnergy!,
    );

    // Mark as configured in pending imports
    final pending = ref.read(pendingImportsProvider);
    final updated = pending.map((p) {
      if (p['name'] == importTask['name'] && p['configured'] != true) {
        return {...p, 'configured': true};
      }
      return p;
    }).toList();
    ref.read(pendingImportsProvider.notifier).state = updated;
    ref.read(currentImportTaskProvider.notifier).state = null;

    context.go('/import-review');
  }

  @override
  Widget build(BuildContext context) {
    final importTask = ref.watch(currentImportTaskProvider);
    final taskRepo = ref.read(taskRepositoryProvider);
    final types = taskRepo.getTaskTypes();

    return ScreenScaffold(
      title: 'Setup Task',
      onBack: () => context.go('/import-review'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Task name preview
            GlassCard(
              borderRadius: 16,
              padding: const EdgeInsets.all(16),
              color: AppColors.primary,
              child: Row(
                children: [
                  const Icon(Icons.task_alt_rounded, color: AppColors.primaryLight, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      importTask?['name'] as String? ?? 'Task',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Type selection
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

            const SizedBox(height: 24),

            // Time selection
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

            const SizedBox(height: 24),

            // Social selection
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
              children: [
                {'level': 'low', 'label': 'Low'},
                {'level': 'medium', 'label': 'Med'},
                {'level': 'high', 'label': 'High'},
              ].map((option) {
                final isSelected = _selectedSocial == option['level'];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GlassCard(
                      borderRadius: 12,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      color: isSelected ? AppColors.primary : null,
                      borderOpacity: isSelected ? 0.5 : 0.15,
                      onTap: () => setState(() => _selectedSocial = option['level']),
                      child: Center(
                        child: Text(
                          option['label']!,
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

            const SizedBox(height: 24),

            // Energy selection
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
              children: [
                {'level': 'low', 'label': 'Low'},
                {'level': 'medium', 'label': 'Med'},
                {'level': 'high', 'label': 'High'},
              ].map((option) {
                final isSelected = _selectedEnergy == option['level'];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GlassCard(
                      borderRadius: 12,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      color: isSelected ? AppColors.primary : null,
                      borderOpacity: isSelected ? 0.5 : 0.15,
                      onTap: () => setState(() => _selectedEnergy = option['level']),
                      child: Center(
                        child: Text(
                          option['label']!,
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

            const SizedBox(height: 32),

            GlassButton(
              label: 'Save Task',
              variant: GlassButtonVariant.primary,
              isLarge: true,
              onPressed: _isComplete ? _saveTask : null,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
