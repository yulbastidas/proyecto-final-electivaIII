import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_page.dart';
import 'home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://<TU-PROYECTO>.supabase.co',
    anonKey: '<TU-ANON-KEY>',
  );
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    return MaterialApp(
      title: 'Mascotas',
      routes: {
        '/': (_) => session == null ? const AuthPage() : const HomePage(),
        '/home': (_) => const HomePage(),
      },
      initialRoute: '/',
    );
  }
}
