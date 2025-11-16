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
  void initState() {
    super.initState();
    _load();
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
                      onDelete: () => _svc.delete(it.id).then((_) => _load()),
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
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();

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
    final p = double.tryParse(_price.text.trim()) ?? 0;

    if (_title.text.trim().isEmpty || _desc.text.trim().isEmpty) return;

    if (!mounted) return;
    setState(() => _submitting = true);

    try {
      await widget.onCreate(
        title: _title.text.trim(),
        description: _desc.text.trim(),
        price: p,
        imageBytes: _bytes,
        filename: _filename,
      );
    } finally {
      if (!mounted) return;

      _title.clear();
      _desc.clear();
      _price.clear();
      _bytes = null;
      _filename = null;
      _submitting = false;

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(.4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AppTextField(controller: _title, label: 'Título'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppTextField(
                    controller: _price,
                    label: 'Precio',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            AppTextField(controller: _desc, label: 'Descripción', maxLines: 3),

            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Venta',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),

            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pick,
                  icon: const Icon(Icons.photo),
                  label: Text(_filename ?? 'Imagen (opcional)'),
                ),
                const Spacer(),
                PrimaryButton(
                  text: 'Publicar',
                  loading: _submitting,
                  onPressed: _submit,
                ),
              ],
            ),

            if (_bytes != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(_bytes!, height: 140, fit: BoxFit.cover),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
