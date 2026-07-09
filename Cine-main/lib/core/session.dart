import 'package:flutter/foundation.dart';

/// Señal global de "sesión expirada".
///
/// El interceptor de Dio la dispara cuando el refresh token ya no sirve; el
/// [AuthCubit] la escucha para cerrar sesión y `go_router` redirige al login.
final ValueNotifier<int> sessionExpired = ValueNotifier<int>(0);

void notifySessionExpired() => sessionExpired.value++;
