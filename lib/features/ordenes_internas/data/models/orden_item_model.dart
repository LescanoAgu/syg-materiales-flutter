import 'package:equatable/equatable.dart';

enum OrigenProducto {
  stockPropio, // Sale de nuestro depósito
  compraDirecta, // Se compra al proveedor y va a obra
  descuentoAcopio // Se descuenta de un acopio previo del cliente
}

class OrdenItem extends Equatable {
  final String id;
  final String productoId;
  final String productoNombre; // Desnormalizado
  final String unidad;
  final double cantidadSolicitada;

  // Gestión de Aprobación/Logística
  final double cantidadAprobada;
  final double cantidadEntregada; // Progreso
  final OrigenProducto origen;
  final String? proveedorId;
  final double precioCompra;
  final String? observaciones;
  final String estadoItem; // pendiente, parcial, completado

  const OrdenItem({
    required this.id,
    required this.productoId,
    required this.productoNombre,
    required this.unidad,
    required this.cantidadSolicitada,
    this.cantidadAprobada = 0,
    this.cantidadEntregada = 0,
    this.origen = OrigenProducto.stockPropio,
    this.proveedorId,
    this.precioCompra = 0,
    this.observaciones,
    this.estadoItem = 'pendiente',
  });

  factory OrdenItem.fromMap(Map<String, dynamic> map) {
    return OrdenItem(
      id: map['id']?.toString() ?? '',
      productoId: map['productoId']?.toString() ?? '',
      productoNombre: map['productoNombre']?.toString() ?? '',
      unidad: map['unidad']?.toString() ?? '',
      cantidadSolicitada: (map['cantidadSolicitada'] as num?)?.toDouble() ?? 0.0,
      cantidadAprobada: (map['cantidadAprobada'] as num?)?.toDouble() ?? 0.0,
      cantidadEntregada: (map['cantidadEntregada'] as num?)?.toDouble() ?? 0.0,
      origen: OrigenProducto.values.firstWhere(
            (e) => e.name == (map['origen'] ?? 'stockPropio'),
        orElse: () => OrigenProducto.stockPropio,
      ),
      proveedorId: map['proveedorId']?.toString(),
      precioCompra: (map['precioCompra'] as num?)?.toDouble() ?? 0.0,
      observaciones: map['observaciones']?.toString(),
      estadoItem: map['estadoItem']?.toString() ?? 'pendiente',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productoId': productoId,
      'productoNombre': productoNombre,
      'unidad': unidad,
      'cantidadSolicitada': cantidadSolicitada,
      'cantidadAprobada': cantidadAprobada,
      'cantidadEntregada': cantidadEntregada,
      'origen': origen.name,
      'proveedorId': proveedorId,
      'precioCompra': precioCompra,
      'observaciones': observaciones,
      'estadoItem': estadoItem,
    };
  }

  OrdenItem copyWith({
    double? cantidadAprobada,
    OrigenProducto? origen,
    String? proveedorId,
    double? cantidadEntregada,
    String? estadoItem,
  }) {
    return OrdenItem(
      id: id,
      productoId: productoId,
      productoNombre: productoNombre,
      unidad: unidad,
      cantidadSolicitada: cantidadSolicitada,
      cantidadAprobada: cantidadAprobada ?? this.cantidadAprobada,
      cantidadEntregada: cantidadEntregada ?? this.cantidadEntregada,
      origen: origen ?? this.origen,
      proveedorId: proveedorId ?? this.proveedorId,
      precioCompra: precioCompra,
      observaciones: observaciones,
      estadoItem: estadoItem ?? this.estadoItem,
    );
  }

  @override
  List<Object?> get props => [id, productoId, cantidadSolicitada, origen, cantidadEntregada];
}

/// ✅ CLASE NECESARIA PARA LA UI (WRAPPER)
/// Esta clase envuelve el OrdenItem y agrega helpers visuales
class OrdenItemDetalle {
  final OrdenItem item;

  // Getters directos al item o lógica visual
  String get productoNombre => item.productoNombre;
  String get productoCodigo => item.productoId;
  String get unidadBase => item.unidad;

  double get cantidadFinal => item.cantidadAprobada > 0 ? item.cantidadAprobada : item.cantidadSolicitada;

  OrdenItemDetalle({required this.item});

  bool get estaCompleto => item.cantidadEntregada >= cantidadFinal;
  bool get esParcial => item.cantidadEntregada > 0 && item.cantidadEntregada < cantidadFinal;
}