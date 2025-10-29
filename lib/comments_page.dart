import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

final _supa = Supabase.instance.client;

class CommentsPage extends StatefulWidget {
  final String postId;
  const CommentsPage({super.key, required this.postId});
  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final ctrl = TextEditingController();

  Future<void> _send() async {
    final txt = ctrl.text.trim();
    if (txt.isEmpty) return;
    await _supa.from('comments').insert({
      'post_id': widget.postId,
      'user_id': _supa.auth.currentUser!.id,
      'text': txt,
    });
    ctrl.clear();
    setState(() {});
  }

  Future<void> _delete(String id) async {
    await _supa.from('comments').delete().eq('id', id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comentarios')),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _supa
                  .from('comments')
                  .select()
                  .eq('post_id', widget.postId)
                  .order('created_at', ascending: true),
              builder: (c, s) {
                if (!s.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = s.data!;
                if (data.isEmpty)
                  return const Center(child: Text('Sé el primero en comentar'));
                final me = _supa.auth.currentUser!.id;
                return ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (_, i) {
                    final x = data[i];
                    final t = DateTime.parse(x['created_at'] as String);
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(x['text'] as String),
                      subtitle: Text(timeago.format(t, locale: 'es')),
                      trailing: x['user_id'] == me
                          ? IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _delete(x['id'] as String),
                            )
                          : null,
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      decoration: const InputDecoration(
                        hintText: 'Escribe un comentario…',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: _send, child: const Icon(Icons.send)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
