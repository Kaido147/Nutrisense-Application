import 'package:flutter_test/flutter_test.dart';
import 'package:nutrisense/models/workout_catalog.dart';
import 'package:nutrisense/services/smart_workout_routine_generator.dart';

void main() {
  group('generateSmartWorkoutRoutine', () {
    test('never exceeds selected time limits', () {
      final category = workoutCategoryByName('Cardio');

      for (final limit in <int>[15, 30, 45]) {
        final routine = generateSmartWorkoutRoutine(
          category: category,
          availableMinutes: limit,
          goal: 'Lose weight',
          intensity: 'High',
        );

        expect(routine.estimatedMinutes, lessThanOrEqualTo(limit));
        expect(
          routine.exercises.fold<int>(
            0,
            (total, exercise) => total + estimatedExerciseMinutes(exercise),
          ),
          routine.estimatedMinutes,
        );
      }
    });

    test('uses only exercises from the selected focus category', () {
      final category = workoutCategoryByName('Core');
      final categoryIds = category.exercises.map((exercise) => exercise.id);

      final routine = generateSmartWorkoutRoutine(
        category: category,
        availableMinutes: 30,
        goal: 'General fitness',
        intensity: 'Moderate',
      );

      expect(routine.exercises, isNotEmpty);
      expect(
        routine.exercises.every(
          (exercise) => categoryIds.contains(exercise.id),
        ),
        isTrue,
      );
    });

    test('avoids duplicate exercise ids', () {
      const category = WorkoutCategory(
        id: 'duplicates',
        name: 'Duplicates',
        description: 'Duplicate exercise ids',
        exercises: <WorkoutExercise>[
          WorkoutExercise(
            id: 'duplicate',
            name: 'First Duplicate',
            sets: 1,
            repsOrDuration: '30 sec',
            difficulty: 'Beginner',
            instruction: 'Move with control.',
          ),
          WorkoutExercise(
            id: 'duplicate',
            name: 'Second Duplicate',
            sets: 1,
            repsOrDuration: '30 sec',
            difficulty: 'Intermediate',
            instruction: 'Move with control.',
          ),
        ],
      );

      final routine = generateSmartWorkoutRoutine(
        category: category,
        availableMinutes: 15,
        goal: 'General fitness',
        intensity: 'Moderate',
      );

      expect(routine.exercises.map((exercise) => exercise.id).toSet(), {
        'duplicate',
      });
      expect(routine.exercises, hasLength(1));
    });

    test('prefers higher value per minute exercises greedily', () {
      const category = WorkoutCategory(
        id: 'ranking',
        name: 'Ranking',
        description: 'Ranking candidates',
        exercises: <WorkoutExercise>[
          WorkoutExercise(
            id: 'long-walk',
            name: 'Long Walk',
            sets: 1,
            repsOrDuration: '10 min',
            difficulty: 'Beginner',
            instruction: 'Walk briskly.',
          ),
          WorkoutExercise(
            id: 'burpee-burst',
            name: 'Burpee Burst',
            sets: 1,
            repsOrDuration: '30 sec',
            difficulty: 'Intermediate',
            instruction: 'Complete controlled burpees.',
          ),
        ],
      );

      final routine = generateSmartWorkoutRoutine(
        category: category,
        availableMinutes: 12,
        goal: 'Lose weight',
        intensity: 'High',
      );

      expect(routine.exercises.first.id, 'burpee-burst');
      expect(routine.estimatedMinutes, lessThanOrEqualTo(12));
    });

    test('returns an empty routine when no exercise fits', () {
      const category = WorkoutCategory(
        id: 'no-fit',
        name: 'No Fit',
        description: 'No fitting candidates',
        exercises: <WorkoutExercise>[
          WorkoutExercise(
            id: 'long-session',
            name: 'Long Session',
            sets: 1,
            repsOrDuration: '20 min',
            difficulty: 'Beginner',
            instruction: 'Move steadily.',
          ),
        ],
      );

      final routine = generateSmartWorkoutRoutine(
        category: category,
        availableMinutes: 5,
        goal: 'General fitness',
        intensity: 'Light',
      );

      expect(routine.exercises, isEmpty);
      expect(routine.estimatedMinutes, 0);
      expect(routine.estimatedCalories, 0);
    });
  });
}
