import 'package:flutter/material.dart';

class CloudButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CloudButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.cloud),
      onPressed: onPressed,
    );
  }
}
