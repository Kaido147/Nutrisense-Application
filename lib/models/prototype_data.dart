import 'package:cloud_firestore/cloud_firestore.dart';

class HealthProfile {
  const HealthProfile({
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.targetWeightKg,
    required this.activityLevel,
    required this.fitnessGoal,
    required this.dietaryPreference,
    required this.medicalConditions,
    required this.allergies,
    required this.moodStatus,
    required this.wellnessStatus,
    required this.updatedAt,
    required this.weightGainPaceKgPerWeek,
  });

  factory HealthProfile.empty() {
    return const HealthProfile(
      age: null,
      gender: null,
      heightCm: null,
      weightKg: null,
      targetWeightKg: null,
      activityLevel: 'Moderate',
      fitnessGoal: 'General fitness',
      dietaryPreference: 'No preference',
      medicalConditions: <String>[],
      allergies: <String>[],
      moodStatus: 'Balanced',
      wellnessStatus: 'Good',
      updatedAt: null,
      weightGainPaceKgPerWeek: null,
    );
  }

  factory HealthProfile.fromMap(Map<String, dynamic>? data) {
    final source = data ?? <String, dynamic>{};
    return HealthProfile(
      age: _readInt(source['age']),
      gender: _readString(source['gender']),
      heightCm: _readDouble(source['heightCm']),
      weightKg: _readDouble(source['weightKg']),
      targetWeightKg: _readDouble(source['targetWeightKg']),
      activityLevel: _readString(source['activityLevel']) ?? 'Moderate',
      fitnessGoal: _readString(source['fitnessGoal']) ?? 'General fitness',
      dietaryPreference:
          _readString(source['dietaryPreference']) ?? 'No preference',
      medicalConditions: _readStringList(source['medicalConditions']),
      allergies: _readStringList(source['allergies']),
      moodStatus: _readString(source['moodStatus']) ?? 'Balanced',
      wellnessStatus: _readString(source['wellnessStatus']) ?? 'Good',
      updatedAt: _readDateTime(source['updatedAt']),
      weightGainPaceKgPerWeek: _readDouble(source['weightGainPaceKgPerWeek']),
    );
  }

  final int? age;
  final String? gender;
  final double? heightCm;
  final double? weightKg;
  final double? targetWeightKg;
  final String activityLevel;
  final String fitnessGoal;
  final String dietaryPreference;
  final List<String> medicalConditions;
  final List<String> allergies;
  final String moodStatus;
  final String wellnessStatus;
  final DateTime? updatedAt;
  final double? weightGainPaceKgPerWeek;

  bool get isComplete {
    return age != null &&
        gender != null &&
        heightCm != null &&
        weightKg != null &&
        targetWeightKg != null &&
        activityLevel.trim().isNotEmpty &&
        fitnessGoal.trim().isNotEmpty &&
        dietaryPreference.trim().isNotEmpty;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'age': age,
      'gender': gender,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'targetWeightKg': targetWeightKg,
      'activityLevel': activityLevel,
      'fitnessGoal': fitnessGoal,
      'dietaryPreference': dietaryPreference,
      'medicalConditions': medicalConditions,
      'allergies': allergies,
      'moodStatus': moodStatus,
      'wellnessStatus': wellnessStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class ClassSchedule {
  const ClassSchedule({
    required this.id,
    required this.title,
    required this.courseCode,
    required this.dayOfWeek,
    required this.dayIndex,
    required this.startTimeMinutes,
    required this.endTimeMinutes,
    required this.timeLabel,
    required this.location,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClassSchedule.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return ClassSchedule.fromMap(snapshot.id, snapshot.data());
  }

  factory ClassSchedule.fromMap(String id, Map<String, dynamic>? data) {
    final source = data ?? <String, dynamic>{};
    final start = _readInt(source['startTimeMinutes']) ?? 0;
    final end = _readInt(source['endTimeMinutes']) ?? start + 60;
    return ClassSchedule(
      id: id,
      title: _readString(source['title']) ?? 'Untitled Class',
      courseCode: _readString(source['courseCode']) ?? '',
      dayOfWeek: _readString(source['dayOfWeek']) ?? 'Monday',
      dayIndex:
          _readInt(source['dayIndex']) ??
          weekdayIndex(_readString(source['dayOfWeek']) ?? 'Monday'),
      startTimeMinutes: start,
      endTimeMinutes: end,
      timeLabel:
          _readString(source['timeLabel']) ??
          '${_formatMinutes(start)} - ${_formatMinutes(end)}',
      location: _readString(source['location']) ?? '',
      color: _readString(source['color']) ?? 'blue',
      createdAt: _readDateTime(source['createdAt']),
      updatedAt: _readDateTime(source['updatedAt']),
    );
  }

  final String id;
  final String title;
  final String courseCode;
  final String dayOfWeek;
  final int dayIndex;
  final int startTimeMinutes;
  final int endTimeMinutes;
  final String timeLabel;
  final String location;
  final String color;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'courseCode': courseCode,
      'dayOfWeek': dayOfWeek,
      'dayIndex': dayIndex,
      'startTimeMinutes': startTimeMinutes,
      'endTimeMinutes': endTimeMinutes,
      'timeLabel': timeLabel,
      'location': location,
      'color': color,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class WorkoutPlan {
  const WorkoutPlan({
    required this.id,
    required this.title,
    required this.category,
    required this.source,
    required this.dateKey,
    required this.durationMinutes,
    required this.intensity,
    required this.fitnessGoal,
    required this.activityLevel,
    required this.exercises,
    required this.completed,
    required this.completedAt,
    required this.createdAt,
  });

  factory WorkoutPlan.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return WorkoutPlan.fromMap(snapshot.id, snapshot.data());
  }

  factory WorkoutPlan.fromMap(String id, Map<String, dynamic>? data) {
    final source = data ?? <String, dynamic>{};
    return WorkoutPlan(
      id: id,
      title: _readString(source['title']) ?? 'Today\'s Workout',
      category: _readString(source['category']) ?? 'Balanced',
      source: _readString(source['source']) ?? 'generated',
      dateKey: _readString(source['dateKey']) ?? todayKey(),
      durationMinutes: _readInt(source['durationMinutes']) ?? 20,
      intensity: _readString(source['intensity']) ?? 'Moderate',
      fitnessGoal: _readString(source['fitnessGoal']) ?? 'General fitness',
      activityLevel: _readString(source['activityLevel']) ?? 'Moderate',
      exercises: _readMapList(source['exercises']),
      completed: _readBool(source['completed']) ?? false,
      completedAt: _readDateTime(source['completedAt']),
      createdAt: _readDateTime(source['createdAt']),
    );
  }

  final String id;
  final String title;
  final String category;
  final String source;
  final String dateKey;
  final int durationMinutes;
  final String intensity;
  final String fitnessGoal;
  final String activityLevel;
  final List<Map<String, dynamic>> exercises;
  final bool completed;
  final DateTime? completedAt;
  final DateTime? createdAt;

  int get completedExerciseCount {
    return exercises.where((exercise) => exercise['completed'] == true).length;
  }

  double get exerciseProgress {
    if (exercises.isEmpty) return completed ? 1.0 : 0.0;
    return completedExerciseCount / exercises.length;
  }
}

class MealLog {
  const MealLog({
    required this.id,
    required this.mealName,
    required this.mealType,
    required this.ingredients,
    required this.caloriesEstimate,
    required this.proteinEstimate,
    required this.tags,
    required this.loggedAt,
  });

  factory MealLog.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final source = snapshot.data();
    return MealLog(
      id: snapshot.id,
      mealName: _readString(source['mealName']) ?? 'Meal',
      mealType: _readString(source['mealType']) ?? 'Meal',
      ingredients: _readStringList(source['ingredients']),
      caloriesEstimate: _readInt(source['caloriesEstimate']) ?? 0,
      proteinEstimate: _readInt(source['proteinEstimate']) ?? 0,
      tags: _readStringList(source['tags']),
      loggedAt: _readDateTime(source['loggedAt']),
    );
  }

  final String id;
  final String mealName;
  final String mealType;
  final List<String> ingredients;
  final int caloriesEstimate;
  final int proteinEstimate;
  final List<String> tags;
  final DateTime? loggedAt;
}

class JournalRecord {
  const JournalRecord({
    required this.id,
    required this.title,
    required this.content,
    required this.mood,
    required this.tags,
    required this.entryDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory JournalRecord.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return JournalRecord.fromMap(snapshot.id, snapshot.data());
  }

  factory JournalRecord.fromMap(String id, Map<String, dynamic>? data) {
    final source = data ?? <String, dynamic>{};
    return JournalRecord(
      id: id,
      title: _readString(source['title']) ?? 'Untitled Entry',
      content: _readString(source['content']) ?? '',
      mood: _readString(source['mood']) ?? 'Calm',
      tags: _readStringList(source['tags']),
      entryDate:
          _readDateTime(source['entryDate']) ??
          _readDateTime(source['createdAt']) ??
          DateTime.now(),
      createdAt: _readDateTime(source['createdAt']),
      updatedAt: _readDateTime(source['updatedAt']),
    );
  }

  final String id;
  final String title;
  final String content;
  final String mood;
  final List<String> tags;
  final DateTime entryDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get preview => content;

  String get moodInitial => mood.isEmpty ? '?' : mood[0].toUpperCase();

  String get dateLabel {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[entryDate.month - 1]} ${entryDate.day}';
  }
}

class DailyQuest {
  const DailyQuest({
    required this.id,
    required this.dateKey,
    required this.type,
    required this.title,
    required this.description,
    required this.targetValue,
    required this.currentValue,
    required this.completed,
    required this.completedAt,
  });

  factory DailyQuest.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final source = snapshot.data();
    return DailyQuest(
      id: snapshot.id,
      dateKey: _readString(source['dateKey']) ?? todayKey(),
      type: _readString(source['type']) ?? 'wellness',
      title: _readString(source['title']) ?? 'Wellness quest',
      description: _readString(source['description']) ?? '',
      targetValue: _readInt(source['targetValue']) ?? 1,
      currentValue: _readInt(source['currentValue']) ?? 0,
      completed: _readBool(source['completed']) ?? false,
      completedAt: _readDateTime(source['completedAt']),
    );
  }

  final String id;
  final String dateKey;
  final String type;
  final String title;
  final String description;
  final int targetValue;
  final int currentValue;
  final bool completed;
  final DateTime? completedAt;
}

class AppReminder {
  const AppReminder({
    required this.id,
    required this.type,
    required this.title,
    required this.timeLabel,
    required this.enabled,
    required this.repeatDays,
  });

  factory AppReminder.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final source = snapshot.data();
    return AppReminder(
      id: snapshot.id,
      type: _readString(source['type']) ?? snapshot.id,
      title: _readString(source['title']) ?? 'Reminder',
      timeLabel: _readString(source['timeLabel']) ?? 'Today',
      enabled: _readBool(source['enabled']) ?? true,
      repeatDays: _readStringList(source['repeatDays']),
    );
  }

  final String id;
  final String type;
  final String title;
  final String timeLabel;
  final bool enabled;
  final List<String> repeatDays;
}

class DashboardStats {
  const DashboardStats({
    required this.todayClasses,
    required this.studyTasks,
    required this.completedStudyTasks,
    required this.studyMinutes,
    required this.completedWorkouts,
    required this.workoutExercisesDone,
    required this.workoutExercisesTotal,
    required this.weeklyCompletedWorkoutDays,
    required this.weeklyStudyMinutes,
    required this.mealsLogged,
    required this.completedQuests,
    required this.totalQuests,
    required this.waterGlasses,
    required this.sleepHours,
  });

  final int todayClasses;
  final int studyTasks;
  final int completedStudyTasks;
  final int studyMinutes;
  final int completedWorkouts;
  final int workoutExercisesDone;
  final int workoutExercisesTotal;
  final int weeklyCompletedWorkoutDays;
  final int weeklyStudyMinutes;
  final int mealsLogged;
  final int completedQuests;
  final int totalQuests;
  final int waterGlasses;
  final double sleepHours;
}

String todayKey([DateTime? date]) {
  final now = date ?? DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

String weekdayName([DateTime? date]) {
  const names = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  return names[(date ?? DateTime.now()).weekday - 1];
}

int weekdayIndex(String dayOfWeek) {
  const names = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  final index = names.indexWhere(
    (name) => name.toLowerCase() == dayOfWeek.trim().toLowerCase(),
  );
  return index < 0 ? 0 : index;
}

String _formatMinutes(int minutes) {
  final hour = minutes ~/ 60;
  final minute = minutes % 60;
  final period = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;
  return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
}

String? _readString(Object? value) {
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  return null;
}

int? _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _readDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

bool? _readBool(Object? value) {
  return value is bool ? value : null;
}

DateTime? _readDateTime(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

List<String> _readStringList(Object? value) {
  if (value is List) {
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  return const <String>[];
}

List<Map<String, dynamic>> _readMapList(Object? value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map(
          (item) => item.map(
            (key, dynamic nestedValue) => MapEntry(key.toString(), nestedValue),
          ),
        )
        .toList(growable: false);
  }
  return const <Map<String, dynamic>>[];
}
