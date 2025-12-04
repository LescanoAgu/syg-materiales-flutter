import 'package:equatable/equatable.dart';

class ClienteModel extends Equatable {
  final String id; // Ahora es String no nullable (usamos '' si es nuevo)
  final String codigo;
  final String razonSocial;
  final String? cuit;
  final String? condicionIva;
  final String? telefono;
  final String? email;
  final String? direccion;
  final String? localidad;
  final String? observaciones;
  final bool activo;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ClienteModel({
    required this.id,
    required this.codigo,
    required this.razonSocial,
    this.cuit,
    this.condicionIva,
    this.telefono,
    this.email,
    this.direccion,
    this.localidad,
    this.observaciones,
    this.activo = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory ClienteModel.fromMap(Map<String, dynamic> map, String docId) {
    return ClienteModel(
      id: docId,
      codigo: map['codigo'] ?? '',
      razonSocial: map['razonSocial'] ?? '',
      cuit: map['cuit'],
      condicionIva: map['condicionIva'],
      telefono: map['telefono'],
      email: map['email'],
      direccion: map['direccion'],
      localidad: map['localidad'],
      observaciones: map['observaciones'],
      activo: map['activo'] ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'codigo': codigo,
      'razonSocial': razonSocial,
      'cuit': cuit,
      'condicionIva': condicionIva,
      'telefono': telefono,
      'email': email,
      'direccion': direccion,
      'localidad': localidad,
      'observaciones': observaciones,
      'activo': activo,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  ClienteModel copyWith({
    String? id,
    String? codigo,
    String? razonSocial,
    String? cuit,
    String? condicionIva,
    String? telefono,
    String? email,
    String? direccion,
    String? localidad,
    String? observaciones,
    bool? activo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClienteModel(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      razonSocial: razonSocial ?? this.razonSocial,
      cuit: cuit ?? this.cuit,
      condicionIva: condicionIva ?? this.condicionIva,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      direccion: direccion ?? this.direccion,
      localidad: localidad ?? this.localidad,
      observaciones: observaciones ?? this.observaciones,
      activo: activo ?? this.activo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get cuitFormateado {
    if (cuit == null || cuit!.length != 11) return cuit ?? '-';
    return '${cuit!.substring(0, 2)}-${cuit!.substring(2, 10)}-${cuit!.substring(10)}';
  }

  @override
  List<Object?> get props => [id, codigo, razonSocial, cuit, activo, createdAt];
}