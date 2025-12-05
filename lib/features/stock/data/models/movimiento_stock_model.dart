import 'package:equatable/equatable.dart';

enum TipoMovimiento { entrada, salida, ajuste }

class MovimientoStock extends Equatable {
  final String? id;
  final String productoId;
  final String productoNombre;
  final TipoMovimiento tipo;
  final double cantidad;
  final double cantidadAnterior;
  final double cantidadPosterior;
  final String? motivo;
  final String? referencia;
  final String? usuarioId;
  final DateTime createdAt;

  // ✅ NUEVOS CAMPOS: Vinculación con Obra
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
    required this.createdAt,
    this.obraId,
    this.obraNombre,
  });

  factory MovimientoStock.fromMap(Map<String, dynamic> map) {
    return MovimientoStock(
      id: map['id']?.toString(),
      productoId: map['productoId']?.toString() ?? '',
      productoNombre: map['productoNombre']?.toString() ?? 'Producto sin nombre',
      tipo: TipoMovimiento.values.firstWhere(
            (e) => e.name == (map['tipo'] ?? 'entrada'),
        orElse: () => TipoMovimiento.entrada,
      ),
      cantidad: (map['cantidad'] as num?)?.toDouble() ?? 0.0,
      cantidadAnterior: (map['cantidadAnterior'] as num?)?.toDouble() ?? 0.0,
      cantidadPosterior: (map['cantidadPosterior'] as num?)?.toDouble() ?? 0.0,
      motivo: map['motivo']?.toString(),
      referencia: map['referencia']?.toString(),
      usuarioId: map['usuarioId']?.toString(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'].toString())
          : DateTime.now(),
      obraId: map['obraId']?.toString(),
      obraNombre: map['obraNombre']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productoId': productoId,
      'productoNombre': productoNombre,
      'tipo': tipo.name,
      'cantidad': cantidad,
      'cantidadAnterior': cantidadAnterior,
      'cantidadPosterior': cantidadPosterior,
      'motivo': motivo,
      'referencia': referencia,
      'usuarioId': usuarioId,
      'createdAt': createdAt.toIso8601String(),
      'obraId': obraId,
      'obraNombre': obraNombre,
    };
  }

  @override
  List<Object?> get props => [id, productoId, tipo, cantidad, createdAt, obraId];
}