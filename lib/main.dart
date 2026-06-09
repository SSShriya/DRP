import 'package:drp/screens/main_shell.dart';
import 'package:drp/screens/society_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/signup_screen.dart';
import 'services/supabase_client.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  Future<bool>? _committeeFuture;
  String? _lastUserId;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [routeObserver],
      home: StreamBuilder<AuthState>(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          final session = snapshot.data?.session;
          if (session == null) return const SignUpScreen();

          // Only re-fetch if the user changed
          if (_lastUserId != session.user.id) {
            _lastUserId = session.user.id;
            _committeeFuture = _isCommitteeMember(session.user.id);
          }

          return FutureBuilder<bool>(
            future: _committeeFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              return snap.data == true ? const SocietyScreen() : const MainShell();
            },
          );
        },
      ),
      routes: {
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const MainShell(),
      },
    );
  }
}

Future<bool> _isCommitteeMember(String userId) async {
  // Retry up to 3 times with a short delay to handle post-signup race condition
  for (int attempt = 0; attempt < 3; attempt++) {
    try {
      final result = await supabase
          .from('users')
          .select()
          .eq('id', userId);
      return result[0]['is_society'];
    } catch (_) {}
    if (attempt < 2) await Future.delayed(const Duration(milliseconds: 500));
  }
  return false;
}
