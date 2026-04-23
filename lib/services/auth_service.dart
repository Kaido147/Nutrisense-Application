import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthFlowException implements Exception {
  const AuthFlowException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  const AuthService({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  }) : _auth = auth,
       _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<void> login({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthFlowException(_mapAuthError(error));
    } catch (_) {
      throw const AuthFlowException(
        'Something went wrong while logging in. Please try again.',
      );
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (error) {
      throw AuthFlowException(_mapAuthError(error));
    } catch (_) {
      throw const AuthFlowException(
        'Something went wrong while logging out. Please try again.',
      );
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    UserCredential credential;

    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthFlowException(_mapAuthError(error));
    } catch (_) {
      throw const AuthFlowException(
        'Something went wrong while creating your account. Please try again.',
      );
    }

    final User? user = credential.user;
    if (user == null) {
      throw const AuthFlowException(
        'Your account was created, but we could not finish setup. Please try logging in.',
      );
    }

    try {
      await user.updateDisplayName(displayName);
      await user.reload();

      await _firestore.collection('users').doc(user.uid).set({
        'email': email.trim(),
        'displayName': displayName,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (_) {
      await _auth.signOut();
      throw const AuthFlowException(
        'Your account was created, but we could not finish setting up your profile. Please try again.',
      );
    } catch (_) {
      await _auth.signOut();
      throw const AuthFlowException(
        'Your account was created, but we could not finish setting up your profile. Please try again.',
      );
    }
  }

  String _mapAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Your password is too weak. Use at least 6 characters.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'The email or password you entered is incorrect.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }
}
