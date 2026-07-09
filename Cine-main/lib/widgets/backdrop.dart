import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';
import '_stripes_painter.dart';

/// Versión ancha del [Poster], pensada para banners.
///
/// Equivalente al `Backdrop` del React:
///   - ancho completo del padre (no se pasa width)
///   - altura configurable (default 220)
///   - rayas diagonales más anchas (12px) y a 115° (en vez de los 8px/135°
///     del Poster) — se ve más "panorámico"
///   - colores ligeramente más claros que el Poster
///   - gradiente oscuro concentrado en el tercio inferior, no uniforme
///   - etiqueta "backdrop / [title]" arriba a la izquierda
///   - borderRadius opcional (default 0, suele ir pegado a los bordes)
class Backdrop extends StatelessWidget {
  final String title;
  final double height;
  final double hue;
  final double radius;

  /// URL de la imagen real (backdrop_url de TMDB). Si es null, gradiente.
  final String? imageUrl;

  const Backdrop({
    super.key,
    required this.title,
    this.height = 220,
    this.hue = 25,
    this.radius = 0,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    // En el React: oklch(0.28 0.05 hue) y oklch(0.16 0.03 hue).
    // Equivalente HSL: igual que el Poster pero un pelín más claros.
    final c1 = HSLColor.fromAHSL(1, hue, 0.22, 0.25).toColor();
    final c2 = HSLColor.fromAHSL(1, hue, 0.16, 0.14).toColor();

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          children: [
            // ─── Capa 1: rayas diagonales ───
            // Reutilizamos el painter compartido con valores propios:
            // stripeWidth 12, cycle 24, ángulo CSS 115°.
            Positioned.fill(
              child: CustomPaint(
                painter: StripesPainter(
                  c1: c1,
                  c2: c2,
                  stripeWidth: 12,
                  cycle: 24,
                  angleDegrees: 115,
                ),
              ),
            ),

            // ─── Capa 1b: imagen real (si hay) ───
            if (imageUrl != null)
              Positioned.fill(
                child: Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),

            // ─── Capa 2: gradiente oscuro concentrado abajo ───
            // En el React: linear-gradient(180deg, rgba(0,0,0,0) 30%, rgba(0,0,0,0.85) 100%)
            // El parámetro stops simula ese "30% transparente, después oscurece".
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xD9000000)],
                    stops: [0.3, 1.0],
                  ),
                ),
              ),
            ),

            // ─── Capa 3: etiqueta "backdrop / título" (solo placeholder) ───
            if (imageUrl == null)
              Positioned(
                top: 12,
                left: 14,
                child: Text(
                  'BACKDROP / ${title.toUpperCase()}',
                  style: AppTextStyles.mono.copyWith(
                    fontSize: 9,
                    letterSpacing: 1.6,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}