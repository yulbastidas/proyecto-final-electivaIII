import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/config/supabase_config.dart';
import 'presentation/pages/auth_page.dart';
import 'presentation/pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await SupabaseConfig.init();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SupabaseConfig.client.auth.currentSession;
    return MaterialApp(
      title: 'Mascotas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
      routes: {
        '/': (_) => session == null ? const AuthPage() : const HomePage(),
        '/home': (_) => const HomePage(),
      },
      initialRoute: '/',
    );
  }
}
