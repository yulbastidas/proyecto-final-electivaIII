import 'package:flutter/material.dart';
import 'feed_page.dart';
import 'marketplace_page.dart';
import 'chat_page.dart';
import 'triage_page.dart';
import 'map_page.dart'; // <-- NUEVO
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int idx = 0;

  // Agregamos MapPage como cuarta pestaña.
  final pages = const [
    FeedPage(),
    MarketplacePage(),
    ChatPage(),
    MapPage(), // <-- NUEVO
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mascotas'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TriagePage()),
            ),
            icon: const Icon(Icons.health_and_safety),
            tooltip: 'Chat IA síntomas',
          ),
          IconButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      // Opcional: IndexedStack evita que se recarguen las páginas al cambiar de tab.
      body: IndexedStack(index: idx, children: pages),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: idx,
        onTap: (i) => setState(() => idx = i),
        type: BottomNavigationBarType.fixed, // Para mostrar 4 ítems
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Feed'),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Marketplace',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Mapa',
          ), // <-- NUEVO
        ],
      ),
    );
  }
}
