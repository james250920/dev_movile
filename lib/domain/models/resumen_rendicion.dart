import 'package:json_annotation/json_annotation.dart';

part 'resumen_rendicion.g.dart';

@JsonSerializable()
class ResumenRendicion {
  final String rendicionId;
  final int totalComprobantes;
  final int totalGastosManuales;
  final int totalEvidencias;
  final double montoComprobantes;
  final double montoGastosManuales;
  final double montoTotal;
  final Map<String, double> detallesPorConcepto;
  final Map<String, double> detallesPorMetodoPago;

  ResumenRendicion({
    required this.rendicionId,
    required this.totalComprobantes,
    required this.totalGastosManuales,
    required this.totalEvidencias,
    required this.montoComprobantes,
    required this.montoGastosManuales,
    required this.montoTotal,
    required this.detallesPorConcepto,
    required this.detallesPorMetodoPago,
  });

  factory ResumenRendicion.fromJson(Map<String, dynamic> json) =>
      _$ResumenRendicionFromJson(json);

  Map<String, dynamic> toJson() => _$ResumenRendicionToJson(this);
}
