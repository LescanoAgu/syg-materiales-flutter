import 'package:cloud_firestore/cloud_firestore.dart';

class CategoriaModel {
  final String? id;
  final String codigo; // ID interno (ej: AGUA)
  final String nombre; // Nombre visible (ej: Agua)
  final String prefijo; // La letra clave (ej: "A", "G", "AR")
  final String? descripcion;
  final int orden;
  final DateTime? createdAt;

  CategoriaModel({
    this.id,
    required this.codigo,
    required this.nombre,
    this.prefijo = '',
    this.descripcion,
    required this.orden,
    this.createdAt,
  });

  factory CategoriaModel.fromMap(Map<String, dynamic> map, String id) {
    return CategoriaModel(
      id: id,
      codigo: map['codigo']?.toString() ?? '',
      nombre: map['nombre']?.toString() ?? '',
      prefijo: map['prefijo']?.toString() ?? '',
      descripcion: map['descripcion']?.toString(),
      orden: (map['orden'] as num?)?.toInt() ?? 0,
      createdAt: map['created_at'] is Timestamp
          ? (map['created_at'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'codigo': codigo,
      'nombre': nombre,
      'prefijo': prefijo,
      'descripcion': descripcion,
      'orden': orden,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}