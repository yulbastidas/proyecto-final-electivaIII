import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:pets/data/models/listing.dart';
import 'package:pets/data/services/listings_service.dart';
import 'package:pets/widgets/listing_card.dart';
import 'package:pets/widgets/app_text_field.dart';
import 'package:pets/widgets/primary_button.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  final _svc = ListingsService();

  bool _loading = true;
  List<Listing> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _svc.getAll();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create({
    required String title,
    required String description,
    required double price,
    Uint8List? imageBytes,
    String? filename,
  }) async {
    String? url;

    if (imageBytes != null && filename != null) {
      url = await _svc.uploadImageBytes(bytes: imageBytes, filename: filename);
    }

    await _svc.create(
      title: title,
      description: description,
      price: price,
      imageUrl: url,
    );

    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _Composer(onCreate: _create),
                  const SizedBox(height: 12),
                  for (final it in _items)
                    ListingCard(
                      listing: it,
                      onDelete: () async {
                        await _svc.delete(it.id);
                        await _load();
                      },
                    ),
                ],
              ),
            ),
    );
  }
}

class _Composer extends StatefulWidget {
  final Future<void> Function({
    required String title,
    required String description,
    required double price,
    Uint8List? imageBytes,
    String? filename,
  })
  onCreate;

  const _Composer({required this.onCreate});

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  Uint8List? _bytes;
  String? _filename;
  bool _submitting = false;

  Future<void> _pick() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x == null) return;

    _bytes = await x.readAsBytes();
    _filename = x.name;
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0;
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    if (title.isEmpty || desc.isEmpty) return;

    if (!mounted) return;
    setState(() => _submitting = true);

    try {
      await widget.onCreate(
        title: title,
        description: desc,
        price: price,
        imageBytes: _bytes,
        filename: _filename,
      );
    } finally {
      if (!mounted) return;

      _titleCtrl.clear();
      _descCtrl.clear();
      _priceCtrl.clear();
      _bytes = null;
      _filename = null;
      _submitting = false;

      setState(() {});
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(.4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ---------- Fila Título + Precio (responsiva) ----------
            LayoutBuilder(
              builder: (context, constraints) {
                bool isSmall = constraints.maxWidth < 380;

                if (isSmall) {
                  return Column(
                    children: [
                      AppTextField(controller: _titleCtrl, label: 'Título'),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _priceCtrl,
                        label: 'Precio',
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _titleCtrl,
                        label: 'Título',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppTextField(
                        controller: _priceCtrl,
                        label: 'Precio',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 10),

            /// ---------- Descripción ----------
            AppTextField(
              controller: _descCtrl,
              label: 'Descripción',
              maxLines: 3,
            ),

            const SizedBox(height: 12),
            const Text(
              'Venta',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: 12),

            /// ---------- Botones (responsivos con Wrap) ----------
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _pick,
                  icon: const Icon(Icons.photo),
                  label: Text(_filename ?? 'Imagen (opcional)'),
                ),
                PrimaryButton(
                  text: 'Publicar',
                  loading: _submitting,
                  onPressed: _submit,
                ),
              ],
            ),

            if (_bytes != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  _bytes!,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
