import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/top_bar.dart';
import '../widgets/icon_btn.dart';
import '../widgets/cs_logo.dart';
import '../core/storage/token_storage.dart';
import '../core/ws/ws_client.dart';
import '../features/auth/presentation/auth_cubit.dart';
import '../features/tickets/data/tickets_repository.dart';
import '../features/tickets/domain/models.dart';

/// Ticket con QR real. Escucha el canal del usuario para reflejar en vivo el
/// cambio de estado cuando el trabajador valida la entrada.
class TicketScreen extends StatefulWidget {
  final int compraId;
  const TicketScreen({super.key, required this.compraId});

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  Compra? _compra;
  String? _error;
  WsClient? _ws;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final compra = await context.read<TicketsRepository>().compra(widget.compraId);
      if (!mounted) return;
      setState(() => _compra = compra);
      _listenStatus();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _listenStatus() async {
    final user = context.read<AuthCubit>().state.user;
    final token = await context.read<TokenStorage>().accessToken;
    if (user == null || token == null) return;
    _ws = WsClient(path: '/ws/usuarios/${user.id}', token: token);
    _ws!.connect();
    _sub = _ws!.stream.listen((msg) {
      if (msg['event'] == 'ticket_status_changed' &&
          msg['compra_id'] == widget.compraId) {
        _load(); // recarga el estado (→ usado)
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ws?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.85),
            radius: 1.0,
            colors: [Color(0xFF332016), AppColors.bg, AppColors.bgDeep],
            stops: [0.0, 0.5, 1.0],
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
                      onTap: () => context.go('/home'),
                      child: const Icon(Icons.home_outlined, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text('Tu ticket',
                        style: AppTextStyles.display.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text)),
                  ],
                ),
                right: IconBtn(
                  onTap: () => context.go('/my-tickets'),
                  child: const Icon(Icons.confirmation_number_outlined, size: 18),
                ),
              ),
              Expanded(
                child: _error != null
                    ? Center(
                        child: Text(_error!,
                            style: const TextStyle(color: AppColors.textDim)))
                    : _compra == null
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.red))
                        : SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                            child: _TicketCard(compra: _compra!),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Compra compra;
  const _TicketCard({required this.compra});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM yyyy', 'es');
    final tf = DateFormat('HH:mm', 'es');
    final usado = compra.qrEstado == 'usado';
    final cancelado = compra.qrEstado == 'cancelado';
    final estadoColor = usado
        ? AppColors.amber
        : cancelado
            ? AppColors.red
            : AppColors.green;
    final estadoLabel = usado
        ? 'USADO'
        : cancelado
            ? 'CANCELADO'
            : 'ACTIVO';

    return Column(
      children: [
        // Banner de estado
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: estadoColor.withValues(alpha: 0.12),
            border: Border.all(color: estadoColor.withValues(alpha: 0.3), width: 1),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text('E-TICKET · $estadoLabel',
              style: AppTextStyles.mono.copyWith(
                  fontSize: 11, letterSpacing: 1.5, color: estadoColor)),
        ),
        const SizedBox(height: 18),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderStrong, width: 1),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: [
              // Header rojo
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.red, AppColors.redDeep],
                  ),
                ),
                child: Row(
                  children: [
                    const CSLogo(size: 19, color: Colors.white, accent: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(compra.funcion.peliculaTitulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.display.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                  ],
                ),
              ),
              // Info grid
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: _Info(
                                label: 'FECHA',
                                value:
                                    df.format(compra.funcion.inicio.toLocal()))),
                        Expanded(
                            child: _Info(
                                label: 'HORA',
                                value:
                                    tf.format(compra.funcion.inicio.toLocal()))),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                            child: _Info(
                                label: 'SALA',
                                value: compra.funcion.salaNombre)),
                        Expanded(
                            child: _Info(
                                label: 'ASIENTOS',
                                value: compra.asientosLabel)),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.borderStrong),
              // QR real
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: QrImageView(
                        data: compra.qrCodigo,
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                        // Si está usado/cancelado, se atenúa.
                        eyeStyle: QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: usado || cancelado
                              ? Colors.grey
                              : const Color(0xFF0A0A0A),
                        ),
                        dataModuleStyle: QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: usado || cancelado
                              ? Colors.grey
                              : const Color(0xFF0A0A0A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('COMPRA #${compra.id}',
                        style: AppTextStyles.mono.copyWith(
                            fontSize: 11,
                            letterSpacing: 1.5,
                            color: AppColors.textDim)),
                  ],
                ),
              ),
              // Footer total
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  color: AppColors.bgDeep,
                  border:
                      Border(top: BorderSide(color: AppColors.border, width: 1)),
                ),
                child: Row(
                  children: [
                    Text('TOTAL',
                        style: AppTextStyles.mono.copyWith(
                            fontSize: 11,
                            letterSpacing: 1.1,
                            color: AppColors.textDim)),
                    const Spacer(),
                    Text('S/${compra.total.toStringAsFixed(2)}',
                        style: AppTextStyles.display.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: AppColors.border, width: 1),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: AppColors.green),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text('SINCRONIZADO · TIEMPO REAL',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.mono.copyWith(
                        fontSize: 10,
                        letterSpacing: 0.4,
                        color: AppColors.textDim)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Info extends StatelessWidget {
  final String label;
  final String value;
  const _Info({required this.label, required this.value});

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
            style: AppTextStyles.display.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.text)),
      ],
    );
  }
}
