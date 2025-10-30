import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'app_text_field.dart';
import 'primary_button.dart';

class PostComposer extends StatefulWidget {
  final Future<void> Function({
    required String description,
    required String status,
    Uint8List? imageBytes,
    String? filename,
  })
  onCreate;

  const PostComposer({super.key, required this.onCreate});

  @override
  State<PostComposer> createState() => _PostComposerState();
}

class _PostComposerState extends State<PostComposer> {
  final _descCtrl = TextEditingController();
  String _status = 'RESCATADO';
  Uint8List? _bytes;
  String? _filename;
  bool _busy = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final f = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (f == null) return;
    _bytes = await f.readAsBytes();
    _filename = f.name;
    setState(() {});
  }

  Future<void> _submit() async {
    if (_descCtrl.text.trim().isEmpty && _bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añade descripción o imagen.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.onCreate(
        description: _descCtrl.text.trim(),
        status: _status,
        imageBytes: _bytes,
        filename: _filename,
      );
      _descCtrl.clear();
      _bytes = null;
      _filename = null;
      setState(() {});
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            AppTextField(
              controller: _descCtrl,
              label: 'Descripción',
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _status, // sin warnings
                    items: const [
                      DropdownMenuItem(
                        value: 'RESCATADO',
                        child: Text('Rescatado'),
                      ),
                      DropdownMenuItem(
                        value: 'ADOPCION',
                        child: Text('En adopción'),
                      ),
                      DropdownMenuItem(value: 'VENTA', child: Text('En venta')),
                    ],
                    onChanged: (v) =>
                        setState(() => _status = v ?? 'RESCATADO'),
                    decoration: const InputDecoration(
                      labelText: 'Estado',
                      border: OutlineInputBorder(),
                      filled: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo),
                  label: Text(_filename == null ? 'Imagen' : '1 seleccionada'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: PrimaryButton(
                text: 'Publicar',
                onPressed: _busy ? null : _submit,
                loading: _busy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
