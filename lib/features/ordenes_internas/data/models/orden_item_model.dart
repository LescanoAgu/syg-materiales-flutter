import 'package:equatable/equatable.dart';

enum OrigenProducto { stockPropio, compraDirecta, descuentoAcopio }

class OrdenItem extends Equatable {
  final String? id;
  final String productoId;
  final String productoNombre;
  final String productoCodigo;
  final String unidad;
  final double cantidad; // Solicitada

  // Logística
  final double cantidadAprobada;
  final double cantidadEntregada;
  final OrigenProducto origen;
  final String? proveedorId;
  final double precioCompra;
  final String? observaciones;
  final String estadoItem; // pendiente, parcial, completado

  const OrdenItem({
    this.id,
    required this.productoId,
    required this.productoNombre,
    required this.productoCodigo,
    required this.unidad,
    required this.cantidad,
    this.cantidadAprobada = 0,
    this.cantidadEntregada = 0,
    this.origen = OrigenProducto.stockPropio,
    this.proveedorId,
    this.precioCompra = 0,
    this.observaciones,
    this.estadoItem = 'pendiente',
  });

  // Getter de compatibilidad
  double get cantidadSolicitada => cantidad;

  factory OrdenItem.fromMap(Map<String, dynamic> map) {
    return OrdenItem(
      id: map['id']?.toString(),
      productoId: map['productoId']?.toString() ?? '',
      productoNombre: map['productoNombre']?.toString() ?? 'Producto',
      productoCodigo: map['productoCodigo']?.toString() ?? '',
      unidad: map['unidad']?.toString() ?? 'u',
      cantidad: (map['cantidad'] ?? map['cantidadSolicitada'] ?? 0).toDouble(),
      cantidadAprobada: (map['cantidadAprobada'] ?? 0).toDouble(),
      cantidadEntregada: (map['cantidadEntregada'] ?? 0).toDouble(),
      origen: map['origen'] != null
          ? OrigenProducto.values.firstWhere((e) => e.toString().split('.').last == map['origen'], orElse: () => OrigenProducto.stockPropio)
          : OrigenProducto.stockPropio,
      proveedorId: map['proveedorId']?.toString(),
      precioCompra: (map['precioCompra'] ?? 0).toDouble(),
      observaciones: map['observaciones']?.toString(),
      estadoItem: map['estadoItem']?.toString() ?? 'pendiente',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productoId': productoId,
      'productoNombre': productoNombre,
      'productoCodigo': productoCodigo,
      'unidad': unidad,
      'cantidad': cantidad,
      'cantidadAprobada': cantidadAprobada,
      'cantidadEntregada': cantidadEntregada,
      'origen': origen.toString().split('.').last,
      'proveedorId': proveedorId,
      'precioCompra': precioCompra,
      'observaciones': observaciones,
      'estadoItem': estadoItem,
    };
  }

  // ✅ MÉTODO COPYWITH AGREGADO (Soluciona el error)
  OrdenItem copyWith({
    String? id,
    String? productoId,
    String? productoNombre,
    String? productoCodigo,
    String? unidad,
    double? cantidad,
    double? cantidadAprobada,
    double? cantidadEntregada,
    OrigenProducto? origen,
    String? proveedorId,
    double? precioCompra,
    String? observaciones,
    String? estadoItem,
  }) {
    return OrdenItem(
      id: id ?? this.id,
      productoId: productoId ?? this.productoId,
      productoNombre: productoNombre ?? this.productoNombre,
      productoCodigo: productoCodigo ?? this.productoCodigo,
      unidad: unidad ?? this.unidad,
      cantidad: cantidad ?? this.cantidad,
      cantidadAprobada: cantidadAprobada ?? this.cantidadAprobada,
      cantidadEntregada: cantidadEntregada ?? this.cantidadEntregada,
      origen: origen ?? this.origen,
      proveedorId: proveedorId ?? this.proveedorId,
      precioCompra: precioCompra ?? this.precioCompra,
      observaciones: observaciones ?? this.observaciones,
      estadoItem: estadoItem ?? this.estadoItem,
    );
  }

  @override
  List<Object?> get props => [id, productoId, cantidad, cantidadEntregada, estadoItem];
}

// Wrapper UI para Item
class OrdenItemDetalle {
  final OrdenItem item;
  final String productoNombre;
  final String productoCodigo;
  final String unidadBase;
  final double cantidadFinal;

  OrdenItemDetalle({
    required this.item,
    required this.productoNombre,
    required this.productoCodigo,
    required this.unidadBase,
    required this.cantidadFinal,
  });
}