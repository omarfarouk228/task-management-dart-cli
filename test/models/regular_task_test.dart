import 'package:dart_task_cli/models/priority.dart';
import 'package:dart_task_cli/models/regular_task.dart';
import 'package:test/test.dart';

void main() {
  group('RegularTask', () {
    test('type getter returns RegularTask', () {
      final task = RegularTask(id: '1', title: 'T', priority: Priority.low);
      expect(task.type, 'RegularTask');
    });

    test('isDone defaults to false', () {
      final task = RegularTask(id: '2', title: 'T', priority: Priority.medium);
      expect(task.isDone, isFalse);
    });

    test('toJson includes type discriminator', () {
      final task = RegularTask(id: '3', title: 'T', priority: Priority.high);
      expect(task.toJson()['type'], 'RegularTask');
    });

    test('round-trips through JSON without data loss', () {
      final original = RegularTask(
        id: 'abc',
        title: 'Buy milk',
        priority: Priority.low,
        deadline: DateTime(2026, 6, 1),
        isDone: true,
      );
      final restored = RegularTask.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.priority, original.priority);
      expect(restored.deadline, original.deadline);
      expect(restored.isDone, isTrue);
    });

    test('display shows [ ] for pending and [x] for done', () {
      final task = RegularTask(id: '4', title: 'Walk dog', priority: Priority.medium);
      expect(task.display(), contains('[ ]'));
      task.isDone = true;
      expect(task.display(), contains('[x]'));
    });

    test('display includes deadline string when set', () {
      final task = RegularTask(
        id: '5',
        title: 'Report',
        priority: Priority.high,
        deadline: DateTime(2026, 7, 15),
      );
      expect(task.display(), contains('2026-07-15'));
    });

    test('display omits deadline section when not set', () {
      final task = RegularTask(id: '6', title: 'No dl', priority: Priority.low);
      expect(task.display(), isNot(contains('Due:')));
    });
  });
}
