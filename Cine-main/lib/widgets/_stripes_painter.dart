
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Pinta rayas diagonales repetidas con dos colores alternados, imitando
/// el `repeating-linear-gradient` de CSS.
///
/// Lo usan [Poster] y [Backdrop]. Parámetros:
///   - [c1]: color de fondo (la "base").
///   - [c2]: color de las rayas (encima de c1).
///   - [stripeWidth]: ancho de cada raya en píxeles.
///   - [cycle]: distancia total de un ciclo (raya + espacio).
///   - [angleDegrees]: ángulo de las rayas en grados CSS.
class StripesPainter extends CustomPainter {
  final Color c1;
  final Color c2;
  final double stripeWidth;
  final double cycle;
  final double angleDegrees;

  StripesPainter({
    required this.c1,
    required this.c2,
    this.stripeWidth = 8,
    this.cycle = 16,
    this.angleDegrees = 135,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = c1);

    final canvasAngleRad = -(angleDegrees - 90) * math.pi / 180;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(canvasAngleRad);

    final diag = (size.width + size.height) * 1.5;
    final paint = Paint()..color = c2;
    for (double x = -diag; x < diag; x += cycle) {
      canvas.drawRect(
        Rect.fromLTWH(x, -diag, stripeWidth, diag * 2),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(StripesPainter old) =>
      old.c1 != c1 ||
      old.c2 != c2 ||
      old.stripeWidth != stripeWidth ||
      old.cycle != cycle ||
      old.angleDegrees != angleDegrees;
}