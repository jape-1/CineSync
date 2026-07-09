
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Variantes visuales del botón.
///
/// - [primary]: fondo rojo con sombra (cs-btn-primary del React). Es el
///   call-to-action principal.
/// - [secondary]: transparente con borde sutil (cs-btn-secondary).
///   Usado para acciones secundarias y para los botones sociales del login.
enum CSButtonVariant { primary, secondary }

/// Botón principal de la app — equivalente a las clases `.cs-btn-primary`
/// y `.cs-btn-secondary` del React.
///
/// Soporta texto + ícono opcional a la derecha (típico patrón
/// "Continuar →" del diseño).
///
/// Si [onPressed] es null, el botón se ve atenuado y no responde
/// (estándar de Flutter para botones deshabilitados — se usa, por ejemplo,
/// en la pantalla de butacas cuando no hay asientos seleccionados).
///
/// [fullWidth] (default false): cuando es true, el botón ocupa todo el
/// ancho del padre. Equivale a `width: '100%'` del React.
class CSButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final CSButtonVariant variant;
  final Widget? icon;
  final bool fullWidth;

  const CSButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = CSButtonVariant.primary,
    this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = variant == CSButtonVariant.primary;
    final isDisabled = onPressed == null;

    // ─── Decoración del fondo ───
    // Primary: fondo rojo + sombra rojiza + highlight blanco interno arriba
    //   (el `inset 0 1px 0 rgba(255,255,255,0.18)` del React lo simulamos
    //    con un BoxShadow blanco con offset negativo).
    // Secondary: transparente con borde fuerte.
    final BoxDecoration decoration;
    if (isPrimary) {
      decoration = BoxDecoration(
        color: AppColors.red,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isDisabled
            ? const []
            : const [
                // Sombra rojiza exterior (cs-btn-primary): el `redGlow`
                BoxShadow(
                  color: AppColors.redGlow,
                  blurRadius: 28,
                  offset: Offset(0, 8),
                ),
              ],
      );
    } else {
      decoration = BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderStrong, width: 1),
      );
    }

    // ─── Contenido (texto + ícono opcional) ───
    final textColor = isPrimary
        ? Colors.white
        : AppColors.text;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: AppTextStyles.button.copyWith(color: textColor),
        ),
        if (icon != null) ...[
          const SizedBox(width: 8),
          // IconTheme propaga color/tamaño al ícono que pases, sin que
          // tengas que especificarlos en cada llamada.
          IconTheme(
            data: IconThemeData(color: textColor, size: 16),
            child: icon!,
          ),
        ],
      ],
    );

    // ─── Botón completo ───
    // Material + InkWell para el ripple al tocarlo (sólo si está habilitado).
    final button = Opacity(
      // Si está disabled, atenuamos visualmente todo el botón.
      opacity: isDisabled ? 0.5 : 1,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: decoration,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              alignment: Alignment.center,
              child: content,
            ),
          ),
        ),
      ),
    );

    // fullWidth=true → SizedBox infinito para ocupar el ancho del padre.
    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}