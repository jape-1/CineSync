import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/session.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_repository.dart';
import '../domain/app_user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  final AuthStatus status;
  final AppUser? user;
  final bool submitting;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.submitting = false,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    bool? submitting,
    String? error,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      submitting: submitting ?? this.submitting,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, user, submitting, error];
}

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repo;
  final TokenStorage _tokens;

  AuthCubit(this._repo, this._tokens) : super(const AuthState()) {
    sessionExpired.addListener(_onSessionExpired);
  }

  void _onSessionExpired() {
    emit(state.copyWith(
      status: AuthStatus.unauthenticated,
      clearUser: true,
      error: 'Tu sesión expiró, inicia sesión de nuevo',
    ));
  }

  Future<void> bootstrap() async {
    if (!await _tokens.hasTokens) {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
      return;
    }
    try {
      final user = await _repo.me();
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } catch (_) {
      await _tokens.clear();
      emit(state.copyWith(status: AuthStatus.unauthenticated, clearUser: true));
    }
  }

  Future<bool> login(String email, String password) async {
    emit(state.copyWith(submitting: true, clearError: true));
    try {
      await _repo.login(email, password);
      final user = await _repo.me();
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        submitting: false,
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(submitting: false, error: e.toString()));
      return false;
    }
  }

  Future<bool> register(String nombre, String email, String password) async {
    emit(state.copyWith(submitting: true, clearError: true));
    try {
      await _repo.register(nombre, email, password);
      // Auto-login tras registrarse.
      await _repo.login(email, password);
      final user = await _repo.me();
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        submitting: false,
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(submitting: false, error: e.toString()));
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    emit(state.copyWith(status: AuthStatus.unauthenticated, clearUser: true));
  }

  void clearError() => emit(state.copyWith(clearError: true));

  @override
  Future<void> close() {
    sessionExpired.removeListener(_onSessionExpired);
    return super.close();
  }
}

/// Adaptador para que `go_router` refresque las redirecciones cuando cambia
/// el estado de autenticación.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final dynamic _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
