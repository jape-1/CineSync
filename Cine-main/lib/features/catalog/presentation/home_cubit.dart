import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/catalog_repository.dart';
import '../domain/models.dart';

class HomeState extends Equatable {
  final bool loading;
  final List<Pelicula> peliculas;
  final List<Genero> generos;
  final String? generoSel;
  final String? error;

  const HomeState({
    this.loading = true,
    this.peliculas = const [],
    this.generos = const [],
    this.generoSel,
    this.error,
  });

  HomeState copyWith({
    bool? loading,
    List<Pelicula>? peliculas,
    List<Genero>? generos,
    String? generoSel,
    String? error,
    bool clearGenero = false,
    bool clearError = false,
  }) =>
      HomeState(
        loading: loading ?? this.loading,
        peliculas: peliculas ?? this.peliculas,
        generos: generos ?? this.generos,
        generoSel: clearGenero ? null : (generoSel ?? this.generoSel),
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [loading, peliculas, generos, generoSel, error];
}

class HomeCubit extends Cubit<HomeState> {
  final CatalogRepository _repo;
  HomeCubit(this._repo) : super(const HomeState());

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final generos = await _repo.generos();
      final peliculas = await _repo.peliculas(genero: state.generoSel);
      emit(state.copyWith(
          loading: false, generos: generos, peliculas: peliculas));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> selectGenero(String? nombre) async {
    emit(state.copyWith(
      generoSel: nombre,
      clearGenero: nombre == null,
      loading: true,
    ));
    try {
      final peliculas = await _repo.peliculas(genero: nombre);
      emit(state.copyWith(loading: false, peliculas: peliculas));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }
}
