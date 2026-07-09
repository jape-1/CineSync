import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../catalog/domain/models.dart';
import '../../seats/domain/seat.dart';
import '../../snacks/domain/models.dart';
import '../../tickets/domain/models.dart';
import '../data/checkout_repository.dart';

class SelectedSnack {
  final SnackItem item;
  int cantidad;
  SelectedSnack(this.item, this.cantidad);
}

/// Borrador de compra compartido entre asientos → dulcería → confirmación.
class CheckoutState extends Equatable {
  final Funcion? funcion;
  final List<Seat> seats;
  final Map<String, SelectedSnack> snacks; // key: 'p{id}' o 'c{id}'
  final String? promoCode;
  final PromoResult? promo;
  final bool submitting;
  final String? error;

  const CheckoutState({
    this.funcion,
    this.seats = const [],
    this.snacks = const {},
    this.promoCode,
    this.promo,
    this.submitting = false,
    this.error,
  });

  CheckoutState copyWith({
    Funcion? funcion,
    List<Seat>? seats,
    Map<String, SelectedSnack>? snacks,
    String? promoCode,
    PromoResult? promo,
    bool? submitting,
    String? error,
    bool clearError = false,
    bool clearPromo = false,
  }) =>
      CheckoutState(
        funcion: funcion ?? this.funcion,
        seats: seats ?? this.seats,
        snacks: snacks ?? this.snacks,
        promoCode: promoCode ?? this.promoCode,
        promo: clearPromo ? null : (promo ?? this.promo),
        submitting: submitting ?? this.submitting,
        error: clearError ? null : (error ?? this.error),
      );

  double get subtotalAsientos =>
      (funcion?.precioBase ?? 0) * seats.length;

  double get subtotalSnacks => snacks.values
      .fold(0.0, (s, x) => s + x.item.precio * x.cantidad);

  double get subtotal => subtotalAsientos + subtotalSnacks;

  double get descuento {
    final p = promo;
    if (p == null || !p.valido || p.valor == null) return 0;
    if (p.tipoDescuento == 'porcentaje') {
      return subtotal * p.valor! / 100;
    }
    return p.valor! > subtotal ? subtotal : p.valor!;
  }

  double get total => subtotal - descuento;

  int get snacksCount =>
      snacks.values.fold(0, (s, x) => s + x.cantidad);

  @override
  List<Object?> get props =>
      [funcion, seats, snacks, promoCode, promo, submitting, error];
}

class CheckoutCubit extends Cubit<CheckoutState> {
  final CheckoutRepository _repo;
  CheckoutCubit(this._repo) : super(const CheckoutState());

  void startFuncion(Funcion funcion) {
    emit(CheckoutState(funcion: funcion));
  }

  /// Enriquece la función con el detalle (película/sala) sin perder el borrador.
  void setFuncionDetalle(Funcion funcion) {
    emit(state.copyWith(funcion: funcion));
  }

  void setSeats(List<Seat> seats) {
    emit(state.copyWith(seats: seats));
  }

  void setSnackQty(SnackItem item, int cantidad) {
    final key = '${item.esCombo ? 'c' : 'p'}${item.id}';
    final map = Map<String, SelectedSnack>.from(state.snacks);
    if (cantidad <= 0) {
      map.remove(key);
    } else {
      map[key] = SelectedSnack(item, cantidad);
    }
    emit(state.copyWith(snacks: map));
  }

  int snackQty(SnackItem item) {
    final key = '${item.esCombo ? 'c' : 'p'}${item.id}';
    return state.snacks[key]?.cantidad ?? 0;
  }

  Future<void> applyPromo(String codigo) async {
    if (codigo.isEmpty) {
      emit(state.copyWith(clearPromo: true, promoCode: ''));
      return;
    }
    try {
      final result = await _repo.validarPromo(codigo);
      emit(state.copyWith(promo: result, promoCode: codigo, clearError: true));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), clearPromo: true));
    }
  }

  Future<Compra?> submit() async {
    final f = state.funcion;
    if (f == null || state.seats.isEmpty) {
      emit(state.copyWith(error: 'Selecciona al menos un asiento'));
      return null;
    }
    emit(state.copyWith(submitting: true, clearError: true));
    try {
      final snacks = state.snacks.values
          .map((s) => CheckoutSnack(
                productoId: s.item.esCombo ? null : s.item.id,
                comboId: s.item.esCombo ? s.item.id : null,
                cantidad: s.cantidad,
              ))
          .toList();
      final compra = await _repo.crearCompra(
        funcionId: f.id,
        asientoFuncionIds: state.seats.map((s) => s.asientoFuncionId).toList(),
        snacks: snacks,
        promocionCodigo:
            (state.promo?.valido ?? false) ? state.promoCode : null,
      );
      emit(const CheckoutState()); // limpia el borrador
      return compra;
    } catch (e) {
      emit(state.copyWith(submitting: false, error: e.toString()));
      return null;
    }
  }
}
