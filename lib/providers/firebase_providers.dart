import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrisense/models/user_profile.dart';
import 'package:nutrisense/services/auth_service.dart';
import 'package:nutrisense/services/goals_service.dart';
import 'package:nutrisense/services/profile_service.dart';

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

final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) {
  return ref.watch(profileServiceProvider).watchCurrentUserProfile();
});
