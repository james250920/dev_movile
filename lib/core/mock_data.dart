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

  static RendicionItem fromJson(Map<String, dynamic> json) => RendicionItem(
    DateTime.parse(json['date'] as String),
    json['description'] as String,
    (json['amount'] as num).toDouble(),
    type: json['type'] as String? ?? 'otros',
    status: json['status'] as String? ?? 'borrador',
    invoiceNumber: json['invoiceNumber'] as String? ?? '',
    supplier: json['supplier'] as String? ?? '',
    imageBase64: json['imageBase64'] as String?,
  );
}

class TareoItem {
  final DateTime date;
  final String task;
  final double hours;

  TareoItem(this.date, this.task, this.hours);
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

  static AsistenciaItem fromJson(Map<String, dynamic> json) => AsistenciaItem(
    DateTime.parse(json['date'] as String),
    json['name'] as String,
    present: (json['present'] as num?)?.toInt() == 1,
    project: json['project'] as String? ?? '',
    checkInTime: json['checkInTime'] == null
        ? null
        : DateTime.parse(json['checkInTime'] as String),
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    locationLabel: json['locationLabel'] as String?,
  );
}

// Mock list (in-memory). Persistence via SQLite (sqflite).
List<RendicionItem> mockRendiciones = [];

Future<Database> _openDb() async {
  final dbPath = await getDatabasesPath();
  final pathDb = join(dbPath, 'rendiciones.db');
  return openDatabase(
    pathDb,
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''
      CREATE TABLE rendiciones(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        description TEXT,
        amount REAL,
        type TEXT,
        status TEXT,
        invoiceNumber TEXT,
        supplier TEXT,
        imageBase64 TEXT
      )
    ''');
    },
  );
}

Future<void> saveRendiciones() async {
  final db = await _openDb();
  final batch = db.batch();
  await db.delete('rendiciones');
  for (final r in mockRendiciones) {
    batch.insert('rendiciones', r.toJson());
  }
  await batch.commit(noResult: true);
}

Future<void> loadRendiciones() async {
  final db = await _openDb();
  final rows = await db.query('rendiciones', orderBy: 'date DESC');
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
  mockRendiciones = rows.map((r) => RendicionItem.fromJson(r)).toList();
}

final List<TareoItem> mockTareos = [
  TareoItem(DateTime.now(), 'Inspección de equipo', 2.5),
  TareoItem(DateTime.now(), 'Instalación', 4.0),
];

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

const List<String> mockProjects = [
  'Proyecto Norte',
  'Obra Sur',
  'Mantenimiento Central',
  'Planta Este',
];

Future<Database> _openAttendanceDb() async {
  final dbPath = await getDatabasesPath();
  final pathDb = join(dbPath, 'asistencias.db');
  return openDatabase(
    pathDb,
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''
      CREATE TABLE asistencias(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        name TEXT,
        present INTEGER,
        project TEXT,
        checkInTime TEXT,
        latitude REAL,
        longitude REAL,
        locationLabel TEXT
      )
    ''');
      await db.execute('''
      CREATE TABLE projects(
        name TEXT PRIMARY KEY,
        qr TEXT
      )
    ''');
      await db.execute('''
      CREATE TABLE workers(
        name TEXT PRIMARY KEY,
        qr TEXT
      )
    ''');
    },
  );
}

Future<void> saveAsistencias() async {
  final db = await _openAttendanceDb();
  final batch = db.batch();
  await db.delete('asistencias');
  for (final a in mockAsistencias) {
    batch.insert('asistencias', a.toJson());
  }
  await batch.commit(noResult: true);
}

Future<void> loadAsistencias() async {
  final db = await _openAttendanceDb();
  final rows = await db.query('asistencias', orderBy: 'date DESC');
  if (rows.isEmpty) {
    await saveAsistencias();
    return;
  }
  mockAsistencias
    ..clear()
    ..addAll(rows.map((row) => AsistenciaItem.fromJson(row)));
}

Future<List<AsistenciaItem>> getAsistenciasFiltered({
  DateTime? date,
  String? project,
}) async {
  final db = await _openAttendanceDb();
  final rows = await db.query('asistencias', orderBy: 'date DESC');
  final list = rows.map((r) => AsistenciaItem.fromJson(r)).toList();
  return list.where((a) {
    var ok = true;
    if (project != null && project.isNotEmpty) ok = ok && a.project == project;
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

// Projects and workers tables (simple QR content storage)
class WorkerItem {
  String name;
  String qr;
  WorkerItem(this.name, this.qr);
  Map<String, dynamic> toJson() => {'name': name, 'qr': qr};
  static WorkerItem fromJson(Map<String, dynamic> j) =>
      WorkerItem(j['name'] as String, j['qr'] as String);
}

List<WorkerItem> mockWorkers = [
  WorkerItem('Juan Perez', 'employee:Juan Perez'),
  WorkerItem('María López', 'employee:María López'),
  WorkerItem('Carlos Ruiz', 'employee:Carlos Ruiz'),
];

Future<void> _ensureProjectWorkerTables(Database db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS projects(
      name TEXT PRIMARY KEY,
      qr TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE IF NOT EXISTS workers(
      name TEXT PRIMARY KEY,
      qr TEXT
    )
  ''');
}

Future<void> saveProjectsAndWorkers() async {
  final db = await _openAttendanceDb();
  await _ensureProjectWorkerTables(db);
  final batch = db.batch();
  await db.delete('projects');
  await db.delete('workers');
  for (final p in mockProjects) {
    batch.insert('projects', {'name': p, 'qr': 'project:$p'});
  }
  for (final w in mockWorkers) {
    batch.insert('workers', w.toJson());
  }
  await batch.commit(noResult: true);
}

Future<void> loadProjectsAndWorkers() async {
  final db = await _openAttendanceDb();
  await _ensureProjectWorkerTables(db);
  final pRows = await db.query('projects');
  if (pRows.isNotEmpty) {
    mockProjects.clear();
    for (final r in pRows) {
      mockProjects.add(r['name'] as String);
    }
  } else {
    await saveProjectsAndWorkers();
  }
  final wRows = await db.query('workers');
  if (wRows.isNotEmpty) {
    mockWorkers = wRows.map((r) => WorkerItem.fromJson(r)).toList();
  }
}
