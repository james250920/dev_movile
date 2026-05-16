// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resumen_rendicion.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResumenRendicion _$ResumenRendicionFromJson(Map<String, dynamic> json) =>
    ResumenRendicion(
      rendicionId: json['rendicionId'] as String,
      totalComprobantes: (json['totalComprobantes'] as num).toInt(),
      totalGastosManuales: (json['totalGastosManuales'] as num).toInt(),
      totalEvidencias: (json['totalEvidencias'] as num).toInt(),
      montoComprobantes: (json['montoComprobantes'] as num).toDouble(),
      montoGastosManuales: (json['montoGastosManuales'] as num).toDouble(),
      montoTotal: (json['montoTotal'] as num).toDouble(),
      detallesPorConcepto: (json['detallesPorConcepto'] as Map<String, dynamic>)
          .map((k, e) => MapEntry(k, (e as num).toDouble())),
      detallesPorMetodoPago:
          (json['detallesPorMetodoPago'] as Map<String, dynamic>).map(
            (k, e) => MapEntry(k, (e as num).toDouble()),
          ),
    );

Map<String, dynamic> _$ResumenRendicionToJson(ResumenRendicion instance) =>
    <String, dynamic>{
      'rendicionId': instance.rendicionId,
      'totalComprobantes': instance.totalComprobantes,
      'totalGastosManuales': instance.totalGastosManuales,
      'totalEvidencias': instance.totalEvidencias,
      'montoComprobantes': instance.montoComprobantes,
      'montoGastosManuales': instance.montoGastosManuales,
      'montoTotal': instance.montoTotal,
      'detallesPorConcepto': instance.detallesPorConcepto,
      'detallesPorMetodoPago': instance.detallesPorMetodoPago,
    };
