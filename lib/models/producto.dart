class Producto {
  int? id;
  String nombre;
  String? descripcion;
  double precio;
  int stock;
  String? imagenUrl;
  int categoriaId;
  String fechaCreacion;
  String? remoteId;
  String? source;
  String? syncedAt;
  int isLocalEdited;

  String? categoriaNombre;
  String? categoriaColor;

  Producto({
    this.id,
    required this.nombre,
    this.descripcion,
    required this.precio,
    required this.stock,
    this.imagenUrl,
    required this.categoriaId,
    required this.fechaCreacion,
    this.categoriaNombre,
    this.categoriaColor,
    this.remoteId,
    this.source,
    this.syncedAt,
    this.isLocalEdited = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'stock': stock,
      'imagenUrl': imagenUrl,
      'categoriaId': categoriaId,
      'fechaCreacion': fechaCreacion,
      'remoteId': remoteId,
      'source': source,
      'syncedAt': syncedAt,
      'isLocalEdited': isLocalEdited,
    };
  }

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String?,
      precio: (map['precio'] as num).toDouble(),
      stock: map['stock'] as int,
      imagenUrl: map['imagenUrl'] as String?,
      categoriaId: map['categoriaId'] as int,
      fechaCreacion: map['fechaCreacion'] as String,
      categoriaNombre: map['categoriaNombre'] as String?,
      categoriaColor: map['categoriaColor'] as String?,
      remoteId: map['remoteId'] as String?,
      source: map['source'] as String?,
      syncedAt: map['syncedAt'] as String?,
      isLocalEdited: (map['isLocalEdited'] as int?) ?? 0,
    );
  }

  String get stockLabel {
    if (stock <= 0) return 'Agotado';
    if (stock <= 10) return 'Bajo stock';
    return 'Disponible';
  }
}
