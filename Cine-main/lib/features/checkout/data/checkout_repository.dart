import 'package:dio/dio.dart';

import '../../../core/json.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../tickets/domain/models.dart';

/// Resultado de validar un código de promoción.
class PromoResult {
  final bool valido;
  final String? tipoDescuento; // porcentaje | monto
  final double? valor;
  final String? descripcion;
  final String? motivo;

  const PromoResult({
    required this.valido,
    this.tipoDescuento,
    this.valor,
    this.descripcion,
    this.motivo,
  });

  factory PromoResult.fromJson(Map<String, dynamic> j) => PromoResult(
        valido: j['valido'] as bool,
        tipoDescuento: j['tipo_descuento'] as String?,
        valor: asDoubleOrNull(j['valor']),
        descripcion: j['descripcion'] as String?,
        motivo: j['motivo'] as String?,
      );
}

/// Una línea de dulcería en el checkout.
class CheckoutSnack {
  final int? productoId;
  final int? comboId;
  final int cantidad;

  const CheckoutSnack({this.productoId, this.comboId, required this.cantidad});

  Map<String, dynamic> toJson() => {
        if (productoId != null) 'producto_id': productoId,
        if (comboId != null) 'combo_id': comboId,
        'cantidad': cantidad,
      };
}

class CheckoutRepository {
  final ApiClient _api;
  CheckoutRepository(this._api);

  Dio get _dio => _api.dio;

  Future<PromoResult> validarPromo(String codigo) async {
    try {
      final res = await _dio.get('/promociones/validar/$codigo');
      return PromoResult.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Compra> crearCompra({
    required int funcionId,
    required List<int> asientoFuncionIds,
    List<CheckoutSnack> snacks = const [],
    String? promocionCodigo,
  }) async {
    try {
      final res = await _dio.post('/compras', data: {
        'funcion_id': funcionId,
        'asientos': asientoFuncionIds,
        'productos': snacks.map((s) => s.toJson()).toList(),
        if (promocionCodigo != null && promocionCodigo.isNotEmpty)
          'promocion_codigo': promocionCodigo,
      });
      return Compra.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
