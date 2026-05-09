import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class RendicionItem {
  DateTime date;
  String description;
  double amount;

  /// Tipo de reembolso: 'asi', 'viaticos', 'otros', etc.
  String type;

  /// Estado: 'borrador', 'enviado', 'aprobado', 'rechazado'
  String status;

  /// Datos de factura
  String invoiceNumber;
  String supplier;
  String? imageBase64; // Imagen en base64

  RendicionItem(
    this.date,
    this.description,
    this.amount, {
    this.type = 'otros',
    this.status = 'borrador',
    this.invoiceNumber = '',
    this.supplier = '',
    this.imageBase64,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'description': description,
    'amount': amount,
    'type': type,
    'status': status,
    'invoiceNumber': invoiceNumber,
    'supplier': supplier,
    'imageBase64': imageBase64,
  };

  static RendicionItem fromJson(Map<String, dynamic> json) {
    try {
      return RendicionItem(
        DateTime.parse(json['date'] as String),
        json['description'] as String? ?? '',
        (json['amount'] as num?)?.toDouble() ?? 0.0,
        type: json['type'] as String? ?? 'otros',
        status: json['status'] as String? ?? 'borrador',
        invoiceNumber: json['invoiceNumber'] as String? ?? '',
        supplier: json['supplier'] as String? ?? '',
        imageBase64: json['imageBase64'] as String?,
      );
    } catch (e) {
      throw FormatException('Error parsing RendicionItem: $e');
    }
  }
}

class TareoItem {
  DateTime date;
  String task;
  double hours;
  String project;
  String month; // format yyyy-MM
  double amount;

  TareoItem(
    this.date,
    this.task,
    this.hours, {
    this.project = '',
    String? month,
    this.amount = 0.0,
  }) : month =
           month ??
           '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'task': task,
    'hours': hours,
    'project': project,
    'month': month,
    'amount': amount,
  };

  static TareoItem fromJson(Map<String, dynamic> json) {
    try {
      return TareoItem(
        DateTime.parse(json['date'] as String),
        json['task'] as String? ?? 'Sin tarea',
        (json['hours'] as num?)?.toDouble() ?? 0.0,
        project: json['project'] as String? ?? '',
        month: json['month'] as String?,
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (e) {
      throw FormatException('Error parsing TareoItem: $e');
    }
  }
}

class AsistenciaItem {
  final DateTime date;
  String name;
  bool present;
  String project;
  DateTime? checkInTime;
  double? latitude;
  double? longitude;
  String? locationLabel;

  AsistenciaItem(
    this.date,
    this.name, {
    this.present = false,
    this.project = '',
    this.checkInTime,
    this.latitude,
    this.longitude,
    this.locationLabel,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'name': name,
    'present': present ? 1 : 0,
    'project': project,
    'checkInTime': checkInTime?.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
    'locationLabel': locationLabel,
  };

  static AsistenciaItem fromJson(Map<String, dynamic> json) {
    try {
      return AsistenciaItem(
        DateTime.parse(json['date'] as String),
        json['name'] as String? ?? 'Sin nombre',
        present: (json['present'] as num?)?.toInt() == 1,
        project: json['project'] as String? ?? '',
        checkInTime: json['checkInTime'] == null
            ? null
            : DateTime.parse(json['checkInTime'] as String),
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        locationLabel: json['locationLabel'] as String?,
      );
    } catch (e) {
      throw FormatException('Error parsing AsistenciaItem: $e');
    }
  }
}

// ==================== DATABASE MANAGEMENT ====================
// Consolidated single database: dev_mobile.db
// Version: 1 (for future migrations)

Database? _dbInstance;
bool _dbInitializing = false;

Future<Database> _openDb() async {
  // Skip database on web - use in-memory mock data only
  if (kIsWeb) {
    throw Exception('Database not available on web. Using local mock data.');
  }

  // Return existing instance
  if (_dbInstance != null) {
    try {
      // Verify connection is still valid
      await _dbInstance!
          .rawQuery('SELECT 1')
          .timeout(const Duration(seconds: 3));
      return _dbInstance!;
    } catch (_) {
      // Connection is broken, reset it
      _dbInstance = null;
    }
  }

  // Prevent concurrent initialization attempts
  if (_dbInitializing) {
    int retries = 0;
    while (_dbInitializing && retries < 50) {
      await Future.delayed(const Duration(milliseconds: 100));
      retries++;
    }

    if (_dbInstance != null) {
      return _dbInstance!;
    }

    if (_dbInitializing) {
      throw TimeoutException('Database initialization timed out');
    }
  }

  _dbInitializing = true;
  try {
    final dbPath = await getDatabasesPath();
    final pathDb = join(dbPath, 'dev_mobile.db');

    _dbInstance = await openDatabase(
      pathDb,
      version: 1,
      onCreate: _createSchema,
      onOpen: _verifySchema,
    ).timeout(const Duration(seconds: 3));

    return _dbInstance!;
  } catch (e) {
    _dbInstance = null;
    throw Exception('Failed to open database: $e');
  } finally {
    _dbInitializing = false;
  }
}

Future<void> _createSchema(Database db, int version) async {
  // Create all tables with proper schema
  await db.execute('''
    CREATE TABLE IF NOT EXISTS rendiciones(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT NOT NULL,
      description TEXT NOT NULL,
      amount REAL NOT NULL,
      type TEXT NOT NULL,
      status TEXT NOT NULL,
      invoiceNumber TEXT,
      supplier TEXT,
      imageBase64 TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS tareos(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT NOT NULL,
      task TEXT NOT NULL,
      hours REAL NOT NULL,
      project TEXT,
      month TEXT NOT NULL,
      amount REAL NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS asistencias(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT NOT NULL,
      name TEXT NOT NULL,
      present INTEGER NOT NULL,
      project TEXT,
      checkInTime TEXT,
      latitude REAL,
      longitude REAL,
      locationLabel TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS projects(
      name TEXT PRIMARY KEY,
      qr TEXT NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS workers(
      name TEXT PRIMARY KEY,
      qr TEXT NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  ''');

  // Create indexes for frequently queried columns
  await _createIndexes(db);
}

Future<void> _createIndexes(Database db) async {
  try {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_rendiciones_date ON rendiciones(date DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_rendiciones_status ON rendiciones(status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_tareos_date ON tareos(date DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_tareos_project ON tareos(project)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_tareos_month ON tareos(month)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_asistencias_date ON asistencias(date DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_asistencias_name ON asistencias(name)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_asistencias_project ON asistencias(project)',
    );
  } catch (e) {
    // Indexes might already exist, that's fine
  }
}

Future<void> _verifySchema(Database db) async {
  // Ensure tables exist even if opening existing DB
  try {
    await _createSchema(db, 1);
  } catch (e) {
    // Tables likely already exist
  }
}

Future<void> closeDatabase() async {
  if (_dbInstance != null) {
    await _dbInstance!.close();
    _dbInstance = null;
  }
}

// ==================== RENDICIONES PERSISTENCE ====================
// Mock list (in-memory). Persistence via SQLite (sqflite).
List<RendicionItem> mockRendiciones = [];

Future<void> saveRendiciones() async {
  // On web, there's no persistent database, so just skip
  if (kIsWeb) {
    return;
  }

  try {
    final db = await _openDb();
    await db.transaction((txn) async {
      await txn.delete('rendiciones');
      for (final r in mockRendiciones) {
        await txn.insert(
          'rendiciones',
          r.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  } catch (e) {
    // Silently ignore save errors on non-web platforms
    return;
  }
}

Future<void> loadRendiciones() async {
  final db = await _openDb();
  try {
    final rows = await db
        .query('rendiciones', orderBy: 'date DESC')
        .timeout(const Duration(seconds: 3));
    if (rows.isEmpty) {
      mockRendiciones = [
        RendicionItem(
          DateTime.now().subtract(const Duration(days: 2)),
          'Compra de materiales',
          120.50,
          type: 'asi',
          status: 'aprobado',
          invoiceNumber: '001-001-000123456',
          supplier: 'Ferretería XYZ',
        ),
        RendicionItem(
          DateTime.now().subtract(const Duration(days: 1)),
          'Transporte',
          45.00,
          type: 'viaticos',
          status: 'borrador',
          invoiceNumber: '0010-000654321',
          supplier: 'Taxi Plus',
        ),
      ];
      await saveRendiciones();
      return;
    }
    mockRendiciones = rows.map((r) {
      try {
        return RendicionItem.fromJson(r);
      } catch (e) {
        throw FormatException('Invalid rendicion row: $r, error: $e');
      }
    }).toList();
  } catch (e) {
    throw Exception('Error loading rendiciones: $e');
  }
}

// ==================== TAREOS PERSISTENCE ====================
final List<TareoItem> mockTareos = [
  TareoItem(
    DateTime.now(),
    'Inspección de equipo',
    2.5,
    project: 'Proyecto Norte',
    amount: 50.0,
  ),
  TareoItem(
    DateTime.now(),
    'Instalación',
    4.0,
    project: 'Obra Sur',
    amount: 120.0,
  ),
];

Future<void> saveTareos() async {
  // On web, there's no persistent database, so just skip
  if (kIsWeb) {
    return;
  }

  try {
    final db = await _openDb();
    await db.transaction((txn) async {
      await txn.delete('tareos');
      for (final t in mockTareos) {
        await txn.insert(
          'tareos',
          t.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  } catch (e) {
    // Silently ignore save errors on non-web platforms
    return;
  }
}

Future<void> loadTareos() async {
  try {
    final db = await _openDb();
    final rows = await db
        .query('tareos', orderBy: 'date DESC')
        .timeout(const Duration(seconds: 3));
    if (rows.isEmpty) {
      // If no data in DB, save defaults and return
      try {
        await saveTareos();
      } catch (_) {
        // Ignore save errors on first load
      }
      return;
    }

    // Parse rows with validation
    final parsedItems = <TareoItem>[];
    for (final r in rows) {
      try {
        parsedItems.add(TareoItem.fromJson(r));
      } catch (e) {
        // Skip invalid rows
        continue;
      }
    }

    if (parsedItems.isNotEmpty) {
      mockTareos
        ..clear()
        ..addAll(parsedItems);
    }
  } catch (e) {
    // Keep existing mock data, don't throw
    return;
  }
}

// ==================== ASISTENCIAS PERSISTENCE ====================
final List<AsistenciaItem> mockAsistencias = [
  AsistenciaItem(
    DateTime.now(),
    'Juan Perez',
    present: true,
    project: 'Proyecto Norte',
    checkInTime: DateTime.now().subtract(const Duration(hours: 1)),
    latitude: -12.0464,
    longitude: -77.0428,
    locationLabel: 'Oficina central',
  ),
  AsistenciaItem(DateTime.now(), 'María López', present: false),
  AsistenciaItem(
    DateTime.now(),
    'Carlos Ruiz',
    present: true,
    project: 'Obra Sur',
    checkInTime: DateTime.now().subtract(const Duration(minutes: 45)),
    latitude: -12.055,
    longitude: -77.03,
    locationLabel: 'Frente de obra',
  ),
];

Future<void> saveAsistencias() async {
  // On web, there's no persistent database, so just skip
  if (kIsWeb) {
    return;
  }

  try {
    final db = await _openDb();
    await db.transaction((txn) async {
      await txn.delete('asistencias');
      for (final a in mockAsistencias) {
        await txn.insert(
          'asistencias',
          a.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  } catch (e) {
    // Silently ignore save errors on non-web platforms
    return;
  }
}

Future<void> loadAsistencias() async {
  try {
    final db = await _openDb();
    final rows = await db
        .query('asistencias', orderBy: 'date DESC')
        .timeout(const Duration(seconds: 3));
    if (rows.isEmpty) {
      // If no data in DB, save defaults and return
      try {
        await saveAsistencias();
      } catch (_) {
        // Ignore save errors on first load
      }
      return;
    }

    // Parse rows with validation
    final parsedItems = <AsistenciaItem>[];
    for (final row in rows) {
      try {
        parsedItems.add(AsistenciaItem.fromJson(row));
      } catch (e) {
        // Skip invalid rows
        continue;
      }
    }

    if (parsedItems.isNotEmpty) {
      mockAsistencias
        ..clear()
        ..addAll(parsedItems);
    }
  } catch (e) {
    // Keep existing mock data, don't throw
    return;
  }
}

Future<List<AsistenciaItem>> getAsistenciasFiltered({
  DateTime? date,
  String? project,
}) async {
  try {
    // On web, skip database and filter in-memory directly
    if (kIsWeb) {
      return mockAsistencias.where((a) {
        var ok = true;
        if (project != null && project.isNotEmpty) {
          ok = ok && a.project == project;
        }
        if (date != null) {
          ok =
              ok &&
              a.date.year == date.year &&
              a.date.month == date.month &&
              a.date.day == date.day;
        }
        return ok;
      }).toList();
    }

    final db = await _openDb();
    final rows = await db
        .query('asistencias', orderBy: 'date DESC')
        .timeout(const Duration(seconds: 3));
    final list = rows.map((r) {
      try {
        return AsistenciaItem.fromJson(r);
      } catch (e) {
        throw FormatException('Invalid asistencia in filter: $r, error: $e');
      }
    }).toList();
    return list.where((a) {
      var ok = true;
      if (project != null && project.isNotEmpty) {
        ok = ok && a.project == project;
      }
      if (date != null) {
        ok =
            ok &&
            a.date.year == date.year &&
            a.date.month == date.month &&
            a.date.day == date.day;
      }
      return ok;
    }).toList();
  } catch (e) {
    // Fall back to in-memory filtering if database fails
    return mockAsistencias.where((a) {
      var ok = true;
      if (project != null && project.isNotEmpty) {
        ok = ok && a.project == project;
      }
      if (date != null) {
        ok =
            ok &&
            a.date.year == date.year &&
            a.date.month == date.month &&
            a.date.day == date.day;
      }
      return ok;
    }).toList();
  }
}

// ==================== PROJECTS AND WORKERS PERSISTENCE ====================
class WorkerItem {
  String name;
  String qr;
  WorkerItem(this.name, this.qr);
  Map<String, dynamic> toJson() => {'name': name, 'qr': qr};
  static WorkerItem fromJson(Map<String, dynamic> j) {
    try {
      return WorkerItem(
        j['name'] as String? ?? 'Sin nombre',
        j['qr'] as String? ?? '',
      );
    } catch (e) {
      throw FormatException('Error parsing WorkerItem: $e');
    }
  }
}

final List<String> mockProjects = [
  'Proyecto Norte',
  'Obra Sur',
  'Mantenimiento Central',
  'Planta Este',
];

List<WorkerItem> mockWorkers = [
  WorkerItem('Juan Perez', 'employee:Juan Perez'),
  WorkerItem('María López', 'employee:María López'),
  WorkerItem('Carlos Ruiz', 'employee:Carlos Ruiz'),
];

Future<void> saveProjectsAndWorkers() async {
  // On web, there's no persistent database, so just skip
  if (kIsWeb) {
    return;
  }

  try {
    final db = await _openDb();
    await db.transaction((txn) async {
      await txn.delete('projects');
      await txn.delete('workers');
      for (final p in mockProjects) {
        await txn.insert('projects', {
          'name': p,
          'qr': 'project:$p',
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final w in mockWorkers) {
        await txn.insert(
          'workers',
          w.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  } catch (e) {
    // Silently ignore save errors on non-web platforms
    return;
  }
}

Future<void> loadProjectsAndWorkers() async {
  try {
    final db = await _openDb();

    // Load projects
    try {
      final pRows = await db
          .query('projects')
          .timeout(const Duration(seconds: 2));
      if (pRows.isNotEmpty) {
        mockProjects.clear();
        for (final r in pRows) {
          final name = r['name'] as String?;
          if (name != null && name.isNotEmpty) {
            mockProjects.add(name);
          }
        }
      } else {
        try {
          await saveProjectsAndWorkers();
        } catch (_) {
          // Ignore save errors
        }
      }
    } catch (_) {
      // Keep defaults if load fails
    }

    // Load workers
    try {
      final wRows = await db
          .query('workers')
          .timeout(const Duration(seconds: 2));
      if (wRows.isNotEmpty) {
        final parsedWorkers = <WorkerItem>[];
        for (final r in wRows) {
          try {
            parsedWorkers.add(WorkerItem.fromJson(r));
          } catch (e) {
            // Skip invalid rows
            continue;
          }
        }
        if (parsedWorkers.isNotEmpty) {
          mockWorkers = parsedWorkers;
        }
      }
    } catch (_) {
      // Keep defaults if load fails
    }
  } catch (e) {
    // Keep existing mock data, don't throw
    return;
  }
}
