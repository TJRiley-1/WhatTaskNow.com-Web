import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/screen_scaffold.dart';

class AddEnergyScreen extends ConsumerWidget {
  const AddEnergyScreen({super.key});

  static const _energyOptions = [
    {
      'label': 'Low',
      'subtitle': 'Can do while tired',
      'value': 'low',
      'icon': Icons.battery_2_bar_rounded,
    },
    {
      'label': 'Medium',
      'subtitle': 'Need some focus',
      'value': 'medium',
      'icon': Icons.battery_4_bar_rounded,
    },
    {
      'label': 'High',
      'subtitle': 'Need full power',
      'value': 'high',
      'icon': Icons.battery_full_rounded,
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScreenScaffold(
      title: 'Energy level needed?',
      stepIndicator: '4 of 6',
      onBack: () => context.pop(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            ..._energyOptions.map((option) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                borderRadius: 16,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                onTap: () {
                  final newTask = Map<String, dynamic>.from(
                    ref.read(newTaskProvider),
                  );
                  newTask['energy'] = option['value'];
                  ref.read(newTaskProvider.notifier).state = newTask;
                  context.push('/add-details');
                },
                child: Row(
                  children: [
                    Icon(
                      option['icon'] as IconData,
                      color: AppColors.primaryLight,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option['label'] as String,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            option['subtitle'] as String,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
