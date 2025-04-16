import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final result = await AuthService().signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (result != null) {
        // Use pushNamedAndRemoveUntil to clear the navigation stack
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed. Please try again.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Login failed. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_bag_outlined,
                        color: Colors.white, size: 28),
                    const SizedBox(width: 8),
                    const Text(
                      'Binimoy',
                      style: TextStyle(
                        fontSize: 24,
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
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(28.0),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Logo or icon
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.account_balance_wallet,
                                        size: 48,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Welcome text
                                    const Text(
                                      'Welcome Back',
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Sign in to continue',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 32),

                                    // Email field
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(16),
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
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 16,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.email_outlined,
                                            color:
                                                Colors.white.withOpacity(0.7),
                                          ),
                                          border: InputBorder.none,
                                          errorStyle: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
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
                                    const SizedBox(height: 20),

                                    // Password field
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(16),
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
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 16,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.lock_outline,
                                            color:
                                                Colors.white.withOpacity(0.7),
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons
                                                      .visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              color:
                                                  Colors.white.withOpacity(0.7),
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscurePassword =
                                                    !_obscurePassword;
                                              });
                                            },
                                          ),
                                          border: InputBorder.none,
                                          errorStyle: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        obscureText: _obscurePassword,
                                        validator: (value) =>
                                            value?.isEmpty ?? true
                                                ? 'Password is required'
                                                : null,
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Forgot password
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () {
                                          // Implement forgot password functionality
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(50, 36),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          'Forgot Password?',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color:
                                                Colors.white.withOpacity(0.8),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 32),

                                    // Login button
                                    ElevatedButton(
                                      onPressed:
                                          _isLoading ? null : _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.green.shade700,
                                        backgroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        elevation: 0,
                                        disabledBackgroundColor:
                                            Colors.white.withOpacity(0.5),
                                      ),
                                      child: _isLoading
                                          ? SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.green.shade700,
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : const Text(
                                              'Sign In',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(height: 24),

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
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pushNamed(
                                              context, '/register'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8),
                                          ),
                                          child: const Text(
                                            'Register',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
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
