import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});
  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final supa = Supabase.instance.client;
  bool creating = false;

  Stream<List<Map<String, dynamic>>> _postStream() {
    // Posts del país del usuario (como tenías)
    final uid = supa.auth.currentUser!.id;
    final profileF = supa
        .from('profiles')
        .select('country_code')
        .eq('id', uid)
        .single();
    return Stream.fromFuture(profileF).asyncExpand((p) {
      final cc = (p['country_code'] ?? 'CO') as String;
      return supa
          .from('posts')
          .stream(primaryKey: ['id'])
          .eq('country_code', cc)
          .order('created_at', ascending: false)
          .map((rows) => rows);
    });
  }

  Future<void> _toggleLike(int postId) async {
    final uid = supa.auth.currentUser!.id;
    final existing = await supa
        .from('post_likes')
        .select('id')
        .eq('post_id', postId)
        .eq('user_id', uid)
        .maybeSingle();
    if (existing != null) {
      await supa.from('post_likes').delete().eq('id', existing['id']);
    } else {
      await supa.from('post_likes').insert({'post_id': postId, 'user_id': uid});
    }
  }

  Future<void> _openCreate() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _Composer(onCreated: () => Navigator.pop(context)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _postStream(),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final posts = snap.data!;
          if (posts.isEmpty) {
            return const Center(
              child: Text('Aún no hay publicaciones en tu zona'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: posts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final p = posts[i];
              final created = DateTime.parse(p['created_at']);
              return Card(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 1.5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          (p['status'] ?? '??').toString().characters.first,
                        ),
                      ),
                      title: Text(
                        p['status'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(timeago.format(created, locale: 'es')),
                      trailing: Chip(
                        label: Text(p['country_code'] ?? ''),
                        side: BorderSide(color: color.outlineVariant),
                      ),
                    ),
                    if (p['media_url'] != null)
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(p['media_url'], fit: BoxFit.cover),
                      ),
                    if ((p['description'] ?? '').toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Text(p['description']),
                      ),
                    FutureBuilder(
                      future: Future.wait([
                        supa
                            .from('post_likes')
                            .select('id')
                            .eq('post_id', p['id']),
                        supa
                            .from('post_likes')
                            .select('id')
                            .eq('post_id', p['id'])
                            .eq('user_id', supa.auth.currentUser!.id),
                        supa
                            .from('comments')
                            .select('id')
                            .eq('post_id', p['id']),
                      ]),
                      builder: (_, AsyncSnapshot<List<dynamic>> s2) {
                        final likes = s2.hasData
                            ? (s2.data![0] as List).length
                            : 0;
                        final meLiked = s2.hasData
                            ? (s2.data![1] as List).isNotEmpty
                            : false;
                        final comments = s2.hasData
                            ? (s2.data![2] as List).length
                            : 0;
                        return Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                meLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: meLiked ? Colors.red : null,
                              ),
                              onPressed: () => _toggleLike(p['id'] as int),
                            ),
                            Text('$likes'),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(Icons.mode_comment_outlined),
                              onPressed: () =>
                                  _openComments(context, p['id'] as int),
                            ),
                            Text('$comments'),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () => _sharePost(p),
                              icon: const Icon(Icons.share),
                              label: const Text('Compartir'),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('Publicar'),
      ),
    );
  }

  void _openComments(BuildContext ctx, int postId) {
    Navigator.of(
      ctx,
    ).push(MaterialPageRoute(builder: (_) => _CommentsPage(postId: postId)));
  }

  void _sharePost(Map<String, dynamic> p) {
    // placeholder; podrías integrar share_plus
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Compartido (demo)')));
  }
}

class _Composer extends StatefulWidget {
  final VoidCallback onCreated;
  const _Composer({required this.onCreated});

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final supa = Supabase.instance.client;
  final descCtrl = TextEditingController();
  String status = 'RESCATADO';
  XFile? picked;
  bool saving = false;

  Future<void> _pick() async {
    final p = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (p != null) setState(() => picked = p);
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      String? mediaUrl;
      if (picked != null) {
        final bytes = await picked!.readAsBytes();
        final path =
            'p_${DateTime.now().millisecondsSinceEpoch}_${picked!.name}';
        await supa.storage
            .from('pets')
            .uploadBinary(
              path,
              bytes as Uint8List,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );
        mediaUrl = supa.storage.from('pets').getPublicUrl(path);
      }
      final uid = supa.auth.currentUser!.id;
      final p = await supa
          .from('profiles')
          .select('country_code')
          .eq('id', uid)
          .single();
      final cc = (p['country_code'] ?? 'CO') as String;

      await supa.from('posts').insert({
        'author': uid,
        'description': descCtrl.text.trim(),
        'media_url': mediaUrl,
        'status': status,
        'country_code': cc,
      });

      widget.onCreated();
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 5,
              width: 50,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            Row(
              children: [
                const Text(
                  'Nueva publicación',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            DropdownButtonFormField(
              value: status,
              items: const [
                DropdownMenuItem(value: 'RESCATADO', child: Text('Rescatado')),
                DropdownMenuItem(value: 'ADOPCION', child: Text('En adopción')),
                DropdownMenuItem(value: 'VENTA', child: Text('En venta')),
              ],
              onChanged: (v) => setState(() => status = v as String),
              decoration: const InputDecoration(labelText: 'Estado'),
            ),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '¿Qué pasa con la mascota?',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pick,
                  icon: const Icon(Icons.photo),
                  label: const Text('Agregar foto'),
                ),
                const SizedBox(width: 12),
                if (picked != null)
                  Text(picked!.name, overflow: TextOverflow.ellipsis),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: saving ? null : _save,
                icon: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: const Text('Publicar'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _CommentsPage extends StatefulWidget {
  final int postId;
  const _CommentsPage({required this.postId});
  @override
  State<_CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<_CommentsPage> {
  final supa = Supabase.instance.client;
  final ctrl = TextEditingController();

  Stream<List<Map<String, dynamic>>> get stream => supa
      .from('comments')
      .stream(primaryKey: ['id'])
      .eq('post_id', widget.postId)
      .order('created_at');

  Future<void> _send() async {
    if (ctrl.text.trim().isEmpty) return;
    await supa.from('comments').insert({
      'post_id': widget.postId,
      'author': supa.auth.currentUser!.id,
      'body': ctrl.text.trim(),
    });
    ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comentarios')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: stream,
              builder: (_, snap) {
                final rows = snap.data ?? [];
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: rows.length,
                  itemBuilder: (_, i) {
                    final c = rows[i];
                    final created = DateTime.parse(c['created_at']);
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(c['body']),
                      subtitle: Text(timeago.format(created, locale: 'es')),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un comentario',
                      contentPadding: EdgeInsets.all(12),
                    ),
                  ),
                ),
                IconButton(onPressed: _send, icon: const Icon(Icons.send)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
