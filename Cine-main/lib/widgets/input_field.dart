
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Campo de texto principal de la app — equivalente al `InputField` del React.
///
/// Estilo:
///   - altura 54px, borderRadius 14 (consistente con los botones)
///   - fondo `surface`, borde sutil
///   - ícono opcional a la izquierda
///   - al enfocar: borde rojo + halo rojizo (el `redGlow`)
///
/// Uso típico:
///   ```dart
///   final emailController = TextEditingController();
///   InputField(
///     icon: Icon(Icons.mail_outline),
///     placeholder: 'correo@cinesync.app',
///     controller: emailController,
///   )
///   ```
///
/// Si no pasas [controller], el campo igual escribe (Flutter crea uno
/// interno), pero no podrás leer su valor desde fuera. Para login/registro
/// siempre pasa controllers desde el padre.
class InputField extends StatefulWidget {
  final Widget? icon;
  final String? placeholder;
  final TextEditingController? controller;
  final bool obscureText;

  /// Tipo de teclado (email, número, etc.). Default es texto normal.
  /// Útil para forzar el teclado de email en el campo de correo:
  ///   `keyboardType: TextInputType.emailAddress`
  final TextInputType? keyboardType;

  const InputField({
    super.key,
    this.icon,
    this.placeholder,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  // FocusNode propio para detectar cuándo el campo está enfocado y poder
  // pintar el borde rojo + halo. El controller en cambio viene de fuera
  // (o lo crea Flutter internamente si no se pasa).
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    // setState para que el widget se repinte con el nuevo estilo de borde.
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    // Importante: limpiar el FocusNode para no dejar listeners colgando.
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      // AnimatedContainer en vez de Container suaviza el cambio de borde
      // y sombra al ganar/perder foco (sin saltos bruscos).
      duration: const Duration(milliseconds: 150),
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isFocused ? AppColors.red : AppColors.border,
          width: 1,
        ),
        // Halo rojizo cuando está enfocado, igual que el box-shadow del React.
        boxShadow: _isFocused
            ? const [
                BoxShadow(
                  color: AppColors.redGlow,
                  blurRadius: 0,
                  spreadRadius: 3,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // ─── Ícono a la izquierda (opcional) ───
          // En el React: padding-left 18 + ícono + padding 12 hasta el texto.
          // Aquí lo conseguimos con padding fijo y un SizedBox como separador.
          if (widget.icon != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 18, right: 12),
              child: IconTheme(
                data: const IconThemeData(color: AppColors.textDim, size: 18),
                child: widget.icon!,
              ),
            ),
          ] else
            const SizedBox(width: 18),

          // ─── TextField que ocupa el resto ───
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              cursorColor: AppColors.red,
              style: AppTextStyles.body.copyWith(
                fontSize: 15,
                color: AppColors.text,
              ),
              decoration: InputDecoration(
                // Quita el subrayado y el padding por defecto del TextField,
                // porque ya tenemos nuestro propio borde y padding.
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: const EdgeInsets.only(right: 18),
                hintText: widget.placeholder,
                hintStyle: AppTextStyles.body.copyWith(
                  fontSize: 15,
                  color: AppColors.textDim,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}