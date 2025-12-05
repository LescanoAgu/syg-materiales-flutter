import 'package:equatable/equatable.dart';

class AcopioItem extends Equatable {
  final String productoId;
  final String productoNombre;
  final double cantidadOriginal; // Lo que se compró en la factura
  final double cantidadRestante; // Lo que queda por retirar

  const AcopioItem({
    required this.productoId,
    required this.productoNombre,
    required this.cantidadOriginal,
    required this.cantidadRestante,
  });

  factory AcopioItem.fromMap(Map<String, dynamic> map) {
    return AcopioItem(
      productoId: map['productoId']?.toString() ?? '',
      productoNombre: map['productoNombre']?.toString() ?? '',
      cantidadOriginal: (map['cantidadOriginal'] as num?)?.toDouble() ?? 0.0,
      cantidadRestante: (map['cantidadRestante'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productoId': productoId,
      'productoNombre': productoNombre,
      'cantidadOriginal': cantidadOriginal,
      'cantidadRestante': cantidadRestante,
    };
  }

  @override
  List<Object?> get props => [productoId, cantidadOriginal, cantidadRestante];
}

class AcopioModel extends Equatable {
  final String id;
  final String numeroFactura; // Ej: "0001-00004523"
  final String etiqueta;      // Ej: "MATERIALES LOSA 1"

  final String clienteId;
  final String clienteRazonSocial;

  final String proveedorId;
  final String proveedorNombre;

  final DateTime fechaCompra;
  final List<AcopioItem> items;
  final bool activo; // True mientras quede saldo en algún item

  const AcopioModel({
    required this.id,
    required this.numeroFactura,
    required this.etiqueta,
    required this.clienteId,
    required this.clienteRazonSocial,
    required this.proveedorId,
    required this.proveedorNombre,
    required this.fechaCompra,
    required this.items,
    this.activo = true,
  });

  factory AcopioModel.fromMap(Map<String, dynamic> map, String docId) {
    return AcopioModel(
      id: docId,
      numeroFactura: map['numeroFactura'] ?? '',
      etiqueta: map['etiqueta'] ?? '',
      clienteId: map['clienteId'] ?? '',
      clienteRazonSocial: map['clienteRazonSocial'] ?? '',
      proveedorId: map['proveedorId'] ?? '',
      proveedorNombre: map['proveedorNombre'] ?? '',
      fechaCompra: map['fechaCompra'] != null
          ? DateTime.parse(map['fechaCompra'])
          : DateTime.now(),
      items: (map['items'] as List<dynamic>?)
          ?.map((x) => AcopioItem.fromMap(x))
          .toList() ?? [],
      activo: map['activo'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'numeroFactura': numeroFactura,
      'etiqueta': etiqueta,
      'clienteId': clienteId,
      'clienteRazonSocial': clienteRazonSocial,
      'proveedorId': proveedorId,
      'proveedorNombre': proveedorNombre,
      'fechaCompra': fechaCompra.toIso8601String(),
      'items': items.map((x) => x.toMap()).toList(),
      'activo': activo,
    };
  }

  // Helper visual para barras de progreso (0.0 a 1.0)
  double get porcentajeConsumido {
    double totalOrig = 0;
    double totalRest = 0;
    for (var i in items) {
      totalOrig += i.cantidadOriginal;
      totalRest += i.cantidadRestante;
    }
    if (totalOrig == 0) return 1.0;
    return 1.0 - (totalRest / totalOrig);
  }

  @override
  List<Object?> get props => [id, numeroFactura, items, activo];
}