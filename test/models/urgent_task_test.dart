import 'package:dart_task_cli/models/priority.dart';
import 'package:dart_task_cli/models/urgent_task.dart';
import 'package:test/test.dart';

void main() {
  group('UrgentTask', () {
    test('priority is always high regardless of default', () {
      final task = UrgentTask(id: '1', title: 'Crash');
      expect(task.priority, Priority.high);
    });

    test('type getter returns UrgentTask', () {
      expect(UrgentTask(id: '2', title: 'T').type, 'UrgentTask');
    });

    test('urgencyNote defaults to empty string', () {
      expect(UrgentTask(id: '3', title: 'T').urgencyNote, '');
    });

    test('display contains [URGENT] tag', () {
      final task = UrgentTask(id: '4', title: 'Deploy', urgencyNote: 'DB down');
      expect(task.display(), contains('[URGENT]'));
    });

    test('display contains urgencyNote text', () {
      final task = UrgentTask(id: '5', title: 'Rollback', urgencyNote: 'P0 incident');
      expect(task.display(), contains('P0 incident'));
    });

    test('round-trips urgencyNote and priority through JSON', () {
      final original = UrgentTask(id: '6', title: 'Hotfix', urgencyNote: 'Critical');
      final restored = UrgentTask.fromJson(original.toJson());
      expect(restored.urgencyNote, 'Critical');
      expect(restored.priority, Priority.high);
    });

    test('toJson includes urgencyNote key', () {
      final task = UrgentTask(id: '7', title: 'T', urgencyNote: 'note');
      expect(task.toJson().containsKey('urgencyNote'), isTrue);
    });
  });
}
