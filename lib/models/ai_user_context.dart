import 'package:nutrisense/models/prototype_data.dart';
import 'package:nutrisense/models/workout_catalog.dart';
import 'package:nutrisense/pages/study/study_models.dart';

enum AiContextSourceStatus { loaded, empty, loading, error, timedOut }

class AiContextSourceState {
  const AiContextSourceState({
    required this.label,
    required this.status,
    this.errorMessage,
  });

  final String label;
  final AiContextSourceStatus status;
  final String? errorMessage;

  bool get hasUsableData =>
      status == AiContextSourceStatus.loaded ||
      status == AiContextSourceStatus.empty;

  String describeUnavailable() {
    return switch (status) {
      AiContextSourceStatus.loading => '$label: currently loading.',
      AiContextSourceStatus.error => '$label: temporarily unavailable.',
      AiContextSourceStatus.timedOut => '$label: timed out while loading.',
      AiContextSourceStatus.empty => '$label: no saved data.',
      AiContextSourceStatus.loaded => '$label: loaded.',
    };
  }
}

class AiUserContext {
  const AiUserContext({
    required this.generatedAt,
    required this.quests,
    required this.studyTasks,
    required this.schedules,
    required this.mealLogs,
    required this.workoutPlans,
    required this.workoutActivities,
    this.workoutCategories = workoutCatalog,
    this.sources = const <String, AiContextSourceState>{},
  });

  factory AiUserContext.empty({
    DateTime? generatedAt,
    Map<String, AiContextSourceState> sources =
        const <String, AiContextSourceState>{},
  }) {
    return AiUserContext(
      generatedAt: generatedAt ?? DateTime.now(),
      quests: const [],
      studyTasks: const [],
      schedules: const [],
      mealLogs: const [],
      workoutPlans: const [],
      workoutActivities: const [],
      sources: sources,
    );
  }

  final DateTime generatedAt;
  final List<DailyQuest> quests;
  final List<StudyTask> studyTasks;
  final List<ClassSchedule> schedules;
  final List<MealLog> mealLogs;
  final List<WorkoutPlan> workoutPlans;
  final List<WorkoutActivity> workoutActivities;
  final List<WorkoutCategory> workoutCategories;
  final Map<String, AiContextSourceState> sources;

  int get completedQuestCount =>
      quests.where((quest) => quest.completed).length;

  int get completedStudyTaskCount =>
      studyTasks.where((task) => task.isCompleted).length;

  bool get hasAnyLoadedUserData {
    return quests.isNotEmpty ||
        studyTasks.isNotEmpty ||
        schedules.isNotEmpty ||
        mealLogs.isNotEmpty ||
        workoutPlans.isNotEmpty ||
        workoutActivities.isNotEmpty ||
        sources.values.any((source) => source.hasUsableData);
  }

  bool get isOnlyWaitingForSources {
    return sources.isNotEmpty &&
        sources.values.every(
          (source) => source.status == AiContextSourceStatus.loading,
        );
  }

  AiUserContext withTimedOutLoadingSources() {
    return AiUserContext(
      generatedAt: generatedAt,
      quests: quests,
      studyTasks: studyTasks,
      schedules: schedules,
      mealLogs: mealLogs,
      workoutPlans: workoutPlans,
      workoutActivities: workoutActivities,
      workoutCategories: workoutCategories,
      sources: sources.map((key, source) {
        if (source.status != AiContextSourceStatus.loading) {
          return MapEntry(key, source);
        }
        return MapEntry(
          key,
          AiContextSourceState(
            label: source.label,
            status: AiContextSourceStatus.timedOut,
          ),
        );
      }),
    );
  }

  String toPromptContext() {
    return [
      'Current Nutrisense user context generated at ${generatedAt.toIso8601String()}.',
      _questSummary(),
      _studyTaskSummary(),
      _scheduleSummary(),
      _mealSummary(),
      _workoutSummary(),
      _workoutCatalogSummary(),
    ].join('\n\n');
  }

  String _questSummary() {
    final unavailable = _unavailableSummary('quests');
    if (unavailable != null) return 'Daily quests: $unavailable';
    if (quests.isEmpty) {
      return 'Daily quests: No daily quests are logged for today.';
    }

    final lines = quests
        .take(8)
        .map(
          (quest) =>
              '- ${quest.title}: ${quest.completed ? 'completed' : 'open'}'
              '${quest.description.isEmpty ? '' : ' (${quest.description})'}',
        )
        .join('\n');

    return 'Daily quests: $completedQuestCount/${quests.length} completed.\n$lines';
  }

  String _studyTaskSummary() {
    final unavailable = _unavailableSummary('studyTasks');
    if (unavailable != null) return 'Study tasks: $unavailable';
    if (studyTasks.isEmpty) {
      return 'Study tasks: No study tasks are logged.';
    }

    final lines = studyTasks
        .take(10)
        .map((task) {
          final due = task.dueAt == null
              ? ''
              : ', due ${task.dueAt!.toLocal().toIso8601String()}';
          return '- ${task.title}: ${task.isCompleted ? 'completed' : 'open'}$due';
        })
        .join('\n');

    return 'Study tasks: $completedStudyTaskCount/${studyTasks.length} completed.\n$lines';
  }

  String _scheduleSummary() {
    final unavailable = _unavailableSummary('schedules');
    if (unavailable != null) return 'Class schedule: $unavailable';
    if (schedules.isEmpty) {
      return 'Class schedule: No saved class schedule.';
    }

    final lines = schedules
        .map((item) {
          final course = item.courseCode.isEmpty ? '' : ' (${item.courseCode})';
          final location = item.location.isEmpty ? '' : ', ${item.location}';
          return '- ${item.dayOfWeek}: ${item.title}$course, ${item.timeLabel}$location';
        })
        .join('\n');

    return 'Class schedule:\n$lines';
  }

  String _mealSummary() {
    final unavailable = _unavailableSummary('mealLogs');
    if (unavailable != null) return 'Meal logs: $unavailable';
    if (mealLogs.isEmpty) {
      return 'Meal logs: No logged meals.';
    }

    final lines = mealLogs
        .take(10)
        .map((meal) {
          final ingredients = meal.ingredients.isEmpty
              ? 'no ingredients listed'
              : meal.ingredients.join(', ');
          return '- ${meal.mealType}: ${meal.mealName}, ${meal.caloriesEstimate} kcal, ${meal.proteinEstimate}g protein, ingredients: $ingredients';
        })
        .join('\n');

    return 'Recent meal logs:\n$lines';
  }

  String _workoutSummary() {
    final parts = <String>[];
    final workoutPlansUnavailable = _unavailableSummary('workoutPlans');
    final workoutActivitiesUnavailable = _unavailableSummary(
      'workoutActivities',
    );
    if (workoutPlansUnavailable != null) {
      parts.add('Saved workout plans: $workoutPlansUnavailable');
    } else if (workoutPlans.isEmpty) {
      parts.add('Saved workout plans: No saved workout plans.');
    } else {
      final lines = workoutPlans
          .take(8)
          .map((plan) {
            final exercises = plan.exercises
                .map((exercise) => exercise['name']?.toString() ?? '')
                .where((name) => name.isNotEmpty)
                .take(6)
                .join(', ');
            return '- ${plan.title}: ${plan.category}, ${plan.durationMinutes} min, ${plan.completed ? 'completed' : 'open'}, exercises: ${exercises.isEmpty ? 'none listed' : exercises}';
          })
          .join('\n');
      parts.add('Saved workout plans:\n$lines');
    }

    if (workoutActivitiesUnavailable != null) {
      parts.add('Workout history: $workoutActivitiesUnavailable');
    } else if (workoutActivities.isEmpty) {
      parts.add('Workout history: No logged workout activity.');
    } else {
      final lines = workoutActivities
          .take(10)
          .map(
            (activity) =>
                '- ${activity.title}: ${activity.type}, ${activity.durationMinutes} min, ${activity.intensity}',
          )
          .join('\n');
      parts.add('Workout history:\n$lines');
    }

    return parts.join('\n');
  }

  String? _unavailableSummary(String key) {
    final source = sources[key];
    if (source == null) return null;
    return switch (source.status) {
      AiContextSourceStatus.loading =>
        'currently loading; no confirmed records available yet.',
      AiContextSourceStatus.error =>
        'temporarily unavailable; do not infer records.',
      AiContextSourceStatus.timedOut =>
        'timed out while loading; use other available context and do not infer records.',
      AiContextSourceStatus.loaded || AiContextSourceStatus.empty => null,
    };
  }

  String _workoutCatalogSummary() {
    final lines = workoutCategories
        .map((category) {
          final exercises = category.exercises
              .map(
                (exercise) =>
                    '${exercise.name} (${exercise.difficulty}, ${exercise.sets} sets, ${exercise.repsOrDuration}; ${exercise.instruction})',
              )
              .join('; ');
          return '- ${category.name}: ${category.description} Available exercises: $exercises';
        })
        .join('\n');

    return 'Allowed in-app workout catalog. For workout recommendations, only use these categories and exercises. If the user asks for something unavailable, suggest the closest available option.\n$lines';
  }
}

class AiContextBuilder {
  const AiContextBuilder();

  AiUserContext build({
    required List<DailyQuest> quests,
    required List<StudyTask> studyTasks,
    required List<ClassSchedule> schedules,
    required List<MealLog> mealLogs,
    required List<WorkoutPlan> workoutPlans,
    required List<WorkoutActivity> workoutActivities,
    Map<String, AiContextSourceState> sources =
        const <String, AiContextSourceState>{},
    DateTime? generatedAt,
  }) {
    return AiUserContext(
      generatedAt: generatedAt ?? DateTime.now(),
      quests: quests,
      studyTasks: studyTasks,
      schedules: schedules,
      mealLogs: mealLogs,
      workoutPlans: workoutPlans,
      workoutActivities: workoutActivities,
      sources: sources,
    );
  }
}
