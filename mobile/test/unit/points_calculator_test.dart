import 'package:flutter_test/flutter_test.dart';
import 'package:whatnow/core/utils/points_calculator.dart';
import 'package:whatnow/core/constants/app_constants.dart';
import 'package:whatnow/data/models/task.dart';

void main() {
  group('calculatePoints', () {
    test('returns correct points for 5min/low/low task', () {
      final task = Task(
        id: '1', name: 'Test', type: 'Chores',
        time: 5, social: 'low', energy: 'low',
      );
      expect(calculatePoints(task), 15); // 5 + 5 + 5
    });

    test('returns correct points for 60min/high/high task', () {
      final task = Task(
        id: '2', name: 'Test', type: 'Work',
        time: 60, social: 'high', energy: 'high',
      );
      expect(calculatePoints(task), 65); // 25 + 20 + 20
    });

    test('returns correct points for 15min/medium/low task', () {
      final task = Task(
        id: '3', name: 'Test', type: 'Health',
        time: 15, social: 'medium', energy: 'low',
      );
      expect(calculatePoints(task), 25); // 10 + 10 + 5
    });

    test('returns correct points for 30min/low/medium task', () {
      final task = Task(
        id: '4', name: 'Test', type: 'Admin',
        time: 30, social: 'low', energy: 'medium',
      );
      expect(calculatePoints(task), 30); // 15 + 5 + 10
    });
  });

  group('getRank', () {
    test('returns Task Newbie for 0 points', () {
      expect(getRank(0).name, 'Task Newbie');
    });

    test('returns Task Apprentice for 100 points', () {
      expect(getRank(100).name, 'Task Apprentice');
    });

    test('returns Task Warrior for 500 points', () {
      expect(getRank(500).name, 'Task Warrior');
    });

    test('returns Task Hero for 1000 points', () {
      expect(getRank(1000).name, 'Task Hero');
    });

    test('returns Task Master for 2500 points', () {
      expect(getRank(2500).name, 'Task Master');
    });

    test('returns Task Legend for 5000 points', () {
      expect(getRank(5000).name, 'Task Legend');
    });

    test('returns correct rank for in-between values', () {
      expect(getRank(99).name, 'Task Newbie');
      expect(getRank(250).name, 'Task Apprentice');
      expect(getRank(999).name, 'Task Warrior');
      expect(getRank(4999).name, 'Task Master');
      expect(getRank(10000).name, 'Task Legend');
    });
  });

  group('getNextRank', () {
    test('returns Task Apprentice for 0 points', () {
      expect(getNextRank(0)?.name, 'Task Apprentice');
    });

    test('returns null for max rank', () {
      expect(getNextRank(5000), isNull);
      expect(getNextRank(10000), isNull);
    });
  });

  group('getUrgencyScore', () {
    test('returns 0 for no due date', () {
      final task = Task(
        id: '1', name: 'Test', type: 'Chores',
        time: 5, social: 'low', energy: 'low',
      );
      expect(getUrgencyScore(task), 0);
    });

    test('returns 4 for overdue task', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 2));
      final task = Task(
        id: '2', name: 'Test', type: 'Chores',
        time: 5, social: 'low', energy: 'low',
        dueDate: yesterday.toIso8601String().split('T')[0],
      );
      expect(getUrgencyScore(task), 4);
    });

    test('returns 3 for task due today', () {
      final today = DateTime.now();
      final task = Task(
        id: '3', name: 'Test', type: 'Chores',
        time: 5, social: 'low', energy: 'low',
        dueDate: today.toIso8601String().split('T')[0],
      );
      expect(getUrgencyScore(task), 3);
    });

    test('returns 0 for far future task', () {
      final future = DateTime.now().add(const Duration(days: 30));
      final task = Task(
        id: '4', name: 'Test', type: 'Chores',
        time: 5, social: 'low', energy: 'low',
        dueDate: future.toIso8601String().split('T')[0],
      );
      expect(getUrgencyScore(task), 0);
    });
  });

  group('isOverdue', () {
    test('returns false for no due date', () {
      final task = Task(
        id: '1', name: 'Test', type: 'Chores',
        time: 5, social: 'low', energy: 'low',
      );
      expect(isOverdue(task), false);
    });

    test('returns true for past due date', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final task = Task(
        id: '2', name: 'Test', type: 'Chores',
        time: 5, social: 'low', energy: 'low',
        dueDate: yesterday.toIso8601String().split('T')[0],
      );
      expect(isOverdue(task), true);
    });

    test('returns false for future due date', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final task = Task(
        id: '3', name: 'Test', type: 'Chores',
        time: 5, social: 'low', energy: 'low',
        dueDate: tomorrow.toIso8601String().split('T')[0],
      );
      expect(isOverdue(task), false);
    });
  });

  group('getNextDueDate', () {
    test('returns null for non-recurring task', () {
      final task = Task(
        id: '1', name: 'Test', type: 'Chores',
        time: 5, social: 'low', energy: 'low',
        recurring: 'none',
      );
      expect(getNextDueDate(task), isNull);
    });

    test('returns next day for daily recurring', () {
      final task = Task(
        id: '2', name: 'Test', type: 'Chores',
        time: 5, social: 'low', energy: 'low',
        recurring: 'daily',
        dueDate: '2025-01-15',
      );
      expect(getNextDueDate(task), '2025-01-16');
    });

    test('returns next week for weekly recurring', () {
      final task = Task(
        id: '3', name: 'Test', type: 'Chores',
        time: 5, social: 'low', energy: 'low',
        recurring: 'weekly',
        dueDate: '2025-01-15',
      );
      expect(getNextDueDate(task), '2025-01-22');
    });
  });
}
