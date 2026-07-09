
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Identificador de cada tab de la barra inferior.
///
/// Se usa un enum en vez de strings (como en el React) para que el editor
/// te autocomplete y avise si te equivocas escribiendo el nombre.
enum BottomTab { home, tickets, snacks, profile }

/// Barra de navegación inferior fija de la app.
///
/// Equivalente al `BottomTabs` del React:
///   - cápsula interior con fondo `surface` y borde sutil
///   - 4 tabs: Inicio, Tickets, Dulcería, Perfil
///   - el tab [active] se resalta en rojo con fondo translúcido
///   - el contenedor exterior respeta la safe area inferior del dispositivo
///
/// [onTap] se llama con el tab pulsado. Si es null, los tabs no responden
/// (útil para usarlo como mockup estático mientras montas la navegación).
class BottomTabs extends StatelessWidget {
  final BottomTab active;
  final ValueChanged<BottomTab>? onTap;

  const BottomTabs({
    super.key,
    required this.active,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Safe area inferior: la zona de la barra de gestos del sistema.
    // En iPhones modernos suele ser ~34px; en Android puede ser 0.
    // Sumamos un colchón propio (14px) para que nunca quede pegado al borde.
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final bottomPad = (safeBottom > 0 ? safeBottom : 14.0) + 8;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, bottomPad),
      decoration: const BoxDecoration(
        // Gradiente de transparente al bgDeep (el del React).
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, AppColors.bgDeep],
          stops: [0.0, 0.3],
        ),
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Container(
        // Cápsula interior
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            _TabItem(tab: BottomTab.home, icon: Icons.home_outlined, label: 'Inicio'),
            _TabItem(tab: BottomTab.tickets, icon: Icons.confirmation_number_outlined, label: 'Tickets'),
            _TabItem(tab: BottomTab.snacks, icon: Icons.local_movies_outlined, label: 'Dulcería'),
            _TabItem(tab: BottomTab.profile, icon: Icons.person_outline, label: 'Perfil'),
          ].map((item) => _wireUp(item)).toList(),
        ),
      ),
    );
  }

  /// Pasa el estado activo y el callback a cada item. Lo hacemos así para
  /// que cada _TabItem siga siendo const-construible (mejor rendimiento)
  /// y la lógica de "estoy activo / qué pasa al tocar" viva en un solo lugar.
  Widget _wireUp(_TabItem item) {
    return _TabItem(
      tab: item.tab,
      icon: item.icon,
      label: item.label,
      active: item.tab == active,
      onTap: onTap == null ? null : () => onTap!(item.tab),
    );
  }
}

class _TabItem extends StatelessWidget {
  final BottomTab tab;
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _TabItem({
    required this.tab,
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.red : AppColors.textDim;
    // Fondo translúcido sólo en el activo: rgba(220,60,60,0.08) del React,
    // que ya es un rojo a baja opacidad. Usamos red con alpha bajo.
    final bg = active ? AppColors.red.withValues(alpha: 0.08) : Colors.transparent;

    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: color,
              height: 1,
            ),
          ),
        ],
      ),
    );

    // Sin onTap → widget puramente visual (como mockup).
    if (onTap == null) return content;

    // Con onTap → envolvemos en InkWell para el ripple, recortado al
    // mismo borderRadius del fondo para que el efecto no se salga.
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: content,
    );
  }
}