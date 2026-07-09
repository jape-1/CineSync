import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/top_bar.dart';
import '../widgets/icon_btn.dart';
import '../widgets/bottom_tabs.dart';
import '../widgets/poster.dart';
import '../widgets/backdrop.dart';
import '../features/auth/presentation/auth_cubit.dart';
import '../features/catalog/data/catalog_repository.dart';
import '../features/catalog/domain/models.dart';
import '../features/catalog/presentation/home_cubit.dart';

/// Cartelera principal (cliente), alimentada por [HomeCubit] con datos reales.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (c) => HomeCubit(c.read<CatalogRepository>())..load(),
      child: const _HomeView(),
    );
  }
}

/// Un hue estable por película (para el placeholder cuando no hay imagen).
double _hueFor(int id) => (id * 47) % 360;

class _HomeView extends StatelessWidget {
  const _HomeView();

  void _goToMovie(BuildContext context, int id) => context.push('/movie/$id');

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user;
    final initials = _initials(user?.nombre ?? 'CS');

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              sticky: true,
              left: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.red, AppColors.redDeep],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(initials,
                        style: AppTextStyles.display.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Hola,',
                          style: AppTextStyles.mono.copyWith(
                              fontSize: 11,
                              letterSpacing: 0.55,
                              color: AppColors.textDim)),
                      const SizedBox(height: 2),
                      Text(user?.nombre ?? 'CineSync',
                          style: AppTextStyles.display.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text)),
                    ],
                  ),
                ],
              ),
              right: IconBtn(
                onTap: () => context.read<AuthCubit>().logout(),
                child: const Icon(Icons.logout, size: 18),
              ),
            ),
            Expanded(
              child: BlocBuilder<HomeCubit, HomeState>(
                builder: (context, state) {
                  if (state.loading && state.peliculas.isEmpty) {
                    return const Center(
                        child: CircularProgressIndicator(color: AppColors.red));
                  }
                  if (state.error != null && state.peliculas.isEmpty) {
                    return _ErrorRetry(
                      message: state.error!,
                      onRetry: () => context.read<HomeCubit>().load(),
                    );
                  }
                  return _content(context, state);
                },
              ),
            ),
            BottomTabs(
              active: BottomTab.home,
              onTap: (tab) {
                if (tab == BottomTab.tickets) {
                  context.push('/my-tickets');
                } else if (tab == BottomTab.profile) {
                  context.read<AuthCubit>().logout();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, HomeState state) {
    final movies = state.peliculas;
    final featured = movies.isNotEmpty ? movies.first : null;
    final grid = movies.length > 1 ? movies.sublist(1) : <Pelicula>[];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          if (featured != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('EN PROYECCIÓN', style: AppTextStyles.eyebrow),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _goToMovie(context, featured.id),
                    child: _FeaturedBanner(pelicula: featured),
                  ),
                ],
              ),
            ),
          _GenreChips(
            generos: state.generos,
            selected: state.generoSel,
            onSelect: (g) => context.read<HomeCubit>().selectGenero(g),
          ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Cartelera', style: AppTextStyles.h2),
          ),
          const SizedBox(height: 14),
          if (movies.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text('No hay películas en cartelera',
                    style: TextStyle(color: AppColors.textDim)),
              ),
            )
          else
            _CarteleraGrid(
              movies: grid.isEmpty ? movies : grid,
              onTap: (id) => _goToMovie(context, id),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'CS';
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class _FeaturedBanner extends StatelessWidget {
  final Pelicula pelicula;
  const _FeaturedBanner({required this.pelicula});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        children: [
          Backdrop(
            title: pelicula.titulo,
            hue: _hueFor(pelicula.id),
            height: 260,
            imageUrl: pelicula.backdropUrl,
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    pelicula.titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.display.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.9,
                      height: 1,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (pelicula.calificacion != null) ...[
                        const Icon(Icons.star, color: AppColors.gold, size: 14),
                        const SizedBox(width: 4),
                        Text(pelicula.calificacion!.toStringAsFixed(1),
                            style: AppTextStyles.body.copyWith(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.85))),
                        const SizedBox(width: 10),
                      ],
                      if (pelicula.duracionMin != null)
                        Text(pelicula.duracionLegible,
                            style: AppTextStyles.body.copyWith(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.85))),
                      if (pelicula.generos.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(pelicula.generos.first.nombre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body.copyWith(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.85))),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenreChips extends StatelessWidget {
  final List<Genero> generos;
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _GenreChips({
    required this.generos,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <String?>[null, ...generos.map((g) => g.nombre)];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: chips.map((nombre) {
          final isSel = nombre == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(nombre),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSel ? AppColors.red : AppColors.surface,
                  borderRadius: BorderRadius.circular(11),
                  border:
                      isSel ? null : Border.all(color: AppColors.border, width: 1),
                ),
                child: Text(
                  nombre ?? 'Todas',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSel ? Colors.white : AppColors.text,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CarteleraGrid extends StatelessWidget {
  final List<Pelicula> movies;
  final void Function(int id) onTap;
  const _CarteleraGrid({required this.movies, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: movies.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.58,
        ),
        itemBuilder: (context, i) {
          final m = movies[i];
          return GestureDetector(
            onTap: () => onTap(m.id),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, c) => Poster(
                      title: m.titulo,
                      hue: _hueFor(m.id),
                      width: c.maxWidth,
                      height: c.maxHeight,
                      imageUrl: m.posterUrl,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(m.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.display.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text)),
                const SizedBox(height: 2),
                Text(
                  [m.duracionLegible, m.generosLegible]
                      .where((s) => s.isNotEmpty)
                      .join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body
                      .copyWith(fontSize: 11, color: AppColors.textDim),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: AppColors.textDim, size: 40),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: AppColors.textDim)),
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
