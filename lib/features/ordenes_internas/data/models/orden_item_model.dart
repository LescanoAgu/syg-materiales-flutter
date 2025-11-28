class OrdenItem {
  final String? id;
  final String ordenId;
  final String productoId;
  final double cantidadSolicitada;
  final double? cantidadAprobada;
  final double cantidadEntregada; // ✅ NUEVO: Control de entregas parciales
  final double precioUnitario;
  final double subtotal;
  final String? observaciones;
  final String estadoItem; // ✅ NUEVO: 'pendiente', 'parcial', 'completado'
  final DateTime createdAt;

  OrdenItem({
    this.id,
    required this.ordenId,
    required this.productoId,
    required this.cantidadSolicitada,
    this.cantidadAprobada,
    this.cantidadEntregada = 0.0, // Default 0
    required this.precioUnitario,
    required this.subtotal,
    this.observaciones,
    this.estadoItem = 'pendiente',
    required this.createdAt,
  });

  // Getter útil para la UI
  double get cantidadPendiente {
    final meta = cantidadAprobada ?? cantidadSolicitada;
    return (meta - cantidadEntregada).clamp(0.0, meta);
  }

  factory OrdenItem.fromMap(Map<String, dynamic> map) {
    return OrdenItem(
      id: map['id']?.toString(),
      ordenId: map['ordenId']?.toString() ?? '',
      productoId: map['productoId']?.toString() ?? '',
      cantidadSolicitada: (map['cantidadSolicitada'] as num?)?.toDouble() ?? 0.0,
      cantidadAprobada: (map['cantidadAprobada'] as num?)?.toDouble(),
      cantidadEntregada: (map['cantidadEntregada'] as num?)?.toDouble() ?? 0.0,
      precioUnitario: (map['precioUnitario'] as num?)?.toDouble() ?? 0.0,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      observaciones: map['observaciones']?.toString(),
      estadoItem: map['estadoItem']?.toString() ?? 'pendiente',
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
      'cantidadEntregada': cantidadEntregada,
      'precioUnitario': precioUnitario,
      'subtotal': subtotal,
      'observaciones': observaciones,
      'estadoItem': estadoItem,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Modelo para la UI (incluye nombres)
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

  // Lógica visual de estado
  bool get estaCompleto => item.cantidadEntregada >= cantidadFinal;
  bool get esParcial => item.cantidadEntregada > 0 && item.cantidadEntregada < cantidadFinal;
}