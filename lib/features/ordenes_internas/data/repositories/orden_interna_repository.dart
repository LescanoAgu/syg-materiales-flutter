import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/orden_interna_model.dart';
import '../models/orden_item_model.dart';
// Importamos repositorios para obtener datos al desnormalizar
import '../../../../features/clientes/data/repositories/cliente_repository.dart';
import '../../../../features/obras/data/repositories/obra_repository.dart';
import '../../../../features/stock/data/repositories/producto_repository.dart';

class OrdenInternaRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'ordenes_internas';

  // Repos para buscar datos
  final ClienteRepository _clienteRepo = ClienteRepository();
  final ObraRepository _obraRepo = ObraRepository();
  final ProductoRepository _productoRepo = ProductoRepository();

  // ========================================
  // CREAR ORDEN
  // ========================================
  Future<String> crearOrden({
    required String clienteId,
    required String obraId,
    required String solicitanteNombre,
    String? observacionesCliente,
    required List<Map<String, dynamic>> items, // {productoId, cantidad, precio, ...}
    String? usuarioCreadorId,
  }) async {

    return _firestore.runTransaction((transaction) async {
      // 1. Generar correlativo usando un documento contador
      final contadorRef = _firestore.collection('sistema').doc('contadores');
      final contadorDoc = await transaction.get(contadorRef);

      int nuevoNumero = 1;
      if (contadorDoc.exists) {
        nuevoNumero = (contadorDoc.data()?['ordenes_count'] ?? 0) + 1;
      }

      String codigoOrden = 'OI-${nuevoNumero.toString().padLeft(4, '0')}';

      // Actualizar contador
      transaction.set(contadorRef, {'ordenes_count': nuevoNumero}, SetOptions(merge: true));

      // 2. Obtener datos para desnormalizar (Cliente y Obra)
      // NOTA: En transacciones estrictas se debe leer dentro, pero para simplificar
      // asumimos lectura previa o consistencia eventual de nombres.
      final cliente = await _clienteRepo.obtenerPorId(clienteId);
      // Asumimos que el obraId es el ID del documento o el código
      // Si usas código como ID en obras, esto funciona directo.
      // Si no, tendrías que buscar la obra. Asumiremos que obraId es el ID del doc.
      final obraDoc = await _firestore.collection('obras').doc(obraId).get();

      // 3. Preparar Orden
      final nuevaOrdenRef = _firestore.collection(_collection).doc();
      double total = 0;

      // 4. Procesar Items
      for (var itemData in items) {
        final prodId = itemData['productoId'] as String;
        final cantidad = (itemData['cantidad'] as num).toDouble();
        final precio = (itemData['precio'] as num).toDouble();
        final subtotal = cantidad * precio;

        total += subtotal;

        // Obtener datos del producto para snapshot (guardar nombre histórico)
        final prodDoc = await _firestore.collection('productos').doc(prodId).get();
        final prodData = prodDoc.data() ?? {};

        // Referencia para el item en SUBCOLECCIÓN
        final itemRef = nuevaOrdenRef.collection('items').doc();

        final itemModel = OrdenItem(
          id: itemRef.id,
          ordenId: nuevaOrdenRef.id,
          productoId: prodId,
          cantidadSolicitada: cantidad,
          precioUnitario: precio,
          subtotal: subtotal,
          observaciones: itemData['observaciones'],
          createdAt: DateTime.now(),
        );

        // Guardamos el item con datos desnormalizados del producto para evitar lecturas extra
        final itemMap = itemModel.toMap();
        itemMap['productoNombre'] = prodData['nombre'] ?? 'Producto eliminado';
        itemMap['productoCodigo'] = prodData['codigo'] ?? '';
        itemMap['unidadBase'] = prodData['unidadBase'] ?? '';

        transaction.set(itemRef, itemMap);
      }

      // 5. Guardar Orden
      final ordenModel = OrdenInterna(
        id: nuevaOrdenRef.id,
        numero: codigoOrden,
        clienteId: clienteId,
        obraId: obraId,
        solicitanteNombre: solicitanteNombre,
        fechaPedido: DateTime.now(),
        estado: 'solicitado',
        observacionesCliente: observacionesCliente,
        total: total,
        usuarioCreadorId: usuarioCreadorId,
        createdAt: DateTime.now(),
      );

      final ordenMap = ordenModel.toMap();
      // Desnormalizar nombres en la orden
      if (cliente != null) ordenMap['clienteRazonSocial'] = cliente.razonSocial;
      if (obraDoc.exists) ordenMap['obraNombre'] = obraDoc.data()?['nombre'] ?? '';

      transaction.set(nuevaOrdenRef, ordenMap);

      return nuevaOrdenRef.id;
    });
  }

  // ========================================
  // LECTURA
  // ========================================
  Future<List<OrdenInternaDetalle>> getOrdenes({String? estado}) async {
    try {
      Query query = _firestore.collection(_collection);

      if (estado != null) {
        query = query.where('estado', isEqualTo: estado);
      }

      query = query.orderBy('createdAt', descending: true);

      final snapshot = await query.get();

      // Mapeamos documentos a objetos
      List<OrdenInternaDetalle> listaDetalle = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;

        final orden = OrdenInterna.fromMap(data);

        // IMPORTANTE: Para la lista principal, quizás NO quieras cargar los items de todas las órdenes
        // por un tema de costos de lectura (N+1).
        // Aquí cargaremos una lista VACÍA de items por defecto para la vista general.
        // El detalle completo se cargará en `getOrdenPorId`.

        listaDetalle.add(OrdenInternaDetalle(
          orden: orden,
          clienteRazonSocial: data['clienteRazonSocial'] ?? 'Desconocido',
          obraNombre: data['obraNombre'],
          items: [], // Lista vacía para optimizar
        ));
      }
      return listaDetalle;

    } catch (e) {
      print('❌ Error getOrdenes: $e');
      return [];
    }
  }

  /// Obtiene el detalle completo de UNA orden (incluyendo subcolección items)
  Future<OrdenInternaDetalle?> getOrdenPorId(String ordenId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(ordenId).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      data['id'] = doc.id;
      final orden = OrdenInterna.fromMap(data);

      // Ahora sí leemos la subcolección de items
      final itemsSnap = await doc.reference.collection('items').get();

      final itemsDetalle = itemsSnap.docs.map((itemDoc) {
        final iData = itemDoc.data();
        iData['id'] = itemDoc.id;

        // Aquí recuperamos los datos desnormalizados que guardamos al crear
        return OrdenItemDetalle(
          item: OrdenItem.fromMap(iData),
          productoNombre: iData['productoNombre'] ?? '?',
          productoCodigo: iData['productoCodigo'] ?? '?',
          unidadBase: iData['unidadBase'] ?? 'u',
          categoriaNombre: '', // Si es crítico, guardarlo también al crear
        );
      }).toList();

      return OrdenInternaDetalle(
        orden: orden,
        clienteRazonSocial: data['clienteRazonSocial'] ?? '',
        obraNombre: data['obraNombre'],
        items: itemsDetalle,
      );

    } catch (e) {
      print('❌ Error getOrdenPorId: $e');
      return null;
    }
  }

  // ========================================
  // ACCIONES
  // ========================================
  Future<void> cambiarEstado({
    required String ordenId,
    required String nuevoEstado,
    String? motivoRechazo,
    String? observaciones,
  }) async {
    final updates = <String, dynamic>{
      'estado': nuevoEstado,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (motivoRechazo != null) updates['motivoRechazo'] = motivoRechazo;
    if (observaciones != null) updates['observacionesInternas'] = observaciones;

    await _firestore.collection(_collection).doc(ordenId).update(updates);
  }
}