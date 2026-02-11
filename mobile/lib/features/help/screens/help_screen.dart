import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/screen_scaffold.dart';
import 'package:go_router/go_router.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = [
    _FaqItem(
      question: 'How do I add tasks?',
      answer:
          'Tap "Add Task" on the home screen. You\'ll choose a task type, how long it takes, '
          'your social battery level, and energy needed. Then give it a name and optionally set '
          'a due date. You can also use "Multi-Add" to add up to 5 tasks at once, or import '
          'tasks from text/CSV.',
    ),
    _FaqItem(
      question: 'What do Time, Energy, and Social mean?',
      answer:
          'Time: How many minutes the task takes (5, 15, 30, or 60 min).\n\n'
          'Energy: How much mental/physical effort it requires '
          '(Low = easy, Medium = moderate, High = demanding).\n\n'
          'Social: How much social interaction is involved '
          '(Low = solo, Medium = some interaction, High = very social).',
    ),
    _FaqItem(
      question: 'How does "What Next" work?',
      answer:
          'Tell the app how you\'re feeling right now — your energy level, social battery, and '
          'how much time you have. The app filters your tasks to find ones that match, then '
          'presents them as swipeable cards. Swipe right to accept a task, swipe left to skip it.',
    ),
    _FaqItem(
      question: 'How do I manage my tasks?',
      answer:
          'Tap the manage icon or go to "Manage Tasks". You can edit any task by tapping it, '
          'delete it with the delete button, or start it directly. Use the filters at the top '
          'to find tasks by time, energy, or social level.',
    ),
    _FaqItem(
      question: 'What are Groups & Leaderboards?',
      answer:
          'Groups let you compete with friends! Create a group and share the invite code. '
          'Members earn points by completing tasks, and you can see weekly rankings on the '
          'leaderboard. Group creators can also set challenges with bonus points.',
    ),
    _FaqItem(
      question: 'How do Points & Ranks work?',
      answer:
          'You earn points for completing tasks. Harder tasks earn more points.\n\n'
          'Ranks: Task Newbie (0) \u2192 Task Apprentice (100) \u2192 Task Slayer (500) '
          '\u2192 Task Master (1500) \u2192 Task Champion (3000) \u2192 Task Legend (5000+)',
    ),
    _FaqItem(
      question: 'How do I delete custom task types?',
      answer:
          'On the "Add Task" type selection screen, long-press a custom type (ones you created) '
          'to see the delete option. The 8 default types cannot be deleted.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Help & FAQ',
      onBack: () => context.pop(),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: _faqs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final faq = _faqs[index];
          return _FaqTile(faq: faq);
        },
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});
}

class _FaqTile extends StatefulWidget {
  final _FaqItem faq;
  const _FaqTile({required this.faq});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isOpen = !_isOpen),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.faq.question,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _isOpen
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          if (_isOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                widget.faq.answer,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
