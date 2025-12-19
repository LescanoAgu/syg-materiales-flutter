import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class AcopioItem extends Equatable {
  final String productoId;
  final String nombreProducto; // Antes productoNombre
  final double cantidadTotalComprada;
  final double cantidadDisponible; // Antes cantidadRestante
  final String unidad;

  const AcopioItem({
    required this.productoId,
    required this.nombreProducto,
    required this.cantidadTotalComprada,
    required this.cantidadDisponible,
    this.unidad = 'u',
  });

  Map<String, dynamic> toMap() {
    return {
      'productoId': productoId,
      'nombreProducto': nombreProducto,
      'cantidadTotalComprada': cantidadTotalComprada,
      'cantidadDisponible': cantidadDisponible,
      'unidad': unidad,
    };
  }

  factory AcopioItem.fromMap(Map<String, dynamic> map) {
    return AcopioItem(
      productoId: map['productoId'] ?? '',
      nombreProducto: map['nombreProducto'] ?? map['productoNombre'] ?? '',
      cantidadTotalComprada: (map['cantidadTotalComprada'] as num?)?.toDouble() ?? 0.0,
      cantidadDisponible: (map['cantidadDisponible'] as num?)?.toDouble() ?? (map['cantidadRestante'] as num?)?.toDouble() ?? 0.0,
      unidad: map['unidad'] ?? 'u',
    );
  }

  // Método helper copyWith
  AcopioItem copyWith({double? cantidadDisponible}) {
    return AcopioItem(
      productoId: productoId,
      nombreProducto: nombreProducto,
      cantidadTotalComprada: cantidadTotalComprada,
      cantidadDisponible: cantidadDisponible ?? this.cantidadDisponible,
      unidad: unidad,
    );
  }

  @override
  List<Object?> get props => [productoId, cantidadDisponible];
}

class AcopioModel extends Equatable {
  final String? id;
  final String clienteId;
  final String clienteRazonSocial;
  final String proveedorId;
  final String proveedorNombre;
  final DateTime fechaUltimoMovimiento;
  final List<AcopioItem> items;

  const AcopioModel({
    this.id,
    required this.clienteId,
    required this.clienteRazonSocial,
    required this.proveedorId,
    required this.proveedorNombre,
    required this.fechaUltimoMovimiento,
    required this.items,
  });

  factory AcopioModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AcopioModel.fromMap(data, doc.id);
  }

  factory AcopioModel.fromMap(Map<String, dynamic> data, String id) {
    return AcopioModel(
      id: id,
      clienteId: data['clienteId'] ?? '',
      clienteRazonSocial: data['clienteRazonSocial'] ?? '',
      proveedorId: data['proveedorId'] ?? '',
      proveedorNombre: data['proveedorNombre'] ?? '',
      fechaUltimoMovimiento: (data['fechaUltimoMovimiento'] as Timestamp).toDate(),
      items: (data['items'] as List<dynamic>? ?? [])
          .map((e) => AcopioItem.fromMap(e))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clienteId': clienteId,
      'clienteRazonSocial': clienteRazonSocial,
      'proveedorId': proveedorId,
      'proveedorNombre': proveedorNombre,
      'fechaUltimoMovimiento': Timestamp.fromDate(fechaUltimoMovimiento),
      'items': items.map((e) => e.toMap()).toList(),
    };
  }

  @override
  List<Object?> get props => [id, clienteId, proveedorId, items];
}