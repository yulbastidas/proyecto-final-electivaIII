// lib/presentation/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'feed_page.dart';
import 'map_page.dart';
import 'health_log_page.dart';
import 'chat_page.dart';
import 'marketplace_page.dart';

// Controller + repo
import '../controller/health_controller.dart';
import '../../data/repositories/health_repository_impl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  late final HealthController _healthCtrl;
  late final String _petId;

  @override
  void initState() {
    super.initState();

    final sb = Supabase.instance.client;
    final uid = sb.auth.currentUser?.id;

    // Si no hay sesión, redirige a login según tu flujo
    if (uid == null) {
      // Navigator.of(context).pushReplacementNamed('/login');  // si lo tienes
      throw Exception('No hay sesión iniciada.');
    }

    // Si aún no tienes tabla "pets", usa el uid como pet_id (mismo tipo: uuid).
    // Cuando tengas pets reales, reemplaza esto por el id del pet seleccionado.
    _petId = uid;

    _healthCtrl = HealthController(
      HealthRepositoryImpl(sb, () => sb.auth.currentUser!.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const FeedPage(),
      const MapPage(),
      HealthLogPage(petId: _petId, controller: _healthCtrl), // ✅ ahora sí
      const ChatPage(),
      const MarketplacePage(),
    ];

    return Scaffold(
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
