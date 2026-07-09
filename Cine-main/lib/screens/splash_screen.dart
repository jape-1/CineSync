import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/cs_logo.dart';

/// Pantalla de bienvenida. Se muestra mientras `go_router` resuelve la sesión
/// (AuthCubit.bootstrap) y luego redirige automáticamente según el rol.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _spin;
  late final AnimationController _loading;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
    _loading = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    _loading.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.4),
            radius: 1.0,
            colors: [
              Color(0xFF2A1810),
              AppColors.bg,
              AppColors.bgDeep,
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const _ConcentricRings(),

              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 112,
                      height: 112,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _spin,
                            builder: (_, __) {
                              return Transform.rotate(
                                angle: _spin.value * 2 * math.pi,
                                child: CustomPaint(
                                  size: const Size(112, 112),
                                  painter: _DashedCirclePainter(),
                                ),
                              );
                            },
                          ),
                          const CSLogo(size: 88),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    Text.rich(
                      TextSpan(
                        style: AppTextStyles.display.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 42,
                          letterSpacing: -1.68,
                          color: AppColors.text,
                        ),
                        children: const [
                          TextSpan(text: 'Cine'),
                          TextSpan(
                            text: 'Sync',
                            style: TextStyle(color: AppColors.red),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'REAL · TIME · CINEMA',
                      style: AppTextStyles.mono.copyWith(
                        fontSize: 11,
                        letterSpacing: 3.52,
                        color: AppColors.textDim,
                      ),
                    ),
                  ],
                ),
              ),

              Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    SizedBox(
                      width: 180,
                      height: 2,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: Stack(
                          children: [
                            Container(color: Colors.white.withValues(alpha: 0.08)),
                            AnimatedBuilder(
                              animation: _loading,
                              builder: (_, __) {
                                final t = _loading.value;
                                final dx = (-0.45 + t * 1.45) * 180;
                                return Positioned(
                                  left: dx,
                                  top: 0,
                                  bottom: 0,
                                  width: 180 * 0.45,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          Colors.transparent,
                                          AppColors.red,
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Text(
                      'v 1.0.0 · sincronizando salas',
                      style: AppTextStyles.mono.copyWith(
                        fontSize: 10,
                        letterSpacing: 2,
                        color: AppColors.textFaint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConcentricRings extends StatelessWidget {
  const _ConcentricRings();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, -0.55),
      child: SizedBox(
        width: 340,
        height: 340,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.redGlow, Colors.transparent],
                ),
              ),
            ),
            for (int i = 0; i < 4; i++)
              Container(
                width: 340.0 - i * 60,
                height: 340.0 - i * 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10 - i * 0.02),
                    width: 1,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.borderStrong;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1;

    const segments = 60;
    const dashAngle = (2 * math.pi) / segments / 2;
    const gapAngle = (2 * math.pi) / segments / 2;

    final rect = Rect.fromCircle(center: center, radius: radius);
    for (int i = 0; i < segments; i++) {
      final start = i * (dashAngle + gapAngle);
      canvas.drawArc(rect, start, dashAngle, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter oldDelegate) => false;
}