import 'package:supabase_flutter/supabase_flutter.dart';
import 'session_manager.dart';

Future<String> loadUserId() async {
  // Prefer the live Supabase session user
  final user = Supabase.instance.client.auth.currentUser;
  if (user != null) return user.id;

  // Fallback to stored ID
  final id = await SessionManager.getUserId();
  if (id == null) {
    await SessionManager.clearSession();
    throw Exception("User session not found. Please log in again.");
  }
  return id;
}
