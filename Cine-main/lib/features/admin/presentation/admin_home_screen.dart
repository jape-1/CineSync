import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/top_bar.dart';
import '../../../widgets/icon_btn.dart';
import '../../auth/presentation/auth_cubit.dart';

/// Hub del administrador: accesos a cada área de gestión.
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  static const _sections = [
    (_Section(label: 'Películas', icon: Icons.movie_outlined, path: '/admin/peliculas')),
    (_Section(label: 'Salas', icon: Icons.meeting_room_outlined, path: '/admin/salas')),
    (_Section(label: 'Funciones', icon: Icons.event_outlined, path: '/admin/funciones')),
    (_Section(label: 'Dulcería', icon: Icons.fastfood_outlined, path: '/admin/dulceria')),
    (_Section(label: 'Promociones', icon: Icons.sell_outlined, path: '/admin/promociones')),
    (_Section(label: 'Usuarios', icon: Icons.badge_outlined, path: '/admin/usuarios')),
    (_Section(label: 'Reportes', icon: Icons.insights_outlined, path: '/admin/reportes')),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              sticky: true,
              left: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('ADMINISTRACIÓN', style: AppTextStyles.eyebrow),
                  Text(user?.nombre ?? 'Admin',
                      style: AppTextStyles.h2.copyWith(fontSize: 22)),
                ],
              ),
              right: IconBtn(
                onTap: () => context.read<AuthCubit>().logout(),
                child: const Icon(Icons.logout, size: 18),
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.all(20),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.15,
                children: _sections
                    .map((s) => _SectionCard(section: s))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section {
  final String label;
  final IconData icon;
  final String path;
  const _Section({required this.label, required this.icon, required this.path});
}

class _SectionCard extends StatelessWidget {
  final _Section section;
  const _SectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(section.path),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(section.icon, color: AppColors.red, size: 22),
            ),
            Text(section.label,
                style: AppTextStyles.display.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text)),
          ],
        ),
      ),
    );
  }
}
