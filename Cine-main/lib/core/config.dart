/// Configuración de red del cliente.
///
/// Se define en tiempo de compilación con --dart-define:
///   Local (emulador Android):   (defaults) → http://10.0.2.2:8000
///   Local (USB / web):          --dart-define=API_HOST=localhost:8000
///   Producción (Railway):       --dart-define=API_HOST=tu-app.up.railway.app
///                               --dart-define=API_SECURE=true
///
/// `API_SECURE=true` cambia el esquema a https:// y wss:// (necesario en Railway,
/// que sirve por HTTPS). En local se deja en false (http/ws).
class AppConfig {
  static const String host = String.fromEnvironment(
    'API_HOST',
    defaultValue: '10.0.2.2:8000',
  );

  static const bool secure = bool.fromEnvironment(
    'API_SECURE',
    defaultValue: false,
  );

  static String get _http => secure ? 'https' : 'http';
  static String get _ws => secure ? 'wss' : 'ws';

  static String get apiBaseUrl => '$_http://$host/api/v1';
  static String get wsBaseUrl => '$_ws://$host';
}
