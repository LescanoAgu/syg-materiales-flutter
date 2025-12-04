import 'package:equatable/equatable.dart';

class ObraModel extends Equatable {
  final String id; // ID de Firestore (no nullable)
  final String codigo;
  final String nombre;

  // Vinculación
  final String clienteId;
  final String clienteRazonSocial;
  final String? clienteCodigo; // ✅ Campo necesario

  final String? direccion;
  final String? localidad;

  // Contacto (Reemplaza a los campos sueltos antiguos)
  final String? nombreContacto;
  final String? telefonoContacto;

  // Ubicación
  final double? latitud;
  final double? longitud;

  // Estado y Fechas
  final String estado; // 'activa', 'finalizada', 'pausada'
  final DateTime fechaInicio;
  final DateTime? fechaFinEstimada;

  const ObraModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.clienteId,
    required this.clienteRazonSocial,
    this.clienteCodigo,
    this.direccion,
    this.localidad,
    this.nombreContacto,
    this.telefonoContacto,
    this.latitud,
    this.longitud,
    this.estado = 'activa',
    required this.fechaInicio,
    this.fechaFinEstimada,
  });

  factory ObraModel.fromMap(Map<String, dynamic> map, String docId) {
    return ObraModel(
      id: docId,
      codigo: map['codigo'] ?? '',
      nombre: map['nombre'] ?? '',
      clienteId: map['clienteId'] ?? '',
      clienteRazonSocial: map['clienteRazonSocial'] ?? '',
      clienteCodigo: map['clienteCodigo'],
      direccion: map['direccion'],
      localidad: map['localidad'],
      // Soporte para datos viejos si existen
      nombreContacto: map['nombreContacto'] ?? map['maestroObraNombre'],
      telefonoContacto: map['telefonoContacto'] ?? map['maestroObraTelefono'],
      latitud: (map['latitud'] as num?)?.toDouble(),
      longitud: (map['longitud'] as num?)?.toDouble(),
      estado: map['estado'] ?? 'activa',
      fechaInicio: map['fechaInicio'] != null
          ? DateTime.parse(map['fechaInicio'])
          : DateTime.now(),
      fechaFinEstimada: map['fechaFinEstimada'] != null
          ? DateTime.parse(map['fechaFinEstimada'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'codigo': codigo,
      'nombre': nombre,
      'clienteId': clienteId,
      'clienteRazonSocial': clienteRazonSocial,
      'clienteCodigo': clienteCodigo,
      'direccion': direccion,
      'localidad': localidad,
      'nombreContacto': nombreContacto,
      'telefonoContacto': telefonoContacto,
      'latitud': latitud,
      'longitud': longitud,
      'estado': estado,
      'fechaInicio': fechaInicio.toIso8601String(),
      'fechaFinEstimada': fechaFinEstimada?.toIso8601String(),
    };
  }

  // Getters de compatibilidad (evitan errores en FormPage viejo si no se actualiza)
  String? get maestroObraNombre => nombreContacto;
  String? get maestroObraTelefono => telefonoContacto;
  String? get contactoObra => nombreContacto;
  String? get telefonoObra => telefonoContacto;

  // Getter fake para compatibilidad
  DateTime get createdAt => fechaInicio;

  @override
  List<Object?> get props => [id, codigo, nombre, clienteId, estado];
}