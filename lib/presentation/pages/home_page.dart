// lib/presentation/pages/home_page.dart
import 'package:flutter/material.dart';
import 'feed_page.dart'; // verifica la ruta

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pets'),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: theme.colorScheme.onPrimaryContainer,
          tabs: const [
            Tab(icon: Icon(Icons.pets), text: 'Adoption'),
            Tab(icon: Icon(Icons.sell), text: 'Sale'),
            Tab(icon: Icon(Icons.volunteer_activism), text: 'Rescued'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        // ✅ Sin pasar 'status', porque FeedPage no lo define
        children: const [FeedPage(), FeedPage(), FeedPage()],
      ),
    );
  }
}
