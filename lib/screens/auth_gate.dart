import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_class_checkin/screens/home_screen.dart';
import 'package:smart_class_checkin/screens/welcome_screen.dart';
import 'package:smart_class_checkin/services/auth_session_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthSession?>(
      valueListenable: AuthSessionService.instance.sessionNotifier,
      builder: (context, localSession, _) {
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            final hasFirebaseUser = snapshot.data != null;
            final hasLocalSession = localSession != null;

            if (snapshot.connectionState == ConnectionState.waiting &&
                !hasLocalSession) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!hasFirebaseUser && !hasLocalSession) {
              return const WelcomeScreen();
            }

            return const HomeScreen();
          },
        );
      },
    );
  }
}
