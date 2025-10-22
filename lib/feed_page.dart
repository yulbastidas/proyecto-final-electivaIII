import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});
  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final supa = Supabase.instance.client;
  List<dynamic> posts = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<String> _userCountry() async {
    final uid = supa.auth.currentUser!.id;
    final p = await supa.from('profiles').select().eq('id', uid).single();
    return (p['country_code'] ?? 'CO') as String;
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final cc = await _userCountry();
    final res = await supa
        .from('posts')
        .select()
        .eq('country_code', cc)
        .order('created_at', ascending: false);
    posts = res;
    setState(() => loading = false);
  }

  Future<void> _createPostDialog() async {
    final descCtrl = TextEditingController();
    String status = 'RESCATADO';
    XFile? picked;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nueva publicación'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              DropdownButtonFormField(
                value: status,
                items: const [
                  DropdownMenuItem(
                    value: 'RESCATADO',
                    child: Text('Rescatado'),
                  ),
                  DropdownMenuItem(
                    value: 'ADOPCION',
                    child: Text('En adopción'),
                  ),
                  DropdownMenuItem(value: 'VENTA', child: Text('En venta')),
                ],
                onChanged: (v) => status = v as String,
                decoration: const InputDecoration(labelText: 'Estado'),
              ),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  final p = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 85,
                  );
                  if (p != null) picked = p;
                },
                icon: const Icon(Icons.photo),
                label: const Text('Seleccionar foto'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _createPost(descCtrl.text.trim(), status, picked);
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Publicar'),
          ),
        ],
      ),
    );
  }

  Future<void> _createPost(String desc, String status, XFile? file) async {
    String? mediaUrl;
    if (file != null) {
      final bytes = await file.readAsBytes();
      final path = 'p_${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      await supa.storage
          .from('pets')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
      mediaUrl = supa.storage.from('pets').getPublicUrl(path);
    }
    final uid = supa.auth.currentUser!.id;
    final cc = await _userCountry();
    await supa.from('posts').insert({
      'author': uid,
      'description': desc,
      'media_url': mediaUrl,
      'status': status,
      'country_code': cc,
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: posts.length,
              itemBuilder: (_, i) {
                final p = posts[i] as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (p['media_url'] != null)
                        Image.network(p['media_url'], fit: BoxFit.cover),
                      ListTile(
                        title: Text(p['status'] ?? ''),
                        subtitle: Text(p['description'] ?? ''),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPostDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
