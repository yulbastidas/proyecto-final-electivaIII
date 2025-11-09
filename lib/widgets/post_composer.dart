import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pets/widgets/app_text_field.dart';
import 'package:pets/widgets/primary_button.dart';

class PostComposer extends StatelessWidget {
  const PostComposer({
    super.key,
    required this.textCtrl,
    required this.status,
    required this.onChangeStatus,
    required this.imageBytes,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.onPublish,
    required this.publishing,
  });

  final TextEditingController textCtrl;
  final String status;
  final ValueChanged<String> onChangeStatus;

  final Uint8List? imageBytes;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;

  final VoidCallback? onPublish;
  final bool publishing;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            AppTextField(
              label: '¿Qué estás pensando?',
              controller: textCtrl,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(
                      labelText: 'Estado',
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
                      if (v != null) onChangeStatus(v);
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
                    fit: BoxFit.cover, // estilo DALL·E
                    filterQuality: FilterQuality.medium,
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
