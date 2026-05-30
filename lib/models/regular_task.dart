import 'task.dart';
import 'priority.dart';

class RegularTask extends Task {
  RegularTask({
    required super.id,
    required super.title,
    required super.priority,
    super.deadline,
    super.isDone,
    super.createdAt,
  });

  @override
  String get type => 'RegularTask';

  @override
  String display() {
    final status = isDone ? '[x]' : '[ ]';
    final dl = deadline != null
        ? ' | Due: ${deadline!.toLocal().toString().split(' ')[0]}'
        : '';
    return '$status $title (${priority.name})$dl';
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'priority': priority.name,
        'deadline': deadline?.toIso8601String(),
        'isDone': isDone,
        'createdAt': createdAt.toIso8601String(),
      };

  factory RegularTask.fromJson(Map<String, dynamic> json) => RegularTask(
        id: json['id'] as String,
        title: json['title'] as String,
        priority: Priority.fromString(json['priority'] as String),
        deadline: json['deadline'] != null
            ? DateTime.parse(json['deadline'] as String)
            : null,
        isDone: json['isDone'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
