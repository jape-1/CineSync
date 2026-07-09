/// Helpers de parseo. El backend serializa `Decimal` como string ("25.00"),
/// así que hay que convertir con cuidado a `double`.
double asDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

double? asDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

DateTime? asDateOrNull(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}
