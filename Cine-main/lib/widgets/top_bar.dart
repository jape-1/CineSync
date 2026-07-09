
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
 
/// Barra superior de la app, con tres zonas: [left], [center] (opcional)
/// y [right].
///
/// Equivalente al `TopBar` del React. La zona izquierda crece para empujar
/// el resto, la derecha se ajusta al contenido, y el centro (cuando se pasa)
/// se centra en el espacio sobrante.
///
/// [sticky] **no** la fija al scroll por sí solo — en Flutter el "stickeo"
/// lo logras poniendo la TopBar fuera del widget scrolleable de la pantalla
/// (típicamente en un `Column` con el `Expanded` con el scroll debajo).
/// El parámetro solo cambia el fondo: cuando es true, pinta el gradiente
/// que difumina el contenido detrás (igual que el React); cuando es false,
/// fondo transparente.
class TopBar extends StatelessWidget {
  final Widget? left;
  final Widget? center;
  final Widget? right;
  final bool sticky;
 
  const TopBar({
    super.key,
    this.left,
    this.center,
    this.right,
    this.sticky = false,
  });
 
  @override
  Widget build(BuildContext context) {
    return Container(
      // padding: '8px 20px 12px'
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      decoration: BoxDecoration(
        // sticky=true → gradiente que desvanece de AppColors.bg (arriba)
        // a transparente (abajo), igual que en el React.
        gradient: sticky
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.bg, AppColors.bg, Colors.transparent],
                stops: [0.0, 0.7, 1.0],
              )
            : null,
      ),
      child: Row(
        children: [
          // ─── Zona izquierda ───
          // En el React: gap:10 entre hijos. Si esperas múltiples widgets,
          // pasa una Row con tus propios children; aquí solo aseguramos el
          // contenedor que ocupa el espacio.
          if (left != null)
            Expanded(
              child: DefaultTextStyle.merge(
                style: AppTextStyles.body.copyWith(color: AppColors.text),
                child: left!,
              ),
            )
          else
            const Spacer(),
 
          // ─── Zona central (opcional) ───
          // En el React: flex:1, text-align:center. Solo se muestra si se
          // pasa, y en ese caso ocupa su propio Expanded.
          if (center != null)
            Expanded(
              child: Center(
                child: DefaultTextStyle.merge(
                  style: AppTextStyles.display.copyWith(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  child: center!,
                ),
              ),
            ),
 
          // ─── Zona derecha ───
          // gap:8 entre hijos en el React. Mismo principio: si quieres
          // múltiples botones, pasa una Row con tu propio spacing.
          if (right != null)
            DefaultTextStyle.merge(
              style: AppTextStyles.body.copyWith(color: AppColors.text),
              child: right!,
            ),
        ],
      ),
    );
  }
}