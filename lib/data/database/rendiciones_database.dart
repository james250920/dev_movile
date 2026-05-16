import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:dev_mobile/domain/models/rendicion.dart';
import 'package:dev_mobile/domain/models/comprobante.dart';
import 'package:dev_mobile/domain/models/gasto_manual.dart';
import 'package:dev_mobile/domain/models/evidencia.dart';
import 'package:dev_mobile/domain/models/observacion_rendicion.dart';

class RendicionesDatabase {
  static final RendicionesDatabase _instance = RendicionesDatabase._internal();

  factory RendicionesDatabase() {
    return _instance;
  }

  RendicionesDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    if (kIsWeb) {
      throw Exception('SQLite no está disponible en web');
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'rendiciones.db');

    return openDatabase(path, version: 1, onCreate: _createTables);
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS rendiciones (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        fechaCreacion TEXT NOT NULL,
        fechaEnvio TEXT,
        fechaAprobacion TEXT,
        titulo TEXT NOT NULL,
        descripcion TEXT,
        estado TEXT NOT NULL,
        totalGastos REAL NOT NULL,
        proyectoId TEXT,
        centroCosto TEXT,
        observaciones TEXT,
        esViatico INTEGER NOT NULL DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS comprobantes (
        id TEXT PRIMARY KEY,
        rendicionId TEXT NOT NULL,
        tipo TEXT NOT NULL,
        numero TEXT NOT NULL,
        fecha TEXT NOT NULL,
        proveedor TEXT NOT NULL,
        descripcion TEXT,
        monto REAL NOT NULL,
        metodoPago TEXT NOT NULL,
        imagenPath TEXT,
        datosOCR TEXT,
        numeroTicket TEXT,
        fechaCreacion TEXT NOT NULL,
        FOREIGN KEY (rendicionId) REFERENCES rendiciones(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS gastos_manuales (
        id TEXT PRIMARY KEY,
        rendicionId TEXT NOT NULL,
        fecha TEXT NOT NULL,
        concepto TEXT NOT NULL,
        descripcion TEXT,
        monto REAL NOT NULL,
        metodoPago TEXT NOT NULL,
        beneficiario TEXT,
        fechaCreacion TEXT NOT NULL,
        FOREIGN KEY (rendicionId) REFERENCES rendiciones(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS evidencias (
        id TEXT PRIMARY KEY,
        rendicionId TEXT NOT NULL,
        rutaArchivo TEXT NOT NULL,
        tipoArchivo TEXT NOT NULL,
        descripcion TEXT,
        fechaCarga TEXT NOT NULL,
        FOREIGN KEY (rendicionId) REFERENCES rendiciones(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS observaciones_rendicion (
        id TEXT PRIMARY KEY,
        rendicionId TEXT NOT NULL,
        autor TEXT NOT NULL,
        tipo TEXT NOT NULL,
        texto TEXT NOT NULL,
        fecha TEXT NOT NULL,
        requiereCorreccion INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (rendicionId) REFERENCES rendiciones(id)
      )
    ''');

    // Crear índices
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_rendiciones_userId ON rendiciones(userId)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_rendiciones_estado ON rendiciones(estado)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_comprobantes_rendicionId ON comprobantes(rendicionId)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_gastos_manuales_rendicionId ON gastos_manuales(rendicionId)',
    );
  }

  // ========== RENDICIONES ==========

  Future<String> createRendicion(Rendicion rendicion) async {
    try {
      final db = await database;
      await db.insert('rendiciones', {
        'id': rendicion.id,
        'userId': rendicion.userId,
        'fechaCreacion': rendicion.fechaCreacion.toIso8601String(),
        'fechaEnvio': rendicion.fechaEnvio?.toIso8601String(),
        'fechaAprobacion': rendicion.fechaAprobacion?.toIso8601String(),
        'titulo': rendicion.titulo,
        'descripcion': rendicion.descripcion,
        'estado': rendicion.estado.toString().split('.').last,
        'totalGastos': rendicion.totalGastos,
        'proyectoId': rendicion.proyectoId,
        'centroCosto': rendicion.centroCosto,
        'observaciones': rendicion.observaciones,
        'esViatico': rendicion.esViatico ? 1 : 0,
      });
      return rendicion.id;
    } catch (e) {
      rethrow;
    }
  }

  Future<Rendicion?> getRendicion(String id) async {
    try {
      final db = await database;
      final result = await db.query(
        'rendiciones',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (result.isEmpty) return null;
      return _mapToRendicion(result.first);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Rendicion>> getRendicionesByUser(String userId) async {
    try {
      final db = await database;
      final result = await db.query(
        'rendiciones',
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'fechaCreacion DESC',
      );
      return result.map(_mapToRendicion).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Rendicion>> getRendicionesByEstado(
    String userId,
    String estado,
  ) async {
    try {
      final db = await database;
      final result = await db.query(
        'rendiciones',
        where: 'userId = ? AND estado = ?',
        whereArgs: [userId, estado],
        orderBy: 'fechaCreacion DESC',
      );
      return result.map(_mapToRendicion).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateRendicion(Rendicion rendicion) async {
    try {
      final db = await database;
      await db.update(
        'rendiciones',
        {
          'titulo': rendicion.titulo,
          'descripcion': rendicion.descripcion,
          'estado': rendicion.estado.toString().split('.').last,
          'totalGastos': rendicion.totalGastos,
          'proyectoId': rendicion.proyectoId,
          'centroCosto': rendicion.centroCosto,
          'observaciones': rendicion.observaciones,
          'fechaEnvio': rendicion.fechaEnvio?.toIso8601String(),
          'fechaAprobacion': rendicion.fechaAprobacion?.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [rendicion.id],
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteRendicion(String id) async {
    try {
      final db = await database;
      // Eliminar datos relacionados
      await db.delete(
        'comprobantes',
        where: 'rendicionId = ?',
        whereArgs: [id],
      );
      await db.delete(
        'gastos_manuales',
        where: 'rendicionId = ?',
        whereArgs: [id],
      );
      await db.delete('evidencias', where: 'rendicionId = ?', whereArgs: [id]);
      await db.delete(
        'observaciones_rendicion',
        where: 'rendicionId = ?',
        whereArgs: [id],
      );
      // Eliminar rendición
      await db.delete('rendiciones', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      rethrow;
    }
  }

  // ========== COMPROBANTES ==========

  Future<String> createComprobante(Comprobante comprobante) async {
    try {
      final db = await database;
      await db.insert('comprobantes', {
        'id': comprobante.id,
        'rendicionId': comprobante.rendicionId,
        'tipo': comprobante.tipo.toString().split('.').last,
        'numero': comprobante.numero,
        'fecha': comprobante.fecha.toIso8601String(),
        'proveedor': comprobante.proveedor,
        'descripcion': comprobante.descripcion,
        'monto': comprobante.monto,
        'metodoPago': comprobante.metodoPago.toString().split('.').last,
        'imagenPath': comprobante.imagenPath,
        'datosOCR': comprobante.datosOCR != null
            ? jsonEncode(comprobante.datosOCR)
            : null,
        'numeroTicket': comprobante.numeroTicket,
        'fechaCreacion': comprobante.fechaCreacion.toIso8601String(),
      });
      return comprobante.id;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Comprobante>> getComprobantesByRendicion(
    String rendicionId,
  ) async {
    try {
      final db = await database;
      final result = await db.query(
        'comprobantes',
        where: 'rendicionId = ?',
        whereArgs: [rendicionId],
        orderBy: 'fecha DESC',
      );
      return result.map(_mapToComprobante).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateComprobante(Comprobante comprobante) async {
    try {
      final db = await database;
      await db.update(
        'comprobantes',
        {
          'tipo': comprobante.tipo.toString().split('.').last,
          'numero': comprobante.numero,
          'fecha': comprobante.fecha.toIso8601String(),
          'proveedor': comprobante.proveedor,
          'descripcion': comprobante.descripcion,
          'monto': comprobante.monto,
          'metodoPago': comprobante.metodoPago.toString().split('.').last,
          'imagenPath': comprobante.imagenPath,
          'datosOCR': comprobante.datosOCR != null
              ? jsonEncode(comprobante.datosOCR)
              : null,
          'numeroTicket': comprobante.numeroTicket,
        },
        where: 'id = ?',
        whereArgs: [comprobante.id],
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteComprobante(String id) async {
    try {
      final db = await database;
      await db.delete('comprobantes', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      rethrow;
    }
  }

  // ========== GASTOS MANUALES ==========

  Future<String> createGastoManual(GastoManual gasto) async {
    try {
      final db = await database;
      await db.insert('gastos_manuales', {
        'id': gasto.id,
        'rendicionId': gasto.rendicionId,
        'fecha': gasto.fecha.toIso8601String(),
        'concepto': gasto.concepto,
        'descripcion': gasto.descripcion,
        'monto': gasto.monto,
        'metodoPago': gasto.metodoPago,
        'beneficiario': gasto.beneficiario,
        'fechaCreacion': gasto.fechaCreacion.toIso8601String(),
      });
      return gasto.id;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<GastoManual>> getGastosManualesByRendicion(
    String rendicionId,
  ) async {
    try {
      final db = await database;
      final result = await db.query(
        'gastos_manuales',
        where: 'rendicionId = ?',
        whereArgs: [rendicionId],
        orderBy: 'fecha DESC',
      );
      return result.map(_mapToGastoManual).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateGastoManual(GastoManual gasto) async {
    try {
      final db = await database;
      await db.update(
        'gastos_manuales',
        {
          'fecha': gasto.fecha.toIso8601String(),
          'concepto': gasto.concepto,
          'descripcion': gasto.descripcion,
          'monto': gasto.monto,
          'metodoPago': gasto.metodoPago,
          'beneficiario': gasto.beneficiario,
        },
        where: 'id = ?',
        whereArgs: [gasto.id],
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteGastoManual(String id) async {
    try {
      final db = await database;
      await db.delete('gastos_manuales', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      rethrow;
    }
  }

  // ========== EVIDENCIAS ==========

  Future<String> createEvidencia(Evidencia evidencia) async {
    try {
      final db = await database;
      await db.insert('evidencias', {
        'id': evidencia.id,
        'rendicionId': evidencia.rendicionId,
        'rutaArchivo': evidencia.rutaArchivo,
        'tipoArchivo': evidencia.tipoArchivo,
        'descripcion': evidencia.descripcion,
        'fechaCarga': evidencia.fechaCarga.toIso8601String(),
      });
      return evidencia.id;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Evidencia>> getEvidenciasByRendicion(String rendicionId) async {
    try {
      final db = await database;
      final result = await db.query(
        'evidencias',
        where: 'rendicionId = ?',
        whereArgs: [rendicionId],
        orderBy: 'fechaCarga DESC',
      );
      return result.map(_mapToEvidencia).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteEvidencia(String id) async {
    try {
      final db = await database;
      await db.delete('evidencias', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      rethrow;
    }
  }

  // ========== OBSERVACIONES ==========

  Future<String> createObservacion(ObservacionRendicion obs) async {
    try {
      final db = await database;
      await db.insert('observaciones_rendicion', {
        'id': obs.id,
        'rendicionId': obs.rendicionId,
        'autor': obs.autor,
        'tipo': obs.tipo,
        'texto': obs.texto,
        'fecha': obs.fecha.toIso8601String(),
        'requiereCorreccion': obs.requiereCorreccion ? 1 : 0,
      });
      return obs.id;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ObservacionRendicion>> getObservacionesByRendicion(
    String rendicionId,
  ) async {
    try {
      final db = await database;
      final result = await db.query(
        'observaciones_rendicion',
        where: 'rendicionId = ?',
        whereArgs: [rendicionId],
        orderBy: 'fecha DESC',
      );
      return result.map(_mapToObservacion).toList();
    } catch (e) {
      rethrow;
    }
  }

  // ========== MAPPERS ==========

  Rendicion _mapToRendicion(Map<String, dynamic> map) {
    return Rendicion(
      id: map['id'] as String,
      userId: map['userId'] as String,
      fechaCreacion: DateTime.parse(map['fechaCreacion'] as String),
      fechaEnvio: map['fechaEnvio'] != null
          ? DateTime.parse(map['fechaEnvio'] as String)
          : null,
      fechaAprobacion: map['fechaAprobacion'] != null
          ? DateTime.parse(map['fechaAprobacion'] as String)
          : null,
      titulo: map['titulo'] as String,
      descripcion: map['descripcion'] as String? ?? '',
      estado: RendicionStatus.values.firstWhere(
        (e) => e.name == map['estado'],
        orElse: () => RendicionStatus.borrador,
      ),
      totalGastos: (map['totalGastos'] as num).toDouble(),
      proyectoId: map['proyectoId'] as String?,
      centroCosto: map['centroCosto'] as String?,
      observaciones: map['observaciones'] as String? ?? '',
      esViatico: (map['esViatico'] as int) == 1,
    );
  }

  Comprobante _mapToComprobante(Map<String, dynamic> map) {
    return Comprobante(
      id: map['id'] as String,
      rendicionId: map['rendicionId'] as String,
      tipo: TipoComprobante.values.firstWhere(
        (e) => e.name == map['tipo'],
        orElse: () => TipoComprobante.recibo,
      ),
      numero: map['numero'] as String,
      fecha: DateTime.parse(map['fecha'] as String),
      proveedor: map['proveedor'] as String,
      descripcion: map['descripcion'] as String? ?? '',
      monto: (map['monto'] as num).toDouble(),
      metodoPago: TipoPago.values.firstWhere(
        (e) => e.name == map['metodoPago'],
        orElse: () => TipoPago.efectivo,
      ),
      imagenPath: map['imagenPath'] as String?,
      datosOCR: map['datosOCR'] != null
          ? jsonDecode(map['datosOCR'] as String) as Map<String, dynamic>
          : null,
      numeroTicket: map['numeroTicket'] as String?,
      fechaCreacion: DateTime.parse(map['fechaCreacion'] as String),
    );
  }

  GastoManual _mapToGastoManual(Map<String, dynamic> map) {
    return GastoManual(
      id: map['id'] as String,
      rendicionId: map['rendicionId'] as String,
      fecha: DateTime.parse(map['fecha'] as String),
      concepto: map['concepto'] as String,
      descripcion: map['descripcion'] as String? ?? '',
      monto: (map['monto'] as num).toDouble(),
      metodoPago: map['metodoPago'] as String,
      beneficiario: map['beneficiario'] as String?,
      fechaCreacion: DateTime.parse(map['fechaCreacion'] as String),
    );
  }

  Evidencia _mapToEvidencia(Map<String, dynamic> map) {
    return Evidencia(
      id: map['id'] as String,
      rendicionId: map['rendicionId'] as String,
      rutaArchivo: map['rutaArchivo'] as String,
      tipoArchivo: map['tipoArchivo'] as String,
      descripcion: map['descripcion'] as String? ?? '',
      fechaCarga: DateTime.parse(map['fechaCarga'] as String),
    );
  }

  ObservacionRendicion _mapToObservacion(Map<String, dynamic> map) {
    return ObservacionRendicion(
      id: map['id'] as String,
      rendicionId: map['rendicionId'] as String,
      autor: map['autor'] as String,
      tipo: map['tipo'] as String,
      texto: map['texto'] as String,
      fecha: DateTime.parse(map['fecha'] as String),
      requiereCorreccion: (map['requiereCorreccion'] as int) == 1,
    );
  }

  Future<void> close() async {
    await _database?.close();
  }
}

// Helper function to encode JSON
String jsonEncode(dynamic object) {
  return json.encode(object);
}

// Helper function to decode JSON
dynamic jsonDecode(String source) {
  try {
    return json.decode(source) as Map<String, dynamic>;
  } catch (e) {
    return {};
  }
}
