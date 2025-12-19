import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/movimiento_stock_model.dart';

class MovimientoStockRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<MovimientoStock> registrarMovimiento({
    required String productoId,
    required String productoNombre,
    required TipoMovimiento tipo,
    required double cantidad,
    String? motivo,
    String? referencia,
    String? usuarioId,
    String? usuarioNombre,
    String? obraId,
    String? obraNombre,
  }) async {

    final stockRef = _firestore.collection('stock').doc(productoId);
    final prodRef = _firestore.collection('productos').doc(productoId);
    final movRef = _firestore.collection('movimientos_stock').doc();

    return await _firestore.runTransaction((transaction) async {
      // 1. Leer stock actual
      final stockDoc = await transaction.get(stockRef);
      double stockActual = 0;

      if (stockDoc.exists) {
        stockActual = (stockDoc.data()?['cantidadDisponible'] as num?)?.toDouble() ?? 0.0;
      }

      // 2. Calcular nuevo stock
      double nuevoStock = stockActual;
      if (tipo == TipoMovimiento.entrada || tipo == TipoMovimiento.ajustePositivo) {
        nuevoStock += cantidad;
      } else if (tipo == TipoMovimiento.salida || tipo == TipoMovimiento.ajusteNegativo) {
        nuevoStock -= cantidad;
      } else if (tipo == TipoMovimiento.ajuste) {
        // Ajuste absoluto (reseteo)
        nuevoStock = cantidad;
      }

      // 3. Crear objeto Movimiento
      final mov = MovimientoStock(
        id: movRef.id,
        productoId: productoId,
        productoNombre: productoNombre,
        tipo: tipo,
        cantidad: cantidad,
        cantidadAnterior: stockActual,
        cantidadPosterior: nuevoStock,
        motivo: motivo,
        referencia: referencia,
        usuarioId: usuarioId,
        usuarioNombre: usuarioNombre ?? 'Sistema',
        fecha: DateTime.now(),
        obraId: obraId,
        obraNombre: obraNombre,
      );

      // 4. Escribir cambios (Atomicidad garantizada)

      // A. Guardar en historial
      transaction.set(movRef, mov.toMap());

      // B. Actualizar colección 'stock' (fuente de verdad)
      transaction.set(stockRef, {
        'productoId': productoId,
        'cantidadDisponible': nuevoStock,
        'ultimaActualizacion': FieldValue.serverTimestamp()
      }, SetOptions(merge: true));

      // C. Actualizar colección 'productos' (para lectura rápida en UI)
      transaction.update(prodRef, {
        'cantidadDisponible': nuevoStock,
        'updatedAt': FieldValue.serverTimestamp()
      });

      return mov;
    });
  }

  Future<List<MovimientoStock>> obtenerMovimientos({
    String? productoId,
    DateTime? desde,
    DateTime? hasta,
    TipoMovimiento? tipo,
  }) async {
    Query query = _firestore.collection('movimientos_stock').orderBy('createdAt', descending: true);

    if (productoId != null) query = query.where('productoId', isEqualTo: productoId);
    if (tipo != null) query = query.where('tipo', isEqualTo: tipo.toString().split('.').last);

    // Filtros de fecha simples
    if (desde != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(desde));
    }
    if (hasta != null) {
      query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(hasta));
    }

    final snapshot = await query.limit(100).get();

    return snapshot.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      data['id'] = d.id;
      return MovimientoStock.fromMap(data);
    }).toList();
  }
}