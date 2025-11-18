import 'package:flutter/material.dart';
import '../../domain/entities/message_entity.dart';
import '../controller/chat_controller.dart';

class ChatPage extends StatefulWidget {
  final String petId;
  final ChatController controller;

  const ChatPage({super.key, required this.petId, required this.controller});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _msgCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.loadSessions(widget.petId);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Asistente Veterinario"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: "Nueva sesión",
            onPressed: () => ctrl.createNewSession(widget.petId),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: ctrl,
        builder: (_, __) {
          if (ctrl.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (ctrl.error != null) {
            return Center(child: Text(ctrl.error!));
          }

          return Row(
            children: [
              _buildSidebar(ctrl),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: ctrl.currentSession == null
                          ? const Center(
                              child: Text(
                                "Selecciona o crea una sesión",
                                style: TextStyle(fontSize: 16),
                              ),
                            )
                          : _buildMessages(ctrl),
                    ),
                    if (ctrl.currentSession != null) _buildInput(ctrl),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------- Sidebar ----------------
  Widget _buildSidebar(ChatController ctrl) {
    return Container(
      width: 250,
      color: Colors.grey.shade200,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              "Sesiones",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView(
              children: ctrl.sessions.map((s) {
                final selected = ctrl.currentSession?.id == s.id;

                return ListTile(
                  title: Text(
                    s.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  selected: selected,
                  onTap: () => ctrl.loadSession(s.id),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => ctrl.deleteSession(s.id),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Mensajes ----------------
  Widget _buildMessages(ChatController ctrl) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...ctrl.messages.map(_buildBubble),
        if (ctrl.isTyping) _typing(),
      ],
    );
  }

  Widget _buildBubble(MessageEntity msg) {
    final isUser = msg.role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isUser ? Colors.blueAccent : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          msg.message,
          style: TextStyle(color: isUser ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  Widget _typing() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          "El asistente está escribiendo...",
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ),
    );
  }

  // ---------------- Input ----------------
  Widget _buildInput(ChatController ctrl) {
    return Container(
      padding: const EdgeInsets.all(10),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgCtrl,
              decoration: const InputDecoration(
                hintText: "Escribe un mensaje...",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: () async {
              final text = _msgCtrl.text.trim();
              if (text.isEmpty) return;

              _msgCtrl.clear();
              await ctrl.send(widget.petId, text);
            },
          ),
        ],
      ),
    );
  }
}
