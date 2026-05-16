import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dev_mobile/data/database/rendiciones_database.dart';
import 'package:dev_mobile/data/services/rendiciones_service.dart';
import 'package:dev_mobile/domain/models/rendicion.dart';
import 'package:dev_mobile/domain/models/comprobante.dart';
import 'package:dev_mobile/domain/models/gasto_manual.dart';
import 'package:dev_mobile/domain/models/resumen_rendicion.dart';

// Database provider
final rendicionesDatabaseProvider = Provider((ref) {
  return RendicionesDatabase();
});

// Service provider
final rendicionesServiceProvider = Provider((ref) {
  final db = ref.watch(rendicionesDatabaseProvider);
  return RendicionesService(database: db);
});

// Current user ID (mock - en producción vendría del auth)
final currentUserIdProvider = StateProvider((ref) => 'user_123');

// ========== RENDICIONES ==========

// Listado de rendiciones del usuario actual
final rendicionesUsuarioProvider =
    FutureProvider.family<List<Rendicion>, String>((ref, userId) async {
      final service = ref.watch(rendicionesServiceProvider);
      return service.obtenerRendicionesDelUsuario(userId);
    });

// Rendiciones filtradas por estado
final rendicionesPorEstadoProvider =
    FutureProvider.family<
      List<Rendicion>,
      ({String userId, RendicionStatus estado})
    >((ref, params) async {
      final service = ref.watch(rendicionesServiceProvider);
      return service.obtenerRendicionesPorEstado(params.userId, params.estado);
    });

// Detalle de una rendición específica
final rendicionDetalleProvider = FutureProvider.family<Rendicion?, String>((
  ref,
  rendicionId,
) async {
  final service = ref.watch(rendicionesServiceProvider);
  return service.obtenerRendicion(rendicionId);
});

// Resumen de una rendición
final resumenRendicionProvider =
    FutureProvider.family<ResumenRendicion, String>((ref, rendicionId) async {
      final service = ref.watch(rendicionesServiceProvider);
      return service.obtenerResumenRendicion(rendicionId);
    });

// Comprobantes de una rendición
final comprobantesRendicionProvider =
    FutureProvider.family<List<Comprobante>, String>((ref, rendicionId) async {
      final service = ref.watch(rendicionesServiceProvider);
      return service.obtenerComprobantesDeRendicion(rendicionId);
    });

// Gastos manuales de una rendición
final gastosManualesRendicionProvider =
    FutureProvider.family<List<GastoManual>, String>((ref, rendicionId) async {
      final service = ref.watch(rendicionesServiceProvider);
      return service.obtenerGastosManualesDeRendicion(rendicionId);
    });

// Estadísticas del usuario
final estadisticasUsuarioProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
      final service = ref.watch(rendicionesServiceProvider);
      return service.obtenerEstadisticasUsuario(userId);
    });

// ========== STATE MANAGEMENT ==========

// Notifier para crear nueva rendición
class CrearRendicionNotifier extends StateNotifier<AsyncValue<Rendicion?>> {
  final RendicionesService _service;

  CrearRendicionNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> crearRendicion({
    required String userId,
    required String titulo,
    String descripcion = '',
    String? proyectoId,
    String? centroCosto,
    bool esViatico = false,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return _service.crearRendicion(
        userId: userId,
        titulo: titulo,
        descripcion: descripcion,
        proyectoId: proyectoId,
        centroCosto: centroCosto,
        esViatico: esViatico,
      );
    });
  }
}

final crearRendicionProvider =
    StateNotifierProvider.autoDispose<
      CrearRendicionNotifier,
      AsyncValue<Rendicion?>
    >((ref) {
      final service = ref.watch(rendicionesServiceProvider);
      return CrearRendicionNotifier(service);
    });

// Notifier para enviar rendición
class EnviarRendicionNotifier extends StateNotifier<AsyncValue<void>> {
  final RendicionesService _service;

  EnviarRendicionNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> enviar(String rendicionId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.enviarRendicion(rendicionId);
    });
  }
}

final enviarRendicionProvider =
    StateNotifierProvider.autoDispose<
      EnviarRendicionNotifier,
      AsyncValue<void>
    >((ref) {
      final service = ref.watch(rendicionesServiceProvider);
      return EnviarRendicionNotifier(service);
    });

// Notifier para agregar comprobante
class AgregarComprobanteNotifier
    extends StateNotifier<AsyncValue<Comprobante?>> {
  final RendicionesService _service;

  AgregarComprobanteNotifier(this._service)
    : super(const AsyncValue.data(null));

  Future<void> agregar({
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
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return _service.agregarComprobante(
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
      );
    });
  }
}

final agregarComprobanteProvider =
    StateNotifierProvider.autoDispose<
      AgregarComprobanteNotifier,
      AsyncValue<Comprobante?>
    >((ref) {
      final service = ref.watch(rendicionesServiceProvider);
      return AgregarComprobanteNotifier(service);
    });

// Notifier para agregar gasto manual
class AgregarGastoManualNotifier
    extends StateNotifier<AsyncValue<GastoManual?>> {
  final RendicionesService _service;

  AgregarGastoManualNotifier(this._service)
    : super(const AsyncValue.data(null));

  Future<void> agregar({
    required String rendicionId,
    required DateTime fecha,
    required String concepto,
    required String descripcion,
    required double monto,
    required String metodoPago,
    String? beneficiario,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return _service.agregarGastoManual(
        rendicionId: rendicionId,
        fecha: fecha,
        concepto: concepto,
        descripcion: descripcion,
        monto: monto,
        metodoPago: metodoPago,
        beneficiario: beneficiario,
      );
    });
  }
}

final agregarGastoManualProvider =
    StateNotifierProvider.autoDispose<
      AgregarGastoManualNotifier,
      AsyncValue<GastoManual?>
    >((ref) {
      final service = ref.watch(rendicionesServiceProvider);
      return AgregarGastoManualNotifier(service);
    });
