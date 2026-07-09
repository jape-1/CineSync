import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/icon_btn.dart';
import '../widgets/poster.dart';
import '../widgets/backdrop.dart';
import '../features/catalog/data/catalog_repository.dart';
import '../features/catalog/domain/models.dart';
import '../features/catalog/presentation/movie_detail_cubit.dart';
import '../features/checkout/presentation/checkout_cubit.dart';

double _hueFor(int id) => (id * 47) % 360;

/// Detalle de película con horarios reales (funciones del backend).
class MovieDetailScreen extends StatelessWidget {
  final int peliculaId;
  const MovieDetailScreen({super.key, required this.peliculaId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (c) =>
          MovieDetailCubit(c.read<CatalogRepository>())..load(peliculaId),
      child: const _MovieDetailView(),
    );
  }
}

class _MovieDetailView extends StatelessWidget {
  const _MovieDetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<MovieDetailCubit, MovieDetailState>(
          builder: (context, state) {
            if (state.loading) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.red));
            }
            final p = state.pelicula;
            if (p == null) {
              return _errorView(context, state.error ?? 'No encontrada');
            }
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 320 + 60, child: _Hero(pelicula: p)),
                        const SizedBox(height: 22),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _StatsBar(pelicula: p),
                        ),
                        if (p.sinopsis != null) ...[
                          const SizedBox(height: 22),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('SINOPSIS', style: AppTextStyles.eyebrow),
                                const SizedBox(height: 10),
                                Text(p.sinopsis!,
                                    style: AppTextStyles.body.copyWith(
                                        fontSize: 13,
                                        color: AppColors.textDim,
                                        height: 1.65)),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text('HORARIOS DISPONIBLES',
                              style: AppTextStyles.eyebrow),
                        ),
                        const SizedBox(height: 12),
                        _Funciones(funciones: state.funciones),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _errorView(BuildContext context, String msg) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(msg, style: const TextStyle(color: AppColors.textDim)),
            TextButton(
                onPressed: () => context.pop(), child: const Text('Volver')),
          ],
        ),
      );
}

class _Hero extends StatelessWidget {
  final Pelicula pelicula;
  const _Hero({required this.pelicula});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          height: 320,
          width: double.infinity,
          child: Backdrop(
            title: pelicula.titulo,
            hue: _hueFor(pelicula.id),
            height: 320,
            imageUrl: pelicula.backdropUrl,
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 320,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x66000000), Colors.transparent, AppColors.bg],
                stops: [0.0, 0.3, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          top: 14,
          left: 20,
          right: 20,
          child: Row(
            children: [
              IconBtn(
                onTap: () => context.pop(),
                child: const Icon(Icons.arrow_back, size: 20),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 0,
          left: 20,
          right: 20,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Poster(
                title: pelicula.titulo,
                hue: _hueFor(pelicula.id),
                width: 108,
                height: 154,
                imageUrl: pelicula.posterUrl,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        pelicula.titulo,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.display.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.6,
                          height: 1.05,
                          color: AppColors.text,
                        ),
                      ),
                      if (pelicula.clasificacion != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: AppColors.borderStrong, width: 1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(pelicula.clasificacion!,
                              style: AppTextStyles.mono.copyWith(
                                  fontSize: 10,
                                  letterSpacing: 1.2,
                                  color: AppColors.text)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsBar extends StatelessWidget {
  final Pelicula pelicula;
  const _StatsBar({required this.pelicula});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Stat(
              label: 'Rating',
              value: pelicula.calificacion?.toStringAsFixed(1) ?? '—',
              icon: const Icon(Icons.star, color: AppColors.gold, size: 14),
            ),
          ),
          Container(width: 1, height: 30, color: AppColors.border),
          Expanded(
              child: _Stat(
                  label: 'Duración',
                  value: pelicula.duracionLegible.isEmpty
                      ? '—'
                      : pelicula.duracionLegible)),
          Container(width: 1, height: 30, color: AppColors.border),
          Expanded(
              child: _Stat(
                  label: 'Género',
                  value: pelicula.generos.isEmpty
                      ? '—'
                      : pelicula.generos.first.nombre)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Widget? icon;
  const _Stat({required this.label, required this.value, this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label.toUpperCase(),
            style: AppTextStyles.mono.copyWith(
                fontSize: 10, letterSpacing: 1.2, color: AppColors.textDim)),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 4)],
            Flexible(
              child: Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.display.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text)),
            ),
          ],
        ),
      ],
    );
  }
}

class _Funciones extends StatelessWidget {
  final List<Funcion> funciones;
  const _Funciones({required this.funciones});

  @override
  Widget build(BuildContext context) {
    if (funciones.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Text('No hay funciones programadas',
            style: TextStyle(color: AppColors.textDim)),
      );
    }
    final df = DateFormat('EEE d MMM · HH:mm', 'es');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: funciones.map((f) {
          return GestureDetector(
            onTap: () {
              context.read<CheckoutCubit>().startFuncion(f);
              context.push('/seats/${f.id}');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(df.format(f.inicio.toLocal()),
                      style: AppTextStyles.display.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text)),
                  const SizedBox(height: 4),
                  Text(
                    'S/${f.precioBase.toStringAsFixed(2)}'
                    '${f.formato != null ? ' · ${f.formato}' : ''}'
                    '${f.idioma != null ? ' · ${f.idioma}' : ''}',
                    style: AppTextStyles.mono.copyWith(
                        fontSize: 11, color: AppColors.textDim),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
