import 'package:equatable/equatable.dart';

class ItemRemito extends Equatable {
  final String productoId;
  final String productoNombre;
  final double cantidad; // Lo que entrego ahora
  final String unidad;

  // ✅ NUEVOS CAMPOS (SNAPSHOT)
  // Guardamos estos datos para que el remito histórico sea fiel al momento en que se hizo
  final double cantidadSolicitadaTotal;
  final double saldoPendienteAnterior;

  const ItemRemito({
    required this.productoId,
    required this.productoNombre,
    required this.cantidad,
    required this.unidad,
    this.cantidadSolicitadaTotal = 0,
    this.saldoPendienteAnterior = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'productoId': productoId,
      'productoNombre': productoNombre,
      'cantidad': cantidad,
      'unidad': unidad,
      'cantidadSolicitadaTotal': cantidadSolicitadaTotal,
      'saldoPendienteAnterior': saldoPendienteAnterior,
    };
  }

  factory ItemRemito.fromMap(Map<String, dynamic> map) {
    return ItemRemito(
      productoId: map['productoId'] ?? '',
      productoNombre: map['productoNombre'] ?? '',
      cantidad: (map['cantidad'] as num).toDouble(),
      unidad: map['unidad'] ?? '',
      cantidadSolicitadaTotal: (map['cantidadSolicitadaTotal'] as num?)?.toDouble() ?? 0.0,
      saldoPendienteAnterior: (map['saldoPendienteAnterior'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [productoId, cantidad];
}

class Remito extends Equatable {
  final String? id;
  final String ordenId;
  final String numeroRemito;
  final DateTime fecha;
  final List<ItemRemito> items;
  final String? firmaAutorizoUrl;
  final String? firmaRecibioUrl;
  final String usuarioDespachadorId;
  final String usuarioDespachadorNombre;
  final String? observaciones;

  const Remito({
    this.id,
    required this.ordenId,
    required this.numeroRemito,
    required this.fecha,
    required this.items,
    this.firmaAutorizoUrl,
    this.firmaRecibioUrl,
    required this.usuarioDespachadorId,
    required this.usuarioDespachadorNombre,
    this.observaciones,
  });

  Map<String, dynamic> toMap() {
    return {
      'ordenId': ordenId,
      'numeroRemito': numeroRemito,
      'fecha': fecha.toIso8601String(),
      'items': items.map((x) => x.toMap()).toList(),
      'firmaAutorizoUrl': firmaAutorizoUrl,
      'firmaRecibioUrl': firmaRecibioUrl,
      'usuarioDespachadorId': usuarioDespachadorId,
      'usuarioDespachadorNombre': usuarioDespachadorNombre,
      'observaciones': observaciones,
    };
  }

  factory Remito.fromMap(Map<String, dynamic> map, String id) {
    return Remito(
      id: id,
      ordenId: map['ordenId'] ?? '',
      numeroRemito: map['numeroRemito'] ?? '',
      fecha: DateTime.parse(map['fecha']),
      items: List<ItemRemito>.from(
        (map['items'] as List).map((x) => ItemRemito.fromMap(x)),
      ),
      firmaAutorizoUrl: map['firmaAutorizoUrl'],
      firmaRecibioUrl: map['firmaRecibioUrl'],
      usuarioDespachadorId: map['usuarioDespachadorId'] ?? '',
      usuarioDespachadorNombre: map['usuarioDespachadorNombre'] ?? '',
      observaciones: map['observaciones'],
    );
  }

  @override
  List<Object?> get props => [id, numeroRemito];
}