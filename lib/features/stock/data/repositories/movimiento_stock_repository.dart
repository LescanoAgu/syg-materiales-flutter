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
    // ✅ NUEVOS PARAMETROS
    String? obraId,
    String? obraNombre,
  }) async {

    final stockRef = _firestore.collection('stock').doc(productoId);
    final movRef = _firestore.collection('movimientos_stock').doc();

    return await _firestore.runTransaction((transaction) async {
      final stockDoc = await transaction.get(stockRef);
      double stockActual = 0;

      if (stockDoc.exists) {
        stockActual = (stockDoc.data()?['cantidadDisponible'] as num?)?.toDouble() ?? 0.0;
      }

      double nuevoStock = stockActual;
      if (tipo == TipoMovimiento.entrada) nuevoStock += cantidad;
      if (tipo == TipoMovimiento.salida) nuevoStock -= cantidad;
      if (tipo == TipoMovimiento.ajuste) nuevoStock = cantidad; // Ajuste fija el valor

      // Actualizar Stock
      transaction.set(stockRef, {
        'productoId': productoId,
        'cantidadDisponible': nuevoStock,
        'ultimaActualizacion': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      // Actualizar espejo en Producto
      transaction.update(_firestore.collection('productos').doc(productoId), {
        'cantidadDisponible': nuevoStock
      });

      // Crear Movimiento
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
        createdAt: DateTime.now(),
        obraId: obraId,      // ✅ Guardar
        obraNombre: obraNombre, // ✅ Guardar
      );

      transaction.set(movRef, mov.toMap());
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
    if (tipo != null) query = query.where('tipo', isEqualTo: tipo.name);
    if (desde != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: desde.toIso8601String());
    }

    final snapshot = await query.limit(100).get();
    var lista = snapshot.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      data['id'] = d.id;
      return MovimientoStock.fromMap(data);
    }).toList();

    if (hasta != null) {
      lista = lista.where((m) => m.createdAt.isBefore(hasta.add(const Duration(days: 1)))).toList();
    }

    return lista;
  }
}