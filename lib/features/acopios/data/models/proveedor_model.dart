import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum TipoProveedor { deposito_syg, proveedor }

class ProveedorModel extends Equatable {
  final String? id;
  final String codigo;
  final String nombre;
  final TipoProveedor tipo;
  final String? direccion;
  final String? telefono;
  final String? contacto;
  final String? email;
  final String estado;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ProveedorModel({
    this.id,
    required this.codigo,
    required this.nombre,
    required this.tipo,
    this.direccion,
    this.telefono,
    this.contacto,
    this.email,
    this.estado = 'activo',
    required this.createdAt,
    this.updatedAt,
  });

  factory ProveedorModel.fromMap(Map<String, dynamic> map, [String? id]) {
    // Helper para enum
    TipoProveedor parseTipo(dynamic val) {
      return TipoProveedor.values.firstWhere(
              (e) => e.toString().split('.').last == val,
          orElse: () => TipoProveedor.proveedor
      );
    }

    // Helper fechas
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return ProveedorModel(
      id: id ?? map['id'],
      codigo: map['codigo']?.toString() ?? '',
      nombre: map['nombre']?.toString() ?? 'Proveedor',
      tipo: parseTipo(map['tipo']),
      direccion: map['direccion']?.toString(),
      telefono: map['telefono']?.toString(),
      contacto: map['contacto']?.toString(),
      email: map['email']?.toString(),
      estado: map['estado']?.toString() ?? 'activo',
      createdAt: parseDate(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'codigo': codigo,
      'nombre': nombre,
      'tipo': tipo.toString().split('.').last,
      'direccion': direccion,
      'telefono': telefono,
      'contacto': contacto,
      'email': email,
      'estado': estado,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  bool get esDepositoSyg => tipo == TipoProveedor.deposito_syg;

  @override
  List<Object?> get props => [id, codigo, nombre];
}