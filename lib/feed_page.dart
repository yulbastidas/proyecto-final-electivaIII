import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'comments_page.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});
  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final supa = Supabase.instance.client;
  bool loading = false;
  List<Map<String, dynamic>> posts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<String> _userCountry() async {
    final uid = supa.auth.currentUser!.id;
    final p = await supa
        .from('profiles')
        .select('country_code')
        .eq('id', uid)
        .single();
    return (p['country_code'] ?? 'CO') as String;
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final cc = await _userCountry();
    final data = await supa
        .from('posts')
        .select(
          'id, author, description, status, media_url, country_code, created_at',
        )
        .eq('country_code', cc)
        .order('created_at', ascending: false);
    posts = (data as List).cast<Map<String, dynamic>>();
    setState(() => loading = false);
  }

  Future<void> _newPostDialog() async {
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
              await _createPost(
                description: descCtrl.text.trim(),
                status: status,
                picked: picked,
              );
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Publicar'),
          ),
        ],
      ),
    );
  }

  Future<void> _createPost({
    required String description,
    required String status,
    required XFile? picked,
  }) async {
    setState(() => loading = true);

    String? mediaUrl;
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      final uid = supa.auth.currentUser!.id;
      final objectPath =
          '$uid/${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
      await supa.storage
          .from('pets')
          .uploadBinary(
            objectPath,
            bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );
      mediaUrl = supa.storage.from('pets').getPublicUrl(objectPath);
    }

    final uid = supa.auth.currentUser!.id;
    final cc = await _userCountry();

    await supa.from('posts').insert({
      'author': uid,
      'description': description,
      'status': status,
      'media_url': mediaUrl,
      'country_code': cc,
    });

    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: posts.length,
              itemBuilder: (_, i) {
                final p = posts[i];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (p['media_url'] != null)
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            p['media_url'],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ListTile(
                        title: Text(p['status']),
                        subtitle: Text(p['description'] ?? ''),
                      ),
                      ButtonBar(
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CommentsPage(postId: p['id'] as String),
                                ),
                              );
                            },
                            icon: const Icon(Icons.comment),
                            label: const Text('Comentarios'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _newPostDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
