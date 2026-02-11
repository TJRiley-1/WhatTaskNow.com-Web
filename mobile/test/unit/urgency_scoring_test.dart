import 'package:flutter_test/flutter_test.dart';
import 'package:whatnow/core/utils/points_calculator.dart';
import 'package:whatnow/data/models/task.dart';

/// Helper to create a minimal Task with optional dueDate and recurring.
Task _makeTask({String? dueDate, String recurring = 'none'}) {
  return Task(
    id: 'test',
    name: 'Test Task',
    type: 'Chores',
    time: 5,
    social: 'low',
    energy: 'low',
    dueDate: dueDate,
    recurring: recurring,
  );
}

String _dateString(DateTime dt) => dt.toIso8601String().split('T')[0];

void main() {
  group('getUrgencyScore', () {
    test('returns 0 for task with no due date', () {
      final task = _makeTask();
      expect(getUrgencyScore(task), 0);
    });

    test('returns 3 for task due today', () {
      final today = DateTime.now();
      final task = _makeTask(dueDate: _dateString(today));
      expect(getUrgencyScore(task), 3);
    });

    test('returns 3 for task due tomorrow', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final task = _makeTask(dueDate: _dateString(tomorrow));
      expect(getUrgencyScore(task), 3);
    });

    test('returns 2 for task due in 2 days', () {
      final future = DateTime.now().add(const Duration(days: 2));
      final task = _makeTask(dueDate: _dateString(future));
      expect(getUrgencyScore(task), 2);
    });

    test('returns 2 for task due in 3 days', () {
      final future = DateTime.now().add(const Duration(days: 3));
      final task = _makeTask(dueDate: _dateString(future));
      expect(getUrgencyScore(task), 2);
    });

    test('returns 1 for task due in 5 days', () {
      final future = DateTime.now().add(const Duration(days: 5));
      final task = _makeTask(dueDate: _dateString(future));
      expect(getUrgencyScore(task), 1);
    });

    test('returns 1 for task due in 7 days', () {
      final future = DateTime.now().add(const Duration(days: 7));
      final task = _makeTask(dueDate: _dateString(future));
      expect(getUrgencyScore(task), 1);
    });

    test('returns 0 for task due in 8+ days', () {
      final future = DateTime.now().add(const Duration(days: 8));
      final task = _makeTask(dueDate: _dateString(future));
      expect(getUrgencyScore(task), 0);
    });

    test('returns 4 for overdue task (past due)', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final task = _makeTask(dueDate: _dateString(yesterday));
      expect(getUrgencyScore(task), 4);
    });

    test('returns 4 for task overdue by many days', () {
      final pastDue = DateTime.now().subtract(const Duration(days: 30));
      final task = _makeTask(dueDate: _dateString(pastDue));
      expect(getUrgencyScore(task), 4);
    });
  });

  group('isOverdue', () {
    test('returns true for past due date', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final task = _makeTask(dueDate: _dateString(yesterday));
      expect(isOverdue(task), true);
    });

    test('returns false for today', () {
      final today = DateTime.now();
      final task = _makeTask(dueDate: _dateString(today));
      expect(isOverdue(task), false);
    });

    test('returns false for future due date', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final task = _makeTask(dueDate: _dateString(tomorrow));
      expect(isOverdue(task), false);
    });

    test('returns false for null due date', () {
      final task = _makeTask();
      expect(isOverdue(task), false);
    });

    test('returns true for date far in the past', () {
      final task = _makeTask(dueDate: '2020-01-01');
      expect(isOverdue(task), true);
    });
  });

  group('getDaysUntilDue', () {
    test('returns null for task with no due date', () {
      final task = _makeTask();
      expect(getDaysUntilDue(task), isNull);
    });

    test('returns 0 for task due today', () {
      final today = DateTime.now();
      final task = _makeTask(dueDate: _dateString(today));
      expect(getDaysUntilDue(task), 0);
    });

    test('returns 1 for task due tomorrow', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final task = _makeTask(dueDate: _dateString(tomorrow));
      expect(getDaysUntilDue(task), 1);
    });

    test('returns 7 for task due in a week', () {
      final nextWeek = DateTime.now().add(const Duration(days: 7));
      final task = _makeTask(dueDate: _dateString(nextWeek));
      expect(getDaysUntilDue(task), 7);
    });

    test('returns negative value for overdue task', () {
      final pastDue = DateTime.now().subtract(const Duration(days: 3));
      final task = _makeTask(dueDate: _dateString(pastDue));
      expect(getDaysUntilDue(task), -3);
    });

    test('returns -1 for task overdue by one day', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final task = _makeTask(dueDate: _dateString(yesterday));
      expect(getDaysUntilDue(task), -1);
    });
  });

  group('getNextDueDate', () {
    test('returns null for non-recurring task', () {
      final task = _makeTask(dueDate: '2025-06-15', recurring: 'none');
      expect(getNextDueDate(task), isNull);
    });

    test('daily recurring advances by 1 day', () {
      final task = _makeTask(dueDate: '2025-06-15', recurring: 'daily');
      expect(getNextDueDate(task), '2025-06-16');
    });

    test('daily recurring across month boundary', () {
      final task = _makeTask(dueDate: '2025-01-31', recurring: 'daily');
      expect(getNextDueDate(task), '2025-02-01');
    });

    test('weekly recurring advances by 7 days', () {
      final task = _makeTask(dueDate: '2025-06-15', recurring: 'weekly');
      expect(getNextDueDate(task), '2025-06-22');
    });

    test('weekly recurring across month boundary', () {
      final task = _makeTask(dueDate: '2025-01-28', recurring: 'weekly');
      expect(getNextDueDate(task), '2025-02-04');
    });

    test('monthly recurring advances by ~1 month', () {
      final task = _makeTask(dueDate: '2025-01-15', recurring: 'monthly');
      expect(getNextDueDate(task), '2025-02-15');
    });

    test('monthly recurring across year boundary', () {
      final task = _makeTask(dueDate: '2025-12-15', recurring: 'monthly');
      expect(getNextDueDate(task), '2026-01-15');
    });

    test('returns null for unknown recurring type', () {
      final task = _makeTask(dueDate: '2025-06-15', recurring: 'biweekly');
      expect(getNextDueDate(task), isNull);
    });

    test('uses current date when dueDate is null for recurring task', () {
      final task = _makeTask(recurring: 'daily');
      final result = getNextDueDate(task);
      expect(result, isNotNull);
      // The result should be tomorrow's date (roughly)
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(result, contains(tomorrow.year.toString()));
    });
  });
}
