import 'dart:io';

import 'package:dart_task_cli/exceptions/task_exceptions.dart';
import 'package:dart_task_cli/models/priority.dart';
import 'package:dart_task_cli/models/regular_task.dart';
import 'package:dart_task_cli/models/urgent_task.dart';
import 'package:dart_task_cli/repository/task_repository.dart';
import 'package:test/test.dart';

void main() {
  group('TaskRepository', () {
    late String tempFile;
    late TaskRepository repo;

    setUp(() async {
      tempFile =
          '${Directory.systemTemp.path}/repo_test_${DateTime.now().microsecondsSinceEpoch}.json';
      repo = TaskRepository(tempFile);
      await repo.load();
    });

    tearDown(() {
      final f = File(tempFile);
      if (f.existsSync()) f.deleteSync();
    });

    test('getAll returns empty list on fresh load', () async {
      expect(await repo.getAll(), isEmpty);
    });

    test('add then getAll returns the task', () async {
      await repo.add(RegularTask(id: 't1', title: 'Test', priority: Priority.medium));
      expect((await repo.getAll()).length, 1);
    });

    test('getById returns null for unknown id', () async {
      expect(await repo.getById('missing'), isNull);
    });

    test('getById returns the correct task', () async {
      await repo.add(RegularTask(id: 'x1', title: 'Find me', priority: Priority.low));
      final found = await repo.getById('x1');
      expect(found?.title, 'Find me');
    });

    test('update replaces the task in storage', () async {
      final task = RegularTask(id: 'u1', title: 'Original', priority: Priority.low);
      await repo.add(task);
      final updated = RegularTask(
          id: 'u1', title: 'Updated', priority: Priority.high,
          createdAt: task.createdAt);
      await repo.update(updated);
      expect((await repo.getById('u1'))?.title, 'Updated');
    });

    test('update throws TaskNotFoundException for unknown id', () {
      final ghost = RegularTask(id: 'ghost', title: 'Ghost', priority: Priority.low);
      expect(() => repo.update(ghost), throwsA(isA<TaskNotFoundException>()));
    });

    test('delete removes the task', () async {
      await repo.add(RegularTask(id: 'd1', title: 'Delete me', priority: Priority.low));
      await repo.delete('d1');
      expect(await repo.getAll(), isEmpty);
    });

    test('delete throws TaskNotFoundException for unknown id', () {
      expect(() => repo.delete('nobody'), throwsA(isA<TaskNotFoundException>()));
    });

    test('getSortedByPriority orders high first', () async {
      await repo.add(RegularTask(id: 'lo', title: 'Low', priority: Priority.low));
      await repo.add(RegularTask(id: 'hi', title: 'High', priority: Priority.high));
      await repo.add(RegularTask(id: 'md', title: 'Med', priority: Priority.medium));
      final sorted = repo.getSortedByPriority();
      expect(sorted[0].priority, Priority.high);
      expect(sorted[2].priority, Priority.low);
    });

    test('getSortedByDate orders oldest first', () async {
      final old = RegularTask(
          id: 'old', title: 'Old', priority: Priority.low,
          createdAt: DateTime(2025, 1, 1));
      final fresh = RegularTask(
          id: 'new', title: 'New', priority: Priority.low,
          createdAt: DateTime(2026, 1, 1));
      await repo.add(fresh);
      await repo.add(old);
      expect(repo.getSortedByDate().first.id, 'old');
    });

    test('UrgentTask type is preserved across reload', () async {
      await repo.add(UrgentTask(id: 'u1', title: 'P0', urgencyNote: 'Down'));
      final reloaded = TaskRepository(tempFile);
      await reloaded.load();
      expect((await reloaded.getAll()).first, isA<UrgentTask>());
    });

    test('isDone persists across reload', () async {
      final task = RegularTask(id: 'p1', title: 'Persist', priority: Priority.low);
      await repo.add(task);
      task.isDone = true;
      await repo.update(task);
      final reloaded = TaskRepository(tempFile);
      await reloaded.load();
      expect((await reloaded.getAll()).first.isDone, isTrue);
    });
  });
}
