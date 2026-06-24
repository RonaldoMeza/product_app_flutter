import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('product_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, filePath);
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categorias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        descripcion TEXT,
        color TEXT,
        remoteId TEXT,
        source TEXT,
        syncedAt TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE productos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        descripcion TEXT,
        precio REAL NOT NULL,
        stock INTEGER NOT NULL,
        imagenUrl TEXT,
        categoriaId INTEGER NOT NULL,
        fechaCreacion TEXT NOT NULL,
        remoteId TEXT,
        source TEXT,
        syncedAt TEXT,
        isLocalEdited INTEGER DEFAULT 0,
        FOREIGN KEY (categoriaId) REFERENCES categorias(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      for (final col in [
        'ALTER TABLE categorias ADD COLUMN remoteId TEXT',
        'ALTER TABLE categorias ADD COLUMN source TEXT',
        'ALTER TABLE categorias ADD COLUMN syncedAt TEXT',
        'ALTER TABLE productos ADD COLUMN remoteId TEXT',
        'ALTER TABLE productos ADD COLUMN source TEXT',
        'ALTER TABLE productos ADD COLUMN syncedAt TEXT',
        'ALTER TABLE productos ADD COLUMN isLocalEdited INTEGER DEFAULT 0',
      ]) {
        try {
          await db.execute(col);
        } catch (_) {}
      }
    }
  }

  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
