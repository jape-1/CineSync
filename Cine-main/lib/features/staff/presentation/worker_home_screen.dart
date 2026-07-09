import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/storage/token_storage.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/top_bar.dart';
import '../../../widgets/cs_button.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../domain/models.dart';
import 'staff_dashboard_cubit.dart';

/// Dashboard del trabajador con ocupación en vivo y contador de validaciones
/// (WebSocket /ws/staff/dashboard) + acceso al escáner.
class WorkerHomeScreen extends StatelessWidget {
  const WorkerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (c) => StaffDashboardCubit(c.read<TokenStorage>())..connect(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

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
                  Text('STAFF · ${user?.turno?.toUpperCase() ?? 'EN VIVO'}',
                      style: AppTextStyles.eyebrow),
                  Text(user?.nombre ?? 'Trabajador',
                      style: AppTextStyles.h2.copyWith(fontSize: 22)),
                ],
              ),
              right: const _LivePill(),
            ),
            Expanded(
              child: BlocBuilder<StaffDashboardCubit, DashboardState>(
                builder: (context, state) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                label: 'VALIDACIONES HOY',
                                value: '${state.validacionesHoy}',
                                icon: Icons.verified_outlined,
                                color: AppColors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                label: 'OCUPACIÓN GLOBAL',
                                value:
                                    '${state.ocupacionGlobal.toStringAsFixed(0)}%',
                                icon: Icons.event_seat_outlined,
                                color: AppColors.amber,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Text('FUNCIONES', style: AppTextStyles.eyebrow),
                        const SizedBox(height: 12),
                        if (state.funciones.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              state.connected
                                  ? 'Sin funciones con asientos'
                                  : 'Conectando al panel…',
                              style: AppTextStyles.body
                                  .copyWith(color: AppColors.textDim),
                            ),
                          )
                        else
                          ...state.funciones
                              .map((f) => _FuncionRow(funcion: f)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: CSButton(
                label: 'Escanear QR',
                onPressed: () => context.push('/worker/scan'),
                icon: const Icon(Icons.qr_code_scanner),
                fullWidth: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: CSButton(
                label: 'Cerrar sesión',
                onPressed: () => context.read<AuthCubit>().logout(),
                variant: CSButtonVariant.secondary,
                icon: const Icon(Icons.logout),
                fullWidth: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(value,
              style: AppTextStyles.display.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.mono.copyWith(
                  fontSize: 9, letterSpacing: 1, color: AppColors.textDim)),
        ],
      ),
    );
  }
}

class _FuncionRow extends StatelessWidget {
  final OccupancyFuncion funcion;
  const _FuncionRow({required this.funcion});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM · HH:mm', 'es');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(funcion.peliculaTitulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.display.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text)),
              ),
              Text('${funcion.ocupados}/${funcion.totalAsientos}',
                  style: AppTextStyles.mono.copyWith(
                      fontSize: 12, color: AppColors.textDim)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
              '${funcion.salaNombre} · ${df.format(funcion.inicio.toLocal())}',
              style: AppTextStyles.body
                  .copyWith(fontSize: 11, color: AppColors.textDim)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (funcion.porcentaje / 100).clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: AppColors.surface2,
              valueColor: AlwaysStoppedAnimation(
                funcion.porcentaje > 80
                    ? AppColors.red
                    : funcion.porcentaje > 50
                        ? AppColors.amber
                        : AppColors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StaffDashboardCubit, DashboardState>(
      builder: (context, state) {
        final on = state.connected;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: on ? AppColors.green : AppColors.textFaint,
                ),
              ),
              const SizedBox(width: 6),
              Text(on ? 'EN VIVO' : 'OFFLINE',
                  style: AppTextStyles.mono.copyWith(
                      fontSize: 10, letterSpacing: 0.8, color: AppColors.textDim)),
            ],
          ),
        );
      },
    );
  }
}
