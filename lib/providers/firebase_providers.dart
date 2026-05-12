import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:nutrisense/models/ai_user_context.dart';
import 'package:nutrisense/models/prototype_data.dart';
import 'package:nutrisense/models/user_profile.dart';
import 'package:nutrisense/pages/study/study_models.dart';
import 'package:nutrisense/pages/study/study_repository.dart';
import 'package:nutrisense/services/auth_service.dart';
import 'package:nutrisense/services/goals_service.dart';
import 'package:nutrisense/services/groq_ai_service.dart';
import 'package:nutrisense/services/macro_calculator.dart';
import 'package:nutrisense/services/nutrition_service.dart';
import 'package:nutrisense/services/profile_service.dart';
import 'package:nutrisense/services/prototype_data_service.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firebaseFirestoreProvider),
  );
});

final goalsServiceProvider = Provider<GoalsService>((ref) {
  return GoalsService(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firebaseFirestoreProvider),
  );
});

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firebaseFirestoreProvider),
  );
});

final prototypeDataServiceProvider = Provider<PrototypeDataService>((ref) {
  return PrototypeDataService(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firebaseFirestoreProvider),
  );
});

final studyRepositoryProvider = Provider<StudyRepository>((ref) {
  return StudyRepository(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firebaseFirestoreProvider),
  );
});

final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) {
  return ref.watch(profileServiceProvider).watchCurrentUserProfile();
});

final nutritionServiceProvider = Provider<NutritionService>((ref) {
  return NutritionService(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firebaseFirestoreProvider),
  );
});

final groqAiServiceProvider = Provider<GroqAiService>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return GroqAiService(client: client);
});

final healthProfileProvider = StreamProvider<HealthProfile?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.asData?.value;
  if (user == null) return Stream.value(null);
  return ref.watch(prototypeDataServiceProvider).watchHealthProfile();
});

final dailyMacrosProvider = FutureProvider<DailyMacros?>((ref) {
  return ref.watch(profileServiceProvider).getDailyMacros();
});

final schedulesProvider = StreamProvider<List<ClassSchedule>>((ref) {
  return ref.watch(prototypeDataServiceProvider).watchSchedules();
});

final studyTasksProvider = StreamProvider<List<StudyTask>>((ref) {
  return ref.watch(studyRepositoryProvider).watchTasks();
});

final todayQuestsProvider = StreamProvider<List<DailyQuest>>((ref) {
  return ref.watch(prototypeDataServiceProvider).watchTodayQuests();
});

final enabledRemindersProvider = StreamProvider<List<AppReminder>>((ref) {
  return ref.watch(prototypeDataServiceProvider).watchEnabledReminders();
});

final remindersProvider = StreamProvider<List<AppReminder>>((ref) {
  return ref.watch(prototypeDataServiceProvider).watchReminders();
});

final workoutPlansProvider = StreamProvider<List<WorkoutPlan>>((ref) {
  return ref.watch(prototypeDataServiceProvider).watchWorkoutPlans();
});

final workoutActivitiesProvider = StreamProvider<List<WorkoutActivity>>((ref) {
  return ref.watch(prototypeDataServiceProvider).watchWorkoutActivities();
});

final mealLogsProvider = StreamProvider<List<MealLog>>((ref) {
  return ref.watch(prototypeDataServiceProvider).watchMealLogs();
});

final journalEntriesProvider = StreamProvider<List<JournalRecord>>((ref) {
  return ref.watch(prototypeDataServiceProvider).watchJournalEntries();
});

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) {
  return ref.watch(prototypeDataServiceProvider).loadDashboardStats();
});

final aiContextBuilderProvider = Provider<AiContextBuilder>((ref) {
  return const AiContextBuilder();
});

final aiUserContextProvider = Provider<AiUserContext>((ref) {
  final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
  _logAiContext('loading started for uid=${uid ?? 'none'}');

  final quests = ref.watch(todayQuestsProvider);
  final studyTasks = ref.watch(studyTasksProvider);
  final schedules = ref.watch(schedulesProvider);
  final mealLogs = ref.watch(mealLogsProvider);
  final workoutPlans = ref.watch(workoutPlansProvider);
  final workoutActivities = ref.watch(workoutActivitiesProvider);

  final questSource = _sourceState('quests', 'Daily quests', quests);
  final studyTaskSource = _sourceState('studyTasks', 'Study tasks', studyTasks);
  final scheduleSource = _sourceState('schedules', 'Class schedule', schedules);
  final mealLogSource = _sourceState('mealLogs', 'Meal logs', mealLogs);
  final workoutPlanSource = _sourceState(
    'workoutPlans',
    'Workout plans',
    workoutPlans,
  );
  final workoutActivitySource = _sourceState(
    'workoutActivities',
    'Workout history',
    workoutActivities,
  );

  return ref
      .watch(aiContextBuilderProvider)
      .build(
        quests: _dataOrEmpty(quests),
        studyTasks: _dataOrEmpty(studyTasks),
        schedules: _dataOrEmpty(schedules),
        mealLogs: _dataOrEmpty(mealLogs),
        workoutPlans: _dataOrEmpty(workoutPlans),
        workoutActivities: _dataOrEmpty(workoutActivities),
        sources: {
          'quests': questSource,
          'studyTasks': studyTaskSource,
          'schedules': scheduleSource,
          'mealLogs': mealLogSource,
          'workoutPlans': workoutPlanSource,
          'workoutActivities': workoutActivitySource,
        },
      );
});

List<T> _dataOrEmpty<T>(AsyncValue<List<T>> value) {
  return value.asData?.value ?? List<T>.empty(growable: false);
}

AiContextSourceState _sourceState<T>(
  String key,
  String label,
  AsyncValue<List<T>> value,
) {
  if (value.hasError) {
    _logAiContext('$key failed: ${value.error}');
    return AiContextSourceState(
      label: label,
      status: AiContextSourceStatus.error,
      errorMessage: value.error.toString(),
    );
  }

  final data = value.asData?.value;
  if (data == null) {
    _logAiContext('$key loading');
    return AiContextSourceState(
      label: label,
      status: AiContextSourceStatus.loading,
    );
  }

  if (data.isEmpty) {
    _logAiContext('$key returned empty data');
    return AiContextSourceState(
      label: label,
      status: AiContextSourceStatus.empty,
    );
  }

  _logAiContext('$key returned ${data.length} item(s)');
  return AiContextSourceState(
    label: label,
    status: AiContextSourceStatus.loaded,
  );
}

void _logAiContext(String message) {
  debugPrint('[AI context] $message');
}
