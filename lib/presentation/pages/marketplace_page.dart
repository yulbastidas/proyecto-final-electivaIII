import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/listing.dart';
import '../../data/services/listings_service.dart';
import '../widgets/listing_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/app_text_field.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});
  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  final _service = ListingsService();
  late Future<List<Listing>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchListings();
  }

  Future<void> _refresh() async {
    setState(() => _future = _service.fetchListings());
  }

  Future<void> _openCreate() async {
    final title = TextEditingController();
    final desc = TextEditingController();
    final price = TextEditingController();
    final contact = TextEditingController();
    File? image;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Nuevo artículo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              AppTextField(controller: title, hint: 'Título'),
              const SizedBox(height: 10),
              AppTextField(controller: desc, hint: 'Descripción', maxLines: 3),
              const SizedBox(height: 10),
              AppTextField(
                controller: price,
                hint: 'Precio (ej: 120000)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              AppTextField(
                controller: contact,
                hint: 'Contacto (WhatsApp / Email / Teléfono)',
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final x = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 85,
                      );
                      if (x != null) image = File(x.path);
                    },
                    icon: const Icon(Icons.photo),
                    label: const Text('Imagen'),
                  ),
                  const Spacer(),
                  PrimaryButton(
                    label: 'Publicar',
                    icon: Icons.cloud_upload_outlined,
                    onPressed: () async {
                      Navigator.pop(context);
                      final p = double.tryParse(price.text.trim()) ?? 0;
                      await _service.createListing(
                        title: title.text.trim(),
                        description: desc.text.trim(),
                        price: p,
                        contact: contact.text.trim(),
                        imageFile: image,
                      );
                      if (context.mounted) _refresh();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final items = snap.data as List<Listing>? ?? [];
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: PrimaryButton(
                    label: 'Vender',
                    icon: Icons.add,
                    onPressed: _openCreate,
                  ),
                );
              }
              final it = items[i - 1];
              return ListingCard(
                item: it,
                onDelete: () async {
                  await _service.deleteOwnListing(it.id);
                  _refresh();
                },
              );
            },
          );
        },
      ),
    );
  }
}
