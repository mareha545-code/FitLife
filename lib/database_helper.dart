
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;

    final ruta = join(
      await getDatabasesPath(),
      'fitlife.db',
    );

    _database = await openDatabase(
      ruta,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE entrenamientos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            fecha TEXT NOT NULL,
            duracion INTEGER NOT NULL,
            pasos INTEGER NOT NULL,
            distancia REAL NOT NULL,
            ruta TEXT NOT NULL
          )
        ''');
      },
    );

    return _database!;
  }

  // GUARDAR ENTRENAMIENTO
  static Future<int> guardarEntrenamiento({
    required String fecha,
    required int duracion,
    required int pasos,
    required double distancia,
    required String ruta,
  }) async {
    final db = await database;

    return await db.insert(
      'entrenamientos',
      {
        'fecha': fecha,
        'duracion': duracion,
        'pasos': pasos,
        'distancia': distancia,
        'ruta': ruta,
      },
    );
  }

  // CONSULTAR HISTORIAL
  static Future<List<Map<String, dynamic>>>
  obtenerEntrenamientos() async {
    final db = await database;

    return await db.query(
      'entrenamientos',
      orderBy: 'id DESC',
    );
  }

  // ELIMINAR ENTRENAMIENTO
  static Future<int> eliminarEntrenamiento(
      int id) async {
    final db = await database;

    return await db.delete(
      'entrenamientos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
