import 'package:equatable/equatable.dart';

enum TipoMovimientoAcopio { entrada, salida, reserva, liberacion, traspaso, cambio_dueno, devolucion }

class MovimientoAcopioModel extends Equatable {
  final String? id;
  final String productoId;
  final TipoMovimientoAcopio tipo;
  final double cantidad;
  final String? origenTipo;
  final String? origenId;
  final String? destinoTipo;
  final String? destinoId;
  final String? motivo;
  final String? referencia;
  final String? remitoNumero;
  final String? facturaNumero;
  final DateTime? facturaFecha;
  final bool valorizado;
  final double? montoValorizado;
  final String? usuarioId; // Cambiado a String
  final DateTime createdAt;

  const MovimientoAcopioModel({
    this.id,
    required this.productoId,
    required this.tipo,
    required this.cantidad,
    this.origenTipo,
    this.origenId,
    this.destinoTipo,
    this.destinoId,
    this.motivo,
    this.referencia,
    this.remitoNumero,
    this.facturaNumero,
    this.facturaFecha,
    this.valorizado = false,
    this.montoValorizado,
    this.usuarioId,
    required this.createdAt,
  });

  factory MovimientoAcopioModel.fromMap(Map<String, dynamic> map) {
    return MovimientoAcopioModel(
      id: map['id']?.toString(),
      productoId: map['productoId']?.toString() ?? '',
      tipo: TipoMovimientoAcopio.values.firstWhere(
              (t) => t.name == map['tipo'], orElse: () => TipoMovimientoAcopio.entrada
      ),
      cantidad: (map['cantidad'] as num?)?.toDouble() ?? 0.0,
      origenTipo: map['origenTipo']?.toString(),
      origenId: map['origenId']?.toString(),
      destinoTipo: map['destinoTipo']?.toString(),
      destinoId: map['destinoId']?.toString(),
      motivo: map['motivo']?.toString(),
      referencia: map['referencia']?.toString(),
      remitoNumero: map['remitoNumero']?.toString(),
      facturaNumero: map['facturaNumero']?.toString(),
      facturaFecha: map['facturaFecha'] != null ? DateTime.parse(map['facturaFecha'].toString()) : null,
      valorizado: map['valorizado'] == true,
      montoValorizado: (map['montoValorizado'] as num?)?.toDouble(),
      usuarioId: map['usuarioId']?.toString(),
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'].toString()) : DateTime.now(),
    );
  }

  // ... toMap y props (omitidos por brevedad)
  @override
  List<Object?> get props => [id];

  bool get tieneFactura => facturaNumero != null && facturaNumero!.isNotEmpty;
}