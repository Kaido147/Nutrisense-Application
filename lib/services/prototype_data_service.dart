import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutrisense/models/prototype_data.dart';
import 'package:nutrisense/models/workout_catalog.dart';

class PrototypeDataException implements Exception {
  const PrototypeDataException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PrototypeDataService {
  const PrototypeDataService({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  }) : _auth = auth,
       _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<HealthProfile?> watchHealthProfile() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);
    return _userDoc(
      user.uid,
    ).collection('healthProfile').doc('current').snapshots().map((snapshot) {
      final data = snapshot.data();
      return data == null ? null : HealthProfile.fromMap(data);
    });
  }

  Future<void> saveHealthProfile(HealthProfile profile) async {
    final user = _requireUser();
    await _userDoc(user.uid)
        .collection('healthProfile')
        .doc('current')
        .set(profile.toFirestore(), SetOptions(merge: true));
    await _userDoc(user.uid).set({
      'healthProfileCompleted': true,
      'healthProfileUpdatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<ClassSchedule>> watchSchedules() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value(const <ClassSchedule>[]);
      return _userDoc(user.uid).collection('schedules').snapshots().map((
        snapshot,
      ) {
        final schedules = snapshot.docs
            .map(ClassSchedule.fromFirestore)
            .toList(growable: false);
        return _sortSchedules(schedules);
      });
    });
  }

  Future<void> addSchedule({
    required String title,
    required String courseCode,
    required String dayOfWeek,
    required int startTimeMinutes,
    required int endTimeMinutes,
    required String timeLabel,
    required String location,
  }) async {
    final user = _requireUser();
    if (title.trim().isEmpty) {
      throw const PrototypeDataException('Please enter a class title.');
    }
    if (endTimeMinutes <= startTimeMinutes) {
      throw const PrototypeDataException('End time must be after start time.');
    }

    await _userDoc(user.uid).collection('schedules').add({
      'title': title.trim(),
      'courseCode': courseCode.trim(),
      'dayOfWeek': dayOfWeek,
      'dayIndex': weekdayIndex(dayOfWeek),
      'startTimeMinutes': startTimeMinutes,
      'endTimeMinutes': endTimeMinutes,
      'timeLabel': timeLabel,
      'location': location.trim(),
      'color': _scheduleColorFor(dayOfWeek),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<ClassSchedule>> loadSchedules() async {
    final user = _requireUser();
    final snapshot = await _userDoc(user.uid).collection('schedules').get();
    return _sortSchedules(
      snapshot.docs.map(ClassSchedule.fromFirestore).toList(growable: false),
    );
  }

  Future<void> ensureDailyQuests() async {
    final user = _requireUser();
    final dateKey = todayKey();
    final collection = _userDoc(user.uid).collection('dailyQuests');
    final existing = await collection
        .where('dateKey', isEqualTo: dateKey)
        .get();
    if (existing.docs.isNotEmpty) return;

    final userSnapshot = await _userDoc(user.uid).get();
    final healthSnapshot = await _userDoc(
      user.uid,
    ).collection('healthProfile').doc('current').get();
    final healthProfile = HealthProfile.fromMap(healthSnapshot.data());
    final quests = _dailyQuestTemplates(
      uid: user.uid,
      dateKey: dateKey,
      userData: userSnapshot.data() ?? <String, dynamic>{},
      healthProfile: healthProfile,
    );
    final batch = _firestore.batch();

    for (final quest in quests) {
      final doc = collection.doc('${dateKey}_${quest['type']}');
      batch.set(doc, {
        ...quest,
        'dateKey': dateKey,
        'currentValue': 0,
        'completed': false,
        'completedAt': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Stream<List<DailyQuest>> watchTodayQuests() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(const <DailyQuest>[]);
    return _userDoc(user.uid)
        .collection('dailyQuests')
        .where('dateKey', isEqualTo: todayKey())
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(DailyQuest.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<void> setQuestCompleted(String questId, bool completed) async {
    final user = _requireUser();
    await _userDoc(user.uid).collection('dailyQuests').doc(questId).set({
      'completed': completed,
      'currentValue': completed ? 1 : 0,
      'completedAt': completed ? FieldValue.serverTimestamp() : null,
    }, SetOptions(merge: true));
  }

  Future<void> ensureDefaultReminders() async {
    final user = _requireUser();
    final collection = _userDoc(user.uid).collection('reminders');
    final existing = await collection.get();
    final existingIds = existing.docs.map((doc) => doc.id).toSet();

    final batch = _firestore.batch();
    final reminders = <Map<String, dynamic>>[
      {
        'type': 'notifications',
        'title': 'Notification preferences',
        'timeLabel': 'App reminders',
      },
      {
        'type': 'hydration',
        'title': 'Hydration check',
        'timeLabel': 'Every 2 hours',
      },
      {'type': 'meal', 'title': 'Healthy meal', 'timeLabel': '12:00 PM'},
      {'type': 'workout', 'title': 'Workout window', 'timeLabel': '5:30 PM'},
      {'type': 'sleep', 'title': 'Sleep wind down', 'timeLabel': '10:00 PM'},
      {'type': 'study', 'title': 'Study focus', 'timeLabel': 'Before blocks'},
      {
        'type': 'mentalBreak',
        'title': 'Mental break',
        'timeLabel': 'After study blocks',
      },
    ];

    for (final reminder in reminders) {
      final doc = collection.doc(reminder['type']! as String);
      if (existingIds.contains(doc.id)) continue;
      batch.set(doc, {
        ...reminder,
        'enabled': true,
        'repeatDays': const <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Stream<List<AppReminder>> watchReminders() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(const <AppReminder>[]);
    return _userDoc(user.uid)
        .collection('reminders')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(AppReminder.fromFirestore)
                  .toList(growable: false)
                ..sort((a, b) => a.title.compareTo(b.title)),
        );
  }

  Stream<List<AppReminder>> watchEnabledReminders() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(const <AppReminder>[]);
    return _userDoc(user.uid)
        .collection('reminders')
        .where('enabled', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(AppReminder.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<void> setReminderEnabled(String reminderId, bool enabled) async {
    final user = _requireUser();
    await _userDoc(user.uid).collection('reminders').doc(reminderId).set({
      'enabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<WorkoutPlan>> watchWorkoutPlans() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(const <WorkoutPlan>[]);
    return _userDoc(user.uid)
        .collection('workoutPlans')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(WorkoutPlan.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<void> generateWorkoutPlan({
    required String category,
    required HealthProfile healthProfile,
    required List<ClassSchedule> schedules,
  }) async {
    final draft = buildGeneratedWorkoutDraft(
      category: category,
      healthProfile: healthProfile,
      schedules: schedules,
    );
    await saveWorkoutDraft(draft, schedules: schedules);
  }

  WorkoutPlanDraft buildGeneratedWorkoutDraft({
    required String category,
    required HealthProfile healthProfile,
    required List<ClassSchedule> schedules,
  }) {
    final selectedCategory = workoutCategoryByName(category);
    final freeMinutes = _largestFreeBlockMinutes(schedules);
    final duration = _durationForFreeBlock(freeMinutes);
    final intensity = _intensityFor(healthProfile);
    final exercises = _generatedExercisesFor(
      category: selectedCategory,
      healthProfile: healthProfile,
      duration: duration,
    );

    return WorkoutPlanDraft(
      title: _workoutTitleFor(
        category: selectedCategory.name,
        goal: healthProfile.fitnessGoal,
      ),
      category: selectedCategory.name,
      source: 'generated',
      durationMinutes: duration,
      intensity: intensity,
      fitnessGoal: healthProfile.fitnessGoal,
      activityLevel: healthProfile.activityLevel,
      exercises: exercises,
    );
  }

  Future<void> saveManualWorkoutPlan({
    required String category,
    required List<WorkoutExercise> exercises,
    required HealthProfile? healthProfile,
    required List<ClassSchedule> schedules,
  }) {
    if (exercises.isEmpty) {
      throw const PrototypeDataException('Select at least one exercise.');
    }
    final duration = exercises.fold<int>(
      0,
      (total, exercise) => total + _estimatedExerciseMinutes(exercise),
    );
    final draft = WorkoutPlanDraft(
      title: '$category Custom Plan',
      category: category,
      source: 'manual',
      durationMinutes: duration.clamp(10, 90),
      intensity: healthProfile == null
          ? 'Moderate'
          : _intensityFor(healthProfile),
      fitnessGoal: healthProfile?.fitnessGoal ?? 'General fitness',
      activityLevel: healthProfile?.activityLevel ?? 'Moderate',
      exercises: exercises,
    );
    return saveWorkoutDraft(draft, schedules: schedules);
  }

  Future<void> saveWorkoutDraft(
    WorkoutPlanDraft draft, {
    required List<ClassSchedule> schedules,
  }) async {
    final user = _requireUser();
    await _userDoc(user.uid).collection('workoutPlans').add({
      'title': draft.title,
      'category': draft.category,
      'source': draft.source,
      'dateKey': todayKey(),
      'durationMinutes': draft.durationMinutes,
      'intensity': draft.intensity,
      'fitnessGoal': draft.fitnessGoal,
      'activityLevel': draft.activityLevel,
      'basedOnScheduleIds': schedules.map((item) => item.id).toList(),
      'exercises': draft.planExercises,
      'completed': false,
      'completedAt': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setWorkoutCompleted(String planId, bool completed) async {
    final user = _requireUser();
    await _userDoc(user.uid).collection('workoutPlans').doc(planId).set({
      'completed': completed,
      'completedAt': completed ? FieldValue.serverTimestamp() : null,
    }, SetOptions(merge: true));
  }

  Stream<List<MealLog>> watchMealLogs() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(const <MealLog>[]);
    return _userDoc(user.uid)
        .collection('mealLogs')
        .orderBy('loggedAt', descending: true)
        .limit(10)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(MealLog.fromFirestore).toList(growable: false),
        );
  }

  Stream<List<JournalRecord>> watchJournalEntries() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(const <JournalRecord>[]);
    return _userDoc(user.uid)
        .collection('journalEntries')
        .orderBy('entryDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(JournalRecord.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<void> addJournalEntry({
    required String title,
    required String content,
    required String mood,
    required DateTime entryDate,
    required List<String> tags,
  }) async {
    final user = _requireUser();
    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty) {
      throw const PrototypeDataException('Please write a journal entry.');
    }

    await _userDoc(user.uid).collection('journalEntries').add({
      'title': _journalTitle(title, trimmedContent),
      'content': trimmedContent,
      'mood': mood.trim().isEmpty ? 'Calm' : mood.trim(),
      'tags': tags
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toSet()
          .toList(growable: false),
      'entryDate': Timestamp.fromDate(entryDate),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateJournalEntry({
    required String entryId,
    required String title,
    required String content,
    required String mood,
    required DateTime entryDate,
    required List<String> tags,
  }) async {
    final user = _requireUser();
    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty) {
      throw const PrototypeDataException('Please write a journal entry.');
    }

    await _userDoc(user.uid).collection('journalEntries').doc(entryId).set({
      'title': _journalTitle(title, trimmedContent),
      'content': trimmedContent,
      'mood': mood.trim().isEmpty ? 'Calm' : mood.trim(),
      'tags': tags
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toSet()
          .toList(growable: false),
      'entryDate': Timestamp.fromDate(entryDate),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteJournalEntry(String entryId) async {
    final user = _requireUser();
    await _userDoc(user.uid).collection('journalEntries').doc(entryId).delete();
  }

  Future<List<Map<String, dynamic>>> generateMealRecommendations({
    required HealthProfile healthProfile,
    required List<String> ingredients,
    required String mealType,
  }) async {
    final user = _requireUser();
    final normalizedIngredients = ingredients
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toSet();

    final results = _recipeCatalog
        .where((recipe) {
          final recipeIngredients = (recipe['ingredients']! as List<String>)
              .map((item) => item.toLowerCase())
              .toSet();
          final tags = (recipe['tags']! as List<String>)
              .map((item) => item.toLowerCase())
              .toSet();
          final allergens = (recipe['allergens']! as List<String>)
              .map((item) => item.toLowerCase())
              .toSet();
          final conditions = healthProfile.medicalConditions
              .map((item) => item.toLowerCase())
              .toSet();
          final allergyFilters = healthProfile.allergies
              .map((item) => item.toLowerCase())
              .toSet();

          final hasIngredientMatch =
              normalizedIngredients.isEmpty ||
              recipeIngredients.intersection(normalizedIngredients).isNotEmpty;
          final matchesMealType =
              mealType == 'Any' ||
              (recipe['mealType']! as String).toLowerCase() ==
                  mealType.toLowerCase();
          final avoidsAllergy =
              allergens.intersection(allergyFilters).isEmpty &&
              allergens.intersection(normalizedIngredients).isEmpty;
          final matchesDiet =
              healthProfile.dietaryPreference == 'No preference' ||
              tags.contains(healthProfile.dietaryPreference.toLowerCase());
          final conditionSafe =
              !conditions.contains('Diabetes'.toLowerCase()) ||
              tags.contains('low sugar');
          final hypertensionSafe =
              !conditions.contains('Hypertension'.toLowerCase()) ||
              tags.contains('low sodium');

          return hasIngredientMatch &&
              matchesMealType &&
              avoidsAllergy &&
              matchesDiet &&
              conditionSafe &&
              hypertensionSafe;
        })
        .take(3)
        .toList(growable: false);

    final fallback = results.isEmpty
        ? _recipeCatalog.take(3).toList(growable: false)
        : results;

    await _userDoc(user.uid).collection('mealRecommendations').add({
      'inputIngredients': ingredients,
      'mood': healthProfile.moodStatus,
      'dietaryPreference': healthProfile.dietaryPreference,
      'allergies': healthProfile.allergies,
      'medicalConditions': healthProfile.medicalConditions,
      'recommendedMeals': fallback,
      'selectedMealName': null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return fallback;
  }

  Future<void> logMeal(Map<String, dynamic> meal) async {
    final user = _requireUser();
    await _userDoc(user.uid).collection('mealLogs').add({
      'mealName': meal['name'],
      'mealType': meal['mealType'],
      'ingredients': meal['ingredients'],
      'caloriesEstimate': _readIntValue(meal['calories']),
      'proteinEstimate': _readIntValue(meal['protein']),
      'tags': meal['tags'],
      'matchedMood': meal['matchedMood'],
      'dietaryPreference': meal['dietaryPreference'],
      'avoidedAllergies': meal['avoidedAllergies'] ?? const <String>[],
      'medicalNotes': meal['medicalNotes'] ?? const <String>[],
      'source': 'rule-based recommendation',
      'dateKey': todayKey(),
      'loggedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<DashboardStats> loadDashboardStats() async {
    final user = _requireUser();
    final uidDoc = _userDoc(user.uid);
    final date = todayKey();
    final today = weekdayName();

    final results = await Future.wait([
      uidDoc.collection('schedules').where('dayOfWeek', isEqualTo: today).get(),
      uidDoc.collection('studyTasks').get(),
      uidDoc
          .collection('studySessions')
          .where('dateKey', isEqualTo: date)
          .get(),
      uidDoc
          .collection('workoutPlans')
          .where('dateKey', isEqualTo: date)
          .where('completed', isEqualTo: true)
          .get(),
      uidDoc.collection('mealLogs').where('dateKey', isEqualTo: date).get(),
      uidDoc.collection('dailyQuests').where('dateKey', isEqualTo: date).get(),
      uidDoc.collection('wellnessLogs').doc(date).get(),
    ]);

    final schedules = results[0] as QuerySnapshot<Map<String, dynamic>>;
    final tasks = results[1] as QuerySnapshot<Map<String, dynamic>>;
    final sessions = results[2] as QuerySnapshot<Map<String, dynamic>>;
    final workouts = results[3] as QuerySnapshot<Map<String, dynamic>>;
    final meals = results[4] as QuerySnapshot<Map<String, dynamic>>;
    final quests = results[5] as QuerySnapshot<Map<String, dynamic>>;
    final wellness = results[6] as DocumentSnapshot<Map<String, dynamic>>;

    final completedTasks = tasks.docs
        .where((doc) => doc.data()['isCompleted'] == true)
        .length;
    final studyMinutes = sessions.docs.fold<int>(
      0,
      (total, doc) => total + (doc.data()['durationMinutes'] as int? ?? 0),
    );
    final completedQuests = quests.docs
        .where((doc) => doc.data()['completed'] == true)
        .length;
    final wellnessData = wellness.data() ?? <String, dynamic>{};

    return DashboardStats(
      todayClasses: schedules.docs.length,
      studyTasks: tasks.docs.length,
      completedStudyTasks: completedTasks,
      studyMinutes: studyMinutes,
      completedWorkouts: workouts.docs.length,
      mealsLogged: meals.docs.length,
      completedQuests: completedQuests,
      totalQuests: quests.docs.length,
      waterGlasses: wellnessData['waterGlasses'] as int? ?? 0,
      sleepHours: (wellnessData['sleepHours'] as num?)?.toDouble() ?? 0,
    );
  }

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw const PrototypeDataException('Please log in again to continue.');
    }
    return user;
  }
}

String _scheduleColorFor(String dayOfWeek) {
  const colors = <String>['blue', 'purple', 'green', 'gold'];
  return colors[dayOfWeek.length % colors.length];
}

List<ClassSchedule> _sortSchedules(List<ClassSchedule> schedules) {
  final sorted = schedules.toList();
  sorted.sort((a, b) {
    final dayCompare = a.dayIndex.compareTo(b.dayIndex);
    if (dayCompare != 0) return dayCompare;
    return a.startTimeMinutes.compareTo(b.startTimeMinutes);
  });
  return sorted;
}

int _largestFreeBlockMinutes(List<ClassSchedule> schedules) {
  final todaySchedules =
      schedules.where((item) => item.dayOfWeek == weekdayName()).toList()
        ..sort((a, b) => a.startTimeMinutes.compareTo(b.startTimeMinutes));
  if (todaySchedules.isEmpty) return 60;
  var largest = (todaySchedules.first.startTimeMinutes - 7 * 60).clamp(0, 240);
  for (var i = 0; i < todaySchedules.length - 1; i++) {
    final gap =
        todaySchedules[i + 1].startTimeMinutes -
        todaySchedules[i].endTimeMinutes;
    if (gap > largest) largest = gap;
  }
  final eveningGap = (21 * 60) - todaySchedules.last.endTimeMinutes;
  if (eveningGap > largest) largest = eveningGap;
  return largest;
}

int _durationForFreeBlock(int freeMinutes) {
  if (freeMinutes >= 60) return 45;
  if (freeMinutes >= 35) return 30;
  return 20;
}

String _intensityFor(HealthProfile healthProfile) {
  final activity = healthProfile.activityLevel.toLowerCase();
  if (activity.contains('high')) return 'High';
  if (activity.contains('low')) return 'Light';
  final current = healthProfile.weightKg;
  final target = healthProfile.targetWeightKg;
  if (current != null && target != null && current > target + 5) {
    return 'Moderate';
  }
  return 'Moderate';
}

List<WorkoutExercise> _generatedExercisesFor({
  required WorkoutCategory category,
  required HealthProfile healthProfile,
  required int duration,
}) {
  final targetCount = duration >= 45
      ? 5
      : duration >= 30
      ? 4
      : 3;
  final exercises = category.exercises.toList();
  if (healthProfile.activityLevel == 'Low') {
    exercises.sort((a, b) => a.difficulty.compareTo(b.difficulty));
  }
  return exercises.take(targetCount).toList(growable: false);
}

int _estimatedExerciseMinutes(WorkoutExercise exercise) {
  final value = exercise.repsOrDuration.toLowerCase();
  final explicitMinutes = RegExp(r'(\d+)\s*min').firstMatch(value);
  if (explicitMinutes != null) {
    return int.tryParse(explicitMinutes.group(1) ?? '') ?? 5;
  }
  if (value.contains('sec')) return exercise.sets * 2;
  return exercise.sets * 3;
}

String _workoutTitleFor({required String category, required String goal}) {
  final normalizedCategory = category.toLowerCase();
  if (normalizedCategory.contains('strength')) return 'Strength Builder';
  if (normalizedCategory.contains('cardio')) return 'Cardio Circuit';
  if (normalizedCategory.contains('hiit')) return 'HIIT Study Break';
  if (normalizedCategory.contains('mobility')) return 'Mobility Flow';
  if (normalizedCategory.contains('recovery')) return 'Recovery Reset';
  final normalized = goal.toLowerCase();
  if (normalized.contains('strength')) return 'Strength Builder';
  if (normalized.contains('weight')) return 'Fat-Burn Circuit';
  if (normalized.contains('flex')) return 'Mobility Flow';
  return 'Balanced Student Routine';
}

List<Map<String, dynamic>> _dailyQuestTemplates({
  required String uid,
  required String dateKey,
  required Map<String, dynamic> userData,
  required HealthProfile healthProfile,
}) {
  final goals = _mapValue(userData['goals']);
  final wellnessGoals = _stringListValue(goals['wellness']);
  final studyGoals = _stringListValue(goals['study']);
  final workoutGoals = _stringListValue(goals['workout']);
  final preferences = _mapValue(userData['preferences']);
  final healthPreferences = _mapValue(preferences['health']);
  final waterTarget =
      _intValue(healthPreferences['dailyWaterGlasses']) ??
      (healthProfile.activityLevel == 'High' ? 10 : 8);
  final sleepTarget =
      _intValue(healthPreferences['targetSleepHours']) ??
      (wellnessGoals.contains('Better sleep') ? 8 : 7);
  final seed = _stableHash(
    '$uid|$dateKey|${healthProfile.fitnessGoal}|'
    '${healthProfile.activityLevel}|${wellnessGoals.join(',')}',
  );

  final quests = <Map<String, dynamic>>[
    {
      'type': 'hydration',
      'title': 'Reach your hydration goal',
      'description': 'Drink $waterTarget glasses of water today.',
      'targetValue': waterTarget,
    },
  ];

  final optional = <Map<String, dynamic>>[
    {
      'type': 'workout',
      'title': workoutGoals.isEmpty
          ? 'Move your body'
          : 'Train toward your goal',
      'description':
          'Complete one workout that fits your ${healthProfile.activityLevel.toLowerCase()} activity level.',
      'targetValue': 1,
    },
    {
      'type': 'meal',
      'title': 'Log a supportive meal',
      'description':
          'Log one meal that fits your ${healthProfile.dietaryPreference.toLowerCase()} preference.',
      'targetValue': 1,
    },
    {
      'type': 'studyFocus',
      'title': studyGoals.isEmpty
          ? 'Finish one study task'
          : 'Protect focus time',
      'description': 'Complete one study task or focus block.',
      'targetValue': 1,
    },
    {
      'type': 'sleep',
      'title': 'Plan your sleep window',
      'description': 'Aim for $sleepTarget hours of sleep tonight.',
      'targetValue': sleepTarget,
    },
    {
      'type': 'reflection',
      'title': 'Log a quick reflection',
      'description': 'Write one short journal entry about your day.',
      'targetValue': 1,
    },
  ];

  for (var i = 0; i < 3; i++) {
    quests.add(optional[(seed + i) % optional.length]);
  }

  return quests;
}

String _journalTitle(String title, String content) {
  final trimmedTitle = title.trim();
  if (trimmedTitle.isNotEmpty) return trimmedTitle;
  final firstLine = content.split(RegExp(r'\s+')).take(5).join(' ');
  return firstLine.isEmpty ? 'Journal Entry' : firstLine;
}

int _stableHash(String value) {
  var hash = 0;
  for (final codeUnit in value.codeUnits) {
    hash = (hash * 31 + codeUnit) & 0x7fffffff;
  }
  return hash;
}

Map<String, dynamic> _mapValue(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map(
      (key, dynamic nestedValue) => MapEntry(key.toString(), nestedValue),
    );
  }
  return <String, dynamic>{};
}

List<String> _stringListValue(Object? value) {
  if (value is List) {
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  return const <String>[];
}

int? _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

const _recipeCatalog = <Map<String, dynamic>>[
  {
    'name': 'Chicken Rice Power Bowl',
    'mealType': 'Lunch',
    'ingredients': <String>['chicken', 'rice', 'carrot', 'egg'],
    'calories': 520,
    'protein': 38,
    'tags': <String>['high-protein', 'low sugar'],
    'allergens': <String>['egg'],
    'time': '20 min',
    'difficulty': 'Easy',
    'description':
        'A filling student-friendly bowl with lean protein and rice.',
  },
  {
    'name': 'Tuna Veggie Sandwich',
    'mealType': 'Lunch',
    'ingredients': <String>['tuna', 'bread', 'lettuce', 'tomato'],
    'calories': 410,
    'protein': 28,
    'tags': <String>['high-protein', 'low sugar'],
    'allergens': <String>['fish', 'gluten'],
    'time': '10 min',
    'difficulty': 'Very Easy',
    'description': 'Quick protein-rich meal for busy class days.',
  },
  {
    'name': 'Oat Banana Breakfast',
    'mealType': 'Breakfast',
    'ingredients': <String>['oats', 'banana', 'milk'],
    'calories': 360,
    'protein': 14,
    'tags': <String>['vegetarian', 'low sodium'],
    'allergens': <String>['dairy'],
    'time': '8 min',
    'difficulty': 'Very Easy',
    'description': 'A calm-energy breakfast for study mornings.',
  },
  {
    'name': 'Tofu Vegetable Stir Fry',
    'mealType': 'Dinner',
    'ingredients': <String>['tofu', 'broccoli', 'rice', 'garlic'],
    'calories': 430,
    'protein': 24,
    'tags': <String>['vegetarian', 'vegan', 'low sodium', 'low sugar'],
    'allergens': <String>['soy'],
    'time': '18 min',
    'difficulty': 'Easy',
    'description': 'Balanced plant-based dinner with vegetables and rice.',
  },
  {
    'name': 'Greek Yogurt Fruit Cup',
    'mealType': 'Snack',
    'ingredients': <String>['yogurt', 'berries', 'banana'],
    'calories': 220,
    'protein': 18,
    'tags': <String>['vegetarian', 'high-protein', 'low sodium'],
    'allergens': <String>['dairy'],
    'time': '5 min',
    'difficulty': 'Very Easy',
    'description': 'Light snack for recovery between classes.',
  },
];

int _readIntValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }
  return 0;
}
