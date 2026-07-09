import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/top_bar.dart';
import '../../../widgets/icon_btn.dart';

/// Scaffold común de una pantalla de gestión: barra con volver + título +
/// botón opcional de "agregar", y un cuerpo.
class AdminScaffold extends StatelessWidget {
  final String title;
  final VoidCallback? onAdd;
  final Widget body;

  const AdminScaffold({
    super.key,
    required this.title,
    this.onAdd,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              sticky: true,
              left: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconBtn(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(title,
                      style: AppTextStyles.display.copyWith(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
              right: onAdd == null
                  ? null
                  : IconBtn(onTap: onAdd, child: const Icon(Icons.add, size: 20)),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta simple para un ítem de una lista de gestión.
class AdminTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const AdminTile(
      {super.key, required this.title, this.subtitle, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: AppTextStyles.display.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: AppTextStyles.body.copyWith(
                            fontSize: 12, color: AppColors.textDim)),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

/// Campo de texto etiquetado para formularios de administración.
class AdminField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscure;

  const AdminField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        style: const TextStyle(color: AppColors.text),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textDim),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.red),
          ),
        ),
      ),
    );
  }
}

void adminSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

/// Muestra un formulario en bottom sheet y devuelve true si se guardó.
Future<T?> showAdminSheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: AppColors.bgDeep,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: child,
    ),
  );
}
