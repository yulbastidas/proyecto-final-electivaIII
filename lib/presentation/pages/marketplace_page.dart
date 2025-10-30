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
      setState(() => _loading = false);
    }
  }

  Future<void> _create({
    required String title,
    required String description,
    required double price,
    required String status,
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
      status: status,
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

/// Formulario para crear una publicación de marketplace
class _Composer extends StatefulWidget {
  final Future<void> Function({
    required String title,
    required String description,
    required double price,
    required String status,
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
  String _status = 'sale';
  Uint8List? _bytes;
  String? _filename;
  bool _submitting = false;

  Future<void> _pick() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x == null) return;
    final b = await x.readAsBytes();
    setState(() {
      _bytes = b;
      _filename = x.name;
    });
  }

  Future<void> _submit() async {
    final p = double.tryParse(_price.text.trim()) ?? 0;
    if (_title.text.trim().isEmpty || _desc.text.trim().isEmpty) return;

    setState(() => _submitting = true);
    try {
      await widget.onCreate(
        title: _title.text.trim(),
        description: _desc.text.trim(),
        price: p,
        status: _status,
        imageBytes: _bytes,
        filename: _filename,
      );
      _title.clear();
      _desc.clear();
      _price.clear();
      setState(() {
        _status = 'sale';
        _bytes = null;
        _filename = null;
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
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
            Row(
              children: [
                DropdownButton<String>(
                  value: _status,
                  items: const [
                    DropdownMenuItem(value: 'sale', child: Text('Venta')),
                    DropdownMenuItem(
                      value: 'adoption',
                      child: Text('Adopción'),
                    ),
                    DropdownMenuItem(value: 'rescue', child: Text('Rescate')),
                  ],
                  onChanged: (v) => setState(() => _status = v ?? 'sale'),
                ),
                const SizedBox(width: 12),
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
