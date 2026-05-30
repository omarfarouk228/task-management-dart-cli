import '../exceptions/task_exceptions.dart';

enum Priority {
  low,
  medium,
  high;

  static Priority fromString(String value) {
    return switch (value.toLowerCase()) {
      'low' => Priority.low,
      'medium' => Priority.medium,
      'high' => Priority.high,
      _ => throw InvalidPriorityException(value),
    };
  }

  // low=1, medium=2, high=3 for sorting
  int get weight => index + 1;
}
