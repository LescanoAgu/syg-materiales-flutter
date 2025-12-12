class CategoriaModel {
  final String? id;
  final String codigo; // ID interno (ej: AGUA)
  final String nombre; // Nombre visible (ej: Agua)
  final String prefijo; // ✅ NUEVO: La letra clave (ej: "A", "G", "AR")
  final String? descripcion;
  final int orden;
  final String? createdAt;

  CategoriaModel({
    this.id,
    required this.codigo,
    required this.nombre,
    this.prefijo = '', // Por defecto vacío
    this.descripcion,
    required this.orden,
    this.createdAt,
  });

  factory CategoriaModel.fromMap(Map<String, dynamic> map) {
    return CategoriaModel(
      id: map['id']?.toString(),
      codigo: map['codigo']?.toString() ?? '',
      nombre: map['nombre']?.toString() ?? '',
      prefijo: map['prefijo']?.toString() ?? '', // ✅ Leemos el prefijo
      descripcion: map['descripcion']?.toString(),
      orden: map['orden'] as int? ?? 0,
      createdAt: map['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'codigo': codigo,
      'nombre': nombre,
      'prefijo': prefijo, // ✅ Guardamos el prefijo
      'descripcion': descripcion,
      'orden': orden,
      'created_at': createdAt,
    };
  }

  CategoriaModel copyWith({
    String? id,
    String? codigo,
    String? nombre,
    String? prefijo,
    String? descripcion,
    int? orden,
    String? createdAt,
  }) {
    return CategoriaModel(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      prefijo: prefijo ?? this.prefijo,
      descripcion: descripcion ?? this.descripcion,
      orden: orden ?? this.orden,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'Cat: $nombre ($prefijo)';
}