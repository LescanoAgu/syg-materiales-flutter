import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/movimiento_stock_model.dart';

class MovimientoStockRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<MovimientoStock> registrarMovimiento({
    required String productoId,
    required String productoNombre, // ✅ NUEVO
    required TipoMovimiento tipo,
    required double cantidad,
    String? motivo,
    String? referencia,
    String? usuarioId,
  }) async {

    final stockRef = _firestore.collection('stock').doc(productoId);
    final movRef = _firestore.collection('movimientos_stock').doc();

    return await _firestore.runTransaction((transaction) async {
      final stockDoc = await transaction.get(stockRef);
      double stockActual = 0;

      // Si no existe el stock, lo inicializamos
      if (stockDoc.exists) {
        stockActual = (stockDoc.data()?['cantidadDisponible'] as num?)?.toDouble() ?? 0.0;
      }

      double nuevoStock = stockActual;
      if (tipo == TipoMovimiento.entrada) nuevoStock += cantidad;
      if (tipo == TipoMovimiento.salida) nuevoStock -= cantidad;
      if (tipo == TipoMovimiento.ajuste) nuevoStock = cantidad;

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

      // Crear Movimiento con NOMBRE
      final mov = MovimientoStock(
        id: movRef.id,
        productoId: productoId,
        productoNombre: productoNombre, // Guardamos el nombre
        tipo: tipo,
        cantidad: cantidad,
        cantidadAnterior: stockActual,
        cantidadPosterior: nuevoStock,
        motivo: motivo,
        referencia: referencia,
        usuarioId: usuarioId,
        createdAt: DateTime.now(),
      );

      transaction.set(movRef, mov.toMap());
      return mov;
    });
  }

  // ... (el resto del archivo obtenerMovimientos sigue igual)
  Future<List<MovimientoStock>> obtenerMovimientos({
    String? productoId,
    DateTime? desde,
    DateTime? hasta,
    TipoMovimiento? tipo,
  }) async {
    Query query = _firestore.collection('movimientos_stock').orderBy('createdAt', descending: true);

    if (productoId != null) query = query.where('productoId', isEqualTo: productoId);
    if (tipo != null) query = query.where('tipo', isEqualTo: tipo.name);

    // Filtro de fechas básico
    if (desde != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: desde.toIso8601String());
    }
    // Nota: 'hasta' requiere lógica compleja en string, lo ideal es filtrar en memoria si son pocos datos
    // o usar Timestamp de Firestore. Por simplicidad, filtramos en memoria lo que falte.

    final snapshot = await query.limit(100).get(); // Aumentamos límite

    var lista = snapshot.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      data['id'] = d.id;
      return MovimientoStock.fromMap(data);
    }).toList();

    // Filtro memoria para 'hasta' si hace falta
    if (hasta != null) {
      lista = lista.where((m) => m.createdAt.isBefore(hasta.add(const Duration(days: 1)))).toList();
    }

    return lista;
  }
}