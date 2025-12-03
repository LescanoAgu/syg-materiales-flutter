import 'package:equatable/equatable.dart';

enum TipoMovimientoAcopio { entrada, salida, reserva, liberacion, traspaso, cambio_dueno, devolucion }

class MovimientoAcopioModel extends Equatable {
  final String? id;
  final String productoId;
  final String? clienteId; // ✅ AGREGADO: Necesario para filtros
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
  final String? usuarioId;
  final DateTime createdAt;

  // Campos desnormalizados opcionales
  final String? productoNombre;
  final String? clienteNombre;

  const MovimientoAcopioModel({
    this.id,
    required this.productoId,
    this.clienteId, // ✅
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
    this.productoNombre,
    this.clienteNombre,
  });

  factory MovimientoAcopioModel.fromMap(Map<String, dynamic> map) {
    return MovimientoAcopioModel(
      id: map['id']?.toString(),
      productoId: map['productoId']?.toString() ?? '',
      clienteId: map['clienteId']?.toString(), // ✅
      tipo: TipoMovimientoAcopio.values.firstWhere(
              (t) => t.name == map['tipo'], orElse: () => TipoMovimientoAcopio.entrada
      ),
      cantidad: (map['cantidad'] as num?)?.toDouble() ?? 0.0,
      origenTipo: map['origenTipo']?.toString(),
      origenId: map['origenId']?.toString(),
      destinoTipo: map['destinoTipo']?.toString(),
      destinoId: map['destinoId']?.toString(),
      motivo: map['motivo']?.toString() ?? map['referencia']?.toString(), // Fallback a referencia
      referencia: map['referencia']?.toString(),
      remitoNumero: map['remitoNumero']?.toString(),
      facturaNumero: map['facturaNumero']?.toString(),
      facturaFecha: map['facturaFecha'] != null ? DateTime.parse(map['facturaFecha'].toString()) : null,
      valorizado: map['valorizado'] == true,
      montoValorizado: (map['montoValorizado'] as num?)?.toDouble(),
      usuarioId: map['usuarioId']?.toString(),
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'].toString()) : DateTime.now(),
      productoNombre: map['productoNombre']?.toString(),
      clienteNombre: map['clienteNombre']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productoId': productoId,
      'clienteId': clienteId,
      'tipo': tipo.name,
      'cantidad': cantidad,
      'motivo': motivo,
      'referencia': referencia,
      'facturaNumero': facturaNumero,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, productoId, clienteId, tipo, cantidad, createdAt];

  bool get tieneFactura => facturaNumero != null && facturaNumero!.isNotEmpty;
}