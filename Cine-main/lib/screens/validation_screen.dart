import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/top_bar.dart';
import '../widgets/icon_btn.dart';
import '../widgets/cs_button.dart';
import '../features/staff/domain/models.dart';

/// Resultado de una validación de QR: válido / usado / inválido, con el detalle
/// del ticket cuando el código corresponde a una compra.
class ValidationScreen extends StatelessWidget {
  final ValidacionResponse? resultado;
  const ValidationScreen({super.key, this.resultado});

  @override
  Widget build(BuildContext context) {
    final r = resultado;
    final estado = r?.resultado ?? ResultadoValidacion.invalido;

    final (Color color, IconData icon, String titulo, String eyebrow) =
        switch (estado) {
      ResultadoValidacion.valido => (
          AppColors.green,
          Icons.check,
          'Acceso permitido',
          'TICKET VÁLIDO'
        ),
      ResultadoValidacion.usado => (
          AppColors.amber,
          Icons.replay,
          'Entrada ya usada',
          'TICKET USADO'
        ),
      ResultadoValidacion.invalido => (
          AppColors.red,
          Icons.close,
          'Acceso denegado',
          'TICKET INVÁLIDO'
        ),
    };

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.1),
            radius: 0.9,
            colors: [color.withValues(alpha: 0.16), AppColors.bgDeep],
            stops: const [0.0, 0.6],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              TopBar(
                left: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconBtn(
                      onTap: () => context.pop(),
                      child: const Icon(Icons.arrow_back, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text('Validador',
                        style: AppTextStyles.display.copyWith(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: _BigStatus(color: color, icon: icon),
                      ),
                      Text(eyebrow,
                          style: AppTextStyles.mono.copyWith(
                              fontSize: 11,
                              letterSpacing: 3.5,
                              color: color)),
                      const SizedBox(height: 6),
                      Text(titulo,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.display.copyWith(
                              fontSize: 30,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.75,
                              color: AppColors.text)),
                      if (r?.motivo != null) ...[
                        const SizedBox(height: 6),
                        Text(r!.motivo!,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body.copyWith(
                                fontSize: 13, color: AppColors.textDim)),
                      ],
                      const SizedBox(height: 28),
                      if (r?.ticket != null) _InfoCard(ticket: r!.ticket!),
                      const SizedBox(height: 24),
                      CSButton(
                        label: 'Escanear siguiente',
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.qr_code_scanner, size: 16),
                        fullWidth: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BigStatus extends StatelessWidget {
  final Color color;
  final IconData icon;
  const _BigStatus({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (int i = 0; i < 3; i++)
            Container(
              width: 150.0 + i * 24,
              height: 150.0 + i * 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: color.withValues(alpha: 0.35 - i * 0.10), width: 1),
              ),
            ),
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withValues(alpha: 0.7)],
              ),
              boxShadow: [
                BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 60,
                    offset: const Offset(0, 20)),
              ],
            ),
          ),
          Icon(icon, size: 60, color: const Color(0xFF0A0A0A)),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final TicketInfo ticket;
  const _InfoCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM · HH:mm', 'es');
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: AppColors.border, width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        colors: [AppColors.red, AppColors.redDeep]),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initials(ticket.clienteNombre),
                    style: AppTextStyles.display.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(ticket.clienteNombre,
                          style: AppTextStyles.display.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text)),
                      Text('Compra #${ticket.compraId}',
                          style: AppTextStyles.mono.copyWith(
                              fontSize: 11, color: AppColors.textDim)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: _Val(
                            label: 'PELÍCULA',
                            value: ticket.peliculaTitulo)),
                    Expanded(
                        child: _Val(
                            label: 'HORA',
                            value: df.format(ticket.inicio.toLocal()),
                            mono: true)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                        child: _Val(label: 'SALA', value: ticket.salaNombre)),
                    Expanded(
                        child: _Val(
                            label: 'ASIENTOS',
                            value: ticket.asientosLabel,
                            mono: true,
                            accent: true)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class _Val extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;
  final bool accent;
  const _Val(
      {required this.label,
      required this.value,
      this.mono = false,
      this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: AppTextStyles.mono.copyWith(
                fontSize: 9, letterSpacing: 1.62, color: AppColors.textDim)),
        const SizedBox(height: 4),
        Text(value,
            style: (mono ? AppTextStyles.mono : AppTextStyles.display).copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: accent ? AppColors.gold : AppColors.text)),
      ],
    );
  }
}
