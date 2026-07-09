import '../../../core/json.dart';

class Genero {
  final int id;
  final String nombre;
  const Genero({required this.id, required this.nombre});

  factory Genero.fromJson(Map<String, dynamic> j) =>
      Genero(id: j['id'] as int, nombre: j['nombre'] as String);
}

class Pelicula {
  final int id;
  final String titulo;
  final String? sinopsis;
  final String? posterUrl;
  final String? backdropUrl;
  final int? duracionMin;
  final String? clasificacion;
  final DateTime? fechaEstreno;
  final double? calificacion;
  final bool activa;
  final List<Genero> generos;

  const Pelicula({
    required this.id,
    required this.titulo,
    this.sinopsis,
    this.posterUrl,
    this.backdropUrl,
    this.duracionMin,
    this.clasificacion,
    this.fechaEstreno,
    this.calificacion,
    this.activa = true,
    this.generos = const [],
  });

  factory Pelicula.fromJson(Map<String, dynamic> j) {
    return Pelicula(
      id: j['id'] as int,
      titulo: j['titulo'] as String,
      sinopsis: j['sinopsis'] as String?,
      posterUrl: j['poster_url'] as String?,
      backdropUrl: j['backdrop_url'] as String?,
      duracionMin: j['duracion_min'] as int?,
      clasificacion: j['clasificacion'] as String?,
      fechaEstreno: asDateOrNull(j['fecha_estreno']),
      calificacion: asDoubleOrNull(j['calificacion']),
      activa: j['activa'] as bool? ?? true,
      generos: ((j['generos'] as List?) ?? [])
          .map((g) => Genero.fromJson(g as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Duración legible "2h 48m".
  String get duracionLegible {
    if (duracionMin == null) return '';
    final h = duracionMin! ~/ 60;
    final m = duracionMin! % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  String get generosLegible => generos.map((g) => g.nombre).join(' · ');
}

class SalaResumen {
  final int id;
  final String nombre;
  final String tipo;
  final int filas;
  final int columnas;

  const SalaResumen({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.filas,
    required this.columnas,
  });

  factory SalaResumen.fromJson(Map<String, dynamic> j) => SalaResumen(
        id: j['id'] as int,
        nombre: j['nombre'] as String,
        tipo: j['tipo'] as String,
        filas: j['filas'] as int? ?? 0,
        columnas: j['columnas'] as int? ?? 0,
      );
}

class Funcion {
  final int id;
  final int peliculaId;
  final int salaId;
  final DateTime inicio;
  final DateTime fin;
  final double precioBase;
  final String? idioma;
  final String? formato;
  final Pelicula? pelicula; // presente en el detalle
  final SalaResumen? sala; // presente en el detalle

  const Funcion({
    required this.id,
    required this.peliculaId,
    required this.salaId,
    required this.inicio,
    required this.fin,
    required this.precioBase,
    this.idioma,
    this.formato,
    this.pelicula,
    this.sala,
  });

  factory Funcion.fromJson(Map<String, dynamic> j) {
    return Funcion(
      id: j['id'] as int,
      peliculaId: j['pelicula_id'] as int,
      salaId: j['sala_id'] as int,
      inicio: DateTime.parse(j['inicio'] as String),
      fin: DateTime.parse(j['fin'] as String),
      precioBase: asDouble(j['precio_base']),
      idioma: j['idioma'] as String?,
      formato: j['formato'] as String?,
      pelicula: j['pelicula'] != null
          ? Pelicula.fromJson(j['pelicula'] as Map<String, dynamic>)
          : null,
      sala: j['sala'] != null
          ? SalaResumen.fromJson(j['sala'] as Map<String, dynamic>)
          : null,
    );
  }
}
