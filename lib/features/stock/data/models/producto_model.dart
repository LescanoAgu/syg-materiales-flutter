import 'package:equatable/equatable.dart';

class ProductoModel extends Equatable {
  final String? id;
  final String codigo;
  final String categoriaId;
  final String? categoriaNombre;
  final String nombre;
  final String unidadBase;
  final double? precioSinIva;
  final double cantidadDisponible;
  final String estado;

  const ProductoModel({
    this.id,
    required this.codigo,
    required this.categoriaId,
    this.categoriaNombre,
    required this.nombre,
    required this.unidadBase,
    this.precioSinIva,
    this.cantidadDisponible = 0,
    this.estado = 'activo',
  });

  // ✅ CORRECCIÓN: Acepta (Map, String) para compatibilidad con Repository
  factory ProductoModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductoModel(
      id: id,
      codigo: map['codigo'] ?? '',
      categoriaId: map['categoriaId'] ?? '',
      categoriaNombre: map['categoriaNombre'],
      nombre: map['nombre'] ?? '',
      unidadBase: map['unidadBase'] ?? 'u',
      precioSinIva: (map['precioSinIva'] as num?)?.toDouble(),
      cantidadDisponible: (map['cantidadDisponible'] as num?)?.toDouble() ?? 0,
      estado: map['estado'] ?? 'activo',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'codigo': codigo,
      'categoriaId': categoriaId,
      'categoriaNombre': categoriaNombre,
      'nombre': nombre,
      'unidadBase': unidadBase,
      'precioSinIva': precioSinIva,
      'cantidadDisponible': cantidadDisponible,
      'estado': estado,
    };
  }

  String get cantidadFormateada =>
      cantidadDisponible % 1 == 0 ? cantidadDisponible.toInt().toString() : cantidadDisponible.toStringAsFixed(2);

  @override
  List<Object?> get props => [id, codigo, nombre, cantidadDisponible];
}