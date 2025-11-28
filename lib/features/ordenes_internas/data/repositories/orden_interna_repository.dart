import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/orden_interna_model.dart';
import '../models/orden_item_model.dart';
import '../../../../features/clientes/data/repositories/cliente_repository.dart';
import '../../../../features/obras/data/repositories/obra_repository.dart';

class OrdenInternaRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'ordenes_internas';
  final ClienteRepository _clienteRepo = ClienteRepository();

  // --- CREAR ORDEN ---
  Future<String> crearOrden({
    required String clienteId,
    required String obraId,
    required String solicitanteNombre,
    String? observacionesCliente,
    required List<Map<String, dynamic>> items,
    String? usuarioCreadorId,
    String prioridad = 'media',
  }) async {
    return _firestore.runTransaction((transaction) async {
      final contadorRef = _firestore.collection('sistema').doc('contadores');
      final contadorDoc = await transaction.get(contadorRef);
      int nuevoNum = 1;
      if (contadorDoc.exists) {
        final data = contadorDoc.data();
        if (data != null && data.containsKey('ordenes_count')) {
          nuevoNum = (data['ordenes_count'] as num).toInt() + 1;
        }
      }
      transaction.set(contadorRef, {'ordenes_count': nuevoNum}, SetOptions(merge: true));
      String codigo = 'OI-${nuevoNum.toString().padLeft(4, '0')}';

      final cliente = await _clienteRepo.obtenerPorId(clienteId);
      final obraDoc = await _firestore.collection('obras').doc(obraId).get();

      final ordenRef = _firestore.collection(_collection).doc();
      double total = 0.0;

      for (var i in items) {
        final cantidad = (i['cantidad'] as num).toDouble();
        final precio = (i['precio'] as num).toDouble();
        final st = cantidad * precio;
        total += st;

        final itemRef = ordenRef.collection('items').doc();
        final item = OrdenItem(
          id: itemRef.id,
          ordenId: ordenRef.id,
          productoId: i['productoId'],
          cantidadSolicitada: cantidad,
          cantidadEntregada: 0.0,
          precioUnitario: precio,
          subtotal: st,
          createdAt: DateTime.now(),
          observaciones: i['observaciones'],
          estadoItem: 'pendiente',
        );

        final itemMap = item.toMap();
        final prod = i['producto'];
        if (prod != null) {
          try {
            itemMap['productoNombre'] = prod.nombre;
            itemMap['productoCodigo'] = prod.codigo;
            itemMap['unidadBase'] = prod.unidadBase;
          } catch (_) {}
        }
        transaction.set(itemRef, itemMap);
      }

      final orden = OrdenInterna(
          id: ordenRef.id,
          numero: codigo,
          clienteId: clienteId,
          obraId: obraId,
          solicitanteNombre: solicitanteNombre,
          fechaPedido: DateTime.now(),
          total: total,
          createdAt: DateTime.now(),
          estado: 'solicitado',
          prioridad: prioridad,
          porcentajeAvance: 0.0,
          observacionesCliente: observacionesCliente,
          clienteRazonSocial: cliente?.razonSocial,
          obraNombre: obraDoc.exists ? (obraDoc.data()?['nombre'] as String?) : null
      );

      transaction.set(ordenRef, orden.toMap());
      return ordenRef.id;
    });
  }

  // --- APROBAR ORDEN (CON VALIDACIÓN DE STOCK) ---
  Future<void> aprobarOrden({
    required String ordenId,
    required String fuente, // 'stock' o 'proveedor'
    String? proveedorId,
    required String usuarioAprobadorId,
  }) async {
    return _firestore.runTransaction((transaction) async {
      final ordenRef = _firestore.collection(_collection).doc(ordenId);

      // ✅ VALIDACIÓN: Si la fuente es Stock, verificamos que alcance.
      if (fuente == 'stock') {
        final itemsSnap = await ordenRef.collection('items').get();

        for (var doc in itemsSnap.docs) {
          final itemData = doc.data();
          final productoId = itemData['productoId'];
          final productoNombre = itemData['productoNombre'] ?? 'Producto';
          final cantidadSolicitada = (itemData['cantidadSolicitada'] as num).toDouble();

          // Consultar stock real en la BD
          final stockRef = _firestore.collection('stock').doc(productoId);
          final stockDoc = await transaction.get(stockRef);

          if (!stockDoc.exists) {
            throw Exception("El producto $productoNombre no tiene registro de stock.");
          }

          final stockDisponible = (stockDoc.data()?['cantidadDisponible'] as num?)?.toDouble() ?? 0.0;

          // 🚨 BLOQUEO SI NO ALCANZA
          if (stockDisponible < cantidadSolicitada) {
            throw Exception("❌ Stock insuficiente para $productoNombre.\nSolicitado: $cantidadSolicitada | Disponible: $stockDisponible");
          }
        }
      }

      transaction.update(ordenRef, {
        'estado': 'aprobado',
        'fuente': fuente,
        'proveedorAsignadoId': proveedorId,
        'aprobadoPorUsuarioId': usuarioAprobadorId,
        'aprobadoFecha': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    });
  }

  // --- ASIGNAR RESPONSABLE ---
  Future<void> asignarResponsable(String ordenId, String usuarioId, String usuarioNombre) async {
    await _firestore.collection(_collection).doc(ordenId).update({
      'responsableEntregaId': usuarioId,
      'responsableEntregaNombre': usuarioNombre,
      'estado': 'en_curso',
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // --- REGISTRAR DESPACHO ---
  Future<void> registrarDespacho({
    required String ordenId,
    required String ordenNumero,
    required String obraId,
    required String usuarioId,
    required String usuarioNombre,
    required List<Map<String, dynamic>> itemsDespachados,
  }) async {
    return _firestore.runTransaction((transaction) async {
      final ordenRef = _firestore.collection(_collection).doc(ordenId);
      final ordenDoc = await transaction.get(ordenRef);
      if (!ordenDoc.exists) throw Exception("La orden no existe");

      final dataOrden = ordenDoc.data()!;
      final estadoActual = dataOrden['estado'];
      final fuente = dataOrden['fuente'];

      if (estadoActual == 'finalizado' || estadoActual == 'cancelado') {
        throw Exception("No se puede despachar una orden cerrada");
      }

      double totalSolicitadoOrden = 0;
      double totalEntregadoOrden = 0;

      final itemsSnap = await ordenRef.collection('items').get();

      for (var doc in itemsSnap.docs) {
        final data = doc.data();
        double solicitada = (data['cantidadAprobada'] ?? data['cantidadSolicitada'] ?? 0).toDouble();
        double entregadaPrevia = (data['cantidadEntregada'] ?? 0).toDouble();

        final despachoActual = itemsDespachados.firstWhere((e) => e['itemId'] == doc.id, orElse: () => {});

        double cantidadADespachar = 0;
        if (despachoActual.isNotEmpty) {
          cantidadADespachar = (despachoActual['cantidad'] as num).toDouble();

          if (entregadaPrevia + cantidadADespachar > solicitada) {
            throw Exception("Exceso de cantidad en ${data['productoNombre']}");
          }

          // ✅ VALIDACIÓN EXTRA: Verificar stock físico antes de restar
          if (fuente == 'stock') {
            final stockRef = _firestore.collection('stock').doc(data['productoId']);
            final stockDoc = await transaction.get(stockRef);
            final disponible = (stockDoc.data()?['cantidadDisponible'] as num?)?.toDouble() ?? 0.0;

            if (disponible < cantidadADespachar) {
              throw Exception("Stock insuficiente en pañol para despachar ${data['productoNombre']}");
            }

            // Actualizar Stock (Resta)
            transaction.update(stockRef, {
              'cantidadDisponible': FieldValue.increment(-cantidadADespachar),
              'ultimaActualizacion': DateTime.now().toIso8601String(),
            });

            // Actualizar Espejo Producto
            final prodRef = _firestore.collection('productos').doc(data['productoId']);
            transaction.update(prodRef, {
              'cantidadDisponible': FieldValue.increment(-cantidadADespachar),
            });
          }

          transaction.update(doc.reference, {
            'cantidadEntregada': entregadaPrevia + cantidadADespachar,
            'estadoItem': (entregadaPrevia + cantidadADespachar >= solicitada) ? 'completado' : 'parcial',
          });

          // ✅ REGISTRO DE MOVIMIENTO (ÚNICO)
          final movRef = _firestore.collection('movimientos_stock').doc();
          transaction.set(movRef, {
            'productoId': data['productoId'],
            'productoNombre': data['productoNombre'],
            'tipo': 'salida',
            'subtipo': 'orden_interna',
            'fuente': fuente,
            'cantidad': cantidadADespachar,
            'motivo': 'Despacho Orden $ordenNumero',
            'referenciaId': ordenId,
            'usuarioId': usuarioId,
            'usuarioNombre': usuarioNombre,
            'fecha': DateTime.now().toIso8601String(),
            'obraId': obraId,
          });
        }

        totalSolicitadoOrden += solicitada;
        totalEntregadoOrden += (entregadaPrevia + cantidadADespachar);
      }

      double nuevoAvance = 0.0;
      if (totalSolicitadoOrden > 0) {
        nuevoAvance = (totalEntregadoOrden / totalSolicitadoOrden).clamp(0.0, 1.0);
      }

      transaction.update(ordenRef, {
        'porcentajeAvance': nuevoAvance,
        'updatedAt': DateTime.now().toIso8601String(),
        'estado': (nuevoAvance >= 1.0) ? 'finalizado' : 'en_curso',
      });
    });
  }

  // --- LECTURA ---
  Future<List<OrdenInternaDetalle>> getOrdenes({String? estado}) async {
    Query query = _firestore.collection(_collection).orderBy('createdAt', descending: true);
    if (estado != null) query = query.where('estado', isEqualTo: estado);
    final snap = await query.get();
    return snap.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      data['id'] = d.id;
      return OrdenInternaDetalle(
        orden: OrdenInterna.fromMap(data),
        clienteRazonSocial: data['clienteRazonSocial'] ?? '?',
        obraNombre: data['obraNombre'],
        items: [],
      );
    }).toList();
  }

  Future<OrdenInternaDetalle?> getOrdenPorId(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    data['id'] = doc.id;
    final itemsSnap = await doc.reference.collection('items').get();
    final items = itemsSnap.docs.map((d) {
      final idata = d.data();
      idata['id'] = d.id;
      return OrdenItemDetalle(
        item: OrdenItem.fromMap(idata),
        productoNombre: idata['productoNombre'] ?? '?',
        productoCodigo: idata['productoCodigo'] ?? '?',
        unidadBase: idata['unidadBase'] ?? 'u',
        categoriaNombre: '',
      );
    }).toList();
    return OrdenInternaDetalle(
      orden: OrdenInterna.fromMap(data),
      clienteRazonSocial: data['clienteRazonSocial'] ?? '?',
      obraNombre: data['obraNombre'],
      items: items,
    );
  }

  Future<void> eliminar(String id) async {
    final ref = _firestore.collection(_collection).doc(id);
    final items = await ref.collection('items').get();
    for (var doc in items.docs) await doc.reference.delete();
    await ref.delete();
  }
}