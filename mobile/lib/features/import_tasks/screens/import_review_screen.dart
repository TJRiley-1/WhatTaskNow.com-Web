import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/screen_scaffold.dart';
import '../../../core/utils/analytics.dart';

class ImportReviewScreen extends ConsumerWidget {
  const ImportReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingImportsProvider);
    final unconfigured = pending.where((p) => p['configured'] != true).toList();
    final configured = pending.where((p) => p['configured'] == true).toList();

    if (unconfigured.isEmpty && configured.isNotEmpty) {
      Analytics.importTasks(configured.length);
    }

    return ScreenScaffold(
      title: 'Review Imports',
      onBack: () => context.go('/import'),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              '${pending.length} tasks found',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
            if (configured.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${configured.length} configured, ${unconfigured.length} remaining',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Expanded(
              child: unconfigured.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            color: AppColors.success,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'All tasks configured!',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 32),
                          GlassButton(
                            label: 'Back to Home',
                            variant: GlassButtonVariant.primary,
                            isLarge: true,
                            onPressed: () => context.go('/home'),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: unconfigured.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = unconfigured[index];
                        return GlassCard(
                          borderRadius: 16,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item['name'] as String,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              GlassButton(
                                label: 'Set Up',
                                variant: GlassButtonVariant.primary,
                                isFullWidth: false,
                                onPressed: () {
                                  ref.read(currentImportTaskProvider.notifier).state = {
                                    'name': item['name'],
                                  };
                                  ref.read(importTaskSettingsProvider.notifier).state = {};
                                  context.go('/import-setup');
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            if (unconfigured.isNotEmpty) ...[
              const SizedBox(height: 16),
              GlassButton(
                label: 'Back to Home',
                variant: GlassButtonVariant.outline,
                onPressed: () => context.go('/home'),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}
