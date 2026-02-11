import 'package:flutter_test/flutter_test.dart';
import 'package:whatnow/core/utils/import_parser.dart';

void main() {
  group('parseImportText', () {
    test('parses bullet list', () {
      final result = parseImportText('- Task 1\n- Task 2\n- Task 3');
      expect(result, ['Task 1', 'Task 2', 'Task 3']);
    });

    test('parses numbered list', () {
      final result = parseImportText('1. Task A\n2. Task B\n3) Task C');
      expect(result, ['Task A', 'Task B', 'Task C']);
    });

    test('parses checkbox list', () {
      final result = parseImportText('[ ] Task 1\n[x] Task 2\n[X] Task 3');
      expect(result, ['Task 1', 'Task 2', 'Task 3']);
    });

    test('skips empty lines', () {
      final result = parseImportText('Task 1\n\n\nTask 2');
      expect(result, ['Task 1', 'Task 2']);
    });

    test('skips lines over 100 chars', () {
      final longLine = 'A' * 101;
      final result = parseImportText('Short task\n$longLine');
      expect(result, ['Short task']);
    });

    test('handles mixed formats', () {
      final result = parseImportText('- Task 1\n* Task 2\n3. Task 3\n[x] Task 4');
      expect(result, ['Task 1', 'Task 2', 'Task 3', 'Task 4']);
    });

    test('returns empty for empty input', () {
      expect(parseImportText(''), isEmpty);
      expect(parseImportText('\n\n'), isEmpty);
    });
  });

  group('parseCSV', () {
    test('parses CSV with name header', () {
      final result = parseCSV('name,type\nTask 1,Chores\nTask 2,Work');
      expect(result, ['Task 1', 'Task 2']);
    });

    test('parses CSV with task header', () {
      final result = parseCSV('task,priority\nDo laundry,high\nBuy milk,low');
      expect(result, ['Do laundry', 'Buy milk']);
    });

    test('parses CSV with title header', () {
      final result = parseCSV('id,title,status\n1,First task,pending');
      expect(result, ['First task']);
    });

    test('falls back to first column when no name header', () {
      final result = parseCSV('col1,col2\nValue A,extra\nValue B,extra');
      expect(result, ['Value A', 'Value B']);
    });

    test('returns empty for single line', () {
      expect(parseCSV('just a header'), isEmpty);
    });

    test('skips empty names', () {
      final result = parseCSV('name,type\nTask 1,Chores\n,Work\nTask 3,Health');
      expect(result, ['Task 1', 'Task 3']);
    });
  });
}
