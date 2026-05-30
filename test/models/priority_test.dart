import 'package:dart_task_cli/exceptions/task_exceptions.dart';
import 'package:dart_task_cli/models/priority.dart';
import 'package:test/test.dart';

void main() {
  group('Priority', () {
    test('fromString parses all values case-insensitively', () {
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

    test('weight ordering: low(1) < medium(2) < high(3)', () {
      expect(Priority.low.weight, 1);
      expect(Priority.medium.weight, 2);
      expect(Priority.high.weight, 3);
    });

    test('enum has exactly three values', () {
      expect(Priority.values.length, 3);
    });

    test('InvalidPriorityException message contains the bad value', () {
      final ex = InvalidPriorityException('extreme');
      expect(ex.toString(), contains('extreme'));
    });
  });
}
