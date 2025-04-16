import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-input',
          message: 'Email and password cannot be empty',
        );
      }

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      
      // Verify user is not null
      if (userCredential.user == null) {
        throw FirebaseAuthException(
          code: 'null-user',
          message: 'Unable to sign in. Please try again.',
        );
      }

      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  // Create new user with email and password
  Future<UserCredential?> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-input',
          message: 'Email and password cannot be empty',
        );
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      print('Sign up error: ${e.code} - ${e.message}');
      rethrow; // Rethrow to handle in UI
    } catch (e) {
      print('Unexpected error during sign up: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }

  // Get auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is signed in
  bool get isSignedIn => currentUser != null;
}