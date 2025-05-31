import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _logoController;
  late AnimationController _pulseController;
  late AnimationController _loadingController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _logoAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();

    // Main animation controller
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Logo animation controller
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Pulse animation controller
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Loading animation controller
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
      ),
    );

    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _loadingController,
        curve: Curves.linear,
      ),
    );

    _startAnimations();
    _navigateToNext();
  }

  void _startAnimations() async {
    if (!mounted || _isDisposed) return;

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted || _isDisposed) return;

    _mainController.forward();

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted || _isDisposed) return;

    _logoController.forward();
    _pulseController.repeat(reverse: true);
    _loadingController.repeat();
  }

  _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted || _isDisposed) return;
    Navigator.pushReplacementNamed(context, '/check-auth');
  }

  @override
  void dispose() {
    _isDisposed = true;
    _mainController.dispose();
    _logoController.dispose();
    _pulseController.dispose();
    _loadingController.dispose();
    super.dispose();
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
                Colors.black.withOpacity(0.4),
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
          child: SafeArea(
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Main Logo Section with Glass Effect
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 50.w),
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
                                  padding: EdgeInsets.symmetric(
                                    vertical: 80.h,
                                    horizontal: 50.w,
                                  ),
                                  child: Column(
                                    children: [
                                      // Animated Logo with Pulse Effect
                                      AnimatedBuilder(
                                        animation: _logoController,
                                        builder: (context, child) {
                                          return FadeTransition(
                                            opacity: _logoAnimation,
                                            child: Transform.scale(
                                              scale: _logoAnimation.value,
                                              child: AnimatedBuilder(
                                                animation: _pulseController,
                                                builder: (context, child) {
                                                  return Transform.scale(
                                                    scale: _pulseAnimation.value,
                                                    child: Container(
                                                      width: 100.r,
                                                      height: 100.r,
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
                                                          width: 3,
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.white.withOpacity(0.1),
                                                            blurRadius: 30,
                                                            spreadRadius: 10,
                                                          ),
                                                        ],
                                                      ),
                                                      child: Center(
                                                        child: Icon(
                                                          Icons.shopping_bag_outlined,
                                                          size: 50.r,
                                                          color: Colors.white.withOpacity(0.9),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                      ),

                                      SizedBox(height: 30.h),

                                      // App Name
                                      AnimatedBuilder(
                                        animation: _logoController,
                                        builder: (context, child) {
                                          return FadeTransition(
                                            opacity: _logoAnimation,
                                            child: Text(
                                              'Binimoy',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 36.sp,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 3.0,
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black.withOpacity(0.3),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),

                                      SizedBox(height: 16.h),

                                      // Tagline
                                      AnimatedBuilder(
                                        animation: _logoController,
                                        builder: (context, child) {
                                          return FadeTransition(
                                            opacity: _logoAnimation,
                                            child: Text(
                                              'RENT • SELL • SWAP • REPEAT',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.8),
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 1.5,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 80.h),

                          // Loading Section with Glass Effect
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 80.w),
                            padding: EdgeInsets.symmetric(vertical: 30.h, horizontal: 40.w),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20.r),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20.r),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1.5,
                                    ),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 30.h, horizontal: 40.w),
                                  child: Column(
                                    children: [
                                      // Loading Spinner
                                      AnimatedBuilder(
                                        animation: _loadingController,
                                        builder: (context, child) {
                                          return FadeTransition(
                                            opacity: _logoAnimation,
                                            child: Transform.rotate(
                                              angle: _rotationAnimation.value * 2 * 3.141592653589793,
                                              child: Container(
                                                width: 40.r,
                                                height: 40.r,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.white.withOpacity(0.3),
                                                    width: 3,
                                                  ),
                                                ),
                                                child: Stack(
                                                  children: [
                                                    Positioned.fill(
                                                      child: CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 3,
                                                        backgroundColor: Colors.transparent,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),

                                      SizedBox(height: 20.h),

                                      // Loading Text
                                      AnimatedBuilder(
                                        animation: _logoController,
                                        builder: (context, child) {
                                          return FadeTransition(
                                            opacity: _logoAnimation,
                                            child: Text(
                                              'Loading...',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.9),
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                          );
                                        },
                                      ),

                                      SizedBox(height: 12.h),

                                      // Animated Loading Dots
                                      AnimatedBuilder(
                                        animation: _loadingController,
                                        builder: (context, child) {
                                          return FadeTransition(
                                            opacity: _logoAnimation,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: List.generate(3, (index) {
                                                final delay = index * 0.3;
                                                final animationValue = (_rotationAnimation.value + delay) % 1.0;
                                                final opacity = (0.3 + 0.7 * (1 - (animationValue - 0.5).abs() * 2)).clamp(0.3, 1.0);

                                                return AnimatedContainer(
                                                  duration: Duration(milliseconds: 100),
                                                  width: 8.r,
                                                  height: 8.r,
                                                  margin: EdgeInsets.symmetric(horizontal: 3.w),
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Colors.white.withOpacity(opacity),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.white.withOpacity(0.3),
                                                        blurRadius: 8,
                                                        spreadRadius: 2,
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 60.h),

                          // Footer Text
                          AnimatedBuilder(
                            animation: _logoController,
                            builder: (context, child) {
                              return FadeTransition(
                                opacity: _logoAnimation,
                                child: Text(
                                  'Preparing your saree experience...',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
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
}
