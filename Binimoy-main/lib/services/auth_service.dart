import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add timeout for Firebase operations
  final Duration _timeout = const Duration(seconds: 20);

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password with timeout
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      // Use a timeout to prevent indefinite waiting
      final credential = await _auth
          .signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      )
          .timeout(_timeout, onTimeout: () {
        throw TimeoutException('Login timed out. Please try again.');
      });

      if (credential.user == null) {
        throw FirebaseAuthException(
          code: 'null-user',
          message: 'Login failed: User is null',
        );
      }

      // Force token refresh to ensure we have latest user data
      await credential.user!.getIdToken(true);

      // Update last login timestamp
      try {
        await _firestore.collection('users').doc(credential.user!.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Failed to update last login timestamp: $e');
        // Continue even if this fails
      }

      // Reload user to ensure we have latest data
      await credential.user!.reload();

      print('Login successful for user: ${credential.user!.uid}');
      return credential;
    } on TimeoutException catch (e) {
      print('Login timeout: $e');
      throw FirebaseAuthException(
        code: 'timeout',
        message: 'Login timed out. Please check your connection and try again.',
      );
    } catch (e) {
      print('Login error in AuthService: $e');
      rethrow;
    }
  }

  // Create new user with email and password
  Future<UserCredential> createUserWithEmailAndPassword(
      String email, String password,
      {String? name}) async {
    try {
      print('Starting user registration for email: $email');

      if (email.isEmpty || password.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-input',
          message: 'Email and password cannot be empty',
        );
      }

      // Create user in Firebase Auth
      print('Creating user in Firebase Auth...');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      print('User created in Firebase Auth: ${credential.user?.uid}');

      if (credential.user == null) {
        print('User creation failed: user is null');
        throw Exception('User creation failed');
      }

      // Update display name in Firebase Auth
      if (name != null && name.isNotEmpty) {
        print('Updating display name for user: ${credential.user!.uid}');
        await credential.user!.updateDisplayName(name);

        // Create user profile in Firestore
        try {
          print('Creating Firestore profile for user: ${credential.user!.uid}');
          await _firestore.collection('users').doc(credential.user!.uid).set({
            'name': name,
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
          });
          print('Firestore profile created successfully');
        } catch (e) {
          print('Firestore profile creation error: $e');
          // Continue even if Firestore profile creation fails
        }
      }

      // Reload user to ensure we have the latest data
      print('Reloading user to get latest data...');
      await credential.user!.reload();

      print('Registration completed successfully');
      return credential;
    } on FirebaseAuthException catch (e) {
      print(
          'Firebase Auth Exception during registration: ${e.code} - ${e.message}');

      // Translate Firebase error codes to user-friendly messages
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'An account already exists with this email.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'weak-password':
          message = 'Password is too weak. Please use a stronger password.';
          break;
        case 'operation-not-allowed':
          message = 'Email/password accounts are not enabled.';
          break;
        default:
          message = e.message ?? 'An error occurred during registration.';
      }
      throw FirebaseAuthException(
        code: e.code,
        message: message,
      );
    } catch (e) {
      print('Unexpected registration error: $e');
      throw FirebaseAuthException(
        code: 'unknown',
        message:
            'An unexpected error occurred during registration. Please try again.',
      );
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      print('Signing out user: ${currentUser?.uid}');
      await _auth.signOut();
      print('User signed out successfully');
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }

  // Get auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is signed in
  bool get isSignedIn => currentUser != null;

  // Ensure authentication is complete - this will help ensure auth state is propagated
  Future<bool> ensureAuthCompleted(User user) async {
    try {
      // Wait for a short time to allow auth state to propagate
      await Future.delayed(const Duration(milliseconds: 300));

      // Verify the user is still logged in
      final currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.uid != user.uid) {
        print(
            'Auth state verification failed: Current user is null or different');
        return false;
      }

      // Force reload user data
      try {
        await currentUser.reload();
      } catch (e) {
        print('User reload error: $e');
        // Continue anyway as this might not be critical
      }

      print('Auth state verification successful for user: ${currentUser.uid}');
      return true;
    } catch (e) {
      print('Error ensuring auth completion: $e');
      return false;
    }
  }
}
