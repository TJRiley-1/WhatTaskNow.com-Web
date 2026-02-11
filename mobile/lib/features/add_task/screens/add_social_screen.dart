import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/screen_scaffold.dart';

class AddSocialScreen extends ConsumerWidget {
  const AddSocialScreen({super.key});

  static const _socialOptions = [
    {
      'label': 'Low',
      'subtitle': 'Solo - no interaction needed',
      'value': 'low',
      'icon': Icons.person_rounded,
    },
    {
      'label': 'Medium',
      'subtitle': 'Some interaction required',
      'value': 'medium',
      'icon': Icons.people_rounded,
    },
    {
      'label': 'High',
      'subtitle': 'Lots of people involved',
      'value': 'high',
      'icon': Icons.groups_rounded,
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScreenScaffold(
      title: 'Social battery needed?',
      stepIndicator: '3 of 6',
      onBack: () => context.pop(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            ..._socialOptions.map((option) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                borderRadius: 16,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                onTap: () {
                  final newTask = Map<String, dynamic>.from(
                    ref.read(newTaskProvider),
                  );
                  newTask['social'] = option['value'];
                  ref.read(newTaskProvider.notifier).state = newTask;
                  context.push('/add-energy');
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
