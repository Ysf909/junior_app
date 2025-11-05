import 'package:flutter/material.dart';

class ListViewButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ListViewButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.list),
      onPressed: onPressed,
    );
  }
}
