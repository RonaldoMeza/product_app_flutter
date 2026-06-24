class Categoria {
  int? id;
  String nombre;
  String? descripcion;
  String? color;
  String? remoteId;
  String? source;
  String? syncedAt;

  Categoria({
    this.id,
    required this.nombre,
    this.descripcion,
    this.color,
    this.remoteId,
    this.source,
    this.syncedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'color': color,
      'remoteId': remoteId,
      'source': source,
      'syncedAt': syncedAt,
    };
  }

  factory Categoria.fromMap(Map<String, dynamic> map) {
    return Categoria(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String?,
      color: map['color'] as String?,
      remoteId: map['remoteId'] as String?,
      source: map['source'] as String?,
      syncedAt: map['syncedAt'] as String?,
    );
  }
}
