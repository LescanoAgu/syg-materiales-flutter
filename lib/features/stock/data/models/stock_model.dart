// Importamos el modelo principal

// Este modelo queda como soporte legacy, pero el sistema usa ProductoModel principalmente
class StockModel {
  final String? id;
  final String productoId;
  final double cantidadDisponible;
  final String? ultimaActualizacion;

  StockModel({
    this.id,
    required this.productoId,
    required this.cantidadDisponible,
    this.ultimaActualizacion,
  });

  factory StockModel.fromMap(Map<String, dynamic> map) {
    return StockModel(
      id: map['id']?.toString(),
      productoId: map['productoId']?.toString() ?? '',
      cantidadDisponible: (map['cantidadDisponible'] as num?)?.toDouble() ?? 0.0,
      ultimaActualizacion: map['ultimaActualizacion']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productoId': productoId,
      'cantidadDisponible': cantidadDisponible,
      'ultimaActualizacion': ultimaActualizacion,
    };
  }

  StockModel copyWith({String? id}) {
    return StockModel(
        id: id ?? this.id,
        productoId: productoId,
        cantidadDisponible: cantidadDisponible,
        ultimaActualizacion: ultimaActualizacion
    );
  }
}