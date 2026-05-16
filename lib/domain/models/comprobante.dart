import 'package:json_annotation/json_annotation.dart';
import 'rendicion.dart' show TipoPago;
export 'rendicion.dart' show TipoPago;

part 'comprobante.g.dart';

enum TipoComprobante {
  @JsonValue('factura')
  factura,
  @JsonValue('recibo')
  recibo,
  @JsonValue('boleta')
  boleta,
  @JsonValue('manual')
  manual,
}

@JsonSerializable()
class Comprobante {
  final String id;
  final String rendicionId;
  final TipoComprobante tipo;
  final String numero;
  final DateTime fecha;
  final String proveedor;
  final String descripcion;
  final double monto;
  final TipoPago metodoPago;
  final String? imagenPath;
  final Map<String, dynamic>? datosOCR;
  final String? numeroTicket;
  final DateTime fechaCreacion;

  Comprobante({
    required this.id,
    required this.rendicionId,
    required this.tipo,
    required this.numero,
    required this.fecha,
    required this.proveedor,
    required this.descripcion,
    required this.monto,
    required this.metodoPago,
    this.imagenPath,
    this.datosOCR,
    this.numeroTicket,
    required this.fechaCreacion,
  });

  factory Comprobante.fromJson(Map<String, dynamic> json) =>
      _$ComprobanteFromJson(json);

  Map<String, dynamic> toJson() => _$ComprobanteToJson(this);

  Comprobante copyWith({
    String? id,
    String? rendicionId,
    TipoComprobante? tipo,
    String? numero,
    DateTime? fecha,
    String? proveedor,
    String? descripcion,
    double? monto,
    TipoPago? metodoPago,
    String? imagenPath,
    Map<String, dynamic>? datosOCR,
    String? numeroTicket,
    DateTime? fechaCreacion,
  }) {
    return Comprobante(
      id: id ?? this.id,
      rendicionId: rendicionId ?? this.rendicionId,
      tipo: tipo ?? this.tipo,
      numero: numero ?? this.numero,
      fecha: fecha ?? this.fecha,
      proveedor: proveedor ?? this.proveedor,
      descripcion: descripcion ?? this.descripcion,
      monto: monto ?? this.monto,
      metodoPago: metodoPago ?? this.metodoPago,
      imagenPath: imagenPath ?? this.imagenPath,
      datosOCR: datosOCR ?? this.datosOCR,
      numeroTicket: numeroTicket ?? this.numeroTicket,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}
