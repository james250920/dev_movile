import 'package:dev_mobile/domain/models/rendicion.dart';
import 'package:dev_mobile/domain/models/comprobante.dart';
import 'package:dev_mobile/domain/models/gasto_manual.dart';
import 'package:dev_mobile/domain/models/resumen_rendicion.dart';
import 'package:dev_mobile/data/database/rendiciones_database.dart';
import 'package:uuid/uuid.dart';

class RendicionesService {
  final RendicionesDatabase _database;

  RendicionesService({required RendicionesDatabase database})
    : _database = database;

  // ========== RENDICIONES ==========

  Future<Rendicion> crearRendicion({
    required String userId,
    required String titulo,
    String descripcion = '',
    String? proyectoId,
    String? centroCosto,
    bool esViatico = false,
  }) async {
    final now = DateTime.now();
    final rendicion = Rendicion(
      id: const Uuid().v4(),
      userId: userId,
      fechaCreacion: now,
      titulo: titulo,
      descripcion: descripcion,
      estado: RendicionStatus.borrador,
      totalGastos: 0.0,
      proyectoId: proyectoId,
      centroCosto: centroCosto,
      esViatico: esViatico,
    );

    await _database.createRendicion(rendicion);
    return rendicion;
  }

  Future<Rendicion?> obtenerRendicion(String id) async {
    return _database.getRendicion(id);
  }

  Future<List<Rendicion>> obtenerRendicionesDelUsuario(String userId) async {
    return _database.getRendicionesByUser(userId);
  }

  Future<List<Rendicion>> obtenerRendicionesPorEstado(
    String userId,
    RendicionStatus estado,
  ) async {
    final estadoStr = estado.toString().split('.').last;
    return _database.getRendicionesByEstado(userId, estadoStr);
  }

  Future<void> enviarRendicion(String rendicionId) async {
    final rendicion = await _database.getRendicion(rendicionId);
    if (rendicion == null) throw Exception('Rendición no encontrada');

    final actualizada = rendicion.copyWith(
      estado: RendicionStatus.enviada,
      fechaEnvio: DateTime.now(),
    );

    await _database.updateRendicion(actualizada);
  }

  Future<void> aprobarRendicion(
    String rendicionId,
    String observaciones,
  ) async {
    final rendicion = await _database.getRendicion(rendicionId);
    if (rendicion == null) throw Exception('Rendición no encontrada');

    final actualizada = rendicion.copyWith(
      estado: RendicionStatus.aprobada,
      fechaAprobacion: DateTime.now(),
      observaciones: observaciones,
    );

    await _database.updateRendicion(actualizada);
  }

  Future<void> rechazarRendicion(
    String rendicionId,
    String observaciones,
  ) async {
    final rendicion = await _database.getRendicion(rendicionId);
    if (rendicion == null) throw Exception('Rendición no encontrada');

    final actualizada = rendicion.copyWith(
      estado: RendicionStatus.rechazada,
      observaciones: observaciones,
    );

    await _database.updateRendicion(actualizada);
  }

  Future<void> deleteRendicion(String id) async {
    await _database.deleteRendicion(id);
  }

  // ========== COMPROBANTES ==========

  Future<Comprobante> agregarComprobante({
    required String rendicionId,
    required TipoComprobante tipo,
    required String numero,
    required DateTime fecha,
    required String proveedor,
    required String descripcion,
    required double monto,
    required TipoPago metodoPago,
    String? imagenPath,
    Map<String, dynamic>? datosOCR,
  }) async {
    final comprobante = Comprobante(
      id: const Uuid().v4(),
      rendicionId: rendicionId,
      tipo: tipo,
      numero: numero,
      fecha: fecha,
      proveedor: proveedor,
      descripcion: descripcion,
      monto: monto,
      metodoPago: metodoPago,
      imagenPath: imagenPath,
      datosOCR: datosOCR,
      fechaCreacion: DateTime.now(),
    );

    await _database.createComprobante(comprobante);
    await _actualizarTotalRendicion(rendicionId);
    return comprobante;
  }

  Future<List<Comprobante>> obtenerComprobantesDeRendicion(
    String rendicionId,
  ) async {
    return _database.getComprobantesByRendicion(rendicionId);
  }

  Future<void> actualizarComprobante(Comprobante comprobante) async {
    await _database.updateComprobante(comprobante);
    await _actualizarTotalRendicion(comprobante.rendicionId);
  }

  Future<void> eliminarComprobante(String id, String rendicionId) async {
    await _database.deleteComprobante(id);
    await _actualizarTotalRendicion(rendicionId);
  }

  // ========== GASTOS MANUALES ==========

  Future<GastoManual> agregarGastoManual({
    required String rendicionId,
    required DateTime fecha,
    required String concepto,
    required String descripcion,
    required double monto,
    required String metodoPago,
    String? beneficiario,
  }) async {
    final gasto = GastoManual(
      id: const Uuid().v4(),
      rendicionId: rendicionId,
      fecha: fecha,
      concepto: concepto,
      descripcion: descripcion,
      monto: monto,
      metodoPago: metodoPago,
      beneficiario: beneficiario,
      fechaCreacion: DateTime.now(),
    );

    await _database.createGastoManual(gasto);
    await _actualizarTotalRendicion(rendicionId);
    return gasto;
  }

  Future<List<GastoManual>> obtenerGastosManualesDeRendicion(
    String rendicionId,
  ) async {
    return _database.getGastosManualesByRendicion(rendicionId);
  }

  Future<void> actualizarGastoManual(GastoManual gasto) async {
    await _database.updateGastoManual(gasto);
    await _actualizarTotalRendicion(gasto.rendicionId);
  }

  Future<void> eliminarGastoManual(String id, String rendicionId) async {
    await _database.deleteGastoManual(id);
    await _actualizarTotalRendicion(rendicionId);
  }

  // ========== CÁLCULOS Y RESUMEN ==========

  Future<ResumenRendicion> obtenerResumenRendicion(String rendicionId) async {
    final comprobantes = await _database.getComprobantesByRendicion(
      rendicionId,
    );
    final gastosManuales = await _database.getGastosManualesByRendicion(
      rendicionId,
    );
    final evidencias = await _database.getEvidenciasByRendicion(rendicionId);

    final montoComprobantes = comprobantes.fold(0.0, (sum, c) => sum + c.monto);
    final montoGastosManuales = gastosManuales.fold(
      0.0,
      (sum, g) => sum + g.monto,
    );
    final montoTotal = montoComprobantes + montoGastosManuales;

    // Detalles por concepto
    final detallesPorConcepto = <String, double>{};
    for (final gasto in gastosManuales) {
      detallesPorConcepto.update(
        gasto.concepto,
        (value) => value + gasto.monto,
        ifAbsent: () => gasto.monto,
      );
    }

    // Detalles por método de pago
    final detallesPorMetodoPago = <String, double>{};
    for (final comprobante in comprobantes) {
      final metodoPago = comprobante.metodoPago.toString().split('.').last;
      detallesPorMetodoPago.update(
        metodoPago,
        (value) => value + comprobante.monto,
        ifAbsent: () => comprobante.monto,
      );
    }
    for (final gasto in gastosManuales) {
      detallesPorMetodoPago.update(
        gasto.metodoPago,
        (value) => value + gasto.monto,
        ifAbsent: () => gasto.monto,
      );
    }

    return ResumenRendicion(
      rendicionId: rendicionId,
      totalComprobantes: comprobantes.length,
      totalGastosManuales: gastosManuales.length,
      totalEvidencias: evidencias.length,
      montoComprobantes: montoComprobantes,
      montoGastosManuales: montoGastosManuales,
      montoTotal: montoTotal,
      detallesPorConcepto: detallesPorConcepto,
      detallesPorMetodoPago: detallesPorMetodoPago,
    );
  }

  Future<void> _actualizarTotalRendicion(String rendicionId) async {
    final resumen = await obtenerResumenRendicion(rendicionId);
    final rendicion = await _database.getRendicion(rendicionId);
    if (rendicion != null) {
      final actualizada = rendicion.copyWith(totalGastos: resumen.montoTotal);
      await _database.updateRendicion(actualizada);
    }
  }

  // ========== ESTADÍSTICAS ==========

  Future<Map<String, dynamic>> obtenerEstadisticasUsuario(String userId) async {
    final rendiciones = await _database.getRendicionesByUser(userId);

    final totalRendiciones = rendiciones.length;
    final rendicionesEnviadas = rendiciones
        .where((r) => r.estado == RendicionStatus.enviada)
        .length;
    final rendicionesAprobadas = rendiciones
        .where((r) => r.estado == RendicionStatus.aprobada)
        .length;
    final rendicionesObservadas = rendiciones
        .where((r) => r.estado == RendicionStatus.observada)
        .length;
    final montoTotal = rendiciones.fold(0.0, (sum, r) => sum + r.totalGastos);
    final montoAprobado = rendiciones
        .where((r) => r.estado == RendicionStatus.aprobada)
        .fold(0.0, (sum, r) => sum + r.totalGastos);

    return {
      'totalRendiciones': totalRendiciones,
      'rendicionesEnviadas': rendicionesEnviadas,
      'rendicionesAprobadas': rendicionesAprobadas,
      'rendicionesObservadas': rendicionesObservadas,
      'montoTotal': montoTotal,
      'montoAprobado': montoAprobado,
      'porcentajeAprobacion': totalRendiciones > 0
          ? (rendicionesAprobadas / totalRendiciones) * 100
          : 0,
    };
  }
}
