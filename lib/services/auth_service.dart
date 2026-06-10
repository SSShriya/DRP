import 'package:flutter/foundation.dart';
import 'session_manager.dart';
import 'supabase_client.dart';

class AuthService {
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required bool isSociety,
  }) async {
    // ── Use web URL for web, deep link for mobile ──────────────────
    final redirectTo = kIsWeb
        ? Uri
              .base
              .origin // ← automatically uses whatever port Flutter is running on
        : 'drp://login-callback';

    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: redirectTo,
      data: {'name': name, 'is_society': isSociety},
    );

    final user = response.user;

    if (user == null) {
      throw Exception('Sign up failed. Please try again.');
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    final response = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    final session = response.session;

    if (user == null || session == null) {
      throw Exception('Login failed. Please check your credentials.');
    }

    await SessionManager.saveSession(userId: user.id);
  }
}
