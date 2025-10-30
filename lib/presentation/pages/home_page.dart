import 'package:flutter/material.dart';
import 'feed_page.dart';
import 'marketplace_page.dart';
import 'chat_page.dart';
import 'map_page.dart';
import 'health_log_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int i = 0;
  final pages = const [
    FeedPage(),
    MarketplacePage(),
    ChatPage(),
    MapPage(),
    HealthLogPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mascotas')),
      body: pages[i],
      bottomNavigationBar: NavigationBar(
        selectedIndex: i,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.pets_outlined), label: 'Feed'),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            label: 'Marketplace',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Mapa'),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            label: 'Bitácora',
          ),
        ],
        onDestinationSelected: (v) => setState(() => i = v),
      ),
    );
  }
}
