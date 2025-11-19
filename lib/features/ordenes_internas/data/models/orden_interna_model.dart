import 'orden_item_model.dart';

class OrdenInterna {
  final String? id;
  final String numero;
  final String clienteId;
  final String obraId;
  final String solicitanteNombre;
  final String? solicitanteEmail;
  final String? solicitanteTelefono;
  final DateTime fechaPedido;
  final DateTime? fechaEntregaEstimada;
  final String estado;
  final String? observacionesCliente;
  final String? observacionesInternas;
  final String? motivoRechazo;
  final double total;
  final String? aprobadoPorUsuarioId;
  final DateTime? aprobadoFecha;
  final String? usuarioCreadorId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Campos desnormalizados
  final String? clienteRazonSocial;
  final String? obraNombre;

  OrdenInterna({
    this.id,
    required this.numero,
    required this.clienteId,
    required this.obraId,
    required this.solicitanteNombre,
    this.solicitanteEmail,
    this.solicitanteTelefono,
    required this.fechaPedido,
    this.fechaEntregaEstimada,
    this.estado = 'solicitado',
    this.observacionesCliente,
    this.observacionesInternas,
    this.motivoRechazo,
    this.total = 0,
    this.aprobadoPorUsuarioId,
    this.aprobadoFecha,
    this.usuarioCreadorId,
    required this.createdAt,
    this.updatedAt,
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
      solicitanteEmail: map['solicitanteEmail']?.toString(),
      solicitanteTelefono: map['solicitanteTelefono']?.toString(),
      fechaPedido: map['fechaPedido'] != null ? DateTime.parse(map['fechaPedido']) : DateTime.now(),
      fechaEntregaEstimada: map['fechaEntregaEstimada'] != null ? DateTime.parse(map['fechaEntregaEstimada']) : null,
      estado: map['estado']?.toString() ?? 'solicitado',
      observacionesCliente: map['observacionesCliente']?.toString(),
      observacionesInternas: map['observacionesInternas']?.toString(),
      motivoRechazo: map['motivoRechazo']?.toString(),
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      aprobadoPorUsuarioId: map['aprobadoPorUsuarioId']?.toString(),
      aprobadoFecha: map['aprobadoFecha'] != null ? DateTime.parse(map['aprobadoFecha']) : null,
      usuarioCreadorId: map['usuarioCreadorId']?.toString(),
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
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
      'total': total,
      'createdAt': createdAt.toIso8601String(),
      'clienteRazonSocial': clienteRazonSocial,
      'obraNombre': obraNombre,
    };
  }

  bool get esFinal => ['despachado', 'facturado', 'cancelado', 'rechazado'].contains(estado);
}

class OrdenInternaDetalle {
  final OrdenInterna orden;
  final String clienteRazonSocial;
  final String? obraNombre;
  final List<OrdenItemDetalle> items;
  final String? aprobadoPorNombre;

  OrdenInternaDetalle({
    required this.orden,
    required this.clienteRazonSocial,
    this.obraNombre,
    required this.items,
    this.aprobadoPorNombre,
  });

  int get cantidadProductos => items.length;
  double get cantidadTotal => items.fold(0.0, (sum, item) => sum + item.cantidadFinal);
  bool get tieneModificaciones => false; // Placeholder logic
}