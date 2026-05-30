class TaskNotFoundException implements Exception {
  final String taskId;
  const TaskNotFoundException(this.taskId);

  @override
  String toString() => 'Task not found: "$taskId"';
}

class InvalidPriorityException implements Exception {
  final String value;
  const InvalidPriorityException(this.value);

  @override
  String toString() =>
      'Invalid priority "$value" — use: low, medium, high';
}

class StorageException implements Exception {
  final String message;
  const StorageException(this.message);

  @override
  String toString() => 'Storage error: $message';
}
