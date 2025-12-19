import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ObraModel extends Equatable {
  final String id;
  final String codigo; // Identificador interno (ej: O-2024-05)
  final String nombre;

  // Relación con Cliente
  final String clienteId;
  final String clienteRazonSocial;
  final String clienteCodigo;

  final String? direccion;
  final String? localidad;
  final String? nombreContacto;
  final String? telefonoContacto;

  // Geo
  final double? latitud;
  final double? longitud;

  final String estado; // activa, finalizada, pausada
  final DateTime fechaInicio;
  final DateTime? fechaFinEstimada;

  const ObraModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.clienteId,
    required this.clienteRazonSocial,
    this.clienteCodigo = '',
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

  factory ObraModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return ObraModel(
      id: id,
      codigo: map['codigo']?.toString() ?? '',
      nombre: map['nombre']?.toString() ?? 'Obra S/N',
      clienteId: map['clienteId']?.toString() ?? '',
      clienteRazonSocial: map['clienteRazonSocial']?.toString() ?? '',
      clienteCodigo: map['clienteCodigo']?.toString() ?? '',
      direccion: map['direccion']?.toString(),
      localidad: map['localidad']?.toString(),
      nombreContacto: map['nombreContacto']?.toString(),
      telefonoContacto: map['telefonoContacto']?.toString(),
      latitud: (map['latitud'] as num?)?.toDouble(),
      longitud: (map['longitud'] as num?)?.toDouble(),
      estado: map['estado']?.toString() ?? 'activa',
      fechaInicio: parseDate(map['fechaInicio']),
      fechaFinEstimada: map['fechaFinEstimada'] != null ? parseDate(map['fechaFinEstimada']) : null,
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
      'fechaInicio': Timestamp.fromDate(fechaInicio),
      'fechaFinEstimada': fechaFinEstimada != null ? Timestamp.fromDate(fechaFinEstimada!) : null,
    };
  }

  @override
  List<Object?> get props => [id, codigo, nombre, clienteId, estado];
}