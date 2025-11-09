// lib/presentation/pages/feed_page.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pets/domain/entities/post.dart';
import 'package:pets/data/repositories/feed_repository_impl.dart';
import 'package:pets/data/services/posts_service.dart';

import 'package:pets/widgets/app_text_field.dart';
import 'package:pets/widgets/primary_button.dart';
import 'package:pets/widgets/post_card.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  late final PostsService _service;

  final _contentCtrl = TextEditingController();
  String _status = 'adoption'; // adoption | sale | rescued | all
  Uint8List? _imageBytes;
  List<int>? _imageForUpload;
  String? _imageName;

  final _picker = ImagePicker();
  final _uuid = const Uuid();

  final List<Post> _posts = [];
  bool _loading = false;
  bool _publishing = false;

  @override
  void initState() {
    super.initState();
    _service = PostsService(
      FeedRepositoryImpl(Supabase.instance.client, bucketName: 'posts'),
    );
    _loadFeed();
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFeed() async {
    setState(() => _loading = true);
    try {
      final fetched = await _service.getLocalizedFeed(status: null, limit: 30);
      setState(() {
        _posts
          ..clear()
          ..addAll(fetched);
      });
    } catch (e) {
      _showSnack('Error al cargar feed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes(); // Uint8List
    setState(() {
      _imageBytes = bytes; // preview
      _imageForUpload = bytes.toList(); // subida
      _imageName = '${_uuid.v4()}.jpg'; // nombre archivo
    });
  }

  void _removeImage() {
    setState(() {
      _imageBytes = null;
      _imageForUpload = null;
      _imageName = null;
    });
  }

  Future<void> _publish() async {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty) {
      _showSnack('Escribe algo para publicar.');
      return;
    }

    setState(() => _publishing = true);
    try {
      final created = await _service.createPost(
        content: content,
        status: _status,
        imageBytes: _imageForUpload,
        filename: _imageName,
      );

      _contentCtrl.clear();
      _removeImage();

      setState(() {
        _posts.insert(0, created);
      });

      _showSnack('Publicado ✅');
    } catch (e) {
      _showSnack('No se pudo publicar: $e');
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Future<void> _like(Post p) async {
    try {
      final updated = await _service.toggleLike(p.id);
      final idx = _posts.indexWhere((e) => e.id == p.id);
      if (idx != -1) {
        setState(() => _posts[idx] = updated);
      }
    } catch (e) {
      _showSnack('No se pudo dar like: $e');
    }
  }

  Future<void> _delete(Post p) async {
    try {
      await _service.deletePost(p.id);
      setState(() => _posts.removeWhere((e) => e.id == p.id));
      _showSnack('Eliminado 🗑️');
    } catch (e) {
      _showSnack('No se pudo eliminar: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Community Feed')),
      body: RefreshIndicator(
        onRefresh: _loadFeed,
        child: CustomScrollView(
          slivers: [
            // === COMPOSER =====================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: _Composer(
                  contentCtrl: _contentCtrl,
                  status: _status,
                  onStatusChanged: (v) => setState(() => _status = v),
                  imageBytes: _imageBytes,
                  onPickImage: _pickImage,
                  onRemoveImage: _removeImage,
                  onPublish: _publishing ? null : _publish,
                  publishing: _publishing,
                ),
              ),
            ),

            // === FILTRO RÁPIDO ================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Wrap(
                  spacing: 8,
                  children: [
                    _StatusChip(
                      label: 'All',
                      selected: _status == 'all',
                      onTap: () => setState(() => _status = 'all'),
                    ),
                    _StatusChip(
                      label: 'Adoption',
                      selected: _status == 'adoption',
                      onTap: () => setState(() => _status = 'adoption'),
                    ),
                    _StatusChip(
                      label: 'Sale',
                      selected: _status == 'sale',
                      onTap: () => setState(() => _status = 'sale'),
                    ),
                    _StatusChip(
                      label: 'Rescued',
                      selected: _status == 'rescued',
                      onTap: () => setState(() => _status = 'rescued'),
                    ),
                    IconButton(
                      tooltip: 'Refrescar',
                      onPressed: _loadFeed,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),
            ),

            // === LISTA ========================================================
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_posts.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'Aún no hay publicaciones',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              )
            else
              SliverList.builder(
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  final p = _posts[index];
                  if (_status != 'all' && p.status != _status) {
                    return const SizedBox.shrink();
                  }
                  return PostCard(
                    post: p,
                    onLike: () => _like(p),
                    onDelete: () => _delete(p),
                    onComment: () {
                      _showSnack('Comentarios próximamente 😉');
                    },
                  );
                },
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController contentCtrl;
  final String status;
  final ValueChanged<String> onStatusChanged;

  final Uint8List? imageBytes;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;

  final VoidCallback? onPublish;
  final bool publishing;

  const _Composer({
    required this.contentCtrl,
    required this.status,
    required this.onStatusChanged,
    required this.imageBytes,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.onPublish,
    required this.publishing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // ⬇⬇⬇ Mantengo tu AppTextField tal cual
            AppTextField(
              label: 'Escribe tu publicación',
              controller: contentCtrl,
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    // ⬇⬇⬇ Mantengo tu initialValue tal cual
                    initialValue: status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'adoption',
                        child: Text('Adoption'),
                      ),
                      DropdownMenuItem(value: 'sale', child: Text('Sale')),
                      DropdownMenuItem(
                        value: 'rescued',
                        child: Text('Rescued'),
                      ),
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('All (view only)'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) onStatusChanged(v);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  onPressed: onPickImage,
                  icon: const Icon(Icons.photo),
                  tooltip: 'Elegir imagen',
                ),
                if (imageBytes != null)
                  IconButton(
                    onPressed: onRemoveImage,
                    icon: const Icon(Icons.close),
                    tooltip: 'Quitar imagen',
                  ),
              ],
            ),
            if (imageBytes != null) ...[
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    imageBytes!,
                    fit: BoxFit.cover, // ✅ FIT estilo DALL·E
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: PrimaryButton(
                text: publishing ? 'Publicando...' : 'Publicar',
                onPressed: publishing ? null : onPublish,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: scheme.primary.withValues(alpha: 0.12),
    );
  }
}
