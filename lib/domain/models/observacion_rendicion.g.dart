// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'observacion_rendicion.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ObservacionRendicion _$ObservacionRendicionFromJson(
  Map<String, dynamic> json,
) => ObservacionRendicion(
  id: json['id'] as String,
  rendicionId: json['rendicionId'] as String,
  autor: json['autor'] as String,
  tipo: json['tipo'] as String,
  texto: json['texto'] as String,
  fecha: DateTime.parse(json['fecha'] as String),
  requiereCorreccion: json['requiereCorreccion'] as bool,
);

Map<String, dynamic> _$ObservacionRendicionToJson(
  ObservacionRendicion instance,
) => <String, dynamic>{
  'id': instance.id,
  'rendicionId': instance.rendicionId,
  'autor': instance.autor,
  'tipo': instance.tipo,
  'texto': instance.texto,
  'fecha': instance.fecha.toIso8601String(),
  'requiereCorreccion': instance.requiereCorreccion,
};
