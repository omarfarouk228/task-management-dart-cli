import 'dart:io';

import 'package:dart_task_cli/exceptions/task_exceptions.dart';
import 'package:dart_task_cli/models/priority.dart';
import 'package:dart_task_cli/models/regular_task.dart';
import 'package:dart_task_cli/models/urgent_task.dart';
import 'package:dart_task_cli/repository/task_repository.dart';
import 'package:test/test.dart';

void main() {
  // ──────────────────────────────────────────────
  // Priority
  // ──────────────────────────────────────────────
  group('Priority', () {
    test('fromString parses all valid values case-insensitively', () {
      expect(Priority.fromString('low'), Priority.low);
      expect(Priority.fromString('MEDIUM'), Priority.medium);
      expect(Priority.fromString('High'), Priority.high);
    });

    test('fromString throws InvalidPriorityException for unknown value', () {
      expect(
        () => Priority.fromString('critical'),
        throwsA(isA<InvalidPriorityException>()),
      );
    });

    test('weight reflects ordering: low < medium < high', () {
      expect(Priority.low.weight, lessThan(Priority.medium.weight));
      expect(Priority.medium.weight, lessThan(Priority.high.weight));
    });
  });

  // ──────────────────────────────────────────────
  // RegularTask
  // ──────────────────────────────────────────────
  group('RegularTask', () {
    test('serialises and deserialises with full fidelity', () {
      final original = RegularTask(
        id: 'abc123',
        title: 'Buy milk',
        priority: Priority.low,
        deadline: DateTime(2026, 6, 1),
      );
      final restored = RegularTask.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.priority, original.priority);
      expect(restored.deadline, original.deadline);
      expect(restored.isDone, isFalse);
    });

    test('display toggles correctly between pending and done', () {
      final task = RegularTask(id: '1', title: 'Walk dog', priority: Priority.medium);
      expect(task.display(), contains('[ ]'));
      task.isDone = true;
      expect(task.display(), contains('[x]'));
    });

    test('display includes deadline when present', () {
      final task = RegularTask(
        id: '2',
        title: 'Submit report',
        priority: Priority.high,
        deadline: DateTime(2026, 7, 15),
      );
      expect(task.display(), contains('2026-07-15'));
    });
  });

  // ──────────────────────────────────────────────
  // UrgentTask
  // ──────────────────────────────────────────────
  group('UrgentTask', () {
    test('is always Priority.high regardless of input', () {
      final task = UrgentTask(id: '1', title: 'Fix prod');
      expect(task.priority, Priority.high);
    });

    test('display includes [URGENT] tag and urgency note', () {
      final task = UrgentTask(id: '1', title: 'Deploy hotfix', urgencyNote: 'DB is down');
      expect(task.display(), contains('[URGENT]'));
      expect(task.display(), contains('DB is down'));
    });

    test('serialises and deserialises urgencyNote correctly', () {
      final original = UrgentTask(id: '99', title: 'Rollback release', urgencyNote: 'Critical');
      final restored = UrgentTask.fromJson(original.toJson());
      expect(restored.urgencyNote, 'Critical');
      expect(restored.priority, Priority.high);
    });
  });

  // ──────────────────────────────────────────────
  // TaskRepository
  // ──────────────────────────────────────────────
  group('TaskRepository', () {
    late String tempFile;
    late TaskRepository repo;

    setUp(() async {
      tempFile =
          '${Directory.systemTemp.path}/tasks_${DateTime.now().millisecondsSinceEpoch}.json';
      repo = TaskRepository(tempFile);
      await repo.load();
    });

    tearDown(() {
      final f = File(tempFile);
      if (f.existsSync()) f.deleteSync();
    });

    test('add stores task and getAll returns it', () async {
      final task = RegularTask(id: 't1', title: 'Test', priority: Priority.medium);
      await repo.add(task);
      final all = await repo.getAll();
      expect(all.length, 1);
      expect(all.first.title, 'Test');
    });

    test('isDone persists across a fresh repository load', () async {
      final task = RegularTask(id: 't2', title: 'Persist test', priority: Priority.low);
      await repo.add(task);
      task.isDone = true;
      await repo.update(task);

      final reloaded = TaskRepository(tempFile);
      await reloaded.load();
      expect((await reloaded.getAll()).first.isDone, isTrue);
    });

    test('delete removes the task', () async {
      final task = RegularTask(id: 't3', title: 'To remove', priority: Priority.high);
      await repo.add(task);
      await repo.delete('t3');
      expect(await repo.getAll(), isEmpty);
    });

    test('delete a nonexistent id throws TaskNotFoundException', () {
      expect(
        () => repo.delete('ghost'),
        throwsA(isA<TaskNotFoundException>()),
      );
    });

    test('getSortedByPriority places high-priority tasks first', () async {
      await repo.add(RegularTask(id: 'lo', title: 'Low',  priority: Priority.low));
      await repo.add(RegularTask(id: 'hi', title: 'High', priority: Priority.high));
      await repo.add(RegularTask(id: 'md', title: 'Med',  priority: Priority.medium));

      final sorted = repo.getSortedByPriority();
      expect(sorted[0].priority, Priority.high);
      expect(sorted[1].priority, Priority.medium);
      expect(sorted[2].priority, Priority.low);
    });

    test('repository preserves UrgentTask type through serialisation', () async {
      final urgent = UrgentTask(id: 'u1', title: 'Server down', urgencyNote: 'P0');
      await repo.add(urgent);

      final reloaded = TaskRepository(tempFile);
      await reloaded.load();
      final task = (await reloaded.getAll()).first;
      expect(task, isA<UrgentTask>());
      expect((task as UrgentTask).urgencyNote, 'P0');
    });
  });
}
