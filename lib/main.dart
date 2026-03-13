import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:smart_class_checkin/firebase_options.dart';
import 'package:smart_class_checkin/screens/auth_gate.dart';
import 'package:smart_class_checkin/services/auth_session_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? startupError;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    startupError = 'Failed to initialize Firebase. Please refresh the page.';
    debugPrint('Firebase init error: $e');
  }

  try {
    await AuthSessionService.instance.loadSession();
  } catch (e) {
    debugPrint('Session load error: $e');
  }

  runApp(SmartClassApp(startupError: startupError));
}

class SmartClassApp extends StatelessWidget {
  const SmartClassApp({super.key, this.startupError});

  final String? startupError;

  // Teal Harmony palette
  static const primaryTeal = Color(0xFF0D9488);
  static const secondaryAqua = Color(0xFF99F6E4);
  static const surfaceMint = Color(0xFFF0FDFA);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Class Check-in & Learning Reflection App',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: surfaceMint,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryTeal,
          primary: primaryTeal,
          secondary: secondaryAqua,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: surfaceMint,
          foregroundColor: Color(0xFF134E4A),
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.80),
          labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
          floatingLabelStyle: const TextStyle(
            color: primaryTeal,
            fontWeight: FontWeight.w600,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: primaryTeal.withValues(alpha: 0.30),
              width: 1.2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primaryTeal, width: 1.8),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.8),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primaryTeal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      home: startupError == null
          ? const AuthGate()
          : _StartupErrorScreen(message: startupError!),
    );
  }
}

class _StartupErrorScreen extends StatelessWidget {
  const _StartupErrorScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(height: 12),
              const Text(
                'Startup Error',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Try a hard refresh: Ctrl + Shift + R',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
