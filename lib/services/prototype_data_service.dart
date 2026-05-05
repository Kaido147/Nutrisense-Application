import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutrisense/models/prototype_data.dart';

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
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream<HealthProfile?>.value(null);
      return _userDoc(user.uid)
          .collection('healthProfile')
          .doc('current')
          .snapshots()
          .map((snapshot) {
            final data = snapshot.data();
            return data == null ? null : HealthProfile.fromMap(data);
          });
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
    final user = _auth.currentUser;
    if (user == null) return Stream.value(const <ClassSchedule>[]);
    return _userDoc(user.uid)
        .collection('schedules')
        .orderBy('dayOfWeek')
        .orderBy('startTimeMinutes')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(ClassSchedule.fromFirestore)
              .toList(growable: false),
        );
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
    final snapshot = await _userDoc(user.uid)
        .collection('schedules')
        .orderBy('dayOfWeek')
        .orderBy('startTimeMinutes')
        .get();
    return snapshot.docs.map(ClassSchedule.fromFirestore).toList(growable: false);
  }

  Future<void> ensureDailyQuests() async {
    final user = _requireUser();
    final dateKey = todayKey();
    final collection = _userDoc(user.uid).collection('dailyQuests');
    final existing = await collection.where('dateKey', isEqualTo: dateKey).get();
    if (existing.docs.isNotEmpty) return;

    final batch = _firestore.batch();
    final quests = <Map<String, dynamic>>[
      {
        'type': 'hydration',
        'title': 'Drink water',
        'description': 'Reach your daily hydration goal.',
        'targetValue': 8,
      },
      {
        'type': 'meal',
        'title': 'Log a healthy meal',
        'description': 'Save one meal recommendation or meal log.',
        'targetValue': 1,
      },
      {
        'type': 'workout',
        'title': 'Move your body',
        'description': 'Complete today\'s recommended workout.',
        'targetValue': 1,
      },
      {
        'type': 'studyBreak',
        'title': 'Take a study break',
        'description': 'Protect your focus with a short recovery break.',
        'targetValue': 1,
      },
    ];

    for (final quest in quests) {
      final doc = collection.doc();
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
    final existing = await collection.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final batch = _firestore.batch();
    final reminders = <Map<String, dynamic>>[
      {
        'type': 'hydration',
        'title': 'Hydration check',
        'timeLabel': 'Every 2 hours',
      },
      {'type': 'meal', 'title': 'Healthy meal', 'timeLabel': '12:00 PM'},
      {'type': 'workout', 'title': 'Workout window', 'timeLabel': '5:30 PM'},
      {'type': 'sleep', 'title': 'Sleep wind down', 'timeLabel': '10:00 PM'},
      {
        'type': 'mentalBreak',
        'title': 'Mental break',
        'timeLabel': 'After study blocks',
      },
    ];

    for (final reminder in reminders) {
      final doc = collection.doc(reminder['type']! as String);
      batch.set(doc, {
        ...reminder,
        'enabled': true,
        'repeatDays': const <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
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
    required HealthProfile healthProfile,
    required List<ClassSchedule> schedules,
  }) async {
    final user = _requireUser();
    final freeMinutes = _largestFreeBlockMinutes(schedules);
    final duration = freeMinutes >= 60
        ? 45
        : freeMinutes >= 35
        ? 30
        : 20;
    final intensity = healthProfile.activityLevel == 'High'
        ? 'High'
        : healthProfile.activityLevel == 'Low'
        ? 'Light'
        : 'Moderate';
    final exercises = _exercisePlanFor(healthProfile.fitnessGoal, duration);

    await _userDoc(user.uid).collection('workoutPlans').add({
      'title': _workoutTitleFor(healthProfile.fitnessGoal),
      'dateKey': todayKey(),
      'durationMinutes': duration,
      'intensity': intensity,
      'fitnessGoal': healthProfile.fitnessGoal,
      'activityLevel': healthProfile.activityLevel,
      'basedOnScheduleIds': schedules.map((item) => item.id).toList(),
      'exercises': exercises,
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
          (snapshot) => snapshot.docs
              .map(MealLog.fromFirestore)
              .toList(growable: false),
        );
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

    final results = _recipeCatalog.where((recipe) {
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
          (recipe['mealType']! as String).toLowerCase() == mealType.toLowerCase();
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
    }).take(3).toList(growable: false);

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
      uidDoc.collection('studySessions').where('dateKey', isEqualTo: date).get(),
      uidDoc
          .collection('workoutPlans')
          .where('dateKey', isEqualTo: date)
          .where('completed', isEqualTo: true)
          .get(),
      uidDoc.collection('mealLogs').get(),
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

int _largestFreeBlockMinutes(List<ClassSchedule> schedules) {
  final todaySchedules = schedules
      .where((item) => item.dayOfWeek == weekdayName())
      .toList()
    ..sort((a, b) => a.startTimeMinutes.compareTo(b.startTimeMinutes));
  if (todaySchedules.isEmpty) return 60;
  var largest = (todaySchedules.first.startTimeMinutes - 7 * 60).clamp(0, 240);
  for (var i = 0; i < todaySchedules.length - 1; i++) {
    final gap =
        todaySchedules[i + 1].startTimeMinutes - todaySchedules[i].endTimeMinutes;
    if (gap > largest) largest = gap;
  }
  final eveningGap = (21 * 60) - todaySchedules.last.endTimeMinutes;
  if (eveningGap > largest) largest = eveningGap;
  return largest;
}

String _workoutTitleFor(String goal) {
  final normalized = goal.toLowerCase();
  if (normalized.contains('strength')) return 'Strength Builder';
  if (normalized.contains('weight')) return 'Fat-Burn Circuit';
  if (normalized.contains('flex')) return 'Mobility Flow';
  return 'Balanced Student Routine';
}

List<Map<String, dynamic>> _exercisePlanFor(String goal, int duration) {
  final normalized = goal.toLowerCase();
  final base = normalized.contains('strength')
      ? _strengthExercises
      : normalized.contains('weight')
      ? _cardioExercises
      : normalized.contains('flex')
      ? _mobilityExercises
      : _balancedExercises;
  final count = duration >= 45
      ? 5
      : duration >= 30
      ? 4
      : 3;
  return base.take(count).map((item) => {...item, 'completed': false}).toList();
}

const _balancedExercises = <Map<String, dynamic>>[
  {'name': 'Bodyweight Squats', 'sets': 3, 'reps': '12', 'durationMinutes': 6},
  {'name': 'Push-ups', 'sets': 3, 'reps': '10', 'durationMinutes': 6},
  {'name': 'Plank', 'sets': 3, 'reps': '30 sec', 'durationMinutes': 5},
  {'name': 'Lunges', 'sets': 3, 'reps': '10 each', 'durationMinutes': 7},
  {'name': 'Cool-down Stretch', 'sets': 1, 'reps': '5 min', 'durationMinutes': 5},
];

const _strengthExercises = <Map<String, dynamic>>[
  {'name': 'Push-ups', 'sets': 4, 'reps': '12', 'durationMinutes': 7},
  {'name': 'Squats', 'sets': 4, 'reps': '15', 'durationMinutes': 7},
  {'name': 'Tricep Dips', 'sets': 3, 'reps': '12', 'durationMinutes': 6},
  {'name': 'Glute Bridges', 'sets': 3, 'reps': '15', 'durationMinutes': 6},
  {'name': 'Core Hold', 'sets': 3, 'reps': '40 sec', 'durationMinutes': 5},
];

const _cardioExercises = <Map<String, dynamic>>[
  {'name': 'Jumping Jacks', 'sets': 3, 'reps': '45 sec', 'durationMinutes': 5},
  {'name': 'High Knees', 'sets': 3, 'reps': '40 sec', 'durationMinutes': 5},
  {'name': 'Mountain Climbers', 'sets': 3, 'reps': '30 sec', 'durationMinutes': 6},
  {'name': 'Fast Walk', 'sets': 1, 'reps': '10 min', 'durationMinutes': 10},
  {'name': 'Breathing Cooldown', 'sets': 1, 'reps': '4 min', 'durationMinutes': 4},
];

const _mobilityExercises = <Map<String, dynamic>>[
  {'name': 'Neck and Shoulder Rolls', 'sets': 2, 'reps': '60 sec', 'durationMinutes': 4},
  {'name': 'Hip Flexor Stretch', 'sets': 2, 'reps': '45 sec', 'durationMinutes': 5},
  {'name': 'Cat-Cow Stretch', 'sets': 3, 'reps': '8', 'durationMinutes': 5},
  {'name': 'Hamstring Stretch', 'sets': 2, 'reps': '45 sec', 'durationMinutes': 5},
  {'name': 'Deep Breathing', 'sets': 1, 'reps': '3 min', 'durationMinutes': 3},
];

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
    'description': 'A filling student-friendly bowl with lean protein and rice.',
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
