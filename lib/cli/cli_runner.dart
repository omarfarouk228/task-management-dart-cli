import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';

import '../exceptions/task_exceptions.dart';
import '../models/priority.dart';
import '../models/regular_task.dart';
import '../models/task.dart';
import '../models/urgent_task.dart';
import '../repository/task_repository.dart';

class CliRunner {
  final TaskRepository _repo;
  late final ArgParser _parser;

  CliRunner(this._repo) {
    _parser = _buildParser();
  }

  ArgParser _buildParser() {
    final root = ArgParser();

    final addCmd = ArgParser()
      ..addOption('priority', abbr: 'p', defaultsTo: 'medium',
          allowed: ['low', 'medium', 'high'],
          help: 'Task priority')
      ..addOption('deadline', abbr: 'd', help: 'Due date (YYYY-MM-DD)')
      ..addOption('note', abbr: 'n',
          help: 'Urgency note — auto-upgrades task to UrgentTask');

    final listCmd = ArgParser()
      ..addOption('sort', abbr: 's', defaultsTo: 'priority',
          allowed: ['priority', 'date'],
          help: 'Sort order')
      ..addFlag('all', abbr: 'a', negatable: false,
          help: 'Include completed tasks');

    final updateCmd = ArgParser()
      ..addOption('title', abbr: 't', help: 'New task title')
      ..addOption('priority', abbr: 'p',
          allowed: ['low', 'medium', 'high'],
          help: 'New priority (RegularTask only)')
      ..addOption('deadline', abbr: 'd', help: 'New due date (YYYY-MM-DD)')
      ..addOption('note', abbr: 'n', help: 'New urgency note (UrgentTask only)');

    root
      ..addCommand('add', addCmd)
      ..addCommand('list', listCmd)
      ..addCommand('done', ArgParser())
      ..addCommand('update', updateCmd)
      ..addCommand('delete', ArgParser())
      ..addFlag('help', abbr: 'h', negatable: false);

    return root;
  }

  Future<void> run(List<String> args) async {
    if (args.isEmpty) {
      _printUsage();
      return;
    }

    ArgResults results;
    try {
      results = _parser.parse(args);
    } catch (e) {
      stderr.writeln('Error: $e');
      _printUsage();
      exit(1);
    }

    if (results['help'] as bool) {
      _printUsage();
      return;
    }

    final cmd = results.command;
    if (cmd == null) {
      _printUsage();
      return;
    }

    try {
      switch (cmd.name) {
        case 'add':
          await _add(cmd);
        case 'list':
          await _list(cmd);
        case 'done':
          await _done(cmd);
        case 'update':
          await _update(cmd);
        case 'delete':
          await _delete(cmd);
        default:
          _printUsage();
      }
    } on TaskNotFoundException catch (e) {
      stderr.writeln('Error: $e');
      exit(1);
    } on InvalidPriorityException catch (e) {
      stderr.writeln('Error: $e');
      exit(1);
    } on StorageException catch (e) {
      stderr.writeln('Error: $e');
      exit(1);
    }
  }

  Future<void> _add(ArgResults args) async {
    if (args.rest.isEmpty) {
      stderr.writeln('Usage: add <title> [-p low|medium|high] [-d YYYY-MM-DD] [-n "note"]');
      exit(1);
    }

    final title = args.rest.join(' ');
    final priority = Priority.fromString(args['priority'] as String);
    final deadlineStr = args['deadline'] as String?;
    final note = args['note'] as String?;

    DateTime? deadline;
    if (deadlineStr != null) {
      try {
        deadline = DateTime.parse(deadlineStr);
      } catch (_) {
        stderr.writeln('Error: Invalid date "$deadlineStr" — use YYYY-MM-DD.');
        exit(1);
      }
    }

    final id = _generateId();
    final Task task = (note != null || priority == Priority.high)
        ? UrgentTask(id: id, title: title, urgencyNote: note ?? '', deadline: deadline)
        : RegularTask(id: id, title: title, priority: priority, deadline: deadline);

    await _repo.add(task);
    print('Added: [$id] "${task.title}" (${task.priority.name})');
  }

  Future<void> _list(ArgResults args) async {
    final sort = args['sort'] as String;
    final showAll = args['all'] as bool;

    final tasks = sort == 'priority'
        ? _repo.getSortedByPriority()
        : _repo.getSortedByDate();

    final visible = showAll ? tasks : tasks.where((t) => !t.isDone).toList();

    if (visible.isEmpty) {
      print(showAll
          ? 'No tasks yet. Add one with: add <title>'
          : 'No pending tasks. Use --all to see completed tasks.');
      return;
    }

    final header = 'Tasks (sorted by $sort)';
    final line = '─' * (header.length + 4);
    print('\n$line');
    print('  $header');
    print(line);
    for (var i = 0; i < visible.length; i++) {
      final t = visible[i];
      print('  ${(i + 1).toString().padLeft(2)}. [${t.id}] ${t.display()}');
    }
    print('$line\n');
  }

  Future<void> _done(ArgResults args) async {
    if (args.rest.isEmpty) {
      stderr.writeln('Usage: done <id>');
      exit(1);
    }
    final id = args.rest.first;
    final task = await _repo.getById(id);
    if (task == null) throw TaskNotFoundException(id);
    if (task.isDone) {
      print('Already done: "${task.title}"');
      return;
    }
    task.isDone = true;
    await _repo.update(task);
    print('Done: "${task.title}"');
  }

  Future<void> _delete(ArgResults args) async {
    if (args.rest.isEmpty) {
      stderr.writeln('Usage: delete <id>');
      exit(1);
    }
    final id = args.rest.first;
    final task = await _repo.getById(id);
    if (task == null) throw TaskNotFoundException(id);
    await _repo.delete(id);
    print('Deleted: "${task.title}"');
  }

  Future<void> _update(ArgResults args) async {
    if (args.rest.isEmpty) {
      stderr.writeln(
          'Usage: update <id> [-t "title"] [-p low|medium|high] [-d YYYY-MM-DD] [-n "note"]');
      exit(1);
    }

    final id = args.rest.first;
    final task = await _repo.getById(id);
    if (task == null) throw TaskNotFoundException(id);

    final newTitle = args['title'] as String?;
    final priorityStr = args['priority'] as String?;
    final deadlineStr = args['deadline'] as String?;
    final note = args['note'] as String?;

    DateTime? newDeadline = task.deadline;
    if (deadlineStr != null) {
      try {
        newDeadline = DateTime.parse(deadlineStr);
      } catch (_) {
        stderr.writeln('Error: Invalid date "$deadlineStr" — use YYYY-MM-DD.');
        exit(1);
      }
    }

    final Task updated;
    if (task is UrgentTask) {
      if (priorityStr != null) {
        stderr.writeln('Warning: UrgentTask priority is always high — --priority flag ignored.');
      }
      updated = UrgentTask(
        id: task.id,
        title: newTitle ?? task.title,
        urgencyNote: note ?? task.urgencyNote,
        deadline: newDeadline,
        isDone: task.isDone,
        createdAt: task.createdAt,
      );
    } else if (note != null) {
      // RegularTask promoted to UrgentTask when a note is provided.
      updated = UrgentTask(
        id: task.id,
        title: newTitle ?? task.title,
        urgencyNote: note,
        deadline: newDeadline,
        isDone: task.isDone,
        createdAt: task.createdAt,
      );
    } else {
      updated = RegularTask(
        id: task.id,
        title: newTitle ?? task.title,
        priority: priorityStr != null
            ? Priority.fromString(priorityStr)
            : task.priority,
        deadline: newDeadline,
        isDone: task.isDone,
        createdAt: task.createdAt,
      );
    }

    await _repo.update(updated);
    print('Updated: [${updated.id}] "${updated.title}" (${updated.priority.name})');
  }

  String _generateId() {
    final rng = Random();
    return (rng.nextInt(900000) + 100000).toString(); // 100000–999999
  }

  void _printUsage() {
    stdout.write('''
Dart Task Manager

Usage:
  add <title> [options]     Add a new task
    -p, --priority          low | medium | high  (default: medium)
    -d, --deadline          YYYY-MM-DD
    -n, --note              Urgency note (auto-upgrades to UrgentTask)

  list [options]            List tasks
    -s, --sort              priority | date  (default: priority)
    -a, --all               Include completed tasks

  done <id>                 Mark a task as done

  update <id> [options]     Update task fields
    -t, --title             New title
    -p, --priority          low | medium | high
    -d, --deadline          YYYY-MM-DD
    -n, --note              New urgency note (UrgentTask only)

  delete <id>               Remove a task

  -h, --help                Show this help

Examples:
  dart run bin/main.dart add "Fix login bug" -p high -d 2026-06-01
  dart run bin/main.dart add "Deploy hotfix" -n "Server is down"
  dart run bin/main.dart list
  dart run bin/main.dart list --sort date --all
  dart run bin/main.dart done 452731
  dart run bin/main.dart update 452731 --title "Fixed login bug" -p medium
  dart run bin/main.dart delete 452731
''');
  }
}
