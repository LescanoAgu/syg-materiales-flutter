import 'orden_item_model.dart';

class OrdenInterna {
  final String? id;
  final String numero;
  final String clienteId;
  final String obraId;
  final String solicitanteNombre;
  final DateTime fechaPedido;
  final String estado;
  final String prioridad;

  // ✅ CAMPOS NUEVOS REQUERIDOS
  final List<String> usuariosEtiquetados;
  final String? firmaUrl;
  final DateTime? fechaEntregaReal;

  final double porcentajeAvance;
  final String? fuente;
  final String? observacionesCliente;
  final double total;
  final DateTime createdAt;

  final String? clienteRazonSocial;
  final String? obraNombre;

  OrdenInterna({
    this.id,
    required this.numero,
    required this.clienteId,
    required this.obraId,
    required this.solicitanteNombre,
    required this.fechaPedido,
    this.estado = 'solicitado',
    this.prioridad = 'media',

    this.usuariosEtiquetados = const [],
    this.firmaUrl,
    this.fechaEntregaReal,

    this.porcentajeAvance = 0.0,
    this.fuente,
    this.observacionesCliente,
    this.total = 0,
    required this.createdAt,
    this.clienteRazonSocial,
    this.obraNombre,
  });

  factory OrdenInterna.fromMap(Map<String, dynamic> map) {
    return OrdenInterna(
      id: map['id']?.toString(),
      numero: map['numero']?.toString() ?? '',
      clienteId: map['clienteId']?.toString() ?? '',
      obraId: map['obraId']?.toString() ?? '',
      solicitanteNombre: map['solicitanteNombre']?.toString() ?? '',
      fechaPedido: map['fechaPedido'] != null ? DateTime.parse(map['fechaPedido']) : DateTime.now(),
      estado: map['estado']?.toString() ?? 'solicitado',
      prioridad: map['prioridad']?.toString() ?? 'media',

      usuariosEtiquetados: List<String>.from(map['usuariosEtiquetados'] ?? []),
      firmaUrl: map['firmaUrl']?.toString(),
      fechaEntregaReal: map['fechaEntregaReal'] != null ? DateTime.parse(map['fechaEntregaReal']) : null,

      porcentajeAvance: (map['porcentajeAvance'] as num?)?.toDouble() ?? 0.0,
      fuente: map['fuente']?.toString(),
      observacionesCliente: map['observacionesCliente']?.toString(),
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      clienteRazonSocial: map['clienteRazonSocial']?.toString(),
      obraNombre: map['obraNombre']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'numero': numero,
      'clienteId': clienteId,
      'obraId': obraId,
      'solicitanteNombre': solicitanteNombre,
      'fechaPedido': fechaPedido.toIso8601String(),
      'estado': estado,
      'prioridad': prioridad,
      'usuariosEtiquetados': usuariosEtiquetados,
      'firmaUrl': firmaUrl,
      'fechaEntregaReal': fechaEntregaReal?.toIso8601String(),
      'porcentajeAvance': porcentajeAvance,
      'fuente': fuente,
      'observacionesCliente': observacionesCliente,
      'total': total,
      'createdAt': createdAt.toIso8601String(),
      'clienteRazonSocial': clienteRazonSocial,
      'obraNombre': obraNombre,
    };
  }

  bool get esFinal => ['finalizado', 'cancelado', 'rechazado', 'entregado'].contains(estado);
}

class OrdenInternaDetalle {
  final OrdenInterna orden;
  final String clienteRazonSocial;
  final String? obraNombre;
  final List<OrdenItemDetalle> items;

  OrdenInternaDetalle({
    required this.orden,
    required this.clienteRazonSocial,
    this.obraNombre,
    required this.items,
  });

  int get cantidadProductos => items.length;
}