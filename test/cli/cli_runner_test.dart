import 'dart:io';

import 'package:dart_task_cli/cli/cli_runner.dart';
import 'package:dart_task_cli/models/priority.dart';
import 'package:dart_task_cli/models/regular_task.dart';
import 'package:dart_task_cli/models/urgent_task.dart';
import 'package:dart_task_cli/repository/task_repository.dart';
import 'package:test/test.dart';

void main() {
  group('CliRunner', () {
    late String tempFile;
    late TaskRepository repo;
    late CliRunner runner;

    setUp(() async {
      tempFile =
          '${Directory.systemTemp.path}/cli_test_${DateTime.now().microsecondsSinceEpoch}.json';
      repo = TaskRepository(tempFile);
      await repo.load();
      runner = CliRunner(repo);
    });

    tearDown(() {
      final f = File(tempFile);
      if (f.existsSync()) f.deleteSync();
    });

    test('add creates a RegularTask with correct title', () async {
      await runner.run(['add', 'Write tests', '-p', 'low']);
      final tasks = await repo.getAll();
      expect(tasks.length, 1);
      expect(tasks.first.title, 'Write tests');
      expect(tasks.first, isA<RegularTask>());
    });

    test('add with --note creates an UrgentTask', () async {
      await runner.run(['add', 'Deploy now', '-n', 'Server down']);
      final tasks = await repo.getAll();
      expect(tasks.first, isA<UrgentTask>());
      expect((tasks.first as UrgentTask).urgencyNote, 'Server down');
    });

    test('add with -p high creates an UrgentTask', () async {
      await runner.run(['add', 'Critical fix', '-p', 'high']);
      expect((await repo.getAll()).first, isA<UrgentTask>());
    });

    test('done marks task as completed', () async {
      await runner.run(['add', 'Finish me', '-p', 'medium']);
      final id = (await repo.getAll()).first.id;
      await runner.run(['done', id]);
      expect((await repo.getById(id))!.isDone, isTrue);
    });

    test('delete removes task from storage', () async {
      await runner.run(['add', 'Remove me', '-p', 'low']);
      final id = (await repo.getAll()).first.id;
      await runner.run(['delete', id]);
      expect(await repo.getAll(), isEmpty);
    });

    test('update changes task title', () async {
      await runner.run(['add', 'Old title', '-p', 'low']);
      final id = (await repo.getAll()).first.id;
      await runner.run(['update', id, '--title', 'New title']);
      expect((await repo.getById(id))!.title, 'New title');
    });

    test('update changes task priority', () async {
      await runner.run(['add', 'My task', '-p', 'low']);
      final id = (await repo.getAll()).first.id;
      await runner.run(['update', id, '-p', 'medium']);
      expect((await repo.getById(id))!.priority, Priority.medium);
    });

    test('update changes UrgentTask urgency note', () async {
      await runner.run(['add', 'P0 issue', '-n', 'Old note']);
      final id = (await repo.getAll()).first.id;
      await runner.run(['update', id, '--note', 'New note']);
      final updated = await repo.getById(id);
      expect((updated as UrgentTask).urgencyNote, 'New note');
    });

    test('list does not throw when repo is empty', () async {
      expect(() async => runner.run(['list']), returnsNormally);
    });

    test('multiple adds accumulate in storage', () async {
      await runner.run(['add', 'Task A', '-p', 'low']);
      await runner.run(['add', 'Task B', '-p', 'high']);
      expect((await repo.getAll()).length, 2);
    });
  });
}
