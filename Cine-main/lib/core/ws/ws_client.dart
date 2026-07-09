import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../config.dart';

/// Envoltorio delgado sobre [WebSocketChannel] para un canal de CineSync.
///
/// El JWT viaja como query param `token` (el backend lo valida en el handshake).
/// Expone un stream de mensajes JSON ya decodificados y un método para enviar.
class WsClient {
  final String path; // p. ej. "/ws/funciones/5"
  final String token;

  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _controller;

  WsClient({required this.path, required this.token});

  Stream<Map<String, dynamic>> get stream => _controller!.stream;

  void connect() {
    final uri = Uri.parse('${AppConfig.wsBaseUrl}$path?token=$token');
    _controller = StreamController<Map<String, dynamic>>.broadcast();
    _channel = WebSocketChannel.connect(uri);
    _channel!.stream.listen(
      (data) {
        try {
          final decoded = jsonDecode(data as String);
          if (decoded is Map<String, dynamic>) {
            _controller?.add(decoded);
          }
        } catch (_) {
          // mensaje no-JSON: se ignora
        }
      },
      onError: (Object e) => _controller?.addError(e),
      onDone: () => _controller?.close(),
      cancelOnError: false,
    );
  }

  void send(Map<String, dynamic> message) {
    _channel?.sink.add(jsonEncode(message));
  }

  Future<void> close() async {
    await _channel?.sink.close();
    await _controller?.close();
  }
}
