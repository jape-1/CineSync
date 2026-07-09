import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/tickets_repository.dart';
import '../domain/models.dart';

class TicketsState extends Equatable {
  final bool loading;
  final List<Compra> activos;
  final List<Compra> usados;
  final List<Compra> cancelados;
  final String? error;

  const TicketsState({
    this.loading = true,
    this.activos = const [],
    this.usados = const [],
    this.cancelados = const [],
    this.error,
  });

  TicketsState copyWith({
    bool? loading,
    List<Compra>? activos,
    List<Compra>? usados,
    List<Compra>? cancelados,
    String? error,
  }) =>
      TicketsState(
        loading: loading ?? this.loading,
        activos: activos ?? this.activos,
        usados: usados ?? this.usados,
        cancelados: cancelados ?? this.cancelados,
        error: error,
      );

  @override
  List<Object?> get props => [loading, activos, usados, cancelados, error];
}

class TicketsCubit extends Cubit<TicketsState> {
  final TicketsRepository _repo;
  TicketsCubit(this._repo) : super(const TicketsState());

  Future<void> load() async {
    emit(const TicketsState(loading: true));
    try {
      final todas = await _repo.historial();
      emit(TicketsState(
        loading: false,
        activos: todas.where((c) => c.qrEstado == 'activo').toList(),
        usados: todas.where((c) => c.qrEstado == 'usado').toList(),
        cancelados: todas.where((c) => c.qrEstado == 'cancelado').toList(),
      ));
    } catch (e) {
      emit(TicketsState(loading: false, error: e.toString()));
    }
  }
}
