// [COPIAR Y PEGAR ESTE ARCHIVO COMPLETO]
// Reemplaza tu: lib/features/stock/data/repositories/movimiento_stock_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/movimiento_stock_model.dart';
import '../models/stock_model.dart';

class MovimientoStockRepository {
  // Instancia de Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Registrar un nuevo movimiento (el método más importante)
  // CAMBIO: productoId ahora es String (el código del producto)
  Future<MovimientoStock> registrarMovimiento({
    required String productoId, // <-- CAMBIO: de int a String
    required TipoMovimiento tipo,
    required double cantidad,
    String? motivo,
    String? referencia,
    int? usuarioId,
  }) async {

    // 1. Definir referencias a los documentos
    final stockDocRef = _firestore.collection('stock').doc(productoId);
    final movimientoDocRef = _firestore.collection('movimientos_stock').doc(); // Firestore genera ID

    // 2. Correr como una transacción
    return await _firestore.runTransaction((transaction) async {
      // 3. Obtener el stock actual DENTRO de la transacción
      final stockSnapshot = await transaction.get(stockDocRef);

      double cantidadAnterior = 0;
      if (stockSnapshot.exists) {
        cantidadAnterior = (stockSnapshot.data()!['cantidad_disponible'] as num).toDouble();
      } else {
        // Si el stock no existe, lo creamos (cantidad anterior es 0)
        print('Creando registro de stock para $productoId');
      }

      // 4. Calcular la nueva cantidad
      double cantidadPosterior;

      switch (tipo) {
        case TipoMovimiento.entrada:
          cantidadPosterior = cantidadAnterior + cantidad;
          break;
        case TipoMovimiento.salida:
          if (cantidadAnterior < cantidad) {
            throw Exception('Stock insuficiente. Disponible: $cantidadAnterior');
          }
          cantidadPosterior = cantidadAnterior - cantidad;
          break;
        case TipoMovimiento.ajuste:
        // En nuestro modelo, el ajuste es relativo (+10 o -10)
          cantidadPosterior = cantidadAnterior + cantidad;
          // Si tu lógica es que 'cantidad' es el *nuevo total*:
          // cantidadPosterior = cantidad;
          break;
      }

      // 5. Crear el modelo del movimiento
      final movimiento = MovimientoStock(
        id: movimientoDocRef.id, // ID generado por Firestore
        productoId: productoId, // <-- CAMBIO: String
        tipo: tipo,
        cantidad: cantidad.abs(),
        cantidadAnterior: cantidadAnterior,
        cantidadPosterior: cantidadPosterior,
        motivo: motivo,
        referencia: referencia,
        usuarioId: usuarioId,
        createdAt: DateTime.now(),
      );

      // 6. Actualizar el stock DENTRO de la transacción
      // Usamos .set con merge:true para crear o actualizar
      transaction.set(stockDocRef, {
        'cantidad_disponible': cantidadPosterior,
        'ultima_actualizacion': movimiento.createdAt.toIso8601String(),
        'productoId': productoId, // Aseguramos que este campo exista
      }, SetOptions(merge: true));

      // 7. Crear el movimiento DENTRO de la transacción
      transaction.set(movimientoDocRef, movimiento.toMap());

      // 8. Retornar el movimiento
      return movimiento;
    });
  }

  // Obtener todos los movimientos de un producto
  // CAMBIO: productoId ahora es String (el código del producto)
  Future<List<MovimientoStock>> getMovimientosPorProducto(String productoId) async {
    try {
      final snapshot = await _firestore
          .collection('movimientos_stock')
          .where('productoId', isEqualTo: productoId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return MovimientoStock.fromMap(doc.data() as Map<String, dynamic>)
            .copyWith(id: doc.id);
      }).toList();

    } catch (e) {
      print('❌ Error al obtener movimientos por producto: $e');
      return [];
    }
  }

  // Obtener movimientos con filtros
  Future<List<MovimientoStock>> getMovimientos({
    DateTime? desde,
    DateTime? hasta,
    TipoMovimiento? tipo,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection('movimientos_stock');

      if (desde != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(desde));
      }
      if (hasta != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(hasta));
      }
      if (tipo != null) {
        query = query.where('tipo', isEqualTo: tipo.name);
      }

      query = query.orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return MovimientoStock.fromMap(doc.data() as Map<String, dynamic>)
            .copyWith(id: doc.id);
      }).toList();

    } catch (e) {
      print('❌ Error al obtener movimientos con filtros: $e');
      return [];
    }
  }

  // Obtener el último movimiento de un producto
  Future<MovimientoStock?> getUltimoMovimiento(String productoId) async {
    try {
      final snapshot = await _firestore
          .collection('movimientos_stock')
          .where('productoId', isEqualTo: productoId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      return MovimientoStock.fromMap(doc.data() as Map<String, dynamic>)
          .copyWith(id: doc.id);

    } catch (e) {
      print('❌ Error al obtener último movimiento: $e');
      return null;
    }
  }

  // Cancelar un movimiento (crear un movimiento inverso)
  // CAMBIO: movimientoId ahora es String
  Future<MovimientoStock> cancelarMovimiento(String movimientoId) async {
    // 1. Obtener el movimiento original
    final doc = await _firestore.collection('movimientos_stock').doc(movimientoId).get();

    if (!doc.exists) {
      throw Exception('Movimiento no encontrado');
    }

    final movimientoOriginal = MovimientoStock.fromMap(doc.data() as Map<String, dynamic>);

    // 2. Crear un movimiento inverso
    TipoMovimiento tipoInverso;
    double cantidadInversa = -movimientoOriginal.cantidad; // Invertir el signo

    switch (movimientoOriginal.tipo) {
      case TipoMovimiento.entrada:
        tipoInverso = TipoMovimiento.salida;
        cantidadInversa = -movimientoOriginal.cantidad;
        break;
      case TipoMovimiento.salida:
        tipoInverso = TipoMovimiento.entrada;
        cantidadInversa = movimientoOriginal.cantidad;
        break;
      case TipoMovimiento.ajuste:
        tipoInverso = TipoMovimiento.ajuste;
        // Si el ajuste fue +10, la cancelación es -10.
        // Si fue -10, la cancelación es +10.
        // Asumimos que la cantidad ya tiene el signo en el modelo original
        cantidadInversa = -movimientoOriginal.cantidad;
        break;
    }

    // 3. Registrar el movimiento inverso (esto corre otra transacción)
    return await registrarMovimiento(
      productoId: movimientoOriginal.productoId, // ya es String
      tipo: tipoInverso,
      cantidad: cantidadInversa, // Pasamos la cantidad con signo
      motivo: 'Cancelación del movimiento #$movimientoId',
      referencia: 'CANC-$movimientoId',
      usuarioId: movimientoOriginal.usuarioId,
    );
  }

  /// Registra múltiples movimientos de stock en un "Batch"
  /// Un Batch es como una transacción pero sin leer datos.
  /// Es más rápido para escrituras masivas.
  Future<bool> registrarMovimientoEnLote({
    required List<Map<String, dynamic>> items, // {productoId (String), cantidad, montoValorizado}
    required TipoMovimiento tipo,
    String? facturaNumero,
    DateTime? facturaFecha,
    String? motivo,
    String? referencia,
    String? remitoNumero,
    bool valorizado = false,
    int? usuarioId,
  }) async {

    // 1. Iniciar un "Batch"
    final batch = _firestore.batch();

    try {
      int movimientosRegistrados = 0;

      for (var item in items) {
        final productoId = item['productoId'] as String; // <-- CAMBIO: String
        final cantidad = item['cantidad'] as double;
        final montoValorizado = item['montoValorizado'] as double?;

        // 1. Obtener stock actual (¡OJO! Esto es riesgoso fuera de transacción)
        // Para un lote, lo más seguro es usar "Increment" de Firestore.
        final stockDocRef = _firestore.collection('stock').doc(productoId);

        double cantidadMovimiento = 0;
        switch (tipo) {
          case TipoMovimiento.entrada:
            cantidadMovimiento = cantidad;
            break;
          case TipoMovimiento.salida:
            cantidadMovimiento = -cantidad;
            // Advertencia: No podemos validar stock en un batch.
            // La app DEBE validar el stock antes de llamar a este método.
            break;
          case TipoMovimiento.ajuste:
          // No podemos hacer ajuste en lote sin transacción.
          // Este método solo soportará ENTRADAS y SALIDAS.
            throw Exception("Los 'Ajustes' no se pueden hacer en lote, deben ser individuales.");
        }

        // 2. Actualizar stock usando "Increment" (atómico)
        batch.set(stockDocRef, {
          'cantidad_disponible': FieldValue.increment(cantidadMovimiento),
          'ultima_actualizacion': DateTime.now().toIso8601String(),
          'productoId': productoId,
        }, SetOptions(merge: true));


        // 3. Crear el movimiento
        // (Nota: No podemos saber cantidad_anterior/posterior en un batch)
        final movimientoDocRef = _firestore.collection('movimientos_stock').doc();
        final movimiento = MovimientoStock(
          id: movimientoDocRef.id,
          productoId: productoId,
          tipo: tipo,
          cantidad: cantidad,
          cantidadAnterior: 0, // No se puede saber en un Batch
          cantidadPosterior: 0, // No se puede saber en un Batch
          motivo: motivo,
          referencia: referencia,
          usuarioId: usuarioId,
          createdAt: DateTime.now(),
        );

        // 4. Registrar movimiento en el Batch
        batch.set(movimientoDocRef, movimiento.toMap());
        movimientosRegistrados++;
      }

      // 5. Ejecutar todas las operaciones del Batch
      await batch.commit();

      print('✅ Movimiento en lote registrado: $movimientosRegistrados productos');
      return true;

    } catch (e) {
      print('❌ Error en registro en lote: $e');
      rethrow;
    }
  }
}