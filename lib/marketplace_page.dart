import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

final _supa = Supabase.instance.client;

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});
  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  Future<void> _newItem() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _MarketForm()),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _supa
            .from('market_items')
            .select()
            .order('created_at', ascending: false),
        builder: (c, s) {
          if (!s.hasData)
            return const Center(child: CircularProgressIndicator());
          final items = s.data!;
          if (items.isEmpty)
            return const Center(child: Text('Sin artículos aún'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) =>
                _ItemCard(item: items[i], onRefresh: () => setState(() {})),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newItem,
        label: const Text('Publicar'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.onRefresh});
  final Map<String, dynamic> item;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final me = Supabase.instance.client.auth.currentUser?.id;
    final mine = me == item['user_id'];
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item['photo_url'] != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: CachedNetworkImage(
                imageUrl: item['photo_url'] as String,
                fit: BoxFit.cover,
                height: 180,
                width: double.infinity,
              ),
            ),
          ListTile(
            title: Text(
              item['title'] as String,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Estado: ${item['status']} · Precio: \$${item['price']} · Contacto: ${item['contact']}',
            ),
            trailing: mine
                ? IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await Supabase.instance.client
                          .from('market_items')
                          .delete()
                          .eq('id', item['id'] as String);
                      onRefresh();
                    },
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _MarketForm extends StatefulWidget {
  const _MarketForm();
  @override
  State<_MarketForm> createState() => _MarketFormState();
}

class _MarketFormState extends State<_MarketForm> {
  final title = TextEditingController();
  final price = TextEditingController();
  final contact = TextEditingController();
  String status = 'venta';
  XFile? img;
  bool loading = false;

  Future<void> _save() async {
    setState(() => loading = true);
    try {
      String? url;
      if (img != null) {
        final path =
            '${_supa.auth.currentUser!.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        await _supa.storage.from('market').upload(path, File(img!.path));
        url = _supa.storage.from('market').getPublicUrl(path);
      }
      await _supa.from('market_items').insert({
        'user_id': _supa.auth.currentUser!.id,
        'title': title.text.trim(),
        'price': double.tryParse(price.text.trim()) ?? 0,
        'contact': contact.text.trim(),
        'status': status,
        'photo_url': url,
      });
      if (!mounted) return;
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo artículo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: title,
            decoration: const InputDecoration(labelText: 'Título'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: price,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Precio'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: contact,
            decoration: const InputDecoration(labelText: 'Contacto'),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField(
            value: status,
            items: const [
              DropdownMenuItem(value: 'venta', child: Text('Venta')),
              DropdownMenuItem(value: 'adopcion', child: Text('Adopción')),
              DropdownMenuItem(value: 'rescate', child: Text('Rescate')),
            ],
            onChanged: (v) => setState(() => status = v as String),
            decoration: const InputDecoration(labelText: 'Estado'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  final x = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 70,
                  );
                  if (x != null) setState(() => img = x);
                },
                icon: const Icon(Icons.photo),
                label: const Text('Seleccionar foto'),
              ),
              const SizedBox(width: 12),
              if (img != null)
                Text(img!.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: loading ? null : _save,
            child: Text(loading ? 'Guardando...' : 'Publicar'),
          ),
        ],
      ),
    );
  }
}
