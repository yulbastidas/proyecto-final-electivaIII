// lib/main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'presentation/pages/auth_page.dart';
import 'presentation/pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init(); // <- aquí estaba el error (ahora sí existe)
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    return MaterialApp(
      title: 'Pets',
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (_) => session == null ? const AuthPage() : const HomePage(),
        '/home': (_) => const HomePage(),
      },
      initialRoute: '/',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.purple),
    );
  }
}
