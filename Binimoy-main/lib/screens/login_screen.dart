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

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  // Add timeout duration for network operations
  final Duration _timeout = const Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );
    
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
      ),
    );
    
    _animationController.forward();
    
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
        SnackBar(
          content: Text('Password reset email sent. Please check your inbox.'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
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
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.5),
              ],
            ),
          ),
          child: SafeArea(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: Column(
                      children: [
                        // App Header
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                          child: Column(
                            children: [
                              // App Logo/Icon
                              Container(
                                width: 80.r,
                                height: 80.r,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withOpacity(0.3),
                                      Colors.white.withOpacity(0.1),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.4),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.1),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 40.r,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ),
                              SizedBox(height: 20.h),
                              
                              // App Name
                              Text(
                                'Binimoy',
                                style: TextStyle(
                                  fontSize: 32.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 2.0,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 8.h),
                              
                              // Tagline
                              Text(
                                'RENT • SELL • SWAP • REPEAT',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        // Main Content with Glass Effect
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 20.w),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30.r),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30.r),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(30.r),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 2,
                                    ),
                                  ),
                                  child: SingleChildScrollView(
                                    padding: EdgeInsets.all(30.r),
                                    child: Form(
                                      key: _formKey,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          SizedBox(height: 20.h),
                                          
                                          // Welcome Text
                                          Text(
                                            'Welcome Back',
                                            style: TextStyle(
                                              fontSize: 28.sp,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(height: 8.h),
                                          Text(
                                            'Sign in to continue your saree journey',
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              color: Colors.white.withOpacity(0.8),
                                              fontWeight: FontWeight.w400,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(height: 40.h),

                                          // Error Message
                                          if (_errorMessage != null) ...[
                                            Container(
                                              padding: EdgeInsets.all(16.r),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(16.r),
                                                border: Border.all(
                                                  color: Colors.red.withOpacity(0.3),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.error_outline,
                                                    color: Colors.white,
                                                    size: 20.r,
                                                  ),
                                                  SizedBox(width: 12.w),
                                                  Expanded(
                                                    child: Text(
                                                      _errorMessage!,
                                                      style: TextStyle(
                                                        fontSize: 14.sp,
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(height: 24.h),
                                          ],

                                          // Email Field
                                          _buildGlassTextField(
                                            controller: _emailController,
                                            labelText: 'Email Address',
                                            hintText: 'Enter your email',
                                            prefixIcon: Icons.email_outlined,
                                            keyboardType: TextInputType.emailAddress,
                                            validator: (value) => value?.isEmpty ?? true 
                                              ? 'Email is required' 
                                              : null,
                                          ),
                                          SizedBox(height: 20.h),

                                          // Password Field
                                          _buildGlassTextField(
                                            controller: _passwordController,
                                            labelText: 'Password',
                                            hintText: 'Enter your password',
                                            prefixIcon: Icons.lock_outline,
                                            isPassword: true,
                                            obscureText: _obscurePassword,
                                            onToggleVisibility: () {
                                              setState(() {
                                                _obscurePassword = !_obscurePassword;
                                              });
                                            },
                                            validator: (value) => value?.isEmpty ?? true 
                                              ? 'Password is required' 
                                              : null,
                                          ),
                                          SizedBox(height: 16.h),

                                          // Forgot Password
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: GestureDetector(
                                              onTap: _isLoading ? null : _resetPassword,
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 16.w, 
                                                  vertical: 8.h
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12.r),
                                                  border: Border.all(
                                                    color: Colors.white.withOpacity(0.2),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Text(
                                                  'Forgot Password?',
                                                  style: TextStyle(
                                                    fontSize: 13.sp,
                                                    color: Colors.white.withOpacity(0.9),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 40.h),

                                          // Login Button
                                          Container(
                                            height: 56.h,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(16.r),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(16.r),
                                              child: BackdropFilter(
                                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                                child: ElevatedButton(
                                                  onPressed: _isLoading ? null : _handleLogin,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.white.withOpacity(0.2),
                                                    foregroundColor: Colors.white,
                                                    elevation: 0,
                                                    shadowColor: Colors.transparent,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(16.r),
                                                      side: BorderSide(
                                                        color: Colors.white.withOpacity(0.3),
                                                        width: 1.5,
                                                      ),
                                                    ),
                                                  ),
                                                  child: _isLoading
                                                      ? SizedBox(
                                                          height: 24.r,
                                                          width: 24.r,
                                                          child: CircularProgressIndicator(
                                                            color: Colors.white,
                                                            strokeWidth: 2.5,
                                                          ),
                                                        )
                                                      : Row(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Icon(Icons.login, size: 20.r),
                                                            SizedBox(width: 8.w),
                                                            Text(
                                                              'Sign In',
                                                              style: TextStyle(
                                                                fontSize: 16.sp,
                                                                fontWeight: FontWeight.bold,
                                                                letterSpacing: 0.5,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 30.h),

                                          // Register Link
                                          Container(
                                            padding: EdgeInsets.all(16.r),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.05),
                                              borderRadius: BorderRadius.circular(16.r),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(0.2),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'Don\'t have an account? ',
                                                  style: TextStyle(
                                                    color: Colors.white.withOpacity(0.8),
                                                    fontSize: 14.sp,
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: () => Navigator.pushNamed(context, '/register'),
                                                  child: Text(
                                                    'Register',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                      fontSize: 14.sp,
                                                      decoration: TextDecoration.underline,
                                                      decorationColor: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: 20.h),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool? obscureText,
    VoidCallback? onToggleVisibility,
    required String? Function(String?) validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: TextFormField(
              controller: controller,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15.sp,
              ),
              decoration: InputDecoration(
                labelText: labelText,
                labelStyle: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
                hintText: hintText,
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                ),
                prefixIcon: Icon(
                  prefixIcon,
                  color: Colors.white.withOpacity(0.8),
                  size: 20.r,
                ),
                suffixIcon: isPassword
                    ? IconButton(
                        icon: Icon(
                          obscureText ?? false
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.white.withOpacity(0.8),
                          size: 20.r,
                        ),
                        onPressed: onToggleVisibility,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 20.h,
                  horizontal: 16.w,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                errorStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 12.sp,
                ),
              ),
              keyboardType: keyboardType,
              obscureText: obscureText ?? false,
              validator: validator,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
