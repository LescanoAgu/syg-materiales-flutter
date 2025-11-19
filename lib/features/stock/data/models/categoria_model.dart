/// Modelo de datos para Categorías
class CategoriaModel {
  final String? id; // CAMBIO: String?
  final String codigo;
  final String nombre;
  final String? descripcion;
  final int orden;
  final String? createdAt;

  CategoriaModel({
    this.id,
    required this.codigo,
    required this.nombre,
    this.descripcion,
    required this.orden,
    this.createdAt,
  });

  factory CategoriaModel.fromMap(Map<String, dynamic> map) {
    return CategoriaModel(
      // CORRECCIÓN: Casting seguro a String
      id: map['id']?.toString(),
      codigo: map['codigo']?.toString() ?? '',
      nombre: map['nombre']?.toString() ?? '',
      descripcion: map['descripcion']?.toString(),
      orden: map['orden'] as int? ?? 0,
      createdAt: map['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'codigo': codigo,
      'nombre': nombre,
      'descripcion': descripcion,
      'orden': orden,
      'created_at': createdAt,
    };
  }

  CategoriaModel copyWith({
    String? id, // CAMBIO: String?
    String? codigo,
    String? nombre,
    String? descripcion,
    int? orden,
    String? createdAt,
  }) {
    return CategoriaModel(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      orden: orden ?? this.orden,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'CategoriaModel(id: $id, codigo: $codigo, nombre: $nombre)';
  }
}