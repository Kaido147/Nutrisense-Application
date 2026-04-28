import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoalsFlowException implements Exception {
  const GoalsFlowException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GoalsService {
  const GoalsService({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  }) : _auth = auth,
       _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<void> saveGoals({
    required List<String> studyGoals,
    required List<String> workoutGoals,
    required List<String> wellnessGoals,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw const GoalsFlowException(
        'Please log in again before saving your goals.',
      );
    }

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'goals': {
          'study': studyGoals,
          'workout': workoutGoals,
          'wellness': wellnessGoals,
        },
        'goalsUpdatedAt': FieldValue.serverTimestamp(),
        'onboardingCompleted': true,
        'onboardingCompletedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (_) {
      throw const GoalsFlowException(
        'We could not save your goals right now. Please try again.',
      );
    } catch (_) {
      throw const GoalsFlowException(
        'Something went wrong while saving your goals. Please try again.',
      );
    }
  }
}
