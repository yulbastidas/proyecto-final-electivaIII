import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommentsPage extends StatefulWidget {
  final String postId;
  const CommentsPage({super.key, required this.postId});

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final supa = Supabase.instance.client;
  final ctrl = TextEditingController();

  late final Stream<List<Map<String, dynamic>>> stream = supa
      .from('comments')
      .stream(primaryKey: ['id'])
      .eq('post_id', widget.postId)
      .order('created_at');

  Future<void> _send() async {
    if (ctrl.text.trim().isEmpty) return;
    await supa.from('comments').insert({
      'post_id': widget.postId,
      'author': supa.auth.currentUser!.id,
      'content': ctrl.text.trim(),
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
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: stream,
              builder: (context, snap) {
                final items = snap.data ?? [];
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final c = items[i];
                    return ListTile(
                      title: Text(c['content'] ?? ''),
                      subtitle: Text(
                        DateTime.parse(c['created_at']).toLocal().toString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: TextField(
                      controller: ctrl,
                      decoration: const InputDecoration(
                        hintText: 'Escribe un comentario…',
                      ),
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
