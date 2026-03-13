import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:smart_class_checkin/firebase_options.dart';

class AuthApiException implements Exception {
  AuthApiException({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String toString() => 'AuthApiException($code): $message';
}

class AuthApiResult {
  const AuthApiResult({
    required this.email,
    required this.localId,
    this.displayName,
  });

  final String email;
  final String localId;
  final String? displayName;
}

class AuthApiService {
  AuthApiService._();

  static final AuthApiService instance = AuthApiService._();

  final http.Client _client = http.Client();

  String get _apiKey => DefaultFirebaseOptions.web.apiKey;

  Uri _uri(String method) {
    return Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:$method?key=$_apiKey',
    );
  }

  Future<AuthApiResult> signUp({
    required String email,
    required String password,
  }) async {
    final body = {
      'email': email,
      'password': password,
      'returnSecureToken': true,
    };

    final response = await _client.post(
      _uri('signUp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final data = _decodeBody(response.body);
    _throwIfError(data);

    return AuthApiResult(
      email: (data['email'] as String?) ?? email,
      localId: (data['localId'] as String?) ?? '',
      displayName: data['displayName'] as String?,
    );
  }

  Future<AuthApiResult> signIn({
    required String email,
    required String password,
  }) async {
    final body = {
      'email': email,
      'password': password,
      'returnSecureToken': true,
    };

    final response = await _client.post(
      _uri('signInWithPassword'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final data = _decodeBody(response.body);
    _throwIfError(data);

    return AuthApiResult(
      email: (data['email'] as String?) ?? email,
      localId: (data['localId'] as String?) ?? '',
      displayName: data['displayName'] as String?,
    );
  }

  static Map<String, dynamic> _decodeBody(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return {};
  }

  static void _throwIfError(Map<String, dynamic> data) {
    final errorData = data['error'];
    if (errorData is! Map) {
      return;
    }

    final code = (errorData['message'] as String?) ?? 'UNKNOWN';
    throw AuthApiException(code: code, message: _friendlyMessage(code));
  }

  static String _friendlyMessage(String code) {
    switch (code) {
      case 'EMAIL_EXISTS':
        return 'This email is already registered. Try logging in instead.';
      case 'OPERATION_NOT_ALLOWED':
        return 'Email/password sign-in is disabled in Firebase settings.';
      case 'TOO_MANY_ATTEMPTS_TRY_LATER':
        return 'Too many attempts. Please wait and try again.';
      case 'EMAIL_NOT_FOUND':
      case 'INVALID_PASSWORD':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Email or password is incorrect. Please try again.';
      case 'INVALID_EMAIL':
        return 'Invalid email address.';
      case 'WEAK_PASSWORD : Password should be at least 6 characters':
      case 'WEAK_PASSWORD':
        return 'Password too weak. Use at least 6 characters.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
