
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
 
/// Logo circular de CineSync.
///
/// Equivalente al SVG `CSLogo` del React (viewBox 0 0 32 32):
///   - círculo exterior gris tenue (stroke 1.5, opacity 0.4)
///   - arco rojo de un cuarto de vuelta (de las 12 a las 3 en punto)
///   - círculo central relleno rojo (r 3.5)
///   - punto interior del color de fondo (r 1.5)
///
/// `color`  → trazo del círculo exterior (default texto)
/// `accent` → arco y punto centrales (default rojo de marca)
/// En el QR se usa todo blanco: CSLogo(color: Colors.white, accent: Colors.white).
class CSLogo extends StatelessWidget {
  final double size;
  final Color color;
  final Color accent;
 
  const CSLogo({
    super.key,
    this.size = 28,
    this.color = AppColors.text,
    this.accent = AppColors.red,
  });
 
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CSLogoPainter(color: color, accent: accent),
      ),
    );
  }
}
 
class _CSLogoPainter extends CustomPainter {
  final Color color;
  final Color accent;
 
  _CSLogoPainter({required this.color, required this.accent});
 
  @override
  void paint(Canvas canvas, Size size) {
    // Todo el SVG original está pensado en un lienzo de 32x32.
    // Escalamos proporcionalmente al tamaño real pedido.
    final s = size.width / 32.0;
    final center = Offset(16 * s, 16 * s);
 
    // 1) Círculo exterior gris tenue (r 14, stroke 1.5, opacity 0.4)
    final outer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * s
      ..color = color.withValues(alpha: color.a * 0.4);
    canvas.drawCircle(center, 14 * s, outer);
 
    // 2) Arco rojo: de las 12 (arriba) a las 3 (derecha) = un cuarto de vuelta.
    //    En el SVG: M16 4  A12 12 0 0 1 28 16  → empieza arriba, termina a la derecha.
    //    En Flutter los ángulos van en radianes: -90° (arriba) barriendo +90° (a la derecha).
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * s
      ..strokeCap = StrokeCap.round
      ..color = accent;
    final arcRect = Rect.fromCircle(center: center, radius: 12 * s);
    canvas.drawArc(
      arcRect,
      -math.pi / 2, // 12 en punto
      math.pi / 2, // barrido de 90° hacia las 3 en punto
      false,
      arc,
    );
 
    // 3) Círculo central relleno rojo (r 3.5)
    final core = Paint()
      ..style = PaintingStyle.fill
      ..color = accent;
    canvas.drawCircle(center, 3.5 * s, core);
 
    // 4) Punto interior color de fondo (r 1.5)
    //    En el React es CS.bg. Como CSLogo puede usarse sobre fondos distintos,
    //    usamos AppColors.bg para fidelidad con el original.
    final dot = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.bg;
    canvas.drawCircle(center, 1.5 * s, dot);
  }
 
  @override
  bool shouldRepaint(_CSLogoPainter old) =>
      old.color != color || old.accent != accent;
}
 