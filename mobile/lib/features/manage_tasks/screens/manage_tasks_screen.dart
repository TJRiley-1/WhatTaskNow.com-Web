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

class ManageTasksScreen extends ConsumerStatefulWidget {
  const ManageTasksScreen({super.key});

  @override
  ConsumerState<ManageTasksScreen> createState() => _ManageTasksScreenState();
}

class _ManageTasksScreenState extends ConsumerState<ManageTasksScreen> {
  int? _filterTime;
  String? _filterEnergy;
  String? _filterSocial;

  static const _levelMap = {'low': 1, 'medium': 2, 'high': 3};

  List<Task> _applyFilters(List<Task> tasks) {
    var filtered = tasks;
    if (_filterTime != null) {
      filtered = filtered.where((t) => t.time <= _filterTime!).toList();
    }
    if (_filterEnergy != null) {
      filtered = filtered
          .where((t) => (_levelMap[t.energy] ?? 0) <= (_levelMap[_filterEnergy] ?? 3))
          .toList();
    }
    if (_filterSocial != null) {
      filtered = filtered
          .where((t) => (_levelMap[t.social] ?? 0) <= (_levelMap[_filterSocial] ?? 3))
          .toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final taskRepo = ref.read(taskRepositoryProvider);
    final allTasks = taskRepo.getTasks();
    final tasks = _applyFilters(allTasks);

    return ScreenScaffold(
      title: 'Your Tasks',
      onBack: () => context.go('/home'),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Filter row
            Row(
              children: [
                Expanded(
                  child: _buildFilterDropdown(
                    value: _filterTime?.toString(),
                    hint: 'Time',
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Any Time')),
                      DropdownMenuItem(value: '5', child: Text('\u2264 5 min')),
                      DropdownMenuItem(value: '15', child: Text('\u2264 15 min')),
                      DropdownMenuItem(value: '30', child: Text('\u2264 30 min')),
                      DropdownMenuItem(value: '60', child: Text('\u2264 60 min')),
                    ],
                    onChanged: (v) => setState(() => _filterTime = v != null ? int.tryParse(v) : null),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterDropdown(
                    value: _filterEnergy,
                    hint: 'Energy',
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Any Energy')),
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                    ],
                    onChanged: (v) => setState(() => _filterEnergy = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterDropdown(
                    value: _filterSocial,
                    hint: 'Social',
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Any Social')),
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                    ],
                    onChanged: (v) => setState(() => _filterSocial = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Task list
            Expanded(
              child: tasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.inbox_rounded,
                            color: AppColors.textMuted,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            allTasks.isEmpty
                                ? 'No tasks yet. Add some!'
                                : 'No tasks match your filters.',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(top: 8, bottom: 24),
                      itemCount: tasks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        final typeColor = AppColors.getTypeColor(task.type);
                        final daysUntil = getDaysUntilDue(task);
                        final overdue = isOverdue(task);

                        return GlassCard(
                          borderRadius: 16,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          onTap: () => context.go('/edit-task/${task.id}'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
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
                                    child: Text(
                                      task.name,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  GlassButton(
                                    label: 'Start',
                                    isSmall: true,
                                    isFullWidth: false,
                                    onPressed: () {
                                      ref.read(acceptedTaskProvider.notifier).state = task;
                                      context.push('/accepted');
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  _buildBadge(task.type, typeColor),
                                  _buildBadge('${task.time} min', AppColors.textMuted),
                                  _buildBadge(
                                    'Energy: ${task.energy}',
                                    AppColors.textMuted,
                                  ),
                                  _buildBadge(
                                    'Social: ${task.social}',
                                    AppColors.textMuted,
                                  ),
                                  if (daysUntil != null)
                                    _buildBadge(
                                      overdue
                                          ? 'Overdue'
                                          : daysUntil == 0
                                              ? 'Due today'
                                              : daysUntil == 1
                                                  ? 'Due tomorrow'
                                                  : 'Due in $daysUntil days',
                                      overdue ? AppColors.error : AppColors.warning,
                                    ),
                                ],
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

  Widget _buildFilterDropdown({
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String?>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: DropdownButton<String?>(
        value: value,
        hint: Text(hint, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        isExpanded: true,
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down, color: AppColors.textMuted, size: 18),
        dropdownColor: AppColors.surfaceDark,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
