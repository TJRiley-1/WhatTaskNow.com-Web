import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/screen_scaffold.dart';

class AddTimeScreen extends ConsumerWidget {
  const AddTimeScreen({super.key});

  static const _timeOptions = [
    {'label': '5 min', 'subtitle': 'Quick win', 'value': 5},
    {'label': '15 min', 'subtitle': 'Short task', 'value': 15},
    {'label': '30 min', 'subtitle': 'Medium task', 'value': 30},
    {'label': '1 hour+', 'subtitle': 'Long task', 'value': 60},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScreenScaffold(
      title: 'How long will it take?',
      stepIndicator: '2 of 6',
      onBack: () => context.pop(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            ..._timeOptions.map((option) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassOptionCard(
                label: option['label'] as String,
                subtitle: option['subtitle'] as String,
                onTap: () {
                  final newTask = Map<String, dynamic>.from(
                    ref.read(newTaskProvider),
                  );
                  newTask['time'] = option['value'];
                  ref.read(newTaskProvider.notifier).state = newTask;
                  context.push('/add-social');
                },
              ),
            )),
          ],
        ),
      ),
    );
  }
}
