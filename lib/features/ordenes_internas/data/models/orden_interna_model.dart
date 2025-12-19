import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

// ==========================================
// 1. ENUMS Y CLASES AUXILIARES
// ==========================================

enum TipoDespacho { empresa, proveedor, retiro }
enum OrigenAbastecimiento { stock_propio, compra_proveedor, acopio_cliente }

/// Clase que representa un item (producto) dentro de la orden.
class OrdenItemDetalle extends Equatable {
  final String materialId;
  final String nombreMaterial;
  final String? productoCodigo;
  final String unidadBase;
  final int cantidad;
  final int cantidadEntregada;

  const OrdenItemDetalle({
    required this.materialId,
    required this.nombreMaterial,
    this.productoCodigo,
    this.unidadBase = 'u',
    required this.cantidad,
    this.cantidadEntregada = 0,
  });

  // Getters útiles
  bool get estaCompleto => cantidadEntregada >= cantidad;
  int get saldoPendiente => cantidad - cantidadEntregada;

  // Getter legacy
  String get productoNombre => nombreMaterial;

  OrdenItemDetalle copyWith({int? cantidad, int? cantidadEntregada}) {
    return OrdenItemDetalle(
      materialId: materialId,
      nombreMaterial: nombreMaterial,
      productoCodigo: productoCodigo,
      unidadBase: unidadBase,
      cantidad: cantidad ?? this.cantidad,
      cantidadEntregada: cantidadEntregada ?? this.cantidadEntregada,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productoId': materialId,
      'productoNombre': nombreMaterial,
      'productoCodigo': productoCodigo,
      'unidad': unidadBase,
      'cantidad': cantidad,
      'cantidadEntregada': cantidadEntregada,
    };
  }

  @override
  List<Object?> get props => [materialId, nombreMaterial, cantidad, cantidadEntregada];
}

// ==========================================
// 2. LA CLASE PRINCIPAL (Datos de la Orden)
// ==========================================

class OrdenInterna extends Equatable {
  final String? id;
  final String numero;

  final String clienteId;
  final String obraId;
  final String solicitanteId;
  final String solicitanteNombre;

  final DateTime fechaCreacion;
  final String estado;
  final String prioridad;

  final String? titulo;
  final String? observacionesCliente;

  // Abastecimiento y Logística
  final bool esRetiroAcopio;
  final String? acopioId;
  final OrigenAbastecimiento origen; // Nuevo: Define de dónde sale la mercadería

  final String destino;
  final String? observaciones;

  // Proveedor asignado (para Compra Directa o Acopio)
  final String? proveedorId;
  final String? proveedorNombre;

  // Quién hace el envío
  final TipoDespacho? tipoDespacho;

  // Items
  final List<OrdenItemDetalle> items;

  // Auditoría
  final String? modificadoPor;
  final String? observacionesAprobacion;
  final String? aprobadoPor;
  final DateTime? fechaAprobacion;

  const OrdenInterna({
    this.id,
    required this.numero,
    required this.clienteId,
    required this.obraId,
    required this.solicitanteId,
    required this.solicitanteNombre,
    required this.fechaCreacion,
    required this.estado,
    required this.prioridad,
    required this.items,
    this.titulo,
    this.observacionesCliente,
    this.esRetiroAcopio = false,
    this.acopioId,
    this.origen = OrigenAbastecimiento.stock_propio,
    this.destino = '',
    this.observaciones,
    this.proveedorId,
    this.proveedorNombre,
    this.tipoDespacho,
    this.modificadoPor,
    this.observacionesAprobacion,
    this.aprobadoPor,
    this.fechaAprobacion,
  });

  @override
  List<Object?> get props => [id, numero, estado, items, proveedorId, tipoDespacho];
}

// ==========================================
// 3. EL WRAPPER PARA UI
// ==========================================

class OrdenInternaDetalle {
  final OrdenInterna orden;
  final String clienteRazonSocial;
  final String? obraNombre;

  const OrdenInternaDetalle({
    required this.orden,
    required this.clienteRazonSocial,
    this.obraNombre,
  });

  List<OrdenItemDetalle> get items => orden.items;
  int get cantidadProductos => orden.items.length;
  String get productoCodigo => orden.items.isNotEmpty ? (orden.items.first.productoCodigo ?? '') : '';

  // Cálculo de progreso (0.0 a 1.0) para la barra de carga
  double get progresoGeneral {
    if (orden.items.isEmpty) return 0.0;
    double totalP = 0;
    double totalE = 0;
    for (var i in orden.items) {
      totalP += i.cantidad;
      totalE += i.cantidadEntregada;
    }
    if (totalP == 0) return 0.0;
    double calculo = totalE / totalP;
    return calculo > 1.0 ? 1.0 : calculo; // Tope 100%
  }
}

// ==========================================
// 4. EL MODELO (Firebase)
// ==========================================

class OrdenInternaModel extends OrdenInterna {
  const OrdenInternaModel({
    super.id,
    required super.numero,
    required super.clienteId,
    required super.obraId,
    required super.solicitanteId,
    required super.solicitanteNombre,
    required super.fechaCreacion,
    required super.estado,
    required super.prioridad,
    required super.items,
    super.titulo,
    super.observacionesCliente,
    super.esRetiroAcopio,
    super.acopioId,
    super.origen,
    super.destino,
    super.observaciones,
    super.proveedorId,
    super.proveedorNombre,
    super.tipoDespacho,
    super.modificadoPor,
    super.observacionesAprobacion,
    super.aprobadoPor,
    super.fechaAprobacion,
  });

  factory OrdenInternaModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrdenInternaModel.fromMap(data, doc.id);
  }

  factory OrdenInternaModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime getDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      return DateTime.now();
    }

    return OrdenInternaModel(
      id: id,
      numero: map['numero']?.toString() ?? '---',
      clienteId: map['clienteId']?.toString() ?? '',
      obraId: map['obraId']?.toString() ?? '',
      solicitanteId: map['solicitanteId']?.toString() ?? '',
      solicitanteNombre: map['solicitanteNombre']?.toString() ?? '',
      fechaCreacion: map['createdAt'] != null ? getDate(map['createdAt']) : (map['fechaPedido'] != null ? getDate(map['fechaPedido']) : DateTime.now()),
      estado: map['estado']?.toString() ?? 'solicitado',
      prioridad: map['prioridad']?.toString() ?? 'media',
      titulo: map['titulo']?.toString(),
      observacionesCliente: map['observacionesCliente']?.toString(),

      // Mapeo Inteligente
      esRetiroAcopio: map['esRetiroAcopio'] ?? false,
      acopioId: map['acopioId']?.toString(),
      origen: map['origen'] != null
          ? OrigenAbastecimiento.values.firstWhere((e) => e.name == map['origen'], orElse: () => OrigenAbastecimiento.stock_propio)
          : (map['esRetiroAcopio'] == true ? OrigenAbastecimiento.acopio_cliente : OrigenAbastecimiento.stock_propio),

      destino: map['destino'] ?? '',
      observaciones: map['observaciones']?.toString(),
      proveedorId: map['proveedorId'],
      proveedorNombre: map['proveedor'],

      tipoDespacho: map['tipoDespacho'] != null
          ? TipoDespacho.values.firstWhere((e) => e.name == map['tipoDespacho'], orElse: () => TipoDespacho.empresa)
          : null,

      modificadoPor: map['modificadoPor'],
      observacionesAprobacion: map['observacionesAprobacion'],
      aprobadoPor: map['aprobadoPor'],
      fechaAprobacion: map['fechaAprobacion'] != null ? getDate(map['fechaAprobacion']) : null,

      items: (map['items'] as List<dynamic>? ?? []).map((item) {
        return OrdenItemDetalle(
          materialId: item['productoId'] ?? item['materialId'] ?? '',
          nombreMaterial: item['productoNombre'] ?? item['nombreMaterial'] ?? 'Sin Nombre',
          productoCodigo: item['productoCodigo'],
          unidadBase: item['unidad'] ?? 'u',
          cantidad: (item['cantidad'] as num?)?.toInt() ?? 0,
          cantidadEntregada: (item['cantidadEntregada'] as num?)?.toInt() ?? 0,
        );
      }).toList(),
    );
  }

  Map<String, dynamic> toDocument() {
    return {
      'numero': numero,
      'clienteId': clienteId,
      'obraId': obraId,
      'solicitanteId': solicitanteId,
      'solicitanteNombre': solicitanteNombre,
      'createdAt': Timestamp.fromDate(fechaCreacion),
      'estado': estado,
      'prioridad': prioridad,
      'titulo': titulo,
      'observacionesCliente': observacionesCliente,
      'esRetiroAcopio': esRetiroAcopio,
      'acopioId': acopioId,
      'origen': origen.name,
      'destino': destino,
      'observaciones': observaciones,
      'proveedorId': proveedorId,
      'proveedor': proveedorNombre,
      'tipoDespacho': tipoDespacho?.name,
      'modificadoPor': modificadoPor,
      'observacionesAprobacion': observacionesAprobacion,
      'aprobadoPor': aprobadoPor,
      'fechaAprobacion': fechaAprobacion != null ? Timestamp.fromDate(fechaAprobacion!) : null,
      'items': items.map((item) => item.toMap()).toList(),
    };
  }
}