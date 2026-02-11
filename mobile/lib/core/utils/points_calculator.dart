import '../constants/app_constants.dart';
import '../../data/models/task.dart';

/// Calculate points for completing a task
int calculatePoints(Task task) {
  final timePoints = kTimePoints[task.time] ?? 10;
  final socialPoints = kLevelPoints[task.social] ?? 5;
  final energyPoints = kLevelPoints[task.energy] ?? 5;
  return timePoints + socialPoints + energyPoints;
}

/// Get current rank based on total points
Rank getRank(int points) {
  Rank rank = kRanks[0];
  for (final r in kRanks) {
    if (points >= r.minPoints) {
      rank = r;
    }
  }
  return rank;
}

/// Get next rank (or null if at max)
Rank? getNextRank(int points) {
  for (final r in kRanks) {
    if (points < r.minPoints) {
      return r;
    }
  }
  return null;
}

/// Get urgency score based on due date (0-4)
int getUrgencyScore(Task task) {
  if (task.dueDate == null) return 0;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final due = DateTime.parse(task.dueDate!);
  final dueDay = DateTime(due.year, due.month, due.day);

  final daysUntilDue = dueDay.difference(today).inDays;

  if (daysUntilDue < 0) return 4; // Overdue
  if (daysUntilDue <= 1) return 3; // Due today or tomorrow
  if (daysUntilDue <= 3) return 2; // Due in 3 days
  if (daysUntilDue <= 7) return 1; // Due in a week
  return 0;
}

/// Check if task is overdue
bool isOverdue(Task task) {
  if (task.dueDate == null) return false;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final due = DateTime.parse(task.dueDate!);
  final dueDay = DateTime(due.year, due.month, due.day);
  return dueDay.isBefore(today);
}

/// Get days until due (negative if overdue)
int? getDaysUntilDue(Task task) {
  if (task.dueDate == null) return null;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final due = DateTime.parse(task.dueDate!);
  final dueDay = DateTime(due.year, due.month, due.day);
  return dueDay.difference(today).inDays;
}

/// Calculate next due date for recurring task
String? getNextDueDate(Task task) {
  if (task.recurring == 'none') return null;

  final lastDue = task.dueDate != null ? DateTime.parse(task.dueDate!) : DateTime.now();

  DateTime nextDue;
  switch (task.recurring) {
    case 'daily':
      nextDue = lastDue.add(const Duration(days: 1));
    case 'weekly':
      nextDue = lastDue.add(const Duration(days: 7));
    case 'monthly':
      nextDue = DateTime(lastDue.year, lastDue.month + 1, lastDue.day);
    default:
      return null;
  }

  return nextDue.toIso8601String().split('T')[0];
}
