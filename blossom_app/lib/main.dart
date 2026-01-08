import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:blossom_app/features/customer/screens/customer_home.dart';
import 'package:blossom_app/features/onboarding/screens/onboarding_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'features/admin/screens/admin_auth_screen.dart';
import 'package:blossom_app/features/staff/screens/staff_dashboard.dart';
import 'package:blossom_app/features/admin/screens/main_layout.dart';

// IMPORTANT: This flag determines if the app forces onboarding flow.
// On Web, this should generally be false so it defaults to Admin/Staff portals if not logged in.
const bool kForceOnboarding = bool.fromEnvironment(
  'FORCE_ONBOARDING',
  defaultValue: true,
);

void main() async {
  // Ensure Flutter binding is initialized BEFORE any async calls
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  // This uses firebase_options.dart which automatically handles Web vs Mobile config
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase Initialization Error: $e");
    // Continue running app even if Firebase fails or times out
  }

  // Set up Firebase Database persistence for offline support (Mobile only)
  try {
    if (!kIsWeb) {
      FirebaseDatabase.instance.setPersistenceEnabled(true);
      FirebaseDatabase.instance.setPersistenceCacheSizeBytes(10 * 1024 * 1024);
    }
  } catch (e) {
    debugPrint('RTDB persistence setup error: $e');
  }

  runApp(const MyApp());
}

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blossom App',
      debugShowCheckedModeBanner: false,
      scrollBehavior: AppScrollBehavior(),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFCFA6A6), // Dusty Rose
          primary: const Color(0xFFCFA6A6),
          secondary: const Color(0xFF556B2F), // Olive Green
          surface: const Color(0xFFFFF8E1), // Beige
          onPrimary: Colors.white,
          onSecondary: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.poppinsTextTheme(),
        cardTheme: CardThemeData(
          elevation: 4,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFCFA6A6), width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFCFA6A6), // Dusty Rose
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      routes: {
        '/admin': (context) => const AdminAuthScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
      },
      // Determine the initial screen based on onboarding flag and auth status
      home: kForceOnboarding
          ? const OnboardingScreen()
          : Builder(
              builder: (context) {
                final bool firebaseReady = Firebase.apps.isNotEmpty;
                if (!firebaseReady) {
                  // If Firebase didn't init, show Admin Auth on Web, Onboarding on Mobile
                  return kIsWeb
                      ? const AdminAuthScreen()
                      : const OnboardingScreen();
                }
                return StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  initialData: FirebaseAuth.instance.currentUser,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        backgroundColor: Color(0xFFFFF8E1),
                        body: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFCFA6A6),
                          ),
                        ),
                      );
                    }
                    if (snapshot.hasData) {
                      final user = snapshot.data!;
                      final email = user.email;

                      if (email != null) {
                        final isAdmin =
                            email.startsWith('admin') ||
                            email.startsWith('ad.blossom');

                        // Scenario 1: Admin Portal (Web, no FORCE_ONBOARDING)
                        if (kIsWeb && !kForceOnboarding) {
                          if (!isAdmin) {
                            // Non-admin trying to access Admin Portal
                            // Sign out and show Admin Auth
                            FirebaseAuth.instance.signOut();
                            return const AdminAuthScreen();
                          }
                          return const MainLayout();
                        }

                        // Scenario 2: Customer/Staff Portal (Mobile or Web with FORCE_ONBOARDING)
                        if (isAdmin) {
                          // Admin trying to access Customer/Staff App
                          // Sign out and show Onboarding/Login
                          FirebaseAuth.instance.signOut();
                          return const OnboardingScreen();
                        }

                        if (email.startsWith('staff')) {
                          return const StaffDashboard();
                        }
                      }

                      // Default to Customer Home for non-admin, non-staff users
                      return const CustomerHomeScreen();
                    }
                    // Not logged in
                    if (kIsWeb) {
                      return const AdminAuthScreen();
                    }
                    return const OnboardingScreen();
                  },
                );
              },
            ),
    );
  }
}
