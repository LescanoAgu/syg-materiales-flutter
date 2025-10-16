import 'package:equatable/equatable.dart';

/// Tipos de movimiento de acopio
enum TipoMovimientoAcopio {
  entrada,        // Entrada al acopio (compra directa)
  salida,         // Salida del acopio (uso/consumo)
  reserva,        // Stock S&G → Acopio Cliente (reservar)
  liberacion,     // Acopio → Stock S&G (liberar)
  traspaso,       // Acopio A → Acopio B
  cambio_dueno,   // Cambio de dueño (Cliente X → S&G)
  devolucion,     // Devolución a proveedor
}

/// Modelo de Movimiento de Acopio
///
/// Registra todas las operaciones sobre acopios:
/// - Entradas y salidas
/// - Traspasos entre acopios
/// - Reservas y liberaciones
/// - Cambios de dueño
class MovimientoAcopioModel extends Equatable {
  final int? id;
  final int productoId;
  final TipoMovimientoAcopio tipo;
  final double cantidad;

  // Origen y destino flexibles
  final String? origenTipo;        // acopio, stock
  final int? origenId;
  final String? destinoTipo;       // acopio, stock
  final int? destinoId;

  final String? motivo;
  final String? referencia;
  final String? remitoNumero;

  // Valorización
  final bool valorizado;
  final double? montoValorizado;

  final int? usuarioId;
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
    this.valorizado = false,
    this.montoValorizado,
    this.usuarioId,
    required this.createdAt,
  });

  /// Factory desde Map (BD)
  factory MovimientoAcopioModel.fromMap(Map<String, dynamic> map) {
    return MovimientoAcopioModel(
      id: map['id'],
      productoId: map['producto_id'],
      tipo: TipoMovimientoAcopio.values.firstWhere(
            (t) => t.name == map['tipo'],
      ),
      cantidad: (map['cantidad'] as num).toDouble(),
      origenTipo: map['origen_tipo'],
      origenId: map['origen_id'],
      destinoTipo: map['destino_tipo'],
      destinoId: map['destino_id'],
      motivo: map['motivo'],
      referencia: map['referencia'],
      remitoNumero: map['remito_numero'],
      valorizado: map['valorizado'] == 1,
      montoValorizado: map['monto_valorizado'] != null
          ? (map['monto_valorizado'] as num).toDouble()
          : null,
      usuarioId: map['usuario_id'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  /// Convertir a Map (para BD)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'producto_id': productoId,
      'tipo': tipo.name,
      'cantidad': cantidad,
      'origen_tipo': origenTipo,
      'origen_id': origenId,
      'destino_tipo': destinoTipo,
      'destino_id': destinoId,
      'motivo': motivo,
      'referencia': referencia,
      'remito_numero': remitoNumero,
      'valorizado': valorizado ? 1 : 0,
      'monto_valorizado': montoValorizado,
      'usuario_id': usuarioId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// CopyWith
  MovimientoAcopioModel copyWith({
    int? id,
    int? productoId,
    TipoMovimientoAcopio? tipo,
    double? cantidad,
    String? origenTipo,
    int? origenId,
    String? destinoTipo,
    int? destinoId,
    String? motivo,
    String? referencia,
    String? remitoNumero,
    bool? valorizado,
    double? montoValorizado,
    int? usuarioId,
    DateTime? createdAt,
  }) {
    return MovimientoAcopioModel(
      id: id ?? this.id,
      productoId: productoId ?? this.productoId,
      tipo: tipo ?? this.tipo,
      cantidad: cantidad ?? this.cantidad,
      origenTipo: origenTipo ?? this.origenTipo,
      origenId: origenId ?? this.origenId,
      destinoTipo: destinoTipo ?? this.destinoTipo,
      destinoId: destinoId ?? this.destinoId,
      motivo: motivo ?? this.motivo,
      referencia: referencia ?? this.referencia,
      remitoNumero: remitoNumero ?? this.remitoNumero,
      valorizado: valorizado ?? this.valorizado,
      montoValorizado: montoValorizado ?? this.montoValorizado,
      usuarioId: usuarioId ?? this.usuarioId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    productoId,
    tipo,
    cantidad,
    origenTipo,
    origenId,
    destinoTipo,
    destinoId,
    motivo,
    referencia,
    remitoNumero,
    valorizado,
    montoValorizado,
    usuarioId,
    createdAt,
  ];

  // Helpers
  bool get esEntrada => tipo == TipoMovimientoAcopio.entrada;
  bool get esSalida => tipo == TipoMovimientoAcopio.salida;
  bool get esTraspaso => tipo == TipoMovimientoAcopio.traspaso;
  bool get tieneRemito => remitoNumero != null && remitoNumero!.isNotEmpty;
}