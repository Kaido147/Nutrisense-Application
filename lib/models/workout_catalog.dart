class WorkoutExercise {
  const WorkoutExercise({
    required this.id,
    required this.name,
    required this.sets,
    required this.repsOrDuration,
    required this.difficulty,
    required this.instruction,
    this.tags = const <String>[],
  });

  final String id;
  final String name;
  final int sets;
  final String repsOrDuration;
  final String difficulty;
  final String instruction;
  final List<String> tags;

  Map<String, dynamic> toPlanMap() {
    return {
      'id': id,
      'name': name,
      'sets': sets,
      'reps': repsOrDuration,
      'difficulty': difficulty,
      'instruction': instruction,
      'tags': tags,
      'completed': false,
    };
  }
}

class WorkoutCategory {
  const WorkoutCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.exercises,
  });

  final String id;
  final String name;
  final String description;
  final List<WorkoutExercise> exercises;
}

class WorkoutPlanDraft {
  const WorkoutPlanDraft({
    required this.title,
    required this.category,
    required this.source,
    required this.durationMinutes,
    required this.intensity,
    required this.fitnessGoal,
    required this.activityLevel,
    required this.exercises,
  });

  final String title;
  final String category;
  final String source;
  final int durationMinutes;
  final String intensity;
  final String fitnessGoal;
  final String activityLevel;
  final List<WorkoutExercise> exercises;

  List<Map<String, dynamic>> get planExercises {
    return exercises.map((exercise) => exercise.toPlanMap()).toList();
  }
}

const workoutCatalog = <WorkoutCategory>[
  WorkoutCategory(
    id: 'full-body',
    name: 'Full Body',
    description: 'Balanced movements for the whole body.',
    exercises: <WorkoutExercise>[
      WorkoutExercise(
        id: 'bodyweight-squats',
        name: 'Bodyweight Squats',
        sets: 3,
        repsOrDuration: '12 reps',
        difficulty: 'Beginner',
        instruction: 'Keep your chest tall and sit your hips back.',
      ),
      WorkoutExercise(
        id: 'push-ups',
        name: 'Push-ups',
        sets: 3,
        repsOrDuration: '8-10 reps',
        difficulty: 'Beginner',
        instruction: 'Lower with control; use knees if needed.',
      ),
      WorkoutExercise(
        id: 'plank',
        name: 'Plank',
        sets: 3,
        repsOrDuration: '30 sec',
        difficulty: 'Beginner',
        instruction: 'Brace your core and keep a straight line.',
      ),
      WorkoutExercise(
        id: 'jumping-jacks',
        name: 'Jumping Jacks',
        sets: 3,
        repsOrDuration: '45 sec',
        difficulty: 'Beginner',
        instruction: 'Move lightly and keep a steady rhythm.',
      ),
    ],
  ),
  WorkoutCategory(
    id: 'upper-body',
    name: 'Upper Body',
    description: 'Simple chest, shoulder, and arm exercises.',
    exercises: <WorkoutExercise>[
      WorkoutExercise(
        id: 'push-ups-upper',
        name: 'Push-ups',
        sets: 3,
        repsOrDuration: '8-10 reps',
        difficulty: 'Beginner',
        instruction: 'Keep hands under shoulders and elbows controlled.',
      ),
      WorkoutExercise(
        id: 'shoulder-taps',
        name: 'Shoulder Taps',
        sets: 3,
        repsOrDuration: '10 each side',
        difficulty: 'Beginner',
        instruction: 'Avoid rocking your hips while tapping shoulders.',
      ),
      WorkoutExercise(
        id: 'arm-circles',
        name: 'Arm Circles',
        sets: 2,
        repsOrDuration: '45 sec',
        difficulty: 'Beginner',
        instruction: 'Make controlled circles forward and backward.',
      ),
      WorkoutExercise(
        id: 'tricep-dips',
        name: 'Tricep Dips',
        sets: 3,
        repsOrDuration: '10 reps',
        difficulty: 'Beginner',
        instruction: 'Use a stable chair and lower slowly.',
      ),
    ],
  ),
  WorkoutCategory(
    id: 'lower-body',
    name: 'Lower Body',
    description: 'Leg and glute strength without equipment.',
    exercises: <WorkoutExercise>[
      WorkoutExercise(
        id: 'squats-lower',
        name: 'Squats',
        sets: 3,
        repsOrDuration: '12 reps',
        difficulty: 'Beginner',
        instruction: 'Push through your heels and stand tall.',
      ),
      WorkoutExercise(
        id: 'lunges',
        name: 'Lunges',
        sets: 3,
        repsOrDuration: '10 each leg',
        difficulty: 'Beginner',
        instruction: 'Step far enough to keep the front knee stable.',
      ),
      WorkoutExercise(
        id: 'glute-bridges',
        name: 'Glute Bridges',
        sets: 3,
        repsOrDuration: '15 reps',
        difficulty: 'Beginner',
        instruction: 'Squeeze glutes at the top without arching your back.',
      ),
      WorkoutExercise(
        id: 'calf-raises',
        name: 'Calf Raises',
        sets: 3,
        repsOrDuration: '15 reps',
        difficulty: 'Beginner',
        instruction: 'Rise slowly and pause at the top.',
      ),
    ],
  ),
  WorkoutCategory(
    id: 'core',
    name: 'Core',
    description: 'Core stability and control for beginners.',
    exercises: <WorkoutExercise>[
      WorkoutExercise(
        id: 'plank-core',
        name: 'Plank',
        sets: 3,
        repsOrDuration: '30 sec',
        difficulty: 'Beginner',
        instruction: 'Keep ribs down and breathe steadily.',
      ),
      WorkoutExercise(
        id: 'crunches',
        name: 'Crunches',
        sets: 3,
        repsOrDuration: '12 reps',
        difficulty: 'Beginner',
        instruction: 'Lift shoulders gently without pulling your neck.',
      ),
      WorkoutExercise(
        id: 'leg-raises',
        name: 'Leg Raises',
        sets: 3,
        repsOrDuration: '10 reps',
        difficulty: 'Beginner',
        instruction: 'Lower legs slowly and keep your back supported.',
      ),
      WorkoutExercise(
        id: 'mountain-climbers-core',
        name: 'Mountain Climbers',
        sets: 3,
        repsOrDuration: '30 sec',
        difficulty: 'Beginner',
        instruction: 'Drive knees forward while keeping shoulders stacked.',
      ),
    ],
  ),
  WorkoutCategory(
    id: 'cardio',
    name: 'Cardio',
    description: 'Quick heart-rate boosters for busy days.',
    exercises: <WorkoutExercise>[
      WorkoutExercise(
        id: 'jumping-jacks-cardio',
        name: 'Jumping Jacks',
        sets: 3,
        repsOrDuration: '45 sec',
        difficulty: 'Beginner',
        instruction: 'Land softly and keep your pace comfortable.',
      ),
      WorkoutExercise(
        id: 'high-knees',
        name: 'High Knees',
        sets: 3,
        repsOrDuration: '40 sec',
        difficulty: 'Beginner',
        instruction: 'Lift knees toward hip height while pumping arms.',
      ),
      WorkoutExercise(
        id: 'burpees',
        name: 'Burpees',
        sets: 3,
        repsOrDuration: '6 reps',
        difficulty: 'Intermediate',
        instruction: 'Step back instead of jumping if needed.',
      ),
      WorkoutExercise(
        id: 'jog-in-place',
        name: 'Jog in Place',
        sets: 3,
        repsOrDuration: '60 sec',
        difficulty: 'Beginner',
        instruction: 'Stay light on your feet and breathe evenly.',
      ),
    ],
  ),
  WorkoutCategory(
    id: 'stretching',
    name: 'Stretching',
    description: 'Gentle mobility for recovery and study breaks.',
    exercises: <WorkoutExercise>[
      WorkoutExercise(
        id: 'neck-stretch',
        name: 'Neck Stretch',
        sets: 2,
        repsOrDuration: '30 sec each side',
        difficulty: 'Beginner',
        instruction: 'Move gently and avoid pulling hard.',
      ),
      WorkoutExercise(
        id: 'hamstring-stretch',
        name: 'Hamstring Stretch',
        sets: 2,
        repsOrDuration: '45 sec each leg',
        difficulty: 'Beginner',
        instruction: 'Hinge at the hips and keep the stretch mild.',
      ),
      WorkoutExercise(
        id: 'shoulder-stretch',
        name: 'Shoulder Stretch',
        sets: 2,
        repsOrDuration: '30 sec each side',
        difficulty: 'Beginner',
        instruction: 'Relax your shoulder away from your ear.',
      ),
      WorkoutExercise(
        id: 'childs-pose',
        name: 'Child’s Pose',
        sets: 2,
        repsOrDuration: '45 sec',
        difficulty: 'Beginner',
        instruction: 'Reach forward and breathe into your back.',
      ),
    ],
  ),
  WorkoutCategory(
    id: 'beginner-workout',
    name: 'Beginner Workout',
    description: 'Low-pressure starter routine.',
    exercises: <WorkoutExercise>[
      WorkoutExercise(
        id: 'wall-push-ups',
        name: 'Wall Push-ups',
        sets: 3,
        repsOrDuration: '10 reps',
        difficulty: 'Beginner',
        instruction: 'Stand tall and press away from a wall.',
      ),
      WorkoutExercise(
        id: 'sit-to-stand',
        name: 'Sit to Stand',
        sets: 3,
        repsOrDuration: '10 reps',
        difficulty: 'Beginner',
        instruction: 'Stand from a chair without using momentum.',
      ),
      WorkoutExercise(
        id: 'march-in-place',
        name: 'March in Place',
        sets: 3,
        repsOrDuration: '45 sec',
        difficulty: 'Beginner',
        instruction: 'Keep posture tall and arms relaxed.',
      ),
      WorkoutExercise(
        id: 'easy-plank',
        name: 'Knee Plank',
        sets: 3,
        repsOrDuration: '20 sec',
        difficulty: 'Beginner',
        instruction: 'Brace gently and keep shoulders over elbows.',
      ),
    ],
  ),
  WorkoutCategory(
    id: 'weight-loss',
    name: 'Weight Loss',
    description: 'Steady movement with simple strength work.',
    exercises: <WorkoutExercise>[
      WorkoutExercise(
        id: 'fast-walk',
        name: 'Fast Walk',
        sets: 1,
        repsOrDuration: '10 min',
        difficulty: 'Beginner',
        instruction: 'Walk briskly while still able to speak.',
      ),
      WorkoutExercise(
        id: 'step-jacks',
        name: 'Step Jacks',
        sets: 3,
        repsOrDuration: '45 sec',
        difficulty: 'Beginner',
        instruction: 'Step side to side instead of jumping.',
      ),
      WorkoutExercise(
        id: 'reverse-lunges',
        name: 'Reverse Lunges',
        sets: 3,
        repsOrDuration: '8 each leg',
        difficulty: 'Beginner',
        instruction: 'Step backward and keep your front foot planted.',
      ),
      WorkoutExercise(
        id: 'mountain-climbers-weight',
        name: 'Mountain Climbers',
        sets: 3,
        repsOrDuration: '30 sec',
        difficulty: 'Beginner',
        instruction: 'Move at a pace you can control.',
      ),
    ],
  ),
  WorkoutCategory(
    id: 'strength-training',
    name: 'Strength Training',
    description: 'Bodyweight strength fundamentals.',
    exercises: <WorkoutExercise>[
      WorkoutExercise(
        id: 'tempo-squats',
        name: 'Tempo Squats',
        sets: 3,
        repsOrDuration: '10 reps',
        difficulty: 'Beginner',
        instruction: 'Lower for three counts, then stand.',
      ),
      WorkoutExercise(
        id: 'incline-push-ups',
        name: 'Incline Push-ups',
        sets: 3,
        repsOrDuration: '8 reps',
        difficulty: 'Beginner',
        instruction: 'Use a desk or bench to make push-ups easier.',
      ),
      WorkoutExercise(
        id: 'single-leg-bridge',
        name: 'Single-leg Bridge',
        sets: 2,
        repsOrDuration: '8 each side',
        difficulty: 'Intermediate',
        instruction: 'Keep hips level as you lift.',
      ),
      WorkoutExercise(
        id: 'dead-bug',
        name: 'Dead Bug',
        sets: 3,
        repsOrDuration: '8 each side',
        difficulty: 'Beginner',
        instruction: 'Move opposite arm and leg while keeping your back down.',
      ),
    ],
  ),
];

WorkoutCategory workoutCategoryByName(String category) {
  return workoutCatalog.firstWhere(
    (item) => item.name.toLowerCase() == category.trim().toLowerCase(),
    orElse: () => workoutCatalog.first,
  );
}
