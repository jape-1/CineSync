import '_stripes_painter.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Placeholder de poster de película.
///
/// Equivalente al `Poster` del React:
///   - rayas diagonales repetidas como fondo (usando LinearGradient con
///     stops alternados — Flutter no tiene `repeating-linear-gradient`)
///   - gradiente oscuro encima para dar profundidad
///   - etiqueta "POSTER" arriba a la izquierda
///   - badge VIP opcional arriba a la derecha (dorado)
///   - título en blanco abajo
///   - línea de color de acento en el borde inferior
///
/// [hue] es 0-360 (HSL): controla el tinte de las rayas. Cambiarlo da
/// posters visualmente distintos para cada película.
/// Default 25 (rojizo, coherente con la marca).
class Poster extends StatelessWidget {
  final String title;
  final double width;
  final double height;
  final double hue;
  final bool vip;
  final double radius;

  /// URL de la imagen real (p. ej. poster_url de TMDB). Si es null, se dibuja
  /// el placeholder de gradiente; si viene, la imagen llena el marco.
  final String? imageUrl;

  const Poster({
    super.key,
    required this.title,
    this.width = 120,
    this.height = 170,
    this.hue = 25,
    this.vip = false,
    this.radius = 14,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    // En el React: oklch(0.25 0.04 hue) y oklch(0.18 0.03 hue).
    // Equivalente HSL: hue del usuario, saturación baja, luminosidad baja.
    // c1 = más claro, c2 = más oscuro → forman las rayas alternadas.
    final c1 = HSLColor.fromAHSL(1, hue, 0.18, 0.22).toColor();
    final c2 = HSLColor.fromAHSL(1, hue, 0.14, 0.15).toColor();
    final accent = HSLColor.fromAHSL(1, hue, 0.65, 0.55).toColor();

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000), // rgba(0,0,0,0.4)
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      // ClipRRect porque el contenido (rayas + gradiente + accent line)
      // tiene que respetar el borderRadius del Container exterior.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            // ─── Capa 1: rayas diagonales ───
            // Truco para imitar `repeating-linear-gradient(135deg, c1 0 8px, c2 8px 16px)`:
            // un gradiente con stops alternados. Cada "rayita" es 8px sobre un
            // total de "muchas rayas". Aquí lo hacemos con un Transform.rotate
            // y un gradiente de 0 a 1 con muchos stops calculados.
            Positioned.fill(child: _StripesBackground(c1: c1, c2: c2)),

            // ─── Capa 1b: imagen real (si hay), sobre el gradiente ───
            if (imageUrl != null)
              Positioned.fill(
                child: Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),

            // ─── Capa 2: gradiente oscuro encima ───
            // En el React: linear-gradient(180deg, rgba(0,0,0,0.1) 0%, rgba(0,0,0,0.55) 100%)
            // Hace que el texto inferior sea legible y el badge VIP destaque.
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x1A000000), Color(0x8C000000)],
                  ),
                ),
              ),
            ),

            // ─── Capa 3: contenido (label, VIP, título) ───
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Etiqueta "poster" solo en el placeholder (sin imagen real)
                      if (imageUrl == null)
                        Text(
                          'POSTER',
                          style: AppTextStyles.mono.copyWith(
                            fontSize: 8,
                            letterSpacing: 0.8,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                      const Spacer(),
                      // Badge VIP arriba a la derecha (opcional)
                      if (vip)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.gold, width: 1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'VIP',
                            style: AppTextStyles.mono.copyWith(
                              fontSize: 8,
                              letterSpacing: 0.8,
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(), // empuja el título abajo
                  // Título grande blanco
                  Text(
                    title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.display.copyWith(
                      fontSize: width < 100 ? 13 : 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                      height: 1.05,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // ─── Capa 4: línea de acento en el borde inferior ───
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 2,
                color: accent.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StripesBackground extends StatelessWidget {
  final Color c1;
  final Color c2;
  const _StripesBackground({required this.c1, required this.c2});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: StripesPainter(
        c1: c1,
        c2: c2,
        stripeWidth: 8,
        cycle: 16,
        angleDegrees: 135,
      ),
    );
  }
}