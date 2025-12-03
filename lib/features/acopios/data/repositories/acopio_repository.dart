import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/billetera_acopio_model.dart';
import '../models/movimiento_acopio_model.dart';

class AcopioRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _colBilleteras = 'acopios_billeteras';
  static const String _colMovimientos = 'movimientos_acopio';

  // --- LECTURA BILLETERA ---
  Future<BilleteraAcopio> obtenerBilletera(String clienteId, String productoId) async {
    final id = '${clienteId}_$productoId';
    try {
      final doc = await _firestore.collection(_colBilleteras).doc(id).get();
      if (doc.exists) {
        return BilleteraAcopio.fromMap(doc.data()!, doc.id);
      }
      return BilleteraAcopio(
        id: id,
        clienteId: clienteId,
        clienteNombre: '',
        productoId: productoId,
        productoNombre: '',
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<BilleteraAcopio>> obtenerBilleterasConSaldo() async {
    try {
      final snapshot = await _firestore.collection(_colBilleteras)
          .where('saldoTotal', isGreaterThan: 0)
          .get();
      return snapshot.docs.map((d) => BilleteraAcopio.fromMap(d.data(), d.id)).toList();
    } catch (e) {
      return [];
    }
  }

  // --- HISTORIAL GENERAL (Por Cliente/Producto) ---
  Future<List<MovimientoAcopioModel>> obtenerHistorialAcopio({
    String? productoId,
    String? clienteId,
  }) async {
    try {
      Query query = _firestore.collection(_colMovimientos).orderBy('fecha', descending: true);

      if (productoId != null) query = query.where('productoId', isEqualTo: productoId);
      if (clienteId != null) query = query.where('clienteId', isEqualTo: clienteId);

      final snapshot = await query.limit(50).get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Usamos el fromMap del modelo. Asegúrate que MovimientoAcopioModel tenga fromMap
        // Si no, aquí habría que mapear manualmente. Asumimos que fromMap existe y es robusto.
        return MovimientoAcopioModel.fromMap(data..['id'] = doc.id);
      }).toList();
    } catch (e) {
      print('❌ Error historial: $e');
      return [];
    }
  }

  // --- HISTORIAL POR UBICACIÓN (Para Proveedores) ---
  /// Este método busca todos los movimientos que afectaron a un proveedor específico
  Future<List<MovimientoAcopioModel>> obtenerMovimientosPorUbicacion(String ubicacionId) async {
    try {
      final snapshot = await _firestore.collection(_colMovimientos)
          .where('ubicacionAfectada', isEqualTo: ubicacionId)
      // Se requiere un índice compuesto en Firestore para 'ubicacionAfectada' + 'fecha'
      // Si falla, quita el orderBy temporalmente o crea el índice siguiendo el link de la consola
          .orderBy('fecha', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return MovimientoAcopioModel.fromMap(data..['id'] = doc.id);
      }).toList();
    } catch (e) {
      print("Error historial proveedor: $e");
      return [];
    }
  }

  // --- ESCRITURA (MOVIMIENTOS) ---
  Future<void> registrarMovimiento({
    required String clienteId,
    required String clienteNombre,
    required String productoId,
    required String productoNombre,
    required double cantidad,
    required String origenDestinoId,
    required String tipoMovimiento,
    String? referencia,
    String? usuarioId,
  }) async {
    final billeteraId = '${clienteId}_$productoId';
    final billeteraRef = _firestore.collection(_colBilleteras).doc(billeteraId);
    final movimientoRef = _firestore.collection(_colMovimientos).doc();

    return _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(billeteraRef);

      BilleteraAcopio billetera;
      if (doc.exists) {
        billetera = BilleteraAcopio.fromMap(doc.data()!, doc.id);
      } else {
        billetera = BilleteraAcopio(
          id: billeteraId,
          clienteId: clienteId,
          clienteNombre: clienteNombre,
          productoId: productoId,
          productoNombre: productoNombre,
        );
      }

      double nuevoStockPropio = billetera.cantidadEnDepositoPropio;
      Map<String, double> nuevosProveedores = Map.from(billetera.cantidadEnProveedores);

      if (origenDestinoId == 'stockPropio') {
        nuevoStockPropio += cantidad;
      } else {
        double actual = nuevosProveedores[origenDestinoId] ?? 0.0;
        nuevosProveedores[origenDestinoId] = actual + cantidad;
      }

      final nuevaBilletera = BilleteraAcopio(
        id: billeteraId,
        clienteId: clienteId,
        clienteNombre: clienteNombre,
        productoId: productoId,
        productoNombre: productoNombre,
        cantidadEnDepositoPropio: nuevoStockPropio,
        cantidadEnProveedores: nuevosProveedores,
      );

      transaction.set(billeteraRef, nuevaBilletera.toMap(), SetOptions(merge: true));

      transaction.set(movimientoRef, {
        'fecha': DateTime.now().toIso8601String(),
        'clienteId': clienteId,
        'clienteNombre': clienteNombre, // Guardamos nombres para facilitar reportes
        'productoId': productoId,
        'productoNombre': productoNombre,
        'cantidad': cantidad,
        'tipo': tipoMovimiento,
        'ubicacionAfectada': origenDestinoId,
        'referencia': referencia,
        'usuarioId': usuarioId,
      });
    });
  }
}