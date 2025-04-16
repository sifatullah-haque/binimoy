import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class CheckAuthStatus extends StatefulWidget {
  final AuthService authService;

  const CheckAuthStatus({super.key, required this.authService});

  @override
  State<CheckAuthStatus> createState() => _CheckAuthStatusState();
}

class _CheckAuthStatusState extends State<CheckAuthStatus> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      print("Checking auth status...");
      final user = FirebaseAuth.instance.currentUser;
      print("Current user: ${user?.uid}");

      if (user != null) {
        // Verify if the user's token is still valid
        try {
          await user.getIdToken(true); // Force token refresh to verify validity
          setState(() {
            _isAuthenticated = true;
            _isLoading = false;
          });
          print("User is authenticated");
        } catch (e) {
          print("Token refresh failed: $e");
          // If token refresh fails, user is not authenticated
          setState(() {
            _isAuthenticated = false;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isAuthenticated = false;
          _isLoading = false;
        });
        print("No user logged in");
      }
    } catch (e) {
      print('Authentication check error: $e');
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.green.shade800,
                Colors.teal.shade600,
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    if (_isAuthenticated) {
      // Use Future.microtask to navigate after the current build cycle completes
      Future.microtask(() => Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => HomeScreen(authService: widget.authService),
            ),
          ));
    } else {
      // Use Future.microtask to navigate after the current build cycle completes
      Future.microtask(() => Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
          ));
    }

    // Return a loading screen while we're navigating
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.green.shade800,
              Colors.teal.shade600,
            ],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }
}
