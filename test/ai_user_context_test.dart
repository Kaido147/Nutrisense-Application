import 'package:flutter_test/flutter_test.dart';
import 'package:nutrisense/models/ai_user_context.dart';
import 'package:nutrisense/models/prototype_data.dart';
import 'package:nutrisense/pages/study/study_models.dart';

void main() {
  test('empty context tells AI there is no logged data', () {
    final context = AiUserContext(
      generatedAt: DateTime(2026, 5, 12),
      quests: const [],
      studyTasks: const [],
      schedules: const [],
      mealLogs: const [],
      workoutPlans: const [],
      workoutActivities: const [],
    );

    final prompt = context.toPromptContext();

    expect(prompt, contains('No daily quests are logged for today'));
    expect(prompt, contains('No study tasks are logged'));
    expect(prompt, contains('No saved class schedule'));
    expect(prompt, contains('No logged meals'));
    expect(prompt, contains('No saved workout plans'));
    expect(prompt, contains('No logged workout activity'));
  });

  test('context includes counts and real app data summaries', () {
    final context = AiUserContext(
      generatedAt: DateTime(2026, 5, 12),
      quests: const [
        DailyQuest(
          id: 'quest-1',
          dateKey: '2026-05-12',
          type: 'meal',
          title: 'Log a meal',
          description: 'Log one meal.',
          targetValue: 1,
          currentValue: 1,
          completed: true,
          completedAt: null,
        ),
        DailyQuest(
          id: 'quest-2',
          dateKey: '2026-05-12',
          type: 'study',
          title: 'Study block',
          description: 'Finish one focus block.',
          targetValue: 1,
          currentValue: 0,
          completed: false,
          completedAt: null,
        ),
      ],
      studyTasks: [
        StudyTask(
          id: 'task-1',
          title: 'Read chapter 4',
          subject: 'Biology',
          isCompleted: false,
          dueAt: DateTime(2026, 5, 13),
        ),
      ],
      schedules: [
        ClassSchedule(
          id: 'class-1',
          title: 'Biology',
          courseCode: 'BIO101',
          dayOfWeek: 'Tuesday',
          dayIndex: 1,
          startTimeMinutes: 9 * 60,
          endTimeMinutes: 10 * 60,
          timeLabel: '9:00 AM - 10:00 AM',
          location: 'Room 204',
          color: 'blue',
          createdAt: null,
          updatedAt: null,
        ),
      ],
      mealLogs: const [
        MealLog(
          id: 'meal-1',
          mealName: 'Chicken Rice',
          mealType: 'Lunch',
          ingredients: ['chicken', 'rice'],
          caloriesEstimate: 520,
          proteinEstimate: 32,
          tags: [],
          loggedAt: null,
        ),
      ],
      workoutPlans: const [
        WorkoutPlan(
          id: 'plan-1',
          title: 'Core Starter',
          category: 'Core',
          source: 'generated',
          dateKey: '2026-05-12',
          durationMinutes: 20,
          intensity: 'Moderate',
          fitnessGoal: 'General fitness',
          activityLevel: 'Moderate',
          exercises: [
            {'name': 'Plank', 'completed': false},
          ],
          completed: false,
          completedAt: null,
          createdAt: null,
        ),
      ],
      workoutActivities: const [
        WorkoutActivity(
          id: 'activity-1',
          title: 'Morning Walk',
          type: 'Cardio',
          dateKey: '2026-05-12',
          durationMinutes: 15,
          intensity: 'Low',
          calories: 80,
          notes: null,
          source: 'manual',
          completedAt: null,
          createdAt: null,
        ),
      ],
    );

    final prompt = context.toPromptContext();

    expect(prompt, contains('Daily quests: 1/2 completed'));
    expect(prompt, contains('Study tasks: 0/1 completed'));
    expect(prompt, contains('Biology (BIO101)'));
    expect(prompt, contains('Chicken Rice'));
    expect(prompt, contains('Core Starter'));
    expect(prompt, contains('Morning Walk'));
  });

  test('context includes only available workout catalog exercises', () {
    final context = AiUserContext(
      generatedAt: DateTime(2026, 5, 12),
      quests: const [],
      studyTasks: const [],
      schedules: const [],
      mealLogs: const [],
      workoutPlans: const [],
      workoutActivities: const [],
    );

    final prompt = context.toPromptContext();

    expect(prompt, contains('Allowed in-app workout catalog'));
    expect(prompt, contains('Bodyweight Squats'));
    expect(prompt, contains('Push-ups'));
    expect(prompt, isNot(contains('Barbell Snatch')));
  });

  test(
    'context marks unavailable and timed out sources without inventing data',
    () {
      final context = AiUserContext.empty(
        generatedAt: DateTime(2026, 5, 12),
        sources: const {
          'mealLogs': AiContextSourceState(
            label: 'Meal logs',
            status: AiContextSourceStatus.error,
          ),
          'schedules': AiContextSourceState(
            label: 'Class schedule',
            status: AiContextSourceStatus.loading,
          ),
        },
      ).withTimedOutLoadingSources();

      final prompt = context.toPromptContext();

      expect(prompt, contains('Meal logs: temporarily unavailable'));
      expect(prompt, contains('Class schedule: timed out while loading'));
      expect(prompt, contains('Allowed in-app workout catalog'));
    },
  );
}
