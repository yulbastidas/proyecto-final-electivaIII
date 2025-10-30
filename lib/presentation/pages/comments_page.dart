import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommentsPage extends StatefulWidget {
  final int postId;
  const CommentsPage({super.key, required this.postId});

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final client = Supabase.instance.client;
  final text = TextEditingController();

  Future<List<Map<String, dynamic>>> _fetch() async {
    return await client
        .from('feed_comments')
        .select()
        .eq('post_id', widget.postId)
        .order('created_at');
  }

  Future<void> _send() async {
    final uid = client.auth.currentUser?.id;
    if (uid == null) return;
    await client.from('feed_comments').insert({
      'post_id': widget.postId,
      'author': uid,
      'text': text.text.trim(),
    });
    text.clear();
    setState(() {});
  }

  Future<void> _delete(int id) async {
    final uid = client.auth.currentUser?.id;
    if (uid == null) return;
    await client.from('feed_comments').delete().eq('id', id).eq('author', uid);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comentarios')),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder(
              future: _fetch(),
              builder: (context, snap) {
                if (!snap.hasData)
                  return const Center(child: CircularProgressIndicator());
                final list = snap.data as List<Map<String, dynamic>>;
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final c = list[i];
                    return ListTile(
                      title: Text(c['text'] ?? ''),
                      subtitle: Text((c['created_at'] ?? '').toString()),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete(c['id'] as int),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: text,
                    decoration: const InputDecoration(hintText: 'Escribe...'),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send), onPressed: _send),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
