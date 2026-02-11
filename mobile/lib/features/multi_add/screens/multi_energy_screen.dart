import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/screen_scaffold.dart';

class MultiEnergyScreen extends ConsumerWidget {
  const MultiEnergyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final energyOptions = [
      {
        'level': 'low',
        'label': 'Low',
        'subtitle': 'Can do from the couch',
        'icon': Icons.battery_1_bar_rounded,
      },
      {
        'level': 'medium',
        'label': 'Medium',
        'subtitle': 'Needs some focus and effort',
        'icon': Icons.battery_4_bar_rounded,
      },
      {
        'level': 'high',
        'label': 'High',
        'subtitle': 'Full energy and concentration',
        'icon': Icons.battery_full_rounded,
      },
    ];

    return ScreenScaffold(
      title: 'Add Multiple Tasks',
      stepIndicator: '4 of 5',
      onBack: () => context.go('/multi-social'),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            const Text(
              'Energy level needed?',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 32),
            ...energyOptions.map((option) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  onTap: () {
                    ref.read(multiAddTaskProvider.notifier).state = {
                      ...ref.read(multiAddTaskProvider),
                      'energy': option['level'],
                    };
                    context.go('/multi-names');
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                        child: Icon(
                          option['icon'] as IconData,
                          color: AppColors.primaryLight,
                          size: 24,
                        ),
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
                                color: AppColors.textMuted,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
