import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutrisense/models/prototype_data.dart';
import 'package:nutrisense/models/user_profile.dart';
import 'package:nutrisense/services/macro_calculator.dart';

class ProfileFlowException implements Exception {
  const ProfileFlowException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ProfileService {
  const ProfileService({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  }) : _auth = auth,
       _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<UserProfile?> watchCurrentUserProfile() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream<UserProfile?>.value(null);
      }

      return _firestore.collection('users').doc(user.uid).snapshots().map((
        snapshot,
      ) {
        return UserProfile.fromFirestore(
          uid: user.uid,
          data: snapshot.data(),
          authEmail: user.email,
          authDisplayName: user.displayName,
        );
      });
    });
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required DateTime? birthDate,
    required String location,
    required String bio,
  }) async {
    final User user = _requireUser();
    final String resolvedFirstName = firstName.trim();
    final String resolvedLastName = lastName.trim();
    final String displayName = '$resolvedFirstName $resolvedLastName'.trim();

    if (displayName.isEmpty) {
      throw const ProfileFlowException(
        'Please provide your first and last name.',
      );
    }

    try {
      await user.updateDisplayName(displayName);
      await user.reload();

      await _firestore.collection('users').doc(user.uid).set({
        'displayName': displayName,
        'firstName': resolvedFirstName,
        'lastName': resolvedLastName,
        'phoneNumber': _nullableString(phoneNumber),
        'birthDate': birthDate == null ? null : Timestamp.fromDate(birthDate),
        'location': _nullableString(location),
        'bio': _nullableString(bio),
        'profileUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (_) {
      throw const ProfileFlowException(
        'We could not save your profile right now. Please try again.',
      );
    } catch (_) {
      throw const ProfileFlowException(
        'Something went wrong while saving your profile. Please try again.',
      );
    }
  }

  Future<void> updatePreferences({
    required int weeklyHours,
    required int focusMinutes,
    required int breakMinutes,
    required int workoutDaysPerWeek,
    required int dailyWaterGlasses,
    required int targetSleepHours,
    required bool studyReminders,
    required bool workoutReminders,
    required bool mealReminders,
  }) async {
    final User user = _requireUser();

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'preferences': {
          'study': {
            'weeklyHours': weeklyHours,
            'focusMinutes': focusMinutes,
            'breakMinutes': breakMinutes,
          },
          'workout': {'daysPerWeek': workoutDaysPerWeek},
          'health': {
            'dailyWaterGlasses': dailyWaterGlasses,
            'targetSleepHours': targetSleepHours,
          },
          'reminders': {
            'study': studyReminders,
            'workout': workoutReminders,
            'meal': mealReminders,
          },
        },
        'preferencesUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (_) {
      throw const ProfileFlowException(
        'We could not save your preferences right now. Please try again.',
      );
    } catch (_) {
      throw const ProfileFlowException(
        'Something went wrong while saving your preferences. Please try again.',
      );
    }
  }

  /// Calculates and saves daily macro targets based on health profile
  Future<DailyMacros> calculateAndSaveDailyMacros(
    HealthProfile healthProfile,
  ) async {
    final User user = _requireUser();

    try {
      final macros = MacroCalculator.calculateMacros(healthProfile);

      await _firestore.collection('users').doc(user.uid).set({
        'dailyMacros': {
          'calories': macros.calories,
          'protein': macros.protein,
          'carbs': macros.carbs,
          'fat': macros.fat,
          'fiber': macros.fiber,
          'calculatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));

      return macros;
    } on ArgumentError catch (e) {
      throw ProfileFlowException('Cannot calculate macros: ${e.message}');
    } on FirebaseException catch (_) {
      throw const ProfileFlowException(
        'We could not save your daily macros right now. Please try again.',
      );
    } catch (_) {
      throw const ProfileFlowException(
        'Something went wrong while calculating your macros. Please try again.',
      );
    }
  }

  /// Gets the current daily macro targets
  Future<DailyMacros?> getDailyMacros() async {
    final User user = _requireUser();

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();
      final macrosData = data?['dailyMacros'] as Map<String, dynamic>?;

      if (macrosData == null) return null;

      return DailyMacros(
        calories: macrosData['calories'] as int? ?? 0,
        protein: macrosData['protein'] as int? ?? 0,
        carbs: macrosData['carbs'] as int? ?? 0,
        fat: macrosData['fat'] as int? ?? 0,
        fiber: macrosData['fiber'] as int? ?? 0,
      );
    } on FirebaseException catch (_) {
      throw const ProfileFlowException(
        'We could not retrieve your daily macros. Please try again.',
      );
    } catch (_) {
      throw const ProfileFlowException(
        'Something went wrong while retrieving your macros.',
      );
    }
  }

  User _requireUser() {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw const ProfileFlowException(
        'Please log in again before updating your profile.',
      );
    }

    return user;
  }

  String? _nullableString(String value) {
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
