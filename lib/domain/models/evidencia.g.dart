// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'evidencia.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Evidencia _$EvidenciaFromJson(Map<String, dynamic> json) => Evidencia(
  id: json['id'] as String,
  rendicionId: json['rendicionId'] as String,
  rutaArchivo: json['rutaArchivo'] as String,
  tipoArchivo: json['tipoArchivo'] as String,
  descripcion: json['descripcion'] as String,
  fechaCarga: DateTime.parse(json['fechaCarga'] as String),
);

Map<String, dynamic> _$EvidenciaToJson(Evidencia instance) => <String, dynamic>{
  'id': instance.id,
  'rendicionId': instance.rendicionId,
  'rutaArchivo': instance.rutaArchivo,
  'tipoArchivo': instance.tipoArchivo,
  'descripcion': instance.descripcion,
  'fechaCarga': instance.fechaCarga.toIso8601String(),
};
