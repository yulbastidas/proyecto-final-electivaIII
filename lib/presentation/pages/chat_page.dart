import 'package:flutter/material.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../data/services/ai_service.dart';
import '../../domain/entities/message_entity.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final repo = ChatRepositoryImpl();
  final ai = AiService();
  final input = TextEditingController();
  final scroll = ScrollController();
  bool loading = false;
  List<MessageEntity> msgs = [];

  Future<void> _load() async {
    msgs = await repo.history();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _send() async {
    final t = input.text.trim();
    if (t.isEmpty) return;
    setState(() => loading = true);
    final user = await repo.sendUser(t);
    setState(() => msgs.add(user));
    input.clear();

    try {
      final answer = await ai.ask(t);
      final asst = await repo.sendAssistant(answer);
      setState(() => msgs.add(asst));
      await Future.delayed(const Duration(milliseconds: 100));
      scroll.jumpTo(scroll.position.maxScrollExtent);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: scroll,
            padding: const EdgeInsets.all(12),
            itemCount: msgs.length,
            itemBuilder: (_, i) {
              final m = msgs[i];
              final me = m.role == 'user';
              return Align(
                alignment: me ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: me
                        ? Colors.deepPurple.shade100
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(m.text),
                ),
              );
            },
          ),
        ),
        SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: input,
                    decoration: const InputDecoration(
                      hintText: 'Describe el síntoma...',
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: loading ? null : _send,
                icon: loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
