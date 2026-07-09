import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/snacks_repository.dart';
import '../domain/models.dart';

class SnacksState extends Equatable {
  final bool loading;
  final List<SnackItem> items;
  final String? error;

  const SnacksState({this.loading = true, this.items = const [], this.error});

  SnacksState copyWith({bool? loading, List<SnackItem>? items, String? error}) =>
      SnacksState(
        loading: loading ?? this.loading,
        items: items ?? this.items,
        error: error,
      );

  @override
  List<Object?> get props => [loading, items, error];
}

class SnacksCubit extends Cubit<SnacksState> {
  final SnacksRepository _repo;
  SnacksCubit(this._repo) : super(const SnacksState());

  Future<void> load() async {
    emit(const SnacksState(loading: true));
    try {
      final combos = await _repo.combos();
      final productos = await _repo.productos();
      final items = <SnackItem>[
        ...combos.where((c) => c.activo).map(SnackItem.fromCombo),
        ...productos.where((p) => p.activo).map(SnackItem.fromProducto),
      ];
      emit(SnacksState(loading: false, items: items));
    } catch (e) {
      emit(SnacksState(loading: false, error: e.toString()));
    }
  }
}
