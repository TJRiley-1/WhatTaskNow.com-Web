import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/screen_scaffold.dart';

class MultiTimeScreen extends ConsumerWidget {
  const MultiTimeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeOptions = [
      {'minutes': 5, 'label': '5 min', 'subtitle': 'Quick task'},
      {'minutes': 15, 'label': '15 min', 'subtitle': 'Short task'},
      {'minutes': 30, 'label': '30 min', 'subtitle': 'Medium task'},
      {'minutes': 60, 'label': '60 min', 'subtitle': 'Long task'},
    ];

    return ScreenScaffold(
      title: 'Add Multiple Tasks',
      stepIndicator: '2 of 5',
      onBack: () => context.go('/multi-type'),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            const Text(
              'How long will they take?',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 32),
            ...timeOptions.map((option) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  onTap: () {
                    ref.read(multiAddTaskProvider.notifier).state = {
                      ...ref.read(multiAddTaskProvider),
                      'time': option['minutes'],
                    };
                    context.go('/multi-social');
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
                        child: Center(
                          child: Text(
                            '${option['minutes']}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
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
                      const Spacer(),
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
