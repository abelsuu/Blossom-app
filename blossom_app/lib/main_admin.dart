// main_admin.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'features/admin/screens/admin_auth_screen.dart';

void main() async {
  // This is the entry point for the admin version of the Blossom app.
  // It initializes Firebase and sets up the app to run the AdminAuthScreen.
  // To run this app, make sure you are in the 'blossom_app' directory
  // and execute 'flutter run -t lib/main_admin.dart'.

  // Ensure Flutter binding is initialized BEFORE any async calls
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint("Firebase Initialization Error/Timeout: $e");
    // Continue running app even if Firebase fails or times out
  }

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
      title: 'Blossom Admin',
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
        scaffoldBackgroundColor: const Color(0xFFFFF8E1),
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
      // This app is specifically for admin users, so we go directly to the
      // AdminAuthScreen.
      home: const AdminAuthScreen(),
    );
  }
}
