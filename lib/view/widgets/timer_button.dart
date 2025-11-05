import 'package:flutter/material.dart';

class TimerButton extends StatelessWidget {
  final VoidCallback onPressed;

  const TimerButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.timer),
      onPressed: onPressed,
    );
  }
}
