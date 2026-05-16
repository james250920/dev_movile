import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Representa una línea individual de gasto dentro de una rendición
class RendicionLineItem {
  DateTime date;
  String description;
  double amount;
  String category; // 'cargo' o 'viaticos'

  RendicionLineItem(
    this.date,
    this.description,
    this.amount, {
    this.category = '',
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'description': description,
    'amount': amount,
    'category': category,
  };

  static RendicionLineItem fromJson(Map<String, dynamic> json) {
    try {
      return RendicionLineItem(
        DateTime.parse(json['date'] as String),
        json['description'] as String? ?? '',
        (json['amount'] as num?)?.toDouble() ?? 0.0,
        category: json['category'] as String? ?? '',
      );
    } catch (e) {
      throw FormatException('Error parsing RendicionLineItem: $e');
    }
  }
}

/// Contenedor que agrupa múltiples líneas de rendición bajo un correlativo
class RendicionContainer {
  String correlative;
  List<RendicionLineItem> items;
  String category; // 'cargo' o 'viaticos' (del primer item)
  DateTime dateCreated;

  /// Estado del contenedor: 'borrador', 'enviado', 'aprobado', 'rechazado'
  String status;

  RendicionContainer({
    required this.correlative,
    this.items = const [],
    this.category = '',
    DateTime? dateCreated,
    this.status = 'borrador',
  }) : dateCreated = dateCreated ?? DateTime.now();

  /// Monto total del contenedor
  double get totalAmount => items.fold(0.0, (sum, item) => sum + item.amount);

  /// Descripción resumida
  String get description {
    if (items.isEmpty) return 'Rendición $correlative';
    if (items.length == 1) return items.first.description;
    return '${items.first.description} +${items.length - 1} más';
  }

  /// Agregar un nuevo item
  void addItem(RendicionLineItem item) {
    if (items.isEmpty && category.isEmpty) {
      category = item.category;
    }
    items.add(item);
  }

  /// Eliminar un item por índice
  void removeItem(int index) {
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
    }
  }

  /// Serializar para persistencia
  Map<String, dynamic> toJson() => {
    'correlative': correlative,
    'category': category,
    'dateCreated': dateCreated.toIso8601String(),
    'status': status,
    'items': items.map((item) => item.toJson()).toList(),
  };

  static RendicionContainer fromJson(Map<String, dynamic> json) {
    try {
      final itemsList =
          (json['items'] as List?)
              ?.map(
                (item) =>
                    RendicionLineItem.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [];

      return RendicionContainer(
        correlative: json['correlative'] as String? ?? '',
        items: itemsList,
        category: json['category'] as String? ?? '',
        dateCreated: json['dateCreated'] != null
            ? DateTime.parse(json['dateCreated'] as String)
            : DateTime.now(),
        status: json['status'] as String? ?? 'borrador',
      );
    } catch (e) {
      throw FormatException('Error parsing RendicionContainer: $e');
    }
  }

  /// Compatibilidad con RendicionItem antiguo (para migración)
  @Deprecated('Use fromContainer() instead')
  static RendicionContainer fromLegacyItem(RendicionItem item) {
    return RendicionContainer(
      correlative: item.correlative,
      items: [
        RendicionLineItem(
          item.date,
          item.description,
          item.amount,
          category: item.category,
        ),
      ],
      category: item.category,
      dateCreated: item.date,
      status: item.status,
    );
  }
}

/// Clase heredada para mantener compatibilidad transitoria
@Deprecated('Use RendicionContainer and RendicionLineItem instead')
class RendicionItem {
  DateTime date;
  String description;
  double amount;
  String correlative;
  String category;
  String status;

  RendicionItem(
    this.date,
    this.description,
    this.amount, {
    this.correlative = '',
    this.category = '',
    this.status = 'borrador',
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'description': description,
    'amount': amount,
    'correlative': correlative,
    'category': category,
    'status': status,
  };

  static RendicionItem fromJson(Map<String, dynamic> json) {
    try {
      return RendicionItem(
        DateTime.parse(json['date'] as String),
        json['description'] as String? ?? '',
        (json['amount'] as num?)?.toDouble() ?? 0.0,
        correlative: json['correlative'] as String? ?? '',
        category: json['category'] as String? ?? '',
        status: json['status'] as String? ?? 'borrador',
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
// Version: 2 (for future migrations)

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
      version: 2,
      onCreate: _createSchema,
      onUpgrade: _upgradeSchema,
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
      correlative TEXT,
      type TEXT NOT NULL,
      status TEXT NOT NULL,
      invoiceNumber TEXT,
      supplier TEXT,
      imageBase64 TEXT,
      costCenter TEXT,
      project TEXT,
      origin TEXT,
      destination TEXT,
      startDate TEXT,
      endDate TEXT,
      travelType TEXT,
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

Future<void> _upgradeSchema(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    await db.execute('ALTER TABLE rendiciones ADD COLUMN correlative TEXT');
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
// Mantiene RendicionItem para compatibilidad, se agrupa en contenedores en UI
List<RendicionItem> mockRendiciones = [];

/// Agrupa items en contenedores por correlativo
List<RendicionContainer> getRendicionContainers() {
  final Map<String, List<RendicionItem>> grouped = {};

  for (final item in mockRendiciones) {
    final key = item.correlative.isEmpty ? 'new' : item.correlative;
    grouped.putIfAbsent(key, () => []).add(item);
  }

  return grouped.entries
      .map(
        (entry) => RendicionContainer(
          correlative: entry.key,
          items: entry.value
              .map(
                (item) => RendicionLineItem(
                  item.date,
                  item.description,
                  item.amount,
                  category: item.category,
                ),
              )
              .toList(),
          category: entry.value.isNotEmpty ? entry.value.first.category : '',
          dateCreated: entry.value.isNotEmpty
              ? entry.value.first.date
              : DateTime.now(),
          status: entry.value.isNotEmpty
              ? entry.value.first.status
              : 'borrador',
        ),
      )
      .toList()
    ..sort((a, b) => b.dateCreated.compareTo(a.dateCreated));
}

String _formatCorrelative(int value) => value.toString().padLeft(3, '0');

bool _isValidCorrelative(String value) => RegExp(r'^\d{3}$').hasMatch(value);

void _normalizeRendicionCorrelatives(List<RendicionItem> items) {
  final used = <int>{};

  for (final item in items) {
    if (_isValidCorrelative(item.correlative)) {
      used.add(int.parse(item.correlative));
    }
  }

  var next = 0;
  for (final item in items) {
    if (_isValidCorrelative(item.correlative)) {
      continue;
    }

    while (used.contains(next)) {
      next++;
    }

    item.correlative = _formatCorrelative(next);
    used.add(next);
    next++;
  }
}

String nextRendicionCorrelative() {
  var maxValue = -1;
  for (final item in mockRendiciones) {
    if (_isValidCorrelative(item.correlative)) {
      final value = int.parse(item.correlative);
      if (value > maxValue) {
        maxValue = value;
      }
    }
  }

  return _formatCorrelative(maxValue + 1);
}

List<RendicionItem> rendicionesByCorrelative(String correlative) {
  return mockRendiciones
      .where((item) => item.correlative == correlative)
      .toList();
}

/// Obtener contenedor por correlativo
RendicionContainer? getRendicionContainer(String correlative) {
  final containers = getRendicionContainers();
  try {
    return containers.firstWhere((c) => c.correlative == correlative);
  } catch (_) {
    return null;
  }
}

void updateRendicionesByCorrelative(String correlative, String status) {
  for (final item in mockRendiciones) {
    if (item.correlative == correlative) {
      item.status = status;
    }
  }
}

/// Agregar un nuevo item a un contenedor existente
void addItemToContainer(String correlative, RendicionLineItem lineItem) {
  final newItem = RendicionItem(
    lineItem.date,
    lineItem.description,
    lineItem.amount,
    correlative: correlative,
    category: lineItem.category,
    status: 'borrador',
  );
  mockRendiciones.add(newItem);
}

/// Eliminar un item específico del contenedor
void removeItemFromContainer(String correlative, int itemIndex) {
  final items = rendicionesByCorrelative(correlative);
  if (itemIndex >= 0 && itemIndex < items.length) {
    mockRendiciones.remove(items[itemIndex]);
  }
}

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
          correlative: '000',
          category: 'cargo',
          status: 'aprobado',
        ),
        RendicionItem(
          DateTime.now().subtract(const Duration(days: 1)),
          'Transporte',
          45.00,
          correlative: '001',
          category: 'viaticos',
          status: 'borrador',
        ),
      ];
      _normalizeRendicionCorrelatives(mockRendiciones);
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
    _normalizeRendicionCorrelatives(mockRendiciones);
    await saveRendiciones();
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
