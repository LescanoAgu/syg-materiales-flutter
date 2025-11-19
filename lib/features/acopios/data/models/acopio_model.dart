import 'package:equatable/equatable.dart';

class AcopioModel extends Equatable {
  final String? id;
  final String productoId;
  final String clienteId;
  final String proveedorId;
  final double cantidadDisponible;
  final String estado;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AcopioModel({
    this.id,
    required this.productoId,
    required this.clienteId,
    required this.proveedorId,
    required this.cantidadDisponible,
    this.estado = 'activo',
    required this.createdAt,
    this.updatedAt,
  });

  factory AcopioModel.fromMap(Map<String, dynamic> map) {
    return AcopioModel(
      id: map['id']?.toString(),
      productoId: map['productoId']?.toString() ?? '',
      clienteId: map['clienteId']?.toString() ?? '',
      proveedorId: map['proveedorId']?.toString() ?? '',
      cantidadDisponible: (map['cantidadDisponible'] as num?)?.toDouble() ?? 0.0,
      estado: map['estado']?.toString() ?? 'activo',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'].toString()) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() => {}; // Implementar si necesario

  @override
  List<Object?> get props => [id, productoId];
}

class AcopioDetalle extends Equatable {
  final AcopioModel acopio;
  final String productoCodigo;
  final String productoNombre;
  final String unidadBase;
  final String categoriaNombre;
  final String clienteRazonSocial;
  final String proveedorNombre;
  final String proveedorTipo;

  // Campos opcionales que faltaban en la definición anterior
  final String clienteCodigo;
  final String proveedorCodigo;

  const AcopioDetalle({
    required this.acopio,
    required this.productoCodigo,
    required this.productoNombre,
    required this.unidadBase,
    required this.categoriaNombre,
    required this.clienteRazonSocial,
    required this.proveedorNombre,
    required this.proveedorTipo,
    this.clienteCodigo = '',
    this.proveedorCodigo = '',
  });

  factory AcopioDetalle.fromMap(Map<String, dynamic> map) {
    return AcopioDetalle(
      acopio: AcopioModel.fromMap(map),
      productoCodigo: map['productoCodigo']?.toString() ?? '',
      productoNombre: map['productoNombre']?.toString() ?? '',
      unidadBase: map['unidadBase']?.toString() ?? '',
      categoriaNombre: map['categoriaNombre']?.toString() ?? '',
      clienteRazonSocial: map['clienteRazonSocial']?.toString() ?? '',
      proveedorNombre: map['proveedorNombre']?.toString() ?? '',
      proveedorTipo: map['proveedorTipo']?.toString() ?? 'proveedor',
      // Recuperamos códigos si existen desnormalizados
      clienteCodigo: map['clienteCodigo']?.toString() ?? '',
      proveedorCodigo: map['proveedorCodigo']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [acopio];

  bool get esDepositoSyg => proveedorTipo == 'deposito_syg';
  String get cantidadFormateada => acopio.cantidadDisponible.toStringAsFixed(2);
}