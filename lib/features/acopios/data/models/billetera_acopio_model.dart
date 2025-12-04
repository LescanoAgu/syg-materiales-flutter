import 'package:equatable/equatable.dart';

/// Representa el saldo de un material específico que un cliente tiene a favor.
class BilleteraAcopio extends Equatable {
  final String id; // ID del documento (generalmente combination clienteId_productoId)
  final String clienteId;
  final String clienteNombre;
  final String productoId;
  final String productoNombre;

  // Saldos divididos por ubicación física
  final double cantidadEnDepositoPropio; // Material guardado en S&G
  final Map<String, double> cantidadEnProveedores; // Material pagado pero en proveedor { 'PROV_ID': 50.0 }

  const BilleteraAcopio({
    required this.id,
    required this.clienteId,
    required this.clienteNombre,
    required this.productoId,
    required this.productoNombre,
    this.cantidadEnDepositoPropio = 0,
    this.cantidadEnProveedores = const {},
  });

  /// Total global que el cliente "posee"
  double get saldoTotal {
    double totalProveedores = cantidadEnProveedores.values.fold(0, (sum, val) => sum + val);
    return cantidadEnDepositoPropio + totalProveedores;
  }

  factory BilleteraAcopio.fromMap(Map<String, dynamic> map, String docId) {
    return BilleteraAcopio(
      id: docId,
      clienteId: map['clienteId'] ?? '',
      clienteNombre: map['clienteNombre'] ?? '',
      productoId: map['productoId'] ?? '',
      productoNombre: map['productoNombre'] ?? '',
      cantidadEnDepositoPropio: (map['cantidadEnDepositoPropio'] as num?)?.toDouble() ?? 0,
      cantidadEnProveedores: Map<String, double>.from(map['cantidadEnProveedores'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clienteId': clienteId,
      'clienteNombre': clienteNombre,
      'productoId': productoId,
      'productoNombre': productoNombre,
      'cantidadEnDepositoPropio': cantidadEnDepositoPropio,
      'cantidadEnProveedores': cantidadEnProveedores,
      'saldoTotal': saldoTotal, // Campo calculado guardado para facilitar queries y ordenamiento
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, clienteId, productoId, saldoTotal];
}