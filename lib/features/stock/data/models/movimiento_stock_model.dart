import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum TipoMovimiento { entrada, salida, ajuste, ajustePositivo, ajusteNegativo }

class MovimientoStock extends Equatable {
  final String? id;
  final String productoId;
  final String productoNombre;
  final TipoMovimiento tipo;
  final double cantidad;
  final double cantidadAnterior;
  final double cantidadPosterior;
  final String? motivo;
  final String? referencia; // N° Remito o Factura
  final String? usuarioId;
  final String usuarioNombre;
  final DateTime fecha; // Antes createdAt

  // Vinculación con Obra
  final String? obraId;
  final String? obraNombre;

  const MovimientoStock({
    this.id,
    required this.productoId,
    this.productoNombre = '',
    required this.tipo,
    required this.cantidad,
    this.cantidadAnterior = 0,
    this.cantidadPosterior = 0,
    this.motivo,
    this.referencia,
    this.usuarioId,
    this.usuarioNombre = 'Sistema',
    required this.fecha,
    this.obraId,
    this.obraNombre,
  });

  factory MovimientoStock.fromMap(Map<String, dynamic> map) {
    // Manejo robusto del Enum
    TipoMovimiento tipoParsed = TipoMovimiento.entrada;
    try {
      tipoParsed = TipoMovimiento.values.firstWhere(
              (e) => e.toString().split('.').last == map['tipo'],
          orElse: () => TipoMovimiento.entrada
      );
    } catch (_) {}

    return MovimientoStock(
      id: map['id']?.toString(),
      productoId: map['productoId']?.toString() ?? '',
      productoNombre: map['productoNombre']?.toString() ?? 'Desconocido',
      tipo: tipoParsed,
      cantidad: (map['cantidad'] as num?)?.toDouble() ?? 0.0,
      cantidadAnterior: (map['cantidadAnterior'] as num?)?.toDouble() ?? 0.0,
      cantidadPosterior: (map['cantidadPosterior'] as num?)?.toDouble() ?? 0.0,
      motivo: map['motivo']?.toString(),
      referencia: map['referencia']?.toString(),
      usuarioId: map['usuarioId']?.toString(),
      usuarioNombre: map['usuarioNombre']?.toString() ?? 'Desconocido',
      fecha: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      obraId: map['obraId']?.toString(),
      obraNombre: map['obraNombre']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productoId': productoId,
      'productoNombre': productoNombre,
      'tipo': tipo.toString().split('.').last,
      'cantidad': cantidad,
      'cantidadAnterior': cantidadAnterior,
      'cantidadPosterior': cantidadPosterior,
      'motivo': motivo,
      'referencia': referencia,
      'usuarioId': usuarioId,
      'usuarioNombre': usuarioNombre,
      'createdAt': Timestamp.fromDate(fecha),
      'obraId': obraId,
      'obraNombre': obraNombre,
    };
  }

  // Getters para compatibilidad con reportes viejos
  DateTime get createdAt => fecha;

  @override
  List<Object?> get props => [id, productoId, fecha];
}