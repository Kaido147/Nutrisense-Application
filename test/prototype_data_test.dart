import 'package:flutter_test/flutter_test.dart';
import 'package:nutrisense/models/prototype_data.dart';
import 'package:nutrisense/models/workout_catalog.dart';

void main() {
  group('HealthProfile', () {
    test('parses target weight and remains safe for older documents', () {
      final oldProfile = HealthProfile.fromMap(<String, dynamic>{
        'age': 21,
        'gender': 'Female',
        'heightCm': 162,
        'weightKg': 58,
        'activityLevel': 'Moderate',
        'fitnessGoal': 'General fitness',
        'dietaryPreference': 'No preference',
      });

      expect(oldProfile.targetWeightKg, isNull);
      expect(oldProfile.isComplete, isFalse);

      final profile = HealthProfile.fromMap(<String, dynamic>{
        'age': 21,
        'gender': 'Female',
        'heightCm': 162,
        'weightKg': 58,
        'targetWeightKg': 55,
        'activityLevel': 'Moderate',
        'fitnessGoal': 'General fitness',
        'dietaryPreference': 'No preference',
      });

      expect(profile.targetWeightKg, 55);
      expect(profile.isComplete, isTrue);
      expect(profile.toFirestore()['targetWeightKg'], 55);
    });
  });

  group('JournalRecord', () {
    test('parses sparse journal data safely', () {
      final entry = JournalRecord.fromMap('entry-1', <String, dynamic>{
        'content': 'A calm study day.',
        'mood': 'Calm',
        'tags': <String>['Study'],
        'entryDate': '2026-05-05T12:00:00.000',
      });

      expect(entry.id, 'entry-1');
      expect(entry.title, 'Untitled Entry');
      expect(entry.content, 'A calm study day.');
      expect(entry.moodInitial, 'C');
      expect(entry.tags, <String>['Study']);
    });
  });

  group('WorkoutPlan', () {
    test('parses category and source with fallbacks', () {
      final categorized = WorkoutPlan.fromMap('plan-1', <String, dynamic>{
        'title': 'Cardio Circuit',
        'category': 'Cardio',
        'source': 'manual',
        'exercises': <Map<String, dynamic>>[],
      });
      final fallback = WorkoutPlan.fromMap('plan-2', <String, dynamic>{});

      expect(categorized.category, 'Cardio');
      expect(categorized.source, 'manual');
      expect(fallback.category, 'Balanced');
      expect(fallback.source, 'generated');
    });
  });

  group('ClassSchedule', () {
    test('derives day index for older documents', () {
      final schedule = ClassSchedule.fromMap('class-1', <String, dynamic>{
        'title': 'Biology',
        'dayOfWeek': 'Wednesday',
        'startTimeMinutes': 9 * 60,
        'endTimeMinutes': 10 * 60,
      });

      expect(schedule.dayIndex, 2);
      expect(schedule.timeLabel, '9:00 AM - 10:00 AM');
    });
  });

  group('workoutCatalog', () {
    test('contains required categories with beginner-friendly exercises', () {
      const requiredCategories = <String>{
        'Full Body',
        'Upper Body',
        'Lower Body',
        'Core',
        'Cardio',
        'Stretching',
        'Beginner Workout',
        'Weight Loss',
        'Strength Training',
      };
      final names = workoutCatalog.map((category) => category.name).toSet();

      expect(names.containsAll(requiredCategories), isTrue);
      for (final category in workoutCatalog) {
        expect(category.exercises, isNotEmpty);
        for (final exercise in category.exercises) {
          expect(exercise.name, isNotEmpty);
          expect(exercise.instruction, isNotEmpty);
          expect(exercise.repsOrDuration, isNotEmpty);
        }
      }
    });
  });
}
