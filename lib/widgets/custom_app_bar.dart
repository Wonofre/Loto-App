// lib/widgets/custom_app_bar.dart
import 'package:flutter/material.dart';
import 'home_button.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions; // Adicionado para permitir ações extras

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.actions, // Adicionado
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: FittedBox(
        // Usando FittedBox para ajustar dinamicamente o título
        fit: BoxFit.scaleDown,
        child: Text(
          title,
          style: const TextStyle(fontSize: 16), // Ajuste de tamanho da fonte
          overflow:
              TextOverflow.ellipsis, // Truncar com reticências se necessário
        ),
      ),
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          : null,
      actions: [
        ...?actions, // Inclui as ações personalizadas se fornecidas
        const HomeButton(), // Mantém o botão home como padrão
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
