import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dart:ui';
import 'dart:io';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  // Add timeout duration for network operations
  final Duration _timeout = const Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    // Check if user is already signed in
    _checkCurrentUser();
  }

  void _checkCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print("User already signed in: ${user.uid}");
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      print("No user is signed in");
    }
  }

  void _resetPassword() async {
    // Validate email
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email to reset password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent. Please check your inbox.'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to send reset email. Please try again.';
      });
    }
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Login attempt
      final result = await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      // If login successful but navigation hasn't happened automatically
      if (result.user != null) {
        print("Login successful, ensuring auth state propagation...");

        // Ensure auth is complete before navigation
        final authVerified =
            await _authService.ensureAuthCompleted(result.user!);

        if (!mounted) return;

        if (authVerified) {
          // Clear any error state before navigation
          setState(() {
            _isLoading = false;
            _errorMessage = null;
          });

          print("Auth state verified, navigating to home screen");
          // Use Navigator.pushAndRemoveUntil to ensure clean navigation state
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/home',
            (route) => false, // Remove all previous routes
          );
        } else {
          // This is unlikely to happen but handle it just in case
          setState(() {
            _isLoading = false;
            _errorMessage =
                'Authentication state failed to update. Please try again.';
          });
        }
      } else {
        throw Exception('Login failed: User is null');
      }
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      setState(() {
        _isLoading = false;
        _errorMessage = _getReadableErrorMessage(e);
      });
    } on TimeoutException catch (e) {
      print('Login timeout: $e');
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Login timed out. Please check your connection and try again.';
      });
    } catch (e) {
      print('Unexpected login error: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    }
  }

  // Helper method to convert Firebase errors to user-friendly messages
  String _getReadableErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many unsuccessful login attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'operation-not-allowed':
        return 'Email/password login is not enabled. Please contact support.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }

  @override
  Widget build(BuildContext context) {
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
        child: SafeArea(
          child: Column(
            children: [
              // App Title
              Padding(
                padding: EdgeInsets.all(16.0.r),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_bag_outlined,
                        color: Colors.white, size: 28.r),
                    SizedBox(width: 8.w),
                    Text(
                      'Binimoy',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Main content
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.0.w),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(24.r),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 12.r,
                              offset: Offset(0, 4.h),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24.r),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Padding(
                              padding: EdgeInsets.all(28.0.r),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Logo or icon
                                    Container(
                                      padding: EdgeInsets.all(16.r),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.account_balance_wallet,
                                        size: 48.r,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 24.h),

                                    // Welcome text
                                    Text(
                                      'Welcome Back',
                                      style: TextStyle(
                                        fontSize: 26.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      'Sign in to continue',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 32.h),

                                    // Error message display
                                    if (_errorMessage != null) ...[
                                      SizedBox(height: 16.h),
                                      Container(
                                        padding: EdgeInsets.all(12.r),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(12.r),
                                          border: Border.all(
                                            color: Colors.red.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          _errorMessage!,
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      SizedBox(height: 16.h),
                                    ],

                                    // Email field
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius:
                                            BorderRadius.circular(16.r),
                                      ),
                                      child: TextFormField(
                                        controller: _emailController,
                                        style: TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          hintText: 'Email',
                                          hintStyle: TextStyle(
                                              color: Colors.white
                                                  .withOpacity(0.7)),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 20.w,
                                            vertical: 16.h,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.email_outlined,
                                            color:
                                                Colors.white.withOpacity(0.7),
                                            size: 20.r,
                                          ),
                                          border: InputBorder.none,
                                          errorStyle: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12.sp,
                                          ),
                                        ),
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        validator: (value) =>
                                            value?.isEmpty ?? true
                                                ? 'Email is required'
                                                : null,
                                      ),
                                    ),
                                    SizedBox(height: 20.h),

                                    // Password field
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius:
                                            BorderRadius.circular(16.r),
                                      ),
                                      child: TextFormField(
                                        controller: _passwordController,
                                        style: TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          hintText: 'Password',
                                          hintStyle: TextStyle(
                                              color: Colors.white
                                                  .withOpacity(0.7)),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 20.w,
                                            vertical: 16.h,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.lock_outline,
                                            color:
                                                Colors.white.withOpacity(0.7),
                                            size: 20.r,
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons
                                                      .visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              color:
                                                  Colors.white.withOpacity(0.7),
                                              size: 20.r,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscurePassword =
                                                    !_obscurePassword;
                                              });
                                            },
                                          ),
                                          border: InputBorder.none,
                                          errorStyle: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12.sp,
                                          ),
                                        ),
                                        obscureText: _obscurePassword,
                                        validator: (value) =>
                                            value?.isEmpty ?? true
                                                ? 'Password is required'
                                                : null,
                                      ),
                                    ),
                                    SizedBox(height: 12.h),

                                    // Forgot password
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed:
                                            _isLoading ? null : _resetPassword,
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size(50.w, 36.h),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          'Forgot Password?',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color:
                                                Colors.white.withOpacity(0.8),
                                            fontSize: 14.sp,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 32.h),

                                    // Login button
                                    ElevatedButton(
                                      onPressed:
                                          _isLoading ? null : _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.green.shade700,
                                        backgroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                            vertical: 16.h),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16.r),
                                        ),
                                        elevation: 0,
                                        disabledBackgroundColor:
                                            Colors.white.withOpacity(0.5),
                                      ),
                                      child: _isLoading
                                          ? SizedBox(
                                              height: 20.r,
                                              width: 20.r,
                                              child: CircularProgressIndicator(
                                                color: Colors.green.shade700,
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : Text(
                                              'Sign In',
                                              style: TextStyle(
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                    SizedBox(height: 24.h),

                                    // Register link
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Don\'t have an account?',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.7),
                                            fontSize: 14.sp,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pushNamed(
                                              context, '/register'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 8.w),
                                          ),
                                          child: Text(
                                            'Register',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              fontSize: 14.sp,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
