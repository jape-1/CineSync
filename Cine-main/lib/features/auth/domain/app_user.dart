import 'package:equatable/equatable.dart';

enum UserRole {
  cliente,
  trabajador,
  administrador;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => UserRole.cliente,
    );
  }
}

class AppUser extends Equatable {
  final int id;
  final String nombre;
  final String email;
  final UserRole rol;
  final String? turno;
  final bool activo;

  const AppUser({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.turno,
    required this.activo,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      email: json['email'] as String,
      rol: UserRole.fromString(json['rol'] as String),
      turno: json['turno'] as String?,
      activo: json['activo'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [id, nombre, email, rol, turno, activo];
}
