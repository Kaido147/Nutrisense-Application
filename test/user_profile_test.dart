import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrisense/models/user_profile.dart';

void main() {
  group('UserProfile.fromFirestore', () {
    test('parses sparse documents safely', () {
      final UserProfile profile = UserProfile.fromFirestore(
        uid: 'user-1',
        data: <String, dynamic>{
          'displayName': 'Alex Johnson',
          'email': 'alex@example.com',
          'goals': <String, dynamic>{
            'study': <String>['2-3 hours/day'],
            'workout': <String>['3-4x per week'],
          },
          'onboardingCompleted': true,
        },
      );

      expect(profile.fullName, 'Alex Johnson');
      expect(profile.resolvedFirstName, 'Alex');
      expect(profile.resolvedLastName, 'Johnson');
      expect(profile.location, isNull);
      expect(profile.phoneNumber, isNull);
      expect(profile.preferences.study.weeklyHours, isNull);
      expect(profile.effectiveStudyWeeklyHours, 18);
      expect(profile.effectiveWorkoutDaysPerWeek, 4);
    });

    test('prefers rich profile and preferences fields when available', () {
      final UserProfile profile = UserProfile.fromFirestore(
        uid: 'user-2',
        authEmail: 'fallback@example.com',
        authDisplayName: 'Fallback Name',
        data: <String, dynamic>{
          'displayName': 'Alex Johnson',
          'firstName': 'Alex',
          'lastName': 'Johnson',
          'birthDate': Timestamp.fromDate(DateTime(2001, 2, 3)),
          'preferences': <String, dynamic>{
            'study': <String, dynamic>{
              'weeklyHours': 30,
              'focusMinutes': 30,
              'breakMinutes': 10,
            },
            'workout': <String, dynamic>{'daysPerWeek': 5},
            'health': <String, dynamic>{
              'dailyWaterGlasses': 9,
              'targetSleepHours': 8,
            },
            'reminders': <String, dynamic>{
              'study': true,
              'workout': false,
              'meal': true,
            },
          },
        },
      );

      expect(profile.fullName, 'Alex Johnson');
      expect(profile.displayEmail, 'fallback@example.com');
      expect(profile.birthDate, DateTime(2001, 2, 3));
      expect(profile.preferences.study.weeklyHours, 30);
      expect(profile.editorWorkoutDaysPerWeek, 5);
      expect(profile.editorMealReminders, isTrue);
    });
  });
}
