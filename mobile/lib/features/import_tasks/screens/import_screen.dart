import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/import_parser.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/screen_scaffold.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _extractTasks() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // Try CSV first if it looks like CSV, otherwise plain text
    List<String> names;
    if (text.contains(',') && text.contains('\n')) {
      names = parseCSV(text);
      if (names.isEmpty) {
        names = parseImportText(text);
      }
    } else {
      names = parseImportText(text);
    }

    if (names.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tasks found in the text'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final pending = names
        .map((name) => {
              'name': name,
              'configured': false,
            })
        .toList();

    ref.read(pendingImportsProvider.notifier).state = pending;
    context.go('/import-review');
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Import Tasks',
      onBack: () => context.go('/home'),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Paste a list of tasks below',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Supports bullet lists, numbered lists, CSV, or one task per line',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GlassCard(
                borderRadius: 16,
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    height: 1.5,
                  ),
                  decoration: const InputDecoration(
                    hintText: '- Buy groceries\n- Clean kitchen\n- Call dentist\n- Send email to boss',
                    hintStyle: TextStyle(
                      color: AppColors.textMuted,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GlassButton(
              label: 'Upload File',
              variant: GlassButtonVariant.outline,
              icon: const Icon(Icons.upload_file_rounded, color: AppColors.textSecondary, size: 20),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('File upload coming soon!'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            GlassButton(
              label: 'Extract Tasks',
              variant: GlassButtonVariant.primary,
              isLarge: true,
              onPressed: _extractTasks,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
