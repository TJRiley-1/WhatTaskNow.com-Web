import 'package:flutter_test/flutter_test.dart';
import 'package:whatnow/data/models/task.dart';
import 'package:whatnow/core/constants/app_constants.dart';

void main() {
  // Test the matching logic directly (same algorithm used in TaskRepository)
  List<Task> findMatchingTasks(List<Task> tasks, {String? energy, String? social, int? time}) {
    final matching = tasks.where((task) {
      final energyMatch = energy == null ||
          (kEnergyLevels[energy] ?? 0) >= (kEnergyLevels[task.energy] ?? 0);
      final socialMatch = social == null ||
          (kSocialLevels[social] ?? 0) >= (kSocialLevels[task.social] ?? 0);
      final timeMatch = time == null || time >= task.time;
      return energyMatch && socialMatch && timeMatch;
    }).toList();
    return matching;
  }

  final tasks = [
    Task(id: '1', name: 'Easy quick', type: 'Chores', time: 5, social: 'low', energy: 'low'),
    Task(id: '2', name: 'Medium social', type: 'Social', time: 15, social: 'medium', energy: 'low'),
    Task(id: '3', name: 'Hard long', type: 'Work', time: 60, social: 'high', energy: 'high'),
    Task(id: '4', name: 'Medium energy', type: 'Health', time: 30, social: 'low', energy: 'medium'),
  ];

  group('task matching', () {
    test('null filters match all tasks', () {
      final result = findMatchingTasks(tasks);
      expect(result.length, 4);
    });

    test('low energy only matches low energy tasks', () {
      final result = findMatchingTasks(tasks, energy: 'low');
      expect(result.length, 2);
      expect(result.any((t) => t.name == 'Easy quick'), true);
      expect(result.any((t) => t.name == 'Medium social'), true);
    });

    test('high energy matches all energy levels', () {
      final result = findMatchingTasks(tasks, energy: 'high');
      expect(result.length, 4);
    });

    test('low social only matches low social tasks', () {
      final result = findMatchingTasks(tasks, social: 'low');
      expect(result.length, 2);
      expect(result.any((t) => t.name == 'Easy quick'), true);
      expect(result.any((t) => t.name == 'Medium energy'), true);
    });

    test('5 min time only matches 5 min tasks', () {
      final result = findMatchingTasks(tasks, time: 5);
      expect(result.length, 1);
      expect(result[0].name, 'Easy quick');
    });

    test('60 min time matches all tasks', () {
      final result = findMatchingTasks(tasks, time: 60);
      expect(result.length, 4);
    });

    test('combined filters work correctly', () {
      final result = findMatchingTasks(tasks, energy: 'low', social: 'low', time: 15);
      expect(result.length, 1);
      expect(result[0].name, 'Easy quick');
    });

    test('combined medium filters', () {
      final result = findMatchingTasks(tasks, energy: 'medium', social: 'medium', time: 30);
      expect(result.length, 3); // Easy quick, Medium social, Medium energy
    });
  });
}
