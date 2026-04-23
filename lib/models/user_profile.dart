import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.createdAt,
    required this.goals,
    required this.onboardingCompleted,
    required this.onboardingCompletedAt,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.birthDate,
    required this.location,
    required this.bio,
    required this.profileUpdatedAt,
    required this.preferences,
    required this.preferencesUpdatedAt,
  });

  factory UserProfile.fromFirestore({
    required String uid,
    required Map<String, dynamic>? data,
    String? authEmail,
    String? authDisplayName,
  }) {
    final Map<String, dynamic> source = data ?? <String, dynamic>{};
    final String resolvedDisplayName =
        _firstNonEmpty(_readString(source['displayName']), authDisplayName) ??
        'Nutrisense User';

    return UserProfile(
      uid: uid,
      email: _firstNonEmpty(_readString(source['email']), authEmail),
      displayName: resolvedDisplayName,
      createdAt: _readDateTime(source['createdAt']),
      goals: UserGoals.fromMap(_readMap(source['goals'])),
      onboardingCompleted: _readBool(source['onboardingCompleted']) ?? false,
      onboardingCompletedAt: _readDateTime(source['onboardingCompletedAt']),
      firstName: _readString(source['firstName']),
      lastName: _readString(source['lastName']),
      phoneNumber: _readString(source['phoneNumber']),
      birthDate: _readDateTime(source['birthDate']),
      location: _readString(source['location']),
      bio: _readString(source['bio']),
      profileUpdatedAt: _readDateTime(source['profileUpdatedAt']),
      preferences: UserPreferences.fromMap(_readMap(source['preferences'])),
      preferencesUpdatedAt: _readDateTime(source['preferencesUpdatedAt']),
    );
  }

  final String uid;
  final String? email;
  final String displayName;
  final DateTime? createdAt;
  final UserGoals goals;
  final bool onboardingCompleted;
  final DateTime? onboardingCompletedAt;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final DateTime? birthDate;
  final String? location;
  final String? bio;
  final DateTime? profileUpdatedAt;
  final UserPreferences preferences;
  final DateTime? preferencesUpdatedAt;

  String get resolvedFirstName {
    final String? stored = _readString(firstName);
    if (stored != null) {
      return stored;
    }

    final List<String> parts = _splitDisplayName(displayName);
    return parts.isNotEmpty ? parts.first : '';
  }

  String get resolvedLastName {
    final String? stored = _readString(lastName);
    if (stored != null) {
      return stored;
    }

    final List<String> parts = _splitDisplayName(displayName);
    if (parts.length <= 1) {
      return '';
    }

    return parts.skip(1).join(' ');
  }

  String get fullName {
    final String combined =
        '${resolvedFirstName.trim()} ${resolvedLastName.trim()}'.trim();
    return combined.isNotEmpty ? combined : displayName;
  }

  String get displayEmail => email ?? '';

  int? get effectiveStudyWeeklyHours {
    return preferences.study.weeklyHours ?? _studyHoursFromGoals();
  }

  int? get effectiveWorkoutDaysPerWeek {
    return preferences.workout.daysPerWeek ?? _workoutDaysFromGoals();
  }

  int get editorStudyWeeklyHours => effectiveStudyWeeklyHours ?? 30;

  int get editorFocusMinutes => preferences.study.focusMinutes ?? 25;

  int get editorBreakMinutes => preferences.study.breakMinutes ?? 5;

  int get editorWorkoutDaysPerWeek => effectiveWorkoutDaysPerWeek ?? 5;

  int get editorDailyWaterGlasses =>
      preferences.health.dailyWaterGlasses ?? 8;

  int get editorTargetSleepHours => preferences.health.targetSleepHours ?? 8;

  bool get editorStudyReminders => preferences.reminders.study ?? true;

  bool get editorWorkoutReminders => preferences.reminders.workout ?? true;

  bool get editorMealReminders => preferences.reminders.meal ?? false;

  double get studySummaryProgress {
    final int? hours = effectiveStudyWeeklyHours;
    if (hours == null) {
      return 0;
    }

    return (hours / 40).clamp(0.0, 1.0);
  }

  double get workoutSummaryProgress {
    final int? days = effectiveWorkoutDaysPerWeek;
    if (days == null) {
      return 0;
    }

    return (days / 7).clamp(0.0, 1.0);
  }

  String get studySummaryValue {
    final int? hours = effectiveStudyWeeklyHours;
    if (hours == null) {
      return 'Not set';
    }

    return '${hours}h/week';
  }

  String get workoutSummaryValue {
    final int? days = effectiveWorkoutDaysPerWeek;
    if (days == null) {
      return 'Not set';
    }

    return '$days days/week';
  }

  int? _studyHoursFromGoals() {
    if (goals.study.contains('4+ hours/day')) {
      return 30;
    }
    if (goals.study.contains('2-3 hours/day')) {
      return 18;
    }
    if (goals.study.contains('1-2 hours/day')) {
      return 10;
    }

    return null;
  }

  int? _workoutDaysFromGoals() {
    if (goals.workout.contains('Daily workout')) {
      return 7;
    }
    if (goals.workout.contains('3-4x per week')) {
      return 4;
    }
    if (goals.workout.contains('1-2x per week')) {
      return 2;
    }

    return null;
  }

  static String? _firstNonEmpty(String? primary, String? fallback) {
    if (primary != null && primary.trim().isNotEmpty) {
      return primary.trim();
    }
    if (fallback != null && fallback.trim().isNotEmpty) {
      return fallback.trim();
    }

    return null;
  }

  static String? _readString(Object? value) {
    if (value is String) {
      final String trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    return null;
  }

  static bool? _readBool(Object? value) {
    return value is bool ? value : null;
  }

  static DateTime? _readDateTime(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  static Map<String, dynamic>? _readMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map(
        (key, dynamic nestedValue) => MapEntry(key.toString(), nestedValue),
      );
    }

    return null;
  }

  static List<String> _splitDisplayName(String value) {
    return value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
  }
}

class UserGoals {
  const UserGoals({
    required this.study,
    required this.workout,
    required this.wellness,
  });

  factory UserGoals.fromMap(Map<String, dynamic>? data) {
    final Map<String, dynamic> source = data ?? <String, dynamic>{};
    return UserGoals(
      study: _readStringList(source['study']),
      workout: _readStringList(source['workout']),
      wellness: _readStringList(source['wellness']),
    );
  }

  final List<String> study;
  final List<String> workout;
  final List<String> wellness;

  static List<String> _readStringList(Object? value) {
    if (value is List) {
      return value
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }

    return const <String>[];
  }
}

class UserPreferences {
  const UserPreferences({
    required this.study,
    required this.workout,
    required this.health,
    required this.reminders,
  });

  factory UserPreferences.fromMap(Map<String, dynamic>? data) {
    final Map<String, dynamic> source = data ?? <String, dynamic>{};
    return UserPreferences(
      study: StudyPreferences.fromMap(_readMap(source['study'])),
      workout: WorkoutPreferences.fromMap(_readMap(source['workout'])),
      health: HealthPreferences.fromMap(_readMap(source['health'])),
      reminders: ReminderPreferences.fromMap(_readMap(source['reminders'])),
    );
  }

  final StudyPreferences study;
  final WorkoutPreferences workout;
  final HealthPreferences health;
  final ReminderPreferences reminders;

  static Map<String, dynamic>? _readMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map(
        (key, dynamic nestedValue) => MapEntry(key.toString(), nestedValue),
      );
    }

    return null;
  }
}

class StudyPreferences {
  const StudyPreferences({
    required this.weeklyHours,
    required this.focusMinutes,
    required this.breakMinutes,
  });

  factory StudyPreferences.fromMap(Map<String, dynamic>? data) {
    final Map<String, dynamic> source = data ?? <String, dynamic>{};
    return StudyPreferences(
      weeklyHours: _readInt(source['weeklyHours']),
      focusMinutes: _readInt(source['focusMinutes']),
      breakMinutes: _readInt(source['breakMinutes']),
    );
  }

  final int? weeklyHours;
  final int? focusMinutes;
  final int? breakMinutes;
}

class WorkoutPreferences {
  const WorkoutPreferences({required this.daysPerWeek});

  factory WorkoutPreferences.fromMap(Map<String, dynamic>? data) {
    final Map<String, dynamic> source = data ?? <String, dynamic>{};
    return WorkoutPreferences(daysPerWeek: _readInt(source['daysPerWeek']));
  }

  final int? daysPerWeek;
}

class HealthPreferences {
  const HealthPreferences({
    required this.dailyWaterGlasses,
    required this.targetSleepHours,
  });

  factory HealthPreferences.fromMap(Map<String, dynamic>? data) {
    final Map<String, dynamic> source = data ?? <String, dynamic>{};
    return HealthPreferences(
      dailyWaterGlasses: _readInt(source['dailyWaterGlasses']),
      targetSleepHours: _readInt(source['targetSleepHours']),
    );
  }

  final int? dailyWaterGlasses;
  final int? targetSleepHours;
}

class ReminderPreferences {
  const ReminderPreferences({
    required this.study,
    required this.workout,
    required this.meal,
  });

  factory ReminderPreferences.fromMap(Map<String, dynamic>? data) {
    final Map<String, dynamic> source = data ?? <String, dynamic>{};
    return ReminderPreferences(
      study: _readBool(source['study']),
      workout: _readBool(source['workout']),
      meal: _readBool(source['meal']),
    );
  }

  final bool? study;
  final bool? workout;
  final bool? meal;
}

int? _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }

  return null;
}

bool? _readBool(Object? value) {
  return value is bool ? value : null;
}
