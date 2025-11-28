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
  final String estado; // 'solicitado', 'aprobado', 'en_curso', 'finalizado', 'cancelado'

  // Logística y Prioridad
  final String prioridad; // 'baja', 'media', 'alta', 'urgente'
  final String? responsableEntregaId;
  final String? responsableEntregaNombre;
  final double porcentajeAvance;

  // ✅ NUEVOS CAMPOS: Fuente de Abastecimiento
  final String? fuente; // 'stock' o 'proveedor'
  final String? proveedorAsignadoId; // ID del proveedor si es compra directa

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
    this.prioridad = 'media',
    this.responsableEntregaId,
    this.responsableEntregaNombre,
    this.porcentajeAvance = 0.0,

    // Nuevos
    this.fuente,
    this.proveedorAsignadoId,

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

      prioridad: map['prioridad']?.toString() ?? 'media',
      responsableEntregaId: map['responsableEntregaId']?.toString(),
      responsableEntregaNombre: map['responsableEntregaNombre']?.toString(),
      porcentajeAvance: (map['porcentajeAvance'] as num?)?.toDouble() ?? 0.0,

      // Nuevos
      fuente: map['fuente']?.toString(),
      proveedorAsignadoId: map['proveedorAsignadoId']?.toString(),

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

      'prioridad': prioridad,
      'responsableEntregaId': responsableEntregaId,
      'responsableEntregaNombre': responsableEntregaNombre,
      'porcentajeAvance': porcentajeAvance,

      // Nuevos
      'fuente': fuente,
      'proveedorAsignadoId': proveedorAsignadoId,

      'total': total,
      'createdAt': createdAt.toIso8601String(),
      'clienteRazonSocial': clienteRazonSocial,
      'obraNombre': obraNombre,
    };
  }

  bool get esFinal => ['finalizado', 'cancelado', 'rechazado'].contains(estado);
  bool get esUrgente => prioridad == 'urgente' || prioridad == 'alta';
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

  double get progresoReal {
    if (items.isEmpty) return 0.0;
    double totalSolicitado = 0;
    double totalEntregado = 0;
    for (var i in items) {
      totalSolicitado += i.cantidadFinal;
      totalEntregado += i.item.cantidadEntregada;
    }
    if (totalSolicitado == 0) return 0.0;
    return (totalEntregado / totalSolicitado).clamp(0.0, 1.0);
  }
}