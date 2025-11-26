class OrdenItem {
  final String? id;
  final String ordenId;
  final String productoId;
  final double cantidadSolicitada;
  final double? cantidadAprobada;
  final double precioUnitario;
  final double subtotal;
  final String? observaciones;
  final DateTime createdAt;

  OrdenItem({
    this.id,
    required this.ordenId,
    required this.productoId,
    required this.cantidadSolicitada,
    this.cantidadAprobada,
    required this.precioUnitario,
    required this.subtotal,
    this.observaciones,
    required this.createdAt,
  });

  factory OrdenItem.fromMap(Map<String, dynamic> map) {
    return OrdenItem(
      id: map['id']?.toString(),
      ordenId: map['ordenId']?.toString() ?? '',
      productoId: map['productoId']?.toString() ?? '',
      cantidadSolicitada: (map['cantidadSolicitada'] as num?)?.toDouble() ?? 0.0,
      cantidadAprobada: (map['cantidadAprobada'] as num?)?.toDouble(),
      precioUnitario: (map['precioUnitario'] as num?)?.toDouble() ?? 0.0,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      observaciones: map['observaciones']?.toString(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ordenId': ordenId,
      'productoId': productoId,
      'cantidadSolicitada': cantidadSolicitada,
      'cantidadAprobada': cantidadAprobada,
      'precioUnitario': precioUnitario,
      'subtotal': subtotal,
      'observaciones': observaciones,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Modelo para la UI (incluye nombres para mostrar en la lista)
class OrdenItemDetalle {
  final OrdenItem item;
  final String productoNombre;
  final String productoCodigo;
  final String unidadBase;
  final String categoriaNombre;

  OrdenItemDetalle({
    required this.item,
    required this.productoNombre,
    required this.productoCodigo,
    required this.unidadBase,
    required this.categoriaNombre,
  });

  double get cantidadFinal => item.cantidadAprobada ?? item.cantidadSolicitada;
  bool get fueModificada => item.cantidadAprobada != null && item.cantidadAprobada != item.cantidadSolicitada;
}