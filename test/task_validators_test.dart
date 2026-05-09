import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrisense/Core/task_validators.dart';

void main() {
  group('validateTaskDueDateTime', () {
    test('rejects past dates', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      expect(
        validateTaskDueDateTime(yesterday, const TimeOfDay(hour: 9, minute: 0)),
        'Due date cannot be in the past',
      );
    });

    test('rejects past times today', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final past = now.subtract(const Duration(minutes: 1));

      expect(
        validateTaskDueDateTime(
          today,
          TimeOfDay(hour: past.hour, minute: past.minute),
        ),
        'Due time has already passed',
      );
    });

    test('allows future dates without a selected time', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));

      expect(validateTaskDueDateTime(tomorrow, null), isNull);
    });
  });
}
