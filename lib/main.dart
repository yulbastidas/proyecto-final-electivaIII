import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_page.dart';
import 'home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://zanejjvwjarxjryaqbdc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InphbmVqanZ3amFyeGpyeWFxYmRjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjExMTkxMzcsImV4cCI6MjA3NjY5NTEzN30.eyzPKnwgGJNarL2tkaaux0DEGQXpg3f2b1WnboJpFX4',
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
