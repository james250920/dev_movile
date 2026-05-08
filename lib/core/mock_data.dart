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

  RendicionItem(
    this.date,
    this.description,
    this.amount, {
    this.type = 'otros',
    this.status = 'borrador',
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'description': description,
    'amount': amount,
    'type': type,
    'status': status,
  };

  static RendicionItem fromJson(Map<String, dynamic> json) => RendicionItem(
    DateTime.parse(json['date'] as String),
    json['description'] as String,
    (json['amount'] as num).toDouble(),
    type: json['type'] as String? ?? 'otros',
    status: json['status'] as String? ?? 'borrador',
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
  final String name;
  bool present;

  AsistenciaItem(this.date, this.name, {this.present = false});
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
        status TEXT
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
      ),
      RendicionItem(
        DateTime.now().subtract(const Duration(days: 1)),
        'Transporte',
        45.00,
        type: 'viaticos',
        status: 'borrador',
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
  AsistenciaItem(DateTime.now(), 'Juan Perez', present: true),
  AsistenciaItem(DateTime.now(), 'María López', present: false),
  AsistenciaItem(DateTime.now(), 'Carlos Ruiz', present: true),
];
