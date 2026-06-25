import '../database/db_helper.dart';
import '../models/categoria.dart';

class CategoriaRepository {
  final DBHelper _db = DBHelper.instance;

  Future<List<Categoria>> getAll() async {
    final db = await _db.database;
    final maps = await db.query('categorias', orderBy: 'nombre ASC');
    return maps.map((map) => Categoria.fromMap(map)).toList();
  }

  Future<Categoria?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query('categorias', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Categoria.fromMap(maps.first);
    return null;
  }

  Future<int> insert(Categoria categoria) async {
    final db = await _db.database;
    return await db.insert('categorias', categoria.toMap());
  }

  Future<int> update(Categoria categoria) async {
    final db = await _db.database;
    return await db.update(
      'categorias',
      categoria.toMap(),
      where: 'id = ?',
      whereArgs: [categoria.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    await db.delete('productos', where: 'categoriaId = ?', whereArgs: [id]);
    return await db.delete('categorias', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> hasProducts(int id) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM productos WHERE categoriaId = ?',
      [id],
    );
    return (result.first['count'] as int? ?? 0) > 0;
  }

  Future<Map<String, int>> getRemoteIdMapping() async {
    final db = await _db.database;
    final maps = await db.query(
      'categorias',
      where: 'source = ?',
      whereArgs: ['dummyjson'],
    );
    return {for (final m in maps) m['remoteId'] as String: m['id'] as int};
  }

  Future<int> syncFromApi(List<Map<String, dynamic>> apiCategories) async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    int inserted = 0;

    for (final cat in apiCategories) {
      final slug = cat['slug'] as String;
      final name = cat['name'] as String;

      final existing = await db.query(
        'categorias',
        where: 'remoteId = ? AND source = ?',
        whereArgs: [slug, 'dummyjson'],
      );

      if (existing.isEmpty) {
        await db.insert('categorias', {
          'nombre': name,
          'descripcion': name,
          'color': null,
          'remoteId': slug,
          'source': 'dummyjson',
          'syncedAt': now,
        });
        inserted++;
      } else {
        await db.update(
          'categorias',
          {'nombre': name, 'descripcion': name, 'syncedAt': now},
          where: 'id = ?',
          whereArgs: [existing.first['id']],
        );
      }
    }
    return inserted;
  }

  Future<String?> getLastSyncAt() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      "SELECT MAX(syncedAt) as lastSync FROM categorias WHERE source = 'dummyjson'",
    );
    return result.first['lastSync'] as String?;
  }

  Future<int> countImported() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM categorias WHERE source = 'dummyjson'",
    );
    return (result.first['count'] as int?) ?? 0;
  }
}
