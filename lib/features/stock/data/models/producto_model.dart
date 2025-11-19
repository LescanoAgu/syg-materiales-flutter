class ProductoModel {
  final String? id;
  final String codigo;
  final String categoriaId;
  final String nombre;
  final String? descripcion;
  final String unidadBase;
  final String? equivalencia;
  final double? precioSinIva;
  final String estado;
  final String? createdAt;
  final String? updatedAt;

  // Datos Desnormalizados (Stock incluido)
  final String? categoriaNombre;
  final String? categoriaCodigo;
  final double cantidadDisponible;

  ProductoModel({
    this.id,
    required this.codigo,
    required this.categoriaId,
    required this.nombre,
    this.descripcion,
    required this.unidadBase,
    this.equivalencia,
    this.precioSinIva,
    this.estado = 'activo',
    this.createdAt,
    this.updatedAt,
    this.categoriaNombre,
    this.categoriaCodigo,
    this.cantidadDisponible = 0.0,
  });

  factory ProductoModel.fromMap(Map<String, dynamic> map) {
    return ProductoModel(
      id: map['id']?.toString(),
      codigo: map['codigo']?.toString() ?? '',
      categoriaId: map['categoriaId']?.toString() ?? '',
      nombre: map['nombre']?.toString() ?? '',
      descripcion: map['descripcion']?.toString(),
      unidadBase: map['unidadBase']?.toString() ?? 'u',
      equivalencia: map['equivalencia']?.toString(),
      precioSinIva: (map['precioSinIva'] as num?)?.toDouble(),
      estado: map['estado']?.toString() ?? 'activo',
      createdAt: map['createdAt']?.toString(),
      updatedAt: map['updatedAt']?.toString(),
      categoriaNombre: map['categoriaNombre']?.toString(),
      categoriaCodigo: map['categoriaCodigo']?.toString(),
      cantidadDisponible: (map['cantidadDisponible'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'codigo': codigo,
      'categoriaId': categoriaId,
      'nombre': nombre,
      'descripcion': descripcion,
      'unidadBase': unidadBase,
      'equivalencia': equivalencia,
      'precioSinIva': precioSinIva,
      'estado': estado,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'categoriaNombre': categoriaNombre,
      'categoriaCodigo': categoriaCodigo,
      'cantidadDisponible': cantidadDisponible,
    };
  }

  // Getters de compatibilidad (para que no rompa la UI vieja)
  String get productoId => id ?? codigo;
  String get productoNombre => nombre;
  String get productoCodigo => codigo;

  String get cantidadFormateada => cantidadDisponible.toStringAsFixed(1).replaceAll('.0', '');
  String get precioFormateado => precioSinIva != null ? '\$${precioSinIva!.toStringAsFixed(2)}' : '-';
  String get unidadCompleta => equivalencia != null ? '$unidadBase ($equivalencia)' : unidadBase;

  bool get sinStock => cantidadDisponible <= 0;
  bool get stockBajo => cantidadDisponible > 0 && cantidadDisponible < 10;
}

// ALIAS MAESTRO: Esto arregla el error de tipos incompatibles
typedef ProductoConStock = ProductoModel;