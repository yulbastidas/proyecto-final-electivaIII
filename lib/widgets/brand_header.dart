import 'package:flutter/material.dart';

class BrandHeader extends StatelessWidget {
  final String title;

  const BrandHeader({super.key, this.title = 'Pets'});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: colors.primaryContainer,
          child: Text(
            '🐾',
            style: TextStyle(fontSize: 36, color: colors.onPrimaryContainer),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: colors.primary,
            letterSpacing: .4,
          ),
        ),
      ],
    );
  }
}
