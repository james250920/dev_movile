// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rendicion.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Rendicion _$RendicionFromJson(Map<String, dynamic> json) => Rendicion(
  id: json['id'] as String,
  userId: json['userId'] as String,
  fechaCreacion: DateTime.parse(json['fechaCreacion'] as String),
  fechaEnvio: json['fechaEnvio'] == null
      ? null
      : DateTime.parse(json['fechaEnvio'] as String),
  fechaAprobacion: json['fechaAprobacion'] == null
      ? null
      : DateTime.parse(json['fechaAprobacion'] as String),
  titulo: json['titulo'] as String,
  descripcion: json['descripcion'] as String,
  estado: $enumDecode(_$RendicionStatusEnumMap, json['estado']),
  totalGastos: (json['totalGastos'] as num).toDouble(),
  proyectoId: json['proyectoId'] as String?,
  centroCosto: json['centroCosto'] as String?,
  observaciones: json['observaciones'] as String? ?? '',
  esViatico: json['esViatico'] as bool? ?? false,
);

Map<String, dynamic> _$RendicionToJson(Rendicion instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'fechaCreacion': instance.fechaCreacion.toIso8601String(),
  'fechaEnvio': instance.fechaEnvio?.toIso8601String(),
  'fechaAprobacion': instance.fechaAprobacion?.toIso8601String(),
  'titulo': instance.titulo,
  'descripcion': instance.descripcion,
  'estado': _$RendicionStatusEnumMap[instance.estado]!,
  'totalGastos': instance.totalGastos,
  'proyectoId': instance.proyectoId,
  'centroCosto': instance.centroCosto,
  'observaciones': instance.observaciones,
  'esViatico': instance.esViatico,
};

const _$RendicionStatusEnumMap = {
  RendicionStatus.borrador: 'borrador',
  RendicionStatus.enviada: 'enviada',
  RendicionStatus.observada: 'observada',
  RendicionStatus.aprobada: 'aprobada',
  RendicionStatus.rechazada: 'rechazada',
  RendicionStatus.pagada: 'pagada',
};
