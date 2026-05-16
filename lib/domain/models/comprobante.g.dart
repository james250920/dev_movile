// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comprobante.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Comprobante _$ComprobanteFromJson(Map<String, dynamic> json) => Comprobante(
  id: json['id'] as String,
  rendicionId: json['rendicionId'] as String,
  tipo: $enumDecode(_$TipoComprobanteEnumMap, json['tipo']),
  numero: json['numero'] as String,
  fecha: DateTime.parse(json['fecha'] as String),
  proveedor: json['proveedor'] as String,
  descripcion: json['descripcion'] as String,
  monto: (json['monto'] as num).toDouble(),
  metodoPago: $enumDecode(_$TipoPagoEnumMap, json['metodoPago']),
  imagenPath: json['imagenPath'] as String?,
  datosOCR: json['datosOCR'] as Map<String, dynamic>?,
  numeroTicket: json['numeroTicket'] as String?,
  fechaCreacion: DateTime.parse(json['fechaCreacion'] as String),
);

Map<String, dynamic> _$ComprobanteToJson(Comprobante instance) =>
    <String, dynamic>{
      'id': instance.id,
      'rendicionId': instance.rendicionId,
      'tipo': _$TipoComprobanteEnumMap[instance.tipo]!,
      'numero': instance.numero,
      'fecha': instance.fecha.toIso8601String(),
      'proveedor': instance.proveedor,
      'descripcion': instance.descripcion,
      'monto': instance.monto,
      'metodoPago': _$TipoPagoEnumMap[instance.metodoPago]!,
      'imagenPath': instance.imagenPath,
      'datosOCR': instance.datosOCR,
      'numeroTicket': instance.numeroTicket,
      'fechaCreacion': instance.fechaCreacion.toIso8601String(),
    };

const _$TipoComprobanteEnumMap = {
  TipoComprobante.factura: 'factura',
  TipoComprobante.recibo: 'recibo',
  TipoComprobante.boleta: 'boleta',
  TipoComprobante.manual: 'manual',
};

const _$TipoPagoEnumMap = {
  TipoPago.efectivo: 'efectivo',
  TipoPago.transferencia: 'transferencia',
  TipoPago.tarjeta_credito: 'tarjeta_credito',
  TipoPago.cheque: 'cheque',
};
