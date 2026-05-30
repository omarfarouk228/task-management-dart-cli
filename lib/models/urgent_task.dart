import 'task.dart';
import 'priority.dart';

/// A task that always carries Priority.high and an optional urgency note.
class UrgentTask extends Task {
  final String urgencyNote;

  UrgentTask({
    required super.id,
    required super.title,
    this.urgencyNote = '',
    super.deadline,
    super.isDone,
    super.createdAt,
  }) : super(priority: Priority.high);

  @override
  String get type => 'UrgentTask';

  @override
  String display() {
    final status = isDone ? '[x]' : '[ ]';
    final dl = deadline != null
        ? ' | Due: ${deadline!.toLocal().toString().split(' ')[0]}'
        : '';
    final note = urgencyNote.isNotEmpty ? ' ! $urgencyNote' : '';
    return '$status [URGENT] $title$dl$note';
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
        'urgencyNote': urgencyNote,
      };

  factory UrgentTask.fromJson(Map<String, dynamic> json) => UrgentTask(
        id: json['id'] as String,
        title: json['title'] as String,
        urgencyNote: (json['urgencyNote'] as String?) ?? '',
        deadline: json['deadline'] != null
            ? DateTime.parse(json['deadline'] as String)
            : null,
        isDone: json['isDone'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
