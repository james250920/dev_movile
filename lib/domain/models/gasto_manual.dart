import 'package:json_annotation/json_annotation.dart';

part 'gasto_manual.g.dart';

@JsonSerializable()
class GastoManual {
  final String id;
  final String rendicionId;
  final DateTime fecha;
  final String concepto;
  final String descripcion;
  final double monto;
  final String metodoPago;
  final String? beneficiario;
  final DateTime fechaCreacion;

  GastoManual({
    required this.id,
    required this.rendicionId,
    required this.fecha,
    required this.concepto,
    required this.descripcion,
    required this.monto,
    required this.metodoPago,
    this.beneficiario,
    required this.fechaCreacion,
  });

  factory GastoManual.fromJson(Map<String, dynamic> json) =>
      _$GastoManualFromJson(json);

  Map<String, dynamic> toJson() => _$GastoManualToJson(this);

  GastoManual copyWith({
    String? id,
    String? rendicionId,
    DateTime? fecha,
    String? concepto,
    String? descripcion,
    double? monto,
    String? metodoPago,
    String? beneficiario,
    DateTime? fechaCreacion,
  }) {
    return GastoManual(
      id: id ?? this.id,
      rendicionId: rendicionId ?? this.rendicionId,
      fecha: fecha ?? this.fecha,
      concepto: concepto ?? this.concepto,
      descripcion: descripcion ?? this.descripcion,
      monto: monto ?? this.monto,
      metodoPago: metodoPago ?? this.metodoPago,
      beneficiario: beneficiario ?? this.beneficiario,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}
