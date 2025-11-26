import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/orden_interna_model.dart';
import '../models/orden_item_model.dart';
import '../../../../features/clientes/data/repositories/cliente_repository.dart';
import '../../../../features/obras/data/repositories/obra_repository.dart';

class OrdenInternaRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'ordenes_internas';
  final ClienteRepository _clienteRepo = ClienteRepository();

  Future<String> crearOrden({
    required String clienteId,
    required String obraId,
    required String solicitanteNombre,
    String? observacionesCliente,
    required List<Map<String, dynamic>> items,
    String? usuarioCreadorId,
  }) async {
    return _firestore.runTransaction((transaction) async {
      // 1. CONTADOR (Lógica desglosada y segura)
      final contadorRef = _firestore.collection('sistema').doc('contadores');
      final contadorDoc = await transaction.get(contadorRef);

      int nuevoNum = 1;
      if (contadorDoc.exists) {
        final data = contadorDoc.data();
        // Verificamos explícitamente que el dato exista y sea numérico
        if (data != null && data.containsKey('ordenes_count')) {
          nuevoNum = (data['ordenes_count'] as num).toInt() + 1;
        }
      }

      // Actualizar contador
      transaction.set(contadorRef, {'ordenes_count': nuevoNum}, SetOptions(merge: true));

      // Generar Código (Ej: OI-0005)
      String codigo = 'OI-${nuevoNum.toString().padLeft(4, '0')}';

      // 2. OBTENER DATOS RELACIONADOS
      final cliente = await _clienteRepo.obtenerPorId(clienteId);
      final obraDoc = await _firestore.collection('obras').doc(obraId).get();

      // 3. PREPARAR REFERENCIA DE ORDEN
      final ordenRef = _firestore.collection(_collection).doc();
      double total = 0.0;

      // 4. PROCESAR ITEMS
      for (var i in items) {
        // Casting explícito y conversión a double para evitar errores de 'num'
        final cantidad = (i['cantidad'] as num).toDouble();
        final precio = (i['precio'] as num).toDouble();
        final st = cantidad * precio; // Ahora st es double seguro

        total += st;

        final itemRef = ordenRef.collection('items').doc();

        // Crear objeto item
        final item = OrdenItem(
          id: itemRef.id,
          ordenId: ordenRef.id,
          productoId: i['productoId'],
          cantidadSolicitada: cantidad,
          precioUnitario: precio,
          subtotal: st,
          createdAt: DateTime.now(),
          observaciones: i['observaciones'],
        );

        // Mapa base del item
        final itemMap = item.toMap();

        // Desnormalización (Guardar nombre del producto en el item para historial)
        final prod = i['producto'];
        if (prod != null) {
          try {
            // Accedemos a las propiedades del objeto ProductoModel
            itemMap['productoNombre'] = prod.nombre;
            itemMap['productoCodigo'] = prod.codigo;
            itemMap['unidadBase'] = prod.unidadBase;
          } catch (e) {
            print("⚠️ Error menor desnormalizando producto en orden: $e");
          }
        }

        transaction.set(itemRef, itemMap);
      }

      // 5. GUARDAR LA ORDEN PRINCIPAL
      final orden = OrdenInterna(
          id: ordenRef.id,
          numero: codigo,
          clienteId: clienteId,
          obraId: obraId,
          solicitanteNombre: solicitanteNombre,
          fechaPedido: DateTime.now(),
          total: total,
          createdAt: DateTime.now(),
          observacionesCliente: observacionesCliente,
          // Datos desnormalizados para lectura rápida
          clienteRazonSocial: cliente?.razonSocial,
          obraNombre: obraDoc.exists ? (obraDoc.data()?['nombre'] as String?) : null
      );

      transaction.set(ordenRef, orden.toMap());

      return ordenRef.id;
    });
  }

  // ========================================
  // MÉTODOS DE LECTURA Y GESTIÓN
  // ========================================

  Future<List<OrdenInternaDetalle>> getOrdenes({String? estado}) async {
    Query query = _firestore.collection(_collection).orderBy('createdAt', descending: true);

    if (estado != null) {
      query = query.where('estado', isEqualTo: estado);
    }

    final snap = await query.get();

    return snap.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      data['id'] = d.id;

      return OrdenInternaDetalle(
        orden: OrdenInterna.fromMap(data),
        clienteRazonSocial: data['clienteRazonSocial'] ?? '?',
        obraNombre: data['obraNombre'],
        items: [], // Lista vacía en vista general para optimizar
      );
    }).toList();
  }

  Future<OrdenInternaDetalle?> getOrdenPorId(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    data['id'] = doc.id;

    // Cargar subcolección items
    final itemsSnap = await doc.reference.collection('items').get();
    final items = itemsSnap.docs.map((d) {
      final idata = d.data();
      idata['id'] = d.id;

      return OrdenItemDetalle(
        item: OrdenItem.fromMap(idata),
        productoNombre: idata['productoNombre'] ?? '?',
        productoCodigo: idata['productoCodigo'] ?? '?',
        unidadBase: idata['unidadBase'] ?? 'u',
        categoriaNombre: '', // Dato opcional
      );
    }).toList();

    return OrdenInternaDetalle(
      orden: OrdenInterna.fromMap(data),
      clienteRazonSocial: data['clienteRazonSocial'] ?? '?',
      obraNombre: data['obraNombre'],
      items: items,
    );
  }

  Future<void> cambiarEstado({required String ordenId, required String nuevoEstado}) async {
    await _firestore.collection(_collection).doc(ordenId).update({
      'estado': nuevoEstado,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> eliminar(String id) async {
    final ref = _firestore.collection(_collection).doc(id);

    // 1. Borrar items (Subcolección)
    final items = await ref.collection('items').get();
    for (var doc in items.docs) {
      await doc.reference.delete();
    }

    // 2. Borrar orden
    await ref.delete();
  }
}