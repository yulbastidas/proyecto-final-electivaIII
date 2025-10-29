import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_page.dart';
import 'home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Cargar variables del .env
  await dotenv.load(fileName: ".env");

  // 2) Inicializar Supabase con variables de entorno
  final url = dotenv.env['SUPABASE_URL'];
  final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
    // Falla temprana para evitar errores silenciosos
    throw Exception('Faltan SUPABASE_URL o SUPABASE_ANON_KEY en .env');
  }

  await Supabase.initialize(url: url, anonKey: anonKey);

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      title: 'Mascotas',
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
