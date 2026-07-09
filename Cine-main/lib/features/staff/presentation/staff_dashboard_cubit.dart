import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/storage/token_storage.dart';
import '../../../core/ws/ws_client.dart';
import '../domain/models.dart';

class DashboardState extends Equatable {
  final double ocupacionGlobal;
  final List<OccupancyFuncion> funciones;
  final int validacionesHoy;
  final bool connected;
  final String? error;

  const DashboardState({
    this.ocupacionGlobal = 0,
    this.funciones = const [],
    this.validacionesHoy = 0,
    this.connected = false,
    this.error,
  });

  DashboardState copyWith({
    double? ocupacionGlobal,
    List<OccupancyFuncion>? funciones,
    int? validacionesHoy,
    bool? connected,
    String? error,
  }) =>
      DashboardState(
        ocupacionGlobal: ocupacionGlobal ?? this.ocupacionGlobal,
        funciones: funciones ?? this.funciones,
        validacionesHoy: validacionesHoy ?? this.validacionesHoy,
        connected: connected ?? this.connected,
        error: error,
      );

  @override
  List<Object?> get props =>
      [ocupacionGlobal, funciones, validacionesHoy, connected, error];
}

/// Conecta a `/ws/staff/dashboard` y mantiene ocupación + validaciones en vivo.
class StaffDashboardCubit extends Cubit<DashboardState> {
  final TokenStorage _tokens;
  WsClient? _ws;
  StreamSubscription? _sub;

  StaffDashboardCubit(this._tokens) : super(const DashboardState());

  Future<void> connect() async {
    final token = await _tokens.accessToken;
    if (token == null) {
      emit(state.copyWith(error: 'Sesión no válida'));
      return;
    }
    _ws = WsClient(path: '/ws/staff/dashboard', token: token);
    _ws!.connect();
    _sub = _ws!.stream.listen(_onMessage, onError: (Object e) {
      emit(state.copyWith(error: 'Conexión del panel interrumpida'));
    });
    emit(state.copyWith(connected: true, error: null));
  }

  void _onMessage(Map<String, dynamic> msg) {
    switch (msg['event']) {
      case 'occupancy_update':
        final funciones = ((msg['funciones'] as List?) ?? [])
            .map((e) => OccupancyFuncion.fromJson(e as Map<String, dynamic>))
            .toList();
        emit(state.copyWith(
          ocupacionGlobal: (msg['ocupacion_global'] as num).toDouble(),
          funciones: funciones,
        ));
        break;
      case 'validation_count_update':
        emit(state.copyWith(validacionesHoy: msg['validaciones_hoy'] as int));
        break;
    }
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    await _ws?.close();
    return super.close();
  }
}
