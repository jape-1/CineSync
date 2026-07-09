import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/json.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../data/admin_repository.dart';
import 'admin_common.dart';

class ReportesAdminScreen extends StatefulWidget {
  const ReportesAdminScreen({super.key});

  @override
  State<ReportesAdminScreen> createState() => _ReportesAdminScreenState();
}

class _ReportesAdminScreenState extends State<ReportesAdminScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  AdminRepository get _repo => context.read<AdminRepository>();

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final ventas = await _repo.reporteVentas();
    final ocupacion = await _repo.reporteOcupacion();
    return [ventas, ocupacion];
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Reportes',
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.red));
          }
          if (snap.hasError) {
            return Center(
                child: Text('${snap.error}',
                    style: const TextStyle(color: AppColors.textDim)));
          }
          final ventas = snap.data![0];
          final ocupacion = snap.data![1];
          final funciones = (ocupacion['items'] as List?) ?? [];
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('VENTAS', style: AppTextStyles.eyebrow),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _Metric(
                      label: 'Recaudado',
                      value:
                          'S/${asDouble(ventas['total_recaudado']).toStringAsFixed(2)}',
                      color: AppColors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Metric(
                      label: 'Compras',
                      value: '${ventas['num_compras'] ?? 0}',
                      color: AppColors.amber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Metric(
                      label: 'Entradas',
                      value: '${ventas['num_entradas'] ?? 0}',
                      color: AppColors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('OCUPACIÓN', style: AppTextStyles.eyebrow),
              const SizedBox(height: 4),
              Text(
                  'Global: ${asDouble(ocupacion['ocupacion_global']).toStringAsFixed(1)}%',
                  style: AppTextStyles.body.copyWith(color: AppColors.textDim)),
              const SizedBox(height: 12),
              ...funciones.map((f) {
                final m = f as Map<String, dynamic>;
                final pct = asDouble(m['porcentaje']);
                return AdminTile(
                  title:
                      '${m['pelicula_titulo']} · ${m['sala_nombre']}',
                  subtitle:
                      '${m['ocupados']}/${m['total_asientos']} asientos · ${pct.toStringAsFixed(1)}%',
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Metric(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: AppTextStyles.display.copyWith(
                  fontSize: 20, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: AppTextStyles.mono.copyWith(
                  fontSize: 9, letterSpacing: 0.8, color: AppColors.textDim)),
        ],
      ),
    );
  }
}
