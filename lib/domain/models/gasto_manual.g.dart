// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gasto_manual.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GastoManual _$GastoManualFromJson(Map<String, dynamic> json) => GastoManual(
  id: json['id'] as String,
  rendicionId: json['rendicionId'] as String,
  fecha: DateTime.parse(json['fecha'] as String),
  concepto: json['concepto'] as String,
  descripcion: json['descripcion'] as String,
  monto: (json['monto'] as num).toDouble(),
  metodoPago: json['metodoPago'] as String,
  beneficiario: json['beneficiario'] as String?,
  fechaCreacion: DateTime.parse(json['fechaCreacion'] as String),
);

Map<String, dynamic> _$GastoManualToJson(GastoManual instance) =>
    <String, dynamic>{
      'id': instance.id,
      'rendicionId': instance.rendicionId,
      'fecha': instance.fecha.toIso8601String(),
      'concepto': instance.concepto,
      'descripcion': instance.descripcion,
      'monto': instance.monto,
      'metodoPago': instance.metodoPago,
      'beneficiario': instance.beneficiario,
      'fechaCreacion': instance.fechaCreacion.toIso8601String(),
    };
