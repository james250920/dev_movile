import 'package:json_annotation/json_annotation.dart';

part 'rendicion.g.dart';

enum RendicionStatus {
  @JsonValue('borrador')
  borrador,
  @JsonValue('enviada')
  enviada,
  @JsonValue('observada')
  observada,
  @JsonValue('aprobada')
  aprobada,
  @JsonValue('rechazada')
  rechazada,
  @JsonValue('pagada')
  pagada,
}

enum TipoPago {
  @JsonValue('efectivo')
  efectivo,
  @JsonValue('transferencia')
  transferencia,
  @JsonValue('tarjeta_credito')
  tarjeta_credito,
  @JsonValue('cheque')
  cheque,
}

@JsonSerializable()
class Rendicion {
  final String id;
  final String userId;
  final DateTime fechaCreacion;
  final DateTime? fechaEnvio;
  final DateTime? fechaAprobacion;
  final String titulo;
  final String descripcion;
  final RendicionStatus estado;
  final double totalGastos;
  final String? proyectoId;
  final String? centroCosto;
  final String observaciones;
  final bool esViatico;

  Rendicion({
    required this.id,
    required this.userId,
    required this.fechaCreacion,
    this.fechaEnvio,
    this.fechaAprobacion,
    required this.titulo,
    required this.descripcion,
    required this.estado,
    required this.totalGastos,
    this.proyectoId,
    this.centroCosto,
    this.observaciones = '',
    this.esViatico = false,
  });

  factory Rendicion.fromJson(Map<String, dynamic> json) =>
      _$RendicionFromJson(json);

  Map<String, dynamic> toJson() => _$RendicionToJson(this);

  Rendicion copyWith({
    String? id,
    String? userId,
    DateTime? fechaCreacion,
    DateTime? fechaEnvio,
    DateTime? fechaAprobacion,
    String? titulo,
    String? descripcion,
    RendicionStatus? estado,
    double? totalGastos,
    String? proyectoId,
    String? centroCosto,
    String? observaciones,
    bool? esViatico,
  }) {
    return Rendicion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaEnvio: fechaEnvio ?? this.fechaEnvio,
      fechaAprobacion: fechaAprobacion ?? this.fechaAprobacion,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      estado: estado ?? this.estado,
      totalGastos: totalGastos ?? this.totalGastos,
      proyectoId: proyectoId ?? this.proyectoId,
      centroCosto: centroCosto ?? this.centroCosto,
      observaciones: observaciones ?? this.observaciones,
      esViatico: esViatico ?? this.esViatico,
    );
  }
}
