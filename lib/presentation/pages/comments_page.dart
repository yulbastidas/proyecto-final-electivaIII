import 'package:flutter/material.dart';
import '../../data/repositories/feed_repository_impl.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/entities/comment_entity.dart';

class CommentsPage extends StatefulWidget {
  final PostEntity post;
  const CommentsPage({super.key, required this.post});

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final repo = FeedRepositoryImpl();
  final text = TextEditingController();
  List<CommentEntity> comments = [];

  Future<void> _load() async {
    comments = await repo.listComments(widget.post.id);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _send() async {
    if (text.text.trim().isEmpty) return;
    await repo.addComment(postId: widget.post.id, text: text.text.trim());
    text.clear();
    await _load();
  }

  Future<void> _delete(CommentEntity c) async {
    await repo.deleteOwnComment(c.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comentarios')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: comments.length,
              itemBuilder: (_, i) {
                final c = comments[i];
                return ListTile(
                  title: Text(c.text),
                  subtitle: Text(c.createdAt.toIso8601String()),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(c),
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
                      controller: text,
                      decoration: const InputDecoration(
                        hintText: 'Escribe un comentario...',
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
