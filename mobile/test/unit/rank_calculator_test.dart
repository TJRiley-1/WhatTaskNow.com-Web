import 'package:flutter_test/flutter_test.dart';
import 'package:whatnow/core/utils/points_calculator.dart';
import 'package:whatnow/core/constants/app_constants.dart';
import 'package:whatnow/data/models/task.dart';

void main() {
  group('getRank', () {
    test('0 points = Task Newbie', () {
      expect(getRank(0).name, 'Task Newbie');
    });

    test('99 points = Task Newbie', () {
      expect(getRank(99).name, 'Task Newbie');
    });

    test('100 points = Task Apprentice', () {
      expect(getRank(100).name, 'Task Apprentice');
    });

    test('499 points = Task Apprentice', () {
      expect(getRank(499).name, 'Task Apprentice');
    });

    test('500 points = Task Warrior', () {
      expect(getRank(500).name, 'Task Warrior');
    });

    test('999 points = Task Warrior', () {
      expect(getRank(999).name, 'Task Warrior');
    });

    test('1000 points = Task Hero', () {
      expect(getRank(1000).name, 'Task Hero');
    });

    test('2499 points = Task Hero', () {
      expect(getRank(2499).name, 'Task Hero');
    });

    test('2500 points = Task Master', () {
      expect(getRank(2500).name, 'Task Master');
    });

    test('4999 points = Task Master', () {
      expect(getRank(4999).name, 'Task Master');
    });

    test('5000 points = Task Legend', () {
      expect(getRank(5000).name, 'Task Legend');
    });

    test('99999 points = Task Legend', () {
      expect(getRank(99999).name, 'Task Legend');
    });

    test('each rank has correct minPoints', () {
      expect(getRank(0).minPoints, 0);
      expect(getRank(100).minPoints, 100);
      expect(getRank(500).minPoints, 500);
      expect(getRank(1000).minPoints, 1000);
      expect(getRank(2500).minPoints, 2500);
      expect(getRank(5000).minPoints, 5000);
    });
  });

  group('getNextRank', () {
    test('Newbie -> Apprentice', () {
      expect(getNextRank(0)?.name, 'Task Apprentice');
      expect(getNextRank(0)?.minPoints, 100);
    });

    test('Apprentice -> Warrior', () {
      expect(getNextRank(100)?.name, 'Task Warrior');
      expect(getNextRank(100)?.minPoints, 500);
    });

    test('Warrior -> Hero', () {
      expect(getNextRank(500)?.name, 'Task Hero');
      expect(getNextRank(500)?.minPoints, 1000);
    });

    test('Hero -> Master', () {
      expect(getNextRank(1000)?.name, 'Task Master');
      expect(getNextRank(1000)?.minPoints, 2500);
    });

    test('Master -> Legend', () {
      expect(getNextRank(2500)?.name, 'Task Legend');
      expect(getNextRank(2500)?.minPoints, 5000);
    });

    test('Legend -> null (max rank)', () {
      expect(getNextRank(5000), isNull);
    });

    test('far beyond Legend -> null', () {
      expect(getNextRank(99999), isNull);
    });

    test('mid-rank returns correct next rank', () {
      expect(getNextRank(50)?.name, 'Task Apprentice');
      expect(getNextRank(250)?.name, 'Task Warrior');
      expect(getNextRank(750)?.name, 'Task Hero');
      expect(getNextRank(1500)?.name, 'Task Master');
      expect(getNextRank(3000)?.name, 'Task Legend');
    });
  });

  group('calculatePoints', () {
    test('5min/low/low = 15 points', () {
      final task = Task(
        id: '1', name: 'Test', type: 'Chores',
        time: 5, social: 'low', energy: 'low',
      );
      expect(calculatePoints(task), 15); // 5 + 5 + 5
    });

    test('15min/medium/medium = 30 points', () {
      final task = Task(
        id: '2', name: 'Test', type: 'Work',
        time: 15, social: 'medium', energy: 'medium',
      );
      expect(calculatePoints(task), 30); // 10 + 10 + 10
    });

    test('30min/high/low = 40 points', () {
      final task = Task(
        id: '3', name: 'Test', type: 'Social',
        time: 30, social: 'high', energy: 'low',
      );
      expect(calculatePoints(task), 40); // 15 + 20 + 5
    });

    test('60min/high/high = 65 points', () {
      final task = Task(
        id: '4', name: 'Test', type: 'Health',
        time: 60, social: 'high', energy: 'high',
      );
      expect(calculatePoints(task), 65); // 25 + 20 + 20
    });

    test('30min/low/high = 40 points', () {
      final task = Task(
        id: '5', name: 'Test', type: 'Admin',
        time: 30, social: 'low', energy: 'high',
      );
      expect(calculatePoints(task), 40); // 15 + 5 + 20
    });

    test('5min/high/medium = 35 points', () {
      final task = Task(
        id: '6', name: 'Test', type: 'Creative',
        time: 5, social: 'high', energy: 'medium',
      );
      expect(calculatePoints(task), 35); // 5 + 20 + 10
    });

    test('60min/low/low = 35 points', () {
      final task = Task(
        id: '7', name: 'Test', type: 'Errand',
        time: 60, social: 'low', energy: 'low',
      );
      expect(calculatePoints(task), 35); // 25 + 5 + 5
    });

    test('15min/low/high = 35 points', () {
      final task = Task(
        id: '8', name: 'Test', type: 'Self-care',
        time: 15, social: 'low', energy: 'high',
      );
      expect(calculatePoints(task), 35); // 10 + 5 + 20
    });
  });

  group('kRanks constant', () {
    test('has 6 ranks', () {
      expect(kRanks.length, 6);
    });

    test('ranks are in ascending order of minPoints', () {
      for (var i = 1; i < kRanks.length; i++) {
        expect(kRanks[i].minPoints, greaterThan(kRanks[i - 1].minPoints));
      }
    });

    test('first rank starts at 0', () {
      expect(kRanks[0].minPoints, 0);
    });
  });
}
