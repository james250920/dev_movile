import 'package:json_annotation/json_annotation.dart';

part 'observacion_rendicion.g.dart';

@JsonSerializable()
class ObservacionRendicion {
  final String id;
  final String rendicionId;
  final String autor;
  final String tipo; // 'observacion', 'comentario', 'rechazo'
  final String texto;
  final DateTime fecha;
  final bool requiereCorreccion;

  ObservacionRendicion({
    required this.id,
    required this.rendicionId,
    required this.autor,
    required this.tipo,
    required this.texto,
    required this.fecha,
    required this.requiereCorreccion,
  });

  factory ObservacionRendicion.fromJson(Map<String, dynamic> json) =>
      _$ObservacionRendicionFromJson(json);

  Map<String, dynamic> toJson() => _$ObservacionRendicionToJson(this);

  ObservacionRendicion copyWith({
    String? id,
    String? rendicionId,
    String? autor,
    String? tipo,
    String? texto,
    DateTime? fecha,
    bool? requiereCorreccion,
  }) {
    return ObservacionRendicion(
      id: id ?? this.id,
      rendicionId: rendicionId ?? this.rendicionId,
      autor: autor ?? this.autor,
      tipo: tipo ?? this.tipo,
      texto: texto ?? this.texto,
      fecha: fecha ?? this.fecha,
      requiereCorreccion: requiereCorreccion ?? this.requiereCorreccion,
    );
  }
}
