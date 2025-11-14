// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'dart:html' as html; // Solo web; si te molesta el warning, déjalo así.

import 'package:supabase_flutter/supabase_flutter.dart';

// IMPORTA EL CONTROLLER POR RUTA RELATIVA:
import '../controller/feed_controller.dart';

import '../../data/services/posts_service.dart';
import '../../data/repositories/feed_repository_impl.dart';
import '../../domain/entities/post.dart';
import '../../widgets/post_item.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  late final FeedController c;

  @override
  void initState() {
    super.initState();
    final repo = FeedRepositoryImpl(Supabase.instance.client);
    final svc = PostsService(repo);
    c = FeedController(svc);
    c.refresh();
  }

  @override
  void dispose() {
    c.disposeAll();
    c.dispose();
    super.dispose();
  }

  Future<void> _pickImageWeb() async {
    if (!kIsWeb) return;
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();
    await input.onChange.first;
    if (input.files == null || input.files!.isEmpty) return;
    final reader = html.FileReader();
    reader.readAsArrayBuffer(input.files!.first);
    await reader.onLoadEnd.first;
    final bytes = reader.result as Uint8List?;
    c.setImage(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: c,
      builder: (_, __) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Feed'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: c.loading ? null : () => c.refresh(),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Composer
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: c.textCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: '¿Qué estás pensando?',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: c.status,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Adoption',
                                    child: Text('Adoption'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Sale',
                                    child: Text('Sale'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Rescued',
                                    child: Text('Rescued'),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v != null) c.status = v;
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Estado',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton.filledTonal(
                              onPressed: _pickImageWeb,
                              icon: const Icon(Icons.image_outlined),
                              tooltip: 'Seleccionar imagen',
                            ),
                          ],
                        ),
                        if (c.imageBytes != null) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              c.imageBytes!,
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            onPressed: c.publishing ? null : () => c.publish(),
                            child: c.publishing
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Publicar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Filtros
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Adoption'),
                      selected: c.status == 'Adoption',
                      onSelected: (_) {
                        c.status = 'Adoption';
                        c.refresh();
                      },
                    ),
                    FilterChip(
                      label: const Text('Sale'),
                      selected: c.status == 'Sale',
                      onSelected: (_) {
                        c.status = 'Sale';
                        c.refresh();
                      },
                    ),
                    FilterChip(
                      label: const Text('Rescued'),
                      selected: c.status == 'Rescued',
                      onSelected: (_) {
                        c.status = 'Rescued';
                        c.refresh();
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                if (c.loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  ...c.items.map((Post p) {
                    return PostItem(
                      post: p,
                      onLike: () => c.toggleLike(p.id), // usa int id
                      onDelete: () => c.remove(p.id),
                      onComment: (text) {
                        // c.addCommentIfSupported(p, '¡Bonito!');
                      },
                    );
                  }),

                const SizedBox(height: 8),

                if (c.loadingMore)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  Center(
                    child: TextButton.icon(
                      onPressed: () => c.loadMore(),
                      icon: const Icon(Icons.expand_more),
                      label: const Text('Cargar más'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
