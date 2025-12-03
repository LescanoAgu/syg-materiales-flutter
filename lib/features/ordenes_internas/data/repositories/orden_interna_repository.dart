import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import '../models/orden_interna_model.dart';
import '../models/orden_item_model.dart';
import '../models/remito_model.dart';
import '../../../../features/clientes/data/repositories/cliente_repository.dart';
import '../../../../core/services/storage_service.dart';

class OrdenInternaRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'ordenes_internas';
  final ClienteRepository _clienteRepo = ClienteRepository();

  // --- CREAR ORDEN ---
  Future<String> crearOrden({
    required String clienteId,
    required String obraId,
    required String solicitanteNombre,
    String? titulo,
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

        final itemData = {
          'id': itemRef.id,
          'ordenId': ordenRef.id,
          'productoId': i['productoId'],
          'productoNombre': i['producto']?.nombre ?? 'Producto',
          'unidad': i['producto']?.unidadBase ?? 'u',
          'cantidadSolicitada': cantidad,
          'cantidadAprobada': 0.0,
          'cantidadEntregada': 0.0,
          'precioUnitario': precio,
          'subtotal': st,
          'observaciones': i['observaciones'],
          'estadoItem': 'pendiente',
          'origen': 'stockPropio',
          'createdAt': DateTime.now().toIso8601String(),
        };
        transaction.set(itemRef, itemData);
      }

      final orden = OrdenInterna(
          id: ordenRef.id,
          numero: codigo,
          titulo: titulo,
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

  // --- EDITAR ORDEN ---
  Future<void> editarOrden({
    required String ordenId,
    required String clienteId,
    required String obraId,
    String? titulo,
    required String prioridad,
    String? observaciones,
    required List<Map<String, dynamic>> items,
  }) async {
    final batch = _firestore.batch();
    final ordenRef = _firestore.collection(_collection).doc(ordenId);

    final itemsViejos = await ordenRef.collection('items').get();
    for (var doc in itemsViejos.docs) {
      batch.delete(doc.reference);
    }

    double total = 0.0;
    for (var i in items) {
      final cantidad = (i['cantidad'] as num).toDouble();
      final precio = (i['precio'] as num).toDouble();
      final st = cantidad * precio;
      total += st;

      final itemRef = ordenRef.collection('items').doc();
      final itemData = {
        'id': itemRef.id,
        'ordenId': ordenId,
        'productoId': i['productoId'],
        'productoNombre': i['producto']?.nombre ?? 'Producto',
        'unidad': i['producto']?.unidadBase ?? 'u',
        'cantidadSolicitada': cantidad,
        'cantidadAprobada': 0.0,
        'cantidadEntregada': 0.0,
        'precioUnitario': precio,
        'subtotal': st,
        'observaciones': i['observaciones'],
        'estadoItem': 'pendiente',
        'origen': 'stockPropio',
        'createdAt': DateTime.now().toIso8601String(),
      };
      batch.set(itemRef, itemData);
    }

    final cliente = await _clienteRepo.obtenerPorId(clienteId);
    final obraDoc = await _firestore.collection('obras').doc(obraId).get();

    batch.update(ordenRef, {
      'clienteId': clienteId,
      'obraId': obraId,
      'clienteRazonSocial': cliente?.razonSocial,
      'obraNombre': obraDoc.exists ? (obraDoc.data()?['nombre'] as String?) : null,
      'titulo': titulo,
      'prioridad': prioridad,
      'observacionesCliente': observaciones,
      'total': total,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    await batch.commit();
  }

  // --- APROBAR ORDEN ---
  Future<void> aprobarOrdenConLogistica({
    required String ordenId,
    required List<OrdenItem> itemsConfigurados,
    required String usuarioAprobadorId,
  }) async {
    final batch = _firestore.batch();
    final ordenRef = _firestore.collection(_collection).doc(ordenId);

    for (var item in itemsConfigurados) {
      final itemRef = ordenRef.collection('items').doc(item.id);
      batch.update(itemRef, {
        'cantidadAprobada': item.cantidadAprobada,
        'origen': item.origen.name,
        'proveedorId': item.proveedorId,
        'precioCompra': item.precioCompra,
      });
    }

    batch.update(ordenRef, {
      'estado': 'aprobado',
      'aprobadoPorUsuarioId': usuarioAprobadorId,
      'aprobadoFecha': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    await batch.commit();
  }
  // --- GENERAR REMITO (Actualizado con Snapshot de Saldos) ---
  Future<void> generarRemito({
    required String ordenId,
    required List<Map<String, dynamic>> itemsDespachados,
    required Uint8List firmaAutoriza,
    required Uint8List firmaRecibe,
    required String usuarioId,
    required String usuarioNombre,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // 1. Subir firmas
    final urlAutoriza = await StorageService().subirFirma(firmaAutoriza, 'remito_${ordenId}_${timestamp}_auth');
    final urlRecibe = await StorageService().subirFirma(firmaRecibe, 'remito_${ordenId}_${timestamp}_rec');

    if (urlAutoriza == null || urlRecibe == null) throw Exception("Error al subir las imágenes de las firmas");

    // 2. Preparar datos previos
    final ordenRef = _firestore.collection(_collection).doc(ordenId);
    final remitosSnap = await ordenRef.collection('remitos').count().get();
    final numRemito = (remitosSnap.count ?? 0) + 1;

    final ordenDoc = await ordenRef.get();
    if (!ordenDoc.exists) throw Exception("Orden no encontrada");

    final ordenNumero = ordenDoc.data()?['numero'] ?? '???';
    final codigoRemito = '$ordenNumero-R${numRemito.toString().padLeft(3, '0')}';

    return _firestore.runTransaction((transaction) async {
      await transaction.get(ordenRef);

      List<ItemRemito> itemsRemitoModel = [];
      double totalSolicitadoGlobal = 0;
      double totalEntregadoGlobal = 0;

      final itemsOrdenSnap = await ordenRef.collection('items').get();

      for (var doc in itemsOrdenSnap.docs) {
        final data = doc.data(); // Ya tiene el cast en tu versión corregida
        final id = doc.id;

        double solicitada = (data['cantidadAprobada'] ?? 0).toDouble();
        double entregadaPrevia = (data['cantidadEntregada'] ?? 0).toDouble();

        // Verificar si se despacha
        final despachoItem = itemsDespachados.firstWhere(
                (e) => e['itemId'] == id,
            orElse: () => <String, dynamic>{}
        );

        double aDespachar = 0;
        if (despachoItem.isNotEmpty) {
          aDespachar = (despachoItem['cantidad'] as num).toDouble();

          if (entregadaPrevia + aDespachar > solicitada + 0.01) {
            throw Exception("Exceso de cantidad en ${data['productoNombre']}");
          }

          // ✅ AQUÍ ESTÁ LA MAGIA: Guardamos la foto del momento
          itemsRemitoModel.add(ItemRemito(
            productoId: data['productoId'] ?? '',
            productoNombre: data['productoNombre'] ?? 'Producto',
            cantidad: aDespachar,
            unidad: data['unidad'] ?? 'u',
            // Snapshot para el reporte:
            cantidadSolicitadaTotal: solicitada,
            saldoPendienteAnterior: solicitada - entregadaPrevia, // Cuánto faltaba antes de este remito
          ));

          // Descuento Stock
          if (data['origen'] == 'stockPropio') {
            final stockRef = _firestore.collection('productos').doc(data['productoId']);
            final stockDoc = await transaction.get(stockRef);
            if (stockDoc.exists) {
              transaction.update(stockRef, {
                'cantidadDisponible': FieldValue.increment(-aDespachar)
              });
            }
          }

          // Actualizar Item (Aquí cambiamos entregadaPrevia, por eso guardamos el snapshot antes)
          transaction.update(doc.reference, {
            'cantidadEntregada': entregadaPrevia + aDespachar,
            'estadoItem': (entregadaPrevia + aDespachar >= solicitada - 0.01) ? 'completado' : 'parcial',
          });
        }

        totalSolicitadoGlobal += solicitada;
        totalEntregadoGlobal += (entregadaPrevia + aDespachar);
      }

      final remitoRef = ordenRef.collection('remitos').doc();
      final nuevoRemito = Remito(
        id: remitoRef.id,
        ordenId: ordenId,
        numeroRemito: codigoRemito,
        fecha: DateTime.now(),
        items: itemsRemitoModel,
        firmaAutorizoUrl: urlAutoriza,
        firmaRecibioUrl: urlRecibe,
        usuarioDespachadorId: usuarioId,
        usuarioDespachadorNombre: usuarioNombre,
      );

      transaction.set(remitoRef, nuevoRemito.toMap());

      double avance = totalSolicitadoGlobal > 0 ? (totalEntregadoGlobal / totalSolicitadoGlobal) : 0;
      String nuevoEstado = (avance >= 0.99) ? 'entregado' : 'en_curso';

      transaction.update(ordenRef, {
        'porcentajeAvance': avance,
        'estado': nuevoEstado,
        'updatedAt': DateTime.now().toIso8601String(),
        if (nuevoEstado == 'entregado') 'fechaEntregaReal': DateTime.now().toIso8601String(),
        if (nuevoEstado == 'entregado') 'firmaUrl': urlRecibe,
      });
    });
  }

  // --- LECTURAS ---
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
      return OrdenItem.fromMap(idata);
    }).toList();

    final itemsDetalle = items.map((i) => OrdenItemDetalle(item: i)).toList();

    return OrdenInternaDetalle(
      orden: OrdenInterna.fromMap(data),
      clienteRazonSocial: data['clienteRazonSocial'] ?? '?',
      obraNombre: data['obraNombre'],
      items: itemsDetalle,
    );
  }

  Future<List<OrdenInternaDetalle>> getOrdenesPorCliente(String clienteId) async {
    try {
      final snap = await _firestore.collection(_collection)
          .where('clienteId', isEqualTo: clienteId)
          .orderBy('createdAt', descending: true)
          .get();

      return snap.docs.map((d) {
        final data = d.data();
        data['id'] = d.id;
        return OrdenInternaDetalle(
          orden: OrdenInterna.fromMap(data),
          clienteRazonSocial: data['clienteRazonSocial'] ?? '?',
          obraNombre: data['obraNombre'],
          items: [],
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Remito>> obtenerRemitos(String ordenId) async {
    final snap = await _firestore.collection(_collection).doc(ordenId).collection('remitos').orderBy('fecha', descending: true).get();
    return snap.docs.map((doc) => Remito.fromMap(doc.data(), doc.id)).toList();
  }

  Future<void> eliminar(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  Future<void> asignarResponsable(String ordenId, String uid, String nombre) async {
    await _firestore.collection(_collection).doc(ordenId).update({'responsableEntregaId': uid, 'responsableEntregaNombre': nombre});
  }

  Future<void> etiquetarUsuario(String ordenId, String uid) async {
    await _firestore.collection(_collection).doc(ordenId).update({'usuariosEtiquetados': FieldValue.arrayUnion([uid])});
  }

  Future<void> finalizarEntregaConFirma({required String ordenId, required Uint8List firmaBytes}) async {}
  Future<List<OrdenInternaDetalle>> getMisDespachos(String userId) async => [];
  Future<void> registrarDespacho({required String ordenId, required String ordenNumero, required String obraId, required String usuarioId, required String usuarioNombre, required List<Map<String, dynamic>> itemsDespachados}) async { throw UnimplementedError(); }
}