import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'feed_page.dart';
import 'chat_page.dart';
import 'map_page.dart';
import 'health_log_page.dart';
import 'marketplace_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;
  final pages = const [
    FeedPage(),
    Placeholder(), // Marketplace (puedes activarlo luego)
    ChatPage(),
    MapPage(),
    HealthLogPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Mascotas'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.pets_outlined), label: 'Feed'),
          NavigationDestination(
            icon: Icon(Icons.store_outlined),
            label: 'Marketplace',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Mapa'),
          NavigationDestination(
            icon: Icon(Icons.medical_services_outlined),
            label: 'Salud',
          ),
        ],
      ),
    );
  }
}
