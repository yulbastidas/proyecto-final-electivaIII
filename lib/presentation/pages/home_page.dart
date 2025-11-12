// lib/presentation/pages/home_page.dart
import 'package:flutter/material.dart';

import 'feed_page.dart';
import 'map_page.dart';
import 'health_log_page.dart';
import 'chat_page.dart';
import 'marketplace_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  // Mantén vivas las pantallas (no se recrean al cambiar de pestaña)
  final _pages = const <Widget>[
    FeedPage(),
    MapPage(),
    HealthLogPage(),
    ChatPage(),
    MarketplacePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Ojo: las páginas ya traen su propio Scaffold/AppBar (por ejemplo FeedPage),
      // por eso aquí NO ponemos AppBar para evitar AppBars duplicadas.
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets_outlined),
            activeIcon: Icon(Icons.pets),
            label: 'Bitácora',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy_outlined),
            activeIcon: Icon(Icons.smart_toy),
            label: 'IA',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront),
            label: 'Mercado',
          ),
        ],
      ),
    );
  }
}
