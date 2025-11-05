import 'package:flutter/material.dart';

// IMPORTA TUS PÁGINAS (ya las tienes en tu proyecto)
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

  // Títulos por pestaña
  static const _titles = <String>[
    'Feed',
    'Mapa',
    'Salud',
    'Asistente',
    'Marketplace',
  ];

  // Pantallas (asegúrate que estas clases existan)
  final _screens = const <Widget>[
    FeedPage(),
    MapPage(),
    HealthLogPage(),
    ChatPage(),
    MarketplacePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        // AppBar
        final appBar = AppBar(
          title: Text(_titles[_index]),
          centerTitle: true,
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
        );

        // Contenido con IndexedStack (conserva estado de cada pestaña)
        final body = IndexedStack(index: _index, children: _screens);

        // Barra de navegación inferior (mobile/tablet)
        final bottomNav = NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dynamic_feed_outlined),
              selectedIcon: Icon(Icons.dynamic_feed),
              label: 'Feed',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: 'Mapa',
            ),
            NavigationDestination(
              icon: Icon(Icons.health_and_safety_outlined),
              selectedIcon: Icon(Icons.health_and_safety),
              label: 'Salud',
            ),
            NavigationDestination(
              icon: Icon(Icons.smart_toy_outlined),
              selectedIcon: Icon(Icons.smart_toy),
              label: 'IA',
            ),
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront),
              label: 'Market',
            ),
          ],
        );

        // Rail lateral (desktop)
        final navRail = NavigationRail(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          labelType: NavigationRailLabelType.all,
          destinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.dynamic_feed_outlined),
              selectedIcon: Icon(Icons.dynamic_feed),
              label: Text('Feed'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: Text('Mapa'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.health_and_safety_outlined),
              selectedIcon: Icon(Icons.health_and_safety),
              label: Text('Salud'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.smart_toy_outlined),
              selectedIcon: Icon(Icons.smart_toy),
              label: Text('IA'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront),
              label: Text('Market'),
            ),
          ],
        );

        if (isWide) {
          // Diseño escritorio: rail a la izquierda
          return Scaffold(
            appBar: appBar,
            body: Row(
              children: [
                const SizedBox(width: 8),
                navRail,
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            ),
          );
        }

        // Diseño móvil: barra inferior
        return Scaffold(
          appBar: appBar,
          body: body,
          bottomNavigationBar: bottomNav,
        );
      },
    );
  }
}
