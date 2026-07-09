import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/storage/token_storage.dart';
import '../../../core/ws/ws_client.dart';
import '../domain/seat.dart';

class SeatsState extends Equatable {
  final List<Seat> seats;
  final int viewers;
  final bool connected;
  final String? error;

  const SeatsState({
    this.seats = const [],
    this.viewers = 0,
    this.connected = false,
    this.error,
  });

  SeatsState copyWith({
    List<Seat>? seats,
    int? viewers,
    bool? connected,
    String? error,
    bool clearError = false,
  }) =>
      SeatsState(
        seats: seats ?? this.seats,
        viewers: viewers ?? this.viewers,
        connected: connected ?? this.connected,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [seats, viewers, connected, error];
}

/// Maneja la conexión WebSocket a `/ws/funciones/{id}` y el estado del mapa.
class SeatsCubit extends Cubit<SeatsState> {
  final int funcionId;
  final int userId;
  final TokenStorage _tokens;

  WsClient? _ws;
  StreamSubscription? _sub;

  SeatsCubit({
    required this.funcionId,
    required this.userId,
    required TokenStorage tokens,
  })  : _tokens = tokens,
        super(const SeatsState());

  Future<void> connect() async {
    final token = await _tokens.accessToken;
    if (token == null) {
      emit(state.copyWith(error: 'Sesión no válida'));
      return;
    }
    _ws = WsClient(path: '/ws/funciones/$funcionId', token: token);
    _ws!.connect();
    _sub = _ws!.stream.listen(_onMessage, onError: (Object e) {
      emit(state.copyWith(error: 'Conexión en vivo interrumpida'));
    });
    emit(state.copyWith(connected: true, clearError: true));
  }

  void _onMessage(Map<String, dynamic> msg) {
    switch (msg['event']) {
      case 'seat_map_update':
        final list = (msg['seats'] as List)
            .map((e) => Seat.fromJson(e as Map<String, dynamic>))
            .toList();
        emit(state.copyWith(seats: list));
        break;
      case 'viewers_count':
        emit(state.copyWith(viewers: msg['count'] as int));
        break;
    }
  }

  void selectSeat(int asientoFuncionId) {
    _ws?.send({'action': 'select_seat', 'asiento_funcion_id': asientoFuncionId});
  }

  void releaseSeat(int asientoFuncionId) {
    _ws?.send({'action': 'release_seat', 'asiento_funcion_id': asientoFuncionId});
  }

  /// Asientos que este usuario tiene bloqueados temporalmente.
  List<Seat> get mySeats => state.seats
      .where((s) =>
          s.estado == 'reservado_temporal' && s.reservadoPor == userId)
      .toList();

  /// Momento de expiración más próximo entre mis bloqueos (para el contador).
  DateTime? get myLockExpiry {
    final mine = mySeats.where((s) => s.reservadoHasta != null).toList();
    if (mine.isEmpty) return null;
    mine.sort((a, b) => a.reservadoHasta!.compareTo(b.reservadoHasta!));
    return mine.first.reservadoHasta;
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    await _ws?.close();
    return super.close();
  }
}
