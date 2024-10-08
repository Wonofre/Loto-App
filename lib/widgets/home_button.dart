// lib/widgets/home_button.dart
import 'package:flutter/material.dart';

class HomeButton extends StatelessWidget {
  const HomeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.home),
      onPressed: () {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      },
      tooltip: 'Voltar à Home',
    );
  }
}
