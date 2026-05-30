import 'dart:convert';
import 'dart:io';

import '../exceptions/task_exceptions.dart';
import '../models/regular_task.dart';
import '../models/task.dart';
import '../models/urgent_task.dart';
import 'repository.dart';

class TaskRepository extends Repository<Task> {
  final String filePath;
  List<Task> _tasks = [];

  TaskRepository(this.filePath);

  Future<void> load() async {
    final file = File(filePath);
    if (!await file.exists()) {
      _tasks = [];
      return;
    }
    try {
      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        _tasks = [];
        return;
      }
      final List<dynamic> raw = jsonDecode(content);
      _tasks = raw.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw StorageException('Failed to load: $e');
    }
  }

  Future<void> _persist() async {
    try {
      await File(filePath)
          .writeAsString(jsonEncode(_tasks.map((t) => t.toJson()).toList()));
    } catch (e) {
      throw StorageException('Failed to save: $e');
    }
  }

  Task _fromJson(Map<String, dynamic> json) => switch (json['type']) {
        'UrgentTask' => UrgentTask.fromJson(json),
        _ => RegularTask.fromJson(json),
      };

  @override
  Future<List<Task>> getAll() async => List.unmodifiable(_tasks);

  @override
  Future<Task?> getById(String id) async {
    try {
      return _tasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> add(Task item) async {
    _tasks.add(item);
    await _persist();
  }

  @override
  Future<void> update(Task item) async {
    final idx = _tasks.indexWhere((t) => t.id == item.id);
    if (idx == -1) throw TaskNotFoundException(item.id);
    _tasks[idx] = item;
    await _persist();
  }

  @override
  Future<void> delete(String id) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx == -1) throw TaskNotFoundException(id);
    _tasks.removeAt(idx);
    await _persist();
  }

  List<Task> getSortedByPriority() => List<Task>.from(_tasks)
    ..sort((a, b) => b.priority.weight.compareTo(a.priority.weight));

  List<Task> getSortedByDate() => List<Task>.from(_tasks)
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
}
