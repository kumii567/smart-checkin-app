import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthSession {
  const AuthSession({required this.email, this.displayName});

  final String email;
  final String? displayName;
}

class AuthSessionService {
  AuthSessionService._();

  static final AuthSessionService instance = AuthSessionService._();

  static const _emailKey = 'auth_email';
  static const _nameKey = 'auth_display_name';

  final ValueNotifier<AuthSession?> sessionNotifier =
      ValueNotifier<AuthSession?>(null);

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_emailKey);
    if (email == null || email.isEmpty) {
      sessionNotifier.value = null;
      return;
    }

    final displayName = prefs.getString(_nameKey);
    sessionNotifier.value = AuthSession(email: email, displayName: displayName);
  }

  Future<void> saveSession({required String email, String? displayName}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email);

    final trimmedName = displayName?.trim();
    if (trimmedName == null || trimmedName.isEmpty) {
      await prefs.remove(_nameKey);
    } else {
      await prefs.setString(_nameKey, trimmedName);
    }

    sessionNotifier.value = AuthSession(email: email, displayName: trimmedName);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emailKey);
    await prefs.remove(_nameKey);
    sessionNotifier.value = null;
  }
}
