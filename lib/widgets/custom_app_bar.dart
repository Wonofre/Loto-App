// lib/widgets/custom_app_bar.dart
import 'package:flutter/material.dart';
import 'home_button.dart'; // Certifique-se de que este widget está definido

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle; // Subtítulo opcional
  final bool showBackButton;
  final List<Widget>? actions; // Ações personalizadas extras

  const CustomAppBar({
    Key? key,
    required this.title,
    this.subtitle,
    this.showBackButton = true,
    this.actions,
  }) : super(key: key);

  @override
  Size get preferredSize =>
      Size.fromHeight(subtitle != null ? 100 : kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor:
          Colors.blue, // Personalize conforme a paleta de cores do seu app
      elevation: 4, // Sombra para dar profundidade
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          : null,
      title: subtitle != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Título Principal
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15, // Tamanho da fonte do título
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow
                        .ellipsis, // Truncar com reticências se necessário
                  ),
                ),
                const SizedBox(
                    height: 3), // Espaçamento entre título e subtítulo
                // Subtítulo
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 12, // Tamanho da fonte do subtítulo
                      color: Colors.white70,
                    ),
                    overflow: TextOverflow
                        .ellipsis, // Truncar com reticências se necessário
                  ),
                ),
              ],
            )
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16, // Tamanho da fonte do título
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                overflow: TextOverflow
                    .ellipsis, // Truncar com reticências se necessário
              ),
            ),
      actions: [
        if (actions != null)
          ...actions!, // Inclui ações personalizadas se fornecidas
        const HomeButton(), // Botão home padrão
        const SizedBox(width: 8), // Espaçamento à direita
      ],
      centerTitle: false, // Alinha o título à esquerda
    );
  }
}
