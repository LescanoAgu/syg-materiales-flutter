import 'package:cloud_firestore/cloud_firestore.dart';

class StockModel {
  final String? id;
  final String productoId;
  final double cantidadDisponible;
  final DateTime? ultimaActualizacion;

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
      ultimaActualizacion: map['ultimaActualizacion'] is Timestamp
          ? (map['ultimaActualizacion'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productoId': productoId,
      'cantidadDisponible': cantidadDisponible,
      'ultimaActualizacion': FieldValue.serverTimestamp(),
    };
  }

  StockModel copyWith({String? id, double? cantidad}) {
    return StockModel(
      id: id ?? this.id,
      productoId: productoId,
      cantidadDisponible: cantidad ?? cantidadDisponible,
      ultimaActualizacion: ultimaActualizacion,
    );
  }
}