import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class RemitoItem extends Equatable {
  final String productoId;
  final String productoNombre;
  final String? productoCodigo;

  final double cantidad; // Lo que se entrega HOY
  final double cantidadSolicitadaTotal; // El total de la orden
  final double saldoPendienteAnterior; // Lo que faltaba antes de hoy
  final String unidad;

  const RemitoItem({
    required this.productoId,
    required this.productoNombre,
    this.productoCodigo,
    required this.cantidad,
    required this.cantidadSolicitadaTotal,
    required this.saldoPendienteAnterior,
    this.unidad = 'u',
  });

  Map<String, dynamic> toMap() {
    return {
      'productoId': productoId,
      'productoNombre': productoNombre,
      'productoCodigo': productoCodigo,
      'cantidad': cantidad,
      'cantidadSolicitadaTotal': cantidadSolicitadaTotal,
      'saldoPendienteAnterior': saldoPendienteAnterior,
      'unidad': unidad,
    };
  }

  factory RemitoItem.fromMap(Map<String, dynamic> map) {
    return RemitoItem(
      productoId: map['productoId'] ?? '',
      productoNombre: map['productoNombre'] ?? '',
      productoCodigo: map['productoCodigo'],
      cantidad: (map['cantidad'] as num?)?.toDouble() ?? 0.0,
      cantidadSolicitadaTotal: (map['cantidadSolicitadaTotal'] as num?)?.toDouble() ?? 0.0,
      saldoPendienteAnterior: (map['saldoPendienteAnterior'] as num?)?.toDouble() ?? 0.0,
      unidad: map['unidad'] ?? 'u',
    );
  }

  @override
  List<Object?> get props => [productoId, cantidad];
}

class Remito extends Equatable {
  final String id;
  final String numeroRemito;
  final String ordenId;
  final DateTime fecha;

  // Trazabilidad Completa
  final String clienteId;
  final String? obraId;

  // Si fue entrega de proveedor directo
  final String? proveedorId;
  final String? proveedorNombre;

  final List<RemitoItem> items;
  final String firmaAutorizoUrl;
  final String firmaRecibioUrl;
  final String usuarioDespachadorId;
  final String usuarioDespachadorNombre;

  const Remito({
    required this.id,
    required this.numeroRemito,
    required this.ordenId,
    required this.fecha,
    required this.clienteId,
    this.obraId,
    this.proveedorId,
    this.proveedorNombre,
    required this.items,
    required this.firmaAutorizoUrl,
    required this.firmaRecibioUrl,
    required this.usuarioDespachadorId,
    required this.usuarioDespachadorNombre,
  });

  factory Remito.fromMap(Map<String, dynamic> map, String id) {
    return Remito(
      id: id,
      numeroRemito: map['numeroRemito'] ?? '',
      ordenId: map['ordenId'] ?? '',
      fecha: (map['fecha'] as Timestamp).toDate(),
      clienteId: map['clienteId'] ?? '',
      obraId: map['obraId'],
      proveedorId: map['proveedorId'],
      proveedorNombre: map['proveedorNombre'],
      items: (map['items'] as List<dynamic>? ?? [])
          .map((x) => RemitoItem.fromMap(x))
          .toList(),
      firmaAutorizoUrl: map['firmaAutorizoUrl'] ?? '',
      firmaRecibioUrl: map['firmaRecibioUrl'] ?? '',
      usuarioDespachadorId: map['usuarioDespachadorId'] ?? '',
      usuarioDespachadorNombre: map['usuarioDespachadorNombre'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'numeroRemito': numeroRemito,
      'ordenId': ordenId,
      'fecha': Timestamp.fromDate(fecha),
      'clienteId': clienteId,
      'obraId': obraId,
      'proveedorId': proveedorId,
      'proveedorNombre': proveedorNombre,
      'items': items.map((x) => x.toMap()).toList(),
      'firmaAutorizoUrl': firmaAutorizoUrl,
      'firmaRecibioUrl': firmaRecibioUrl,
      'usuarioDespachadorId': usuarioDespachadorId,
      'usuarioDespachadorNombre': usuarioDespachadorNombre,
    };
  }

  @override
  List<Object?> get props => [id, numeroRemito, ordenId, fecha];
}