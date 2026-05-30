import '../interfaces/displayable.dart';
import '../interfaces/serializable.dart';
import 'priority.dart';

abstract class Task implements Displayable, Serializable {
  final String id;
  String title;
  Priority priority;
  DateTime? deadline;
  bool isDone;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    required this.priority,
    this.deadline,
    this.isDone = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get type;
  Map<String, dynamic> toJson();
}
