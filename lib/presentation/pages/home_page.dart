// lib/presentation/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Páginas
import 'feed_page.dart';
import 'map_page.dart';
import 'health_log_page.dart';
import 'chat_page.dart';
import 'marketplace_page.dart';

// HEALTH
import '../controller/health_controller.dart';
import '../../data/repositories/health_repository_impl.dart';

// CHAT
import '../controller/chat_controller.dart';
import '../../data/repositories/chat_repository_impl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  late final HealthController _healthCtrl;
  late final ChatController _chatCtrl;
  late final String _petId;

  @override
  void initState() {
    super.initState();

    final sb = Supabase.instance.client;
    final uid = sb.auth.currentUser?.id;

    if (uid == null) {
      throw Exception("No hay sesión activa.");
    }

    _petId = uid;

    _healthCtrl = HealthController(
      HealthRepositoryImpl(sb, () => sb.auth.currentUser!.id),
    );

    final chatRepo = ChatRepositoryImpl(
      sb: sb,
      getUid: () => sb.auth.currentUser!.id,
    );

    _chatCtrl = ChatController(chatRepo);
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const FeedPage(),
      const MapPage(),
      HealthLogPage(petId: _petId, controller: _healthCtrl),
      ChatPage(petId: _petId, controller: _chatCtrl),
      const MarketplacePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _signOut,
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
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
