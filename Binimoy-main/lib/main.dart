import 'package:binimoy/screens/transaction_history_screen.dart';
import 'package:binimoy/screens/add_post_screen.dart'; // Add this import
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/loading_screen.dart';
import 'screens/home_screen.dart';
import 'screens/check_auth_status.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print("Initializing Firebase...");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Update App Check configuration
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
    );
    print("Firebase initialized successfully");
  } catch (e) {
    print("Firebase initialization error: $e");
  }

  final authService = AuthService();
  runApp(MyApp(authService: authService));
}

class MyApp extends StatelessWidget {
  final AuthService authService;

  const MyApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 800), // Base design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Binimoy',
          theme: ThemeData(
            primarySwatch: Colors.green,
            scaffoldBackgroundColor: Colors.white,
            // Make text scale responsive
            textTheme: Typography.englishLike2018.apply(fontSizeFactor: 1.sp),
          ),
          home: child,
          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/home': (context) => HomeScreen(authService: authService),
            '/check-auth': (context) =>
                CheckAuthStatus(authService: authService),
            '/transaction_history': (context) =>
                const TransactionHistoryScreen(),
            '/add-post': (context) =>
                const AddPostScreen(), // Add the missing route
          },
          // Add navigation observer for debugging
          navigatorObservers: [
            NavigatorObserver(),
          ],
        );
      },
      child: FutureBuilder(
          // Add a small delay to allow Firebase to initialize auth state
          future: Future.delayed(const Duration(milliseconds: 500)),
          builder: (context, snapshot) {
            // Show loading screen until the delay completes
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingScreen();
            }

            return StreamBuilder<User?>(
              // Use StreamBuilder with authStateChanges for reactive auth state
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                // Show loading screen while determining auth state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingScreen();
                }

                // User is logged in
                if (snapshot.hasData && snapshot.data != null) {
                  print("User authenticated: ${snapshot.data!.uid}");
                  return HomeScreen(authService: authService);
                }

                // User is not logged in
                return const LoginScreen();
              },
            );
          }),
    );
  }
}
