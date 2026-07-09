import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/catalog_repository.dart';
import '../domain/models.dart';

class MovieDetailState extends Equatable {
  final bool loading;
  final Pelicula? pelicula;
  final List<Funcion> funciones;
  final String? error;

  const MovieDetailState({
    this.loading = true,
    this.pelicula,
    this.funciones = const [],
    this.error,
  });

  MovieDetailState copyWith({
    bool? loading,
    Pelicula? pelicula,
    List<Funcion>? funciones,
    String? error,
  }) =>
      MovieDetailState(
        loading: loading ?? this.loading,
        pelicula: pelicula ?? this.pelicula,
        funciones: funciones ?? this.funciones,
        error: error,
      );

  @override
  List<Object?> get props => [loading, pelicula, funciones, error];
}

class MovieDetailCubit extends Cubit<MovieDetailState> {
  final CatalogRepository _repo;
  MovieDetailCubit(this._repo) : super(const MovieDetailState());

  Future<void> load(int peliculaId) async {
    emit(const MovieDetailState(loading: true));
    try {
      final pelicula = await _repo.pelicula(peliculaId);
      final funciones = await _repo.funciones(peliculaId: peliculaId);
      emit(MovieDetailState(
          loading: false, pelicula: pelicula, funciones: funciones));
    } catch (e) {
      emit(MovieDetailState(loading: false, error: e.toString()));
    }
  }
}
