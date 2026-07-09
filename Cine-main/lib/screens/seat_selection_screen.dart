import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/top_bar.dart';
import '../widgets/icon_btn.dart';
import '../widgets/cs_button.dart';
import '../core/storage/token_storage.dart';
import '../features/auth/presentation/auth_cubit.dart';
import '../features/catalog/data/catalog_repository.dart';
import '../features/catalog/domain/models.dart';
import '../features/checkout/presentation/checkout_cubit.dart';
import '../features/seats/domain/seat.dart';
import '../features/seats/presentation/seats_cubit.dart';

/// Selección de asientos con bloqueo temporal en vivo (WebSocket).
class SeatSelectionScreen extends StatelessWidget {
  final int funcionId;
  const SeatSelectionScreen({super.key, required this.funcionId});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthCubit>().state.user!.id;
    return BlocProvider(
      create: (c) => SeatsCubit(
        funcionId: funcionId,
        userId: userId,
        tokens: c.read<TokenStorage>(),
      )..connect(),
      child: _SeatsView(funcionId: funcionId),
    );
  }
}

class _SeatsView extends StatefulWidget {
  final int funcionId;
  const _SeatsView({required this.funcionId});

  @override
  State<_SeatsView> createState() => _SeatsViewState();
}

class _SeatsViewState extends State<_SeatsView> {
  Funcion? _detalle;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _loadDetalle();
    // Repinta cada segundo para el contador del bloqueo temporal.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadDetalle() async {
    try {
      final f = await context.read<CatalogRepository>().funcion(widget.funcionId);
      if (mounted) {
        setState(() => _detalle = f);
        context.read<CheckoutCubit>().setFuncionDetalle(f);
      }
    } catch (_) {/* el header queda con datos mínimos */}
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _fmtCountdown(DateTime? expiry) {
    if (expiry == null) return '05:00';
    final secs = expiry.difference(DateTime.now()).inSeconds.clamp(0, 3599);
    final mm = (secs ~/ 60).toString().padLeft(2, '0');
    final ss = (secs % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  double _countdownFraction(DateTime? expiry) {
    if (expiry == null) return 1;
    final secs = expiry.difference(DateTime.now()).inSeconds.clamp(0, 300);
    return secs / 300;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<SeatsCubit>();
    final state = cubit.state;
    final expiry = cubit.myLockExpiry;
    final mySeats = cubit.mySeats;
    final precio = _detalle?.precioBase ?? 0;
    final total = precio * mySeats.length;

    final tituloPelicula = _detalle?.pelicula?.titulo ?? 'Función';
    final salaLinea = _detalle == null
        ? ''
        : '${_detalle!.sala?.nombre ?? 'Sala'} · '
            '${DateFormat('d MMM · HH:mm', 'es').format(_detalle!.inicio.toLocal())}';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.85),
            radius: 0.9,
            colors: [Color(0xFF2A1E15), AppColors.bg],
            stops: [0.0, 0.5],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              TopBar(
                left: Row(
                  children: [
                    IconBtn(
                      onTap: () => context.pop(),
                      child: const Icon(Icons.arrow_back, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(tituloPelicula,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.display.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.text)),
                          Text(salaLinea.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.mono.copyWith(
                                  fontSize: 11,
                                  letterSpacing: 0.55,
                                  color: AppColors.textDim)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // "Personas viendo": debajo del header para no chocar con el título.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 2),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _ViewersPill(count: state.viewers),
                ),
              ),
              // Barra de bloqueo temporal
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Row(
                  children: [
                    Text('BLOQUEO TEMPORAL',
                        style: AppTextStyles.mono.copyWith(
                            fontSize: 10,
                            letterSpacing: 1.8,
                            color: AppColors.amber)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: Container(
                          height: 3,
                          color: AppColors.surface,
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _countdownFraction(expiry),
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  AppColors.amber,
                                  AppColors.red
                                ]),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(_fmtCountdown(expiry),
                        style: AppTextStyles.mono.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.amber)),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: _CinemaScreen(),
              ),
              Expanded(
                child: state.seats.isEmpty
                    ? Center(
                        child: state.error != null
                            ? Text(state.error!,
                                style:
                                    const TextStyle(color: AppColors.textDim))
                            : const CircularProgressIndicator(
                                color: AppColors.red),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: _SeatMap(
                          seats: state.seats,
                          userId: cubit.userId,
                          onTap: (seat) => _onTapSeat(cubit, seat),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: const _Legend(),
              ),
              _SummaryTray(
                seatLabels: mySeats.map((s) => s.label).toList(),
                total: total,
                onContinue: mySeats.isEmpty
                    ? null
                    : () {
                        context.read<CheckoutCubit>().setSeats(mySeats);
                        context.push('/snacks');
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTapSeat(SeatsCubit cubit, Seat seat) {
    final mine =
        seat.estado == 'reservado_temporal' && seat.reservadoPor == cubit.userId;
    if (mine) {
      cubit.releaseSeat(seat.asientoFuncionId);
    } else if (seat.estado == 'libre') {
      cubit.selectSeat(seat.asientoFuncionId);
    }
    // ocupado o reservado por otro → no hace nada
  }
}

class _ViewersPill extends StatelessWidget {
  final int count;
  const _ViewersPill({required this.count});

  @override
  Widget build(BuildContext context) {
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
          const Icon(Icons.visibility, size: 12, color: AppColors.green),
          const SizedBox(width: 6),
          Text('$count viendo',
              style: AppTextStyles.mono.copyWith(
                  fontSize: 10, letterSpacing: 0.4, color: AppColors.textDim)),
        ],
      ),
    );
  }
}

class _SeatMap extends StatelessWidget {
  final List<Seat> seats;
  final int userId;
  final void Function(Seat) onTap;
  const _SeatMap(
      {required this.seats, required this.userId, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Agrupa por fila y ordena.
    final byRow = <String, List<Seat>>{};
    for (final s in seats) {
      byRow.putIfAbsent(s.fila, () => []).add(s);
    }
    final rows = byRow.keys.toList()..sort();
    for (final r in rows) {
      byRow[r]!.sort((a, b) => a.numero.compareTo(b.numero));
    }

    return Column(
      children: rows.map((r) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RowLabel(letter: r),
              ...byRow[r]!.map((s) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.5),
                    child: _SeatTile(seat: s, userId: userId, onTap: onTap),
                  )),
              _RowLabel(letter: r),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _RowLabel extends StatelessWidget {
  final String letter;
  const _RowLabel({required this.letter});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      child: Text(letter,
          textAlign: TextAlign.center,
          style: AppTextStyles.mono.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.textFaint)),
    );
  }
}

class _SeatTile extends StatelessWidget {
  final Seat seat;
  final int userId;
  final void Function(Seat) onTap;
  const _SeatTile(
      {required this.seat, required this.userId, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const sz = 19.0;
    final mine = seat.estado == 'reservado_temporal' && seat.reservadoPor == userId;

    Color bg;
    Color border = Colors.transparent;
    List<BoxShadow>? shadow;

    if (mine) {
      bg = AppColors.text;
      border = AppColors.text;
      shadow = [BoxShadow(color: Colors.white.withValues(alpha: 0.4), blurRadius: 12)];
    } else if (seat.estado == 'ocupado') {
      bg = AppColors.red.withValues(alpha: 0.85);
    } else if (seat.estado == 'reservado_temporal') {
      bg = AppColors.amber; // reservado por otro
    } else if (seat.esVip) {
      bg = AppColors.gold.withValues(alpha: 0.18);
      border = AppColors.gold;
    } else {
      bg = AppColors.green.withValues(alpha: 0.18);
      border = AppColors.green.withValues(alpha: 0.65);
    }

    final tappable = seat.estado == 'libre' || mine;

    return GestureDetector(
      onTap: tappable ? () => onTap(seat) : null,
      child: Container(
        width: sz,
        height: sz,
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border, width: 1.2),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(4),
          ),
          boxShadow: shadow,
        ),
        alignment: Alignment.center,
        child: seat.esVip && !mine && seat.estado == 'libre'
            ? const Text('★', style: TextStyle(fontSize: 8, color: AppColors.gold))
            : null,
      ),
    );
  }
}

class _CinemaScreen extends StatelessWidget {
  const _CinemaScreen();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Center(
        child: Text('P A N T A L L A',
            style: AppTextStyles.mono.copyWith(
                fontSize: 9, letterSpacing: 3.6, color: AppColors.textFaint)),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Expanded(child: _LegendItem(color: AppColors.green, label: 'Libre')),
          Expanded(
              child: _LegendItem(
                  color: AppColors.amber, label: 'Reservado', solid: true)),
          Expanded(
              child: _LegendItem(
                  color: AppColors.red, label: 'Ocupado', solid: true)),
          Expanded(
              child: _LegendItem(color: AppColors.text, label: 'Tuyo', solid: true)),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool solid;
  const _LegendItem(
      {required this.color, required this.label, this.solid = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: solid ? color : color.withValues(alpha: 0.18),
            border: solid ? null : Border.all(color: color, width: 1.2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(label,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body
                  .copyWith(fontSize: 11, color: AppColors.textDim)),
        ),
      ],
    );
  }
}

class _SummaryTray extends StatelessWidget {
  final List<String> seatLabels;
  final double total;
  final VoidCallback? onContinue;

  const _SummaryTray(
      {required this.seatLabels, required this.total, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: AppColors.bgDeep,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '${seatLabels.length} '
                        '${seatLabels.length == 1 ? 'ASIENTO' : 'ASIENTOS'}',
                        style: AppTextStyles.mono.copyWith(
                            fontSize: 10,
                            letterSpacing: 1.2,
                            color: AppColors.textDim)),
                    const SizedBox(height: 4),
                    if (seatLabels.isEmpty)
                      Text('Selecciona en el mapa',
                          style: AppTextStyles.mono.copyWith(
                              fontSize: 12, color: AppColors.textFaint))
                    else
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: seatLabels
                            .map((id) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(id,
                                      style: AppTextStyles.mono.copyWith(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.text)),
                                ))
                            .toList(),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('TOTAL',
                      style: AppTextStyles.mono.copyWith(
                          fontSize: 10,
                          letterSpacing: 1.2,
                          color: AppColors.textDim)),
                  Text('S/${total.toStringAsFixed(2)}',
                      style: AppTextStyles.display.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          CSButton(
            label: 'Continuar a dulcería',
            onPressed: onContinue,
            icon: const Icon(Icons.arrow_forward),
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}
