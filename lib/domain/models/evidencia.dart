import 'package:json_annotation/json_annotation.dart';

part 'evidencia.g.dart';

@JsonSerializable()
class Evidencia {
  final String id;
  final String rendicionId;
  final String rutaArchivo;
  final String tipoArchivo;
  final String descripcion;
  final DateTime fechaCarga;

  Evidencia({
    required this.id,
    required this.rendicionId,
    required this.rutaArchivo,
    required this.tipoArchivo,
    required this.descripcion,
    required this.fechaCarga,
  });

  factory Evidencia.fromJson(Map<String, dynamic> json) =>
      _$EvidenciaFromJson(json);

  Map<String, dynamic> toJson() => _$EvidenciaToJson(this);

  Evidencia copyWith({
    String? id,
    String? rendicionId,
    String? rutaArchivo,
    String? tipoArchivo,
    String? descripcion,
    DateTime? fechaCarga,
  }) {
    return Evidencia(
      id: id ?? this.id,
      rendicionId: rendicionId ?? this.rendicionId,
      rutaArchivo: rutaArchivo ?? this.rutaArchivo,
      tipoArchivo: tipoArchivo ?? this.tipoArchivo,
      descripcion: descripcion ?? this.descripcion,
      fechaCarga: fechaCarga ?? this.fechaCarga,
    );
  }
}
