import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dart:ui';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  void _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.createUserWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
        name: _nameController.text,
      );

      if (!mounted) return;

      if (result.user != null) {
        print("Registration successful, ensuring auth state propagation...");

        // Ensure auth is complete before navigation
        final authVerified =
            await _authService.ensureAuthCompleted(result.user!);

        if (!mounted) return;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful!'),
            backgroundColor: Colors.green,
          ),
        );

        if (authVerified) {
          print("Auth state verified, navigating to home screen");
          // Use pushNamedAndRemoveUntil to clear navigation history
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/home',
            (route) => false, // Remove all previous routes
          );
        } else {
          // This is unlikely but handle it just in case
          setState(() {
            _isLoading = false;
            _errorMessage =
                'Authentication state failed to update. Please try again or log in.';
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message ?? 'Registration failed';
      });
    } catch (e) {
      print('Registration error: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Registration failed: ${e.toString()}';
      });
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
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back,
                          color: Colors.white, size: 24.r),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'Binimoy',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 48.w), // For balance
                  ],
                ),
              ),

              // Main content
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 24.0.w, vertical: 16.0.h),
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
                                        Icons.person_add,
                                        size: 48.r,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 24.h),

                                    // Title text
                                    Text(
                                      'Create Account',
                                      style: TextStyle(
                                        fontSize: 26.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      'Sign up to get started',
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

                                    // Name field
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius:
                                            BorderRadius.circular(16.r),
                                      ),
                                      child: TextFormField(
                                        controller: _nameController,
                                        style: const TextStyle(
                                            color: Colors.white),
                                        decoration: InputDecoration(
                                          hintText: 'Full Name',
                                          hintStyle: TextStyle(
                                              color: Colors.white
                                                  .withOpacity(0.7)),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 20.w,
                                            vertical: 16.h,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.person_outline,
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
                                        validator: (value) =>
                                            value?.isEmpty ?? true
                                                ? 'Name is required'
                                                : null,
                                      ),
                                    ),
                                    SizedBox(height: 20.h),

                                    // Email field
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius:
                                            BorderRadius.circular(16.r),
                                      ),
                                      child: TextFormField(
                                        controller: _emailController,
                                        style: const TextStyle(
                                            color: Colors.white),
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
                                        validator: (value) {
                                          if (value?.isEmpty ?? true) {
                                            return 'Email is required';
                                          }
                                          if (!value!.contains('@')) {
                                            return 'Please enter a valid email';
                                          }
                                          return null;
                                        },
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
                                        style: const TextStyle(
                                            color: Colors.white),
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
                                        validator: (value) {
                                          if (value?.isEmpty ?? true) {
                                            return 'Password is required';
                                          }
                                          if (value!.length < 6) {
                                            return 'Password must be at least 6 characters';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    SizedBox(height: 20.h),

                                    // Confirm Password field
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius:
                                            BorderRadius.circular(16.r),
                                      ),
                                      child: TextFormField(
                                        controller: _confirmPasswordController,
                                        style: const TextStyle(
                                            color: Colors.white),
                                        decoration: InputDecoration(
                                          hintText: 'Confirm Password',
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
                                              _obscureConfirmPassword
                                                  ? Icons
                                                      .visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              color:
                                                  Colors.white.withOpacity(0.7),
                                              size: 20.r,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscureConfirmPassword =
                                                    !_obscureConfirmPassword;
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
                                        obscureText: _obscureConfirmPassword,
                                        validator: (value) {
                                          if (value?.isEmpty ?? true) {
                                            return 'Please confirm your password';
                                          }
                                          if (value !=
                                              _passwordController.text) {
                                            return 'Passwords do not match';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    SizedBox(height: 32.h),

                                    // Register button
                                    ElevatedButton(
                                      onPressed: _isLoading ? null : _register,
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
                                              'Sign Up',
                                              style: TextStyle(
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                    SizedBox(height: 12.h),

                                    // Login link
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Already have an account?',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.7),
                                            fontSize: 14.sp,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 8.w),
                                          ),
                                          child: Text(
                                            'Log In',
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
