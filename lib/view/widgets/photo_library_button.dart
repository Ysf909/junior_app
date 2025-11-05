import 'package:flutter/material.dart';

class PhotoLibraryButton extends StatelessWidget {
  final VoidCallback onPressed;

  const PhotoLibraryButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.photo_library),
      onPressed: onPressed,
    );
  }
}
