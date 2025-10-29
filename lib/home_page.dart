import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'feed_page.dart';
import 'marketplace_page.dart';
import 'chat_page.dart';
import 'map_page.dart';
import 'triage_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int idx = 0;
  final pages = const [FeedPage(), MarketplacePage(), ChatPage(), MapPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mascotas'),
        actions: [
          IconButton(
            tooltip: 'Asistente síntomas',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TriagePage()),
            ),
            icon: const Icon(Icons.health_and_safety),
          ),
          IconButton(
            tooltip: 'Salir',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: pages[idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => setState(() => idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.pets), label: 'Feed'),
          NavigationDestination(icon: Icon(Icons.store), label: 'Marketplace'),
          NavigationDestination(icon: Icon(Icons.chat_bubble), label: 'Chat'),
          NavigationDestination(icon: Icon(Icons.map), label: 'Mapa'),
        ],
      ),
    );
  }
}
