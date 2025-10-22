import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final supa = Supabase.instance.client;
  final ctrl = TextEditingController();
  late final stream = supa
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('room', 'general')
      .order('id');

  Future<void> _send() async {
    if (ctrl.text.isEmpty) return;
    await supa.from('messages').insert({
      'room': 'general',
      'sender': supa.auth.currentUser?.id,
      'content': ctrl.text,
    });
    ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: stream,
            builder: (_, snap) {
              final msgs = snap.data ?? [];
              return ListView(
                padding: const EdgeInsets.all(8),
                children: msgs
                    .map((m) => ListTile(title: Text(m['content'])))
                    .toList(),
              );
            },
          ),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                decoration: const InputDecoration(hintText: 'Escribe...'),
              ),
            ),
            IconButton(onPressed: _send, icon: const Icon(Icons.send)),
          ],
        ),
      ],
    );
  }
}
