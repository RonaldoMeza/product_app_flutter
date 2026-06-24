import '../database/db_helper.dart';
import '../models/producto.dart';

class ProductoRepository {
  final DBHelper _db = DBHelper.instance;

  Future<List<Producto>> getAll() async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT p.*, c.nombre as categoriaNombre, c.color as categoriaColor
      FROM productos p
      INNER JOIN categorias c ON p.categoriaId = c.id
      ORDER BY p.fechaCreacion DESC
    ''');
    return maps.map((map) => Producto.fromMap(map)).toList();
  }

  Future<Producto?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT p.*, c.nombre as categoriaNombre, c.color as categoriaColor
      FROM productos p
      INNER JOIN categorias c ON p.categoriaId = c.id
      WHERE p.id = ?
    ''', [id]);
    if (maps.isNotEmpty) return Producto.fromMap(maps.first);
    return null;
  }

  Future<int> insert(Producto producto) async {
    final db = await _db.database;
    return await db.insert('productos', producto.toMap());
  }

  Future<int> update(Producto producto) async {
    final db = await _db.database;
    final data = producto.toMap();
    if (producto.source == 'dummyjson') {
      data['isLocalEdited'] = 1;
    }
    return await db.update(
      'productos',
      data,
      where: 'id = ?',
      whereArgs: [producto.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.delete('productos', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Producto>> search(String query) async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT p.*, c.nombre as categoriaNombre, c.color as categoriaColor
      FROM productos p
      INNER JOIN categorias c ON p.categoriaId = c.id
      WHERE p.nombre LIKE ? OR p.descripcion LIKE ?
      ORDER BY p.fechaCreacion DESC
    ''', ['%$query%', '%$query%']);
    return maps.map((map) => Producto.fromMap(map)).toList();
  }

  Future<List<Producto>> getByCategoria(int categoriaId) async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT p.*, c.nombre as categoriaNombre, c.color as categoriaColor
      FROM productos p
      INNER JOIN categorias c ON p.categoriaId = c.id
      WHERE p.categoriaId = ?
      ORDER BY p.fechaCreacion DESC
    ''', [categoriaId]);
    return maps.map((map) => Producto.fromMap(map)).toList();
  }

  Future<List<Producto>> getBajoStock({int threshold = 10}) async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT p.*, c.nombre as categoriaNombre, c.color as categoriaColor
      FROM productos p
      INNER JOIN categorias c ON p.categoriaId = c.id
      WHERE p.stock <= ?
      ORDER BY p.stock ASC
    ''', [threshold]);
    return maps.map((map) => Producto.fromMap(map)).toList();
  }

  Future<int> getTotal() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM productos');
    return (result.first['count'] as int?) ?? 0;
  }

  Future<double> getValorTotalInventario() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(precio * stock), 0) as total FROM productos',
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<int> syncFromApi(
    List<Map<String, dynamic>> apiProducts,
    Map<String, int> categoryMapping,
  ) async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    int inserted = 0;

    for (final p in apiProducts) {
      final remoteId = p['id'].toString();
      final categorySlug = p['category'] as String;
      final categoriaId = categoryMapping[categorySlug];
      if (categoriaId == null) continue;

      final existing = await db.query(
        'productos',
        where: 'remoteId = ? AND source = ?',
        whereArgs: [remoteId, 'dummyjson'],
      );

      if (existing.isEmpty) {
        await db.insert('productos', {
          'nombre': p['title'] as String,
          'descripcion': p['description'] as String?,
          'precio': (p['price'] as num).toDouble(),
          'stock': (p['stock'] as num?)?.toInt() ?? 0,
          'imagenUrl': p['thumbnail'] as String?,
          'categoriaId': categoriaId,
          'fechaCreacion': now,
          'remoteId': remoteId,
          'source': 'dummyjson',
          'syncedAt': now,
          'isLocalEdited': 0,
        });
        inserted++;
      } else {
        final existingId = existing.first['id'] as int;
        final isLocalEdited = (existing.first['isLocalEdited'] as int?) ?? 0;

        if (isLocalEdited == 0) {
          await db.update(
            'productos',
            {
              'nombre': p['title'] as String,
              'descripcion': p['description'] as String?,
              'precio': (p['price'] as num).toDouble(),
              'stock': (p['stock'] as num?)?.toInt() ?? 0,
              'imagenUrl': p['thumbnail'] as String?,
              'syncedAt': now,
            },
            where: 'id = ?',
            whereArgs: [existingId],
          );
        }
      }
    }
    return inserted;
  }

  Future<String?> getLastSyncAt() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      "SELECT MAX(syncedAt) as lastSync FROM productos WHERE source = 'dummyjson'",
    );
    return result.first['lastSync'] as String?;
  }

  Future<int> countImported() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM productos WHERE source = 'dummyjson'",
    );
    return (result.first['count'] as int?) ?? 0;
  }
}
