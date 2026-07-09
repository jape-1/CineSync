
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
 
/// Botón redondo de la barra superior (back, search, share, notificaciones…).
///
/// Equivalente al `IconBtn` del React:
///   - círculo de [size]×[size] (default 38)
///   - fondo `surface`, borde sutil `border`
///   - cualquier widget como contenido (típicamente un `Icon`)
///   - [badge] opcional: pill rojo arriba-derecha con el texto que pases
///     (por ejemplo "3", "99+"). Si es null, no se muestra.
///   - [onTap] opcional: si no lo pasas, el botón es decorativo (sin ripple).
class IconBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? badge;
  final double size;
 
  const IconBtn({
    super.key,
    required this.child,
    this.onTap,
    this.badge,
    this.size = 38,
  });
 
  @override
  Widget build(BuildContext context) {
    // Stack para poder pegar el badge fuera del botón (top:-2, right:-2 en el React).
    // clipBehavior: none deja que el badge se salga del Stack sin recortarse.
    return SizedBox(
      width: size + 4, // +4 para que el badge no se corte por el padre
      height: size + 4,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Botón en sí, centrado dentro del SizedBox extra de 4px
          Positioned(
            top: 2,
            left: 2,
            child: _buildButton(),
          ),
          if (badge != null)
            Positioned(
              top: 0,
              right: 0,
              child: _buildBadge(),
            ),
        ],
      ),
    );
  }
 
  Widget _buildButton() {
    final decoration = BoxDecoration(
      color: AppColors.surface,
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.border, width: 1),
    );
 
    // Material+InkWell para el ripple sólo si hay onTap. Si es decorativo,
    // ahorramos esa capa y ponemos un Container plano.
    if (onTap == null) {
      return Container(
        width: size,
        height: size,
        decoration: decoration,
        alignment: Alignment.center,
        // IconTheme propaga el color por defecto a cualquier `Icon` hijo.
        child: IconTheme(
          data: const IconThemeData(color: AppColors.text, size: 18),
          child: child,
        ),
      );
    }
 
    return Material(
      color: AppColors.surface,
      shape: CircleBorder(
        side: BorderSide(color: AppColors.border, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: IconTheme(
              data: const IconThemeData(color: AppColors.text, size: 18),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
 
  Widget _buildBadge() {
    // Badge: pill rojo con texto. minWidth 16, height 16, padding horizontal 4,
    // borde de 2px del color de fondo para que se "recorte" del botón.
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.red,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.bg, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        badge!,
        textAlign: TextAlign.center,
        style: AppTextStyles.mono.copyWith(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
 