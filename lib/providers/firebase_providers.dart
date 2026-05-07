import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrisense/models/prototype_data.dart';
import 'package:nutrisense/models/user_profile.dart';
import 'package:nutrisense/services/auth_service.dart';
import 'package:nutrisense/services/goals_service.dart';
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

final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) {
  return ref.watch(profileServiceProvider).watchCurrentUserProfile();
});

final nutritionServiceProvider = Provider<NutritionService>((ref) {
  return NutritionService(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firebaseFirestoreProvider),
  );
});

final healthProfileProvider = StreamProvider<HealthProfile?>((ref) {
  return ref.watch(prototypeDataServiceProvider).watchHealthProfile();
});

final dailyMacrosProvider = FutureProvider<DailyMacros?>((ref) {
  return ref.watch(profileServiceProvider).getDailyMacros();
});

final schedulesProvider = StreamProvider<List<ClassSchedule>>((ref) {
  return ref.watch(prototypeDataServiceProvider).watchSchedules();
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
