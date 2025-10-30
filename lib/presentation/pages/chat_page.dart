import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final input = TextEditingController();
  final messages = <_Msg>[
    _Msg(
      role: 'assistant',
      text: 'Hola 👋 Soy tu asistente para orientación veterinaria general.',
      time: DateTime.now(),
    ),
  ];

  void _send() {
    final t = input.text.trim();
    if (t.isEmpty) return;
    setState(() {
      messages.add(_Msg(role: 'user', text: t, time: DateTime.now()));
      // respuesta fija (sin IA, por ahora)
      messages.add(
        _Msg(
          role: 'assistant',
          text:
              'Gracias por tu mensaje. Recuerda: esta app NO reemplaza a un veterinario.\n'
              'Si hay fiebre, vómito persistente, diarrea con sangre o decaimiento severo → acude a una clínica.',
          time: DateTime.now(),
        ),
      );
      input.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: messages.length,
            itemBuilder: (_, i) {
              final m = messages[i];
              final isUser = m.role == 'user';
              return Align(
                alignment: isUser
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.deepPurple.shade100 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(m.text),
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: input,
                    decoration: const InputDecoration(
                      hintText: 'Describe el síntoma...',
                    ),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send), onPressed: _send),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Msg {
  final String role, text;
  final DateTime time;
  _Msg({required this.role, required this.text, required this.time});
}
