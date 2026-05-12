import 'package:nutrisense/models/workout_catalog.dart';

class SmartWorkoutRoutine {
  const SmartWorkoutRoutine({
    required this.exercises,
    required this.estimatedMinutes,
    required this.estimatedCalories,
  });

  final List<WorkoutExercise> exercises;
  final int estimatedMinutes;
  final int estimatedCalories;
}

class _ScoredExercise {
  const _ScoredExercise({
    required this.exercise,
    required this.catalogIndex,
    required this.minutes,
    required this.calories,
    required this.benefit,
  });

  final WorkoutExercise exercise;
  final int catalogIndex;
  final int minutes;
  final int calories;
  final double benefit;

  double get benefitPerMinute => benefit / minutes;
}

SmartWorkoutRoutine generateSmartWorkoutRoutine({
  required WorkoutCategory category,
  required int availableMinutes,
  required String goal,
  required String intensity,
}) {
  final timeLimit = availableMinutes.clamp(0, 180).toInt();
  final scored = <_ScoredExercise>[];
  final seenIds = <String>{};

  for (var i = 0; i < category.exercises.length; i++) {
    final exercise = category.exercises[i];
    if (!seenIds.add(exercise.id)) continue;

    final minutes = estimatedExerciseMinutes(exercise);
    if (minutes <= 0 || minutes > timeLimit) continue;

    final calories = _estimatedExerciseCalories(exercise, intensity);
    scored.add(
      _ScoredExercise(
        exercise: exercise,
        catalogIndex: i,
        minutes: minutes,
        calories: calories,
        benefit: _benefitScore(
          exercise: exercise,
          minutes: minutes,
          calories: calories,
          goal: goal,
          intensity: intensity,
        ),
      ),
    );
  }

  scored.sort((a, b) {
    final valueCompare = b.benefitPerMinute.compareTo(a.benefitPerMinute);
    if (valueCompare != 0) return valueCompare;

    final benefitCompare = b.benefit.compareTo(a.benefit);
    if (benefitCompare != 0) return benefitCompare;

    return a.catalogIndex.compareTo(b.catalogIndex);
  });

  final selected = <WorkoutExercise>[];
  var totalMinutes = 0;
  var totalCalories = 0;

  for (final item in scored) {
    // Greedy Approach: take the best remaining value-per-minute exercise
    // whenever it still fits in the user's available workout time.
    if (totalMinutes + item.minutes > timeLimit) continue;
    selected.add(item.exercise);
    totalMinutes += item.minutes;
    totalCalories += item.calories;
  }

  return SmartWorkoutRoutine(
    exercises: selected,
    estimatedMinutes: totalMinutes,
    estimatedCalories: totalCalories,
  );
}

int estimatedExerciseMinutes(WorkoutExercise exercise) {
  final value = exercise.repsOrDuration.toLowerCase();
  final explicitMinutes = RegExp(r'(\d+)\s*min').firstMatch(value);
  if (explicitMinutes != null) {
    final minutes = int.tryParse(explicitMinutes.group(1) ?? '') ?? 5;
    return (minutes * exercise.sets).clamp(1, 180).toInt();
  }

  if (value.contains('sec')) {
    return (exercise.sets * 2).clamp(1, 180).toInt();
  }

  return (exercise.sets * 3).clamp(1, 180).toInt();
}

double _benefitScore({
  required WorkoutExercise exercise,
  required int minutes,
  required int calories,
  required String goal,
  required String intensity,
}) {
  final difficulty = _difficultyScore(exercise.difficulty);
  final intensityScore = _intensityScore(intensity);
  final goalBoost = _goalBoost(exercise, goal);
  final durationValue = minutes * 1.5;

  return calories +
      (difficulty * 14) +
      (intensityScore * 8) +
      goalBoost +
      durationValue;
}

int _estimatedExerciseCalories(WorkoutExercise exercise, String intensity) {
  final factor = switch (_intensityScore(intensity)) {
    3 => 8,
    1 => 4,
    _ => 6,
  };
  final difficultyBonus = (_difficultyScore(exercise.difficulty) - 1) * 2;
  return (estimatedExerciseMinutes(exercise) * (factor + difficultyBonus))
      .clamp(1, 999)
      .toInt();
}

int _difficultyScore(String difficulty) {
  return switch (difficulty.toLowerCase()) {
    'advanced' => 3,
    'intermediate' => 2,
    _ => 1,
  };
}

int _intensityScore(String intensity) {
  return switch (intensity.toLowerCase()) {
    'high' || 'intense' => 3,
    'light' || 'low' => 1,
    _ => 2,
  };
}

double _goalBoost(WorkoutExercise exercise, String goal) {
  final normalizedGoal = goal.toLowerCase();
  final haystack = <String>[
    exercise.name,
    exercise.id,
    exercise.instruction,
    exercise.difficulty,
    ...exercise.tags,
  ].join(' ').toLowerCase();

  if (normalizedGoal.contains('weight')) {
    if (_containsAny(haystack, const [
      'jump',
      'jog',
      'knee',
      'burpee',
      'climber',
      'walk',
    ])) {
      return 18;
    }
  }
  if (normalizedGoal.contains('strength')) {
    if (_containsAny(haystack, const [
      'push',
      'squat',
      'lunge',
      'bridge',
      'dip',
      'raise',
    ])) {
      return 18;
    }
  }
  if (normalizedGoal.contains('flex')) {
    if (_containsAny(haystack, const ['stretch', 'pose', 'mobility'])) {
      return 18;
    }
  }
  if (normalizedGoal.contains('general')) {
    return 6;
  }
  return 0;
}

bool _containsAny(String value, List<String> needles) {
  return needles.any((needle) => value.contains(needle));
}
