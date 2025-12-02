import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/acopio_model.dart';
import '../models/movimiento_acopio_model.dart';

class AcopioRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _colAcopios = 'acopios';
  static const String _colMovimientos = 'movimientos_acopio';
  static const String _colProductos = 'productos';
  static const String _colStock = 'stock';

  // --- LECTURA ---

  Future<List<AcopioDetalle>> obtenerTodosConDetalle({bool soloActivos = true}) async {
    try {
      Query query = _firestore.collection(_colAcopios);
      if (soloActivos) {
        query = query.where('cantidadDisponible', isGreaterThan: 0);
      }
      query = query.orderBy('cantidadDisponible', descending: true);

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return AcopioDetalle.fromMap(data);
      }).toList();
    } catch (e) {
      print('❌ Error cargando acopios: $e');
      return [];
    }
  }

  Future<List<MovimientoAcopioModel>> obtenerHistorialAcopio({
    String? productoId,
    String? clienteId,
    String? proveedorId
  }) async {
    try {
      Query query = _firestore.collection(_colMovimientos).orderBy('createdAt', descending: true);

      if (productoId != null) query = query.where('productoId', isEqualTo: productoId);
      if (clienteId != null) query = query.where('clienteId', isEqualTo: clienteId);

      final snapshot = await query.limit(50).get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return MovimientoAcopioModel.fromMap(data);
      }).toList();
    } catch (e) {
      print('❌ Error historial: $e');
      return [];
    }
  }

  // --- ESCRITURA ---
  Future<void> registrarMovimiento({
    required String productoId,
    required String clienteId,
    required String proveedorId,
    required TipoMovimientoAcopio tipo,
    required double cantidad,
    String? motivo,
    String? referencia,
    String? facturaNumero,
    DateTime? facturaFecha,
    bool valorizado = false,
    String productoNombre = '',
    String productoCodigo = '',
    String clienteNombre = '',
    String proveedorNombre = '',
    String categoriaNombre = '',
    String unidadBase = '',
  }) async {

    final acopioQuery = _firestore.collection(_colAcopios)
        .where('clienteId', isEqualTo: clienteId)
        .where('productoId', isEqualTo: productoId)
        .where('proveedorId', isEqualTo: proveedorId)
        .limit(1);

    final stockRef = _firestore.collection(_colStock).doc(productoCodigo);
    final productoRef = _firestore.collection(_colProductos).doc(productoCodigo);
    final movimientoRef = _firestore.collection(_colMovimientos).doc();

    return _firestore.runTransaction((transaction) async {
      final acopioSnapshot = await acopioQuery.get();
      DocumentReference? acopioDocRef;
      double saldoAcopioActual = 0;

      if (acopioSnapshot.docs.isNotEmpty) {
        acopioDocRef = acopioSnapshot.docs.first.reference;
        saldoAcopioActual = (acopioSnapshot.docs.first.data()['cantidadDisponible'] as num).toDouble();
      } else {
        acopioDocRef = _firestore.collection(_colAcopios).doc();
      }

      double stockFisicoActual = 0;
      if (tipo == TipoMovimientoAcopio.entrada || tipo == TipoMovimientoAcopio.devolucion) {
        final stockDoc = await transaction.get(stockRef);
        if (stockDoc.exists) {
          stockFisicoActual = (stockDoc.data()?['cantidadDisponible'] as num?)?.toDouble() ?? 0;
        }
      }

      double nuevoSaldoAcopio = saldoAcopioActual;
      double nuevoStockFisico = stockFisicoActual;

      switch (tipo) {
        case TipoMovimientoAcopio.entrada:
          if (stockFisicoActual < cantidad) throw Exception("Stock físico insuficiente");
          nuevoSaldoAcopio += cantidad;
          nuevoStockFisico -= cantidad;
          break;
        case TipoMovimientoAcopio.salida:
          if (saldoAcopioActual < cantidad) throw Exception("Saldo de acopio insuficiente");
          nuevoSaldoAcopio -= cantidad;
          break;
        case TipoMovimientoAcopio.devolucion:
          if (saldoAcopioActual < cantidad) throw Exception("Devolución excede acopio");
          nuevoSaldoAcopio -= cantidad;
          nuevoStockFisico += cantidad;
          break;
        default:
          break;
      }

      final datosAcopio = {
        'clienteId': clienteId,
        'productoId': productoId,
        'proveedorId': proveedorId,
        'cantidadDisponible': nuevoSaldoAcopio,
        'estado': nuevoSaldoAcopio > 0 ? 'activo' : 'inactivo',
        'updatedAt': DateTime.now().toIso8601String(),
        'clienteRazonSocial': clienteNombre,
        'clienteCodigo': clienteId,
        'productoNombre': productoNombre,
        'productoCodigo': productoCodigo,
        'proveedorNombre': proveedorNombre,
        'proveedorCodigo': proveedorId,
        'unidadBase': unidadBase,
        'categoriaNombre': categoriaNombre,
      };

      // ✅ CORRECCIÓN: Eliminado el '!' porque acopioDocRef ya es seguro
      transaction.set(acopioDocRef, datosAcopio, SetOptions(merge: true));

      if (tipo == TipoMovimientoAcopio.entrada || tipo == TipoMovimientoAcopio.devolucion) {
        transaction.update(stockRef, {
          'cantidadDisponible': nuevoStockFisico,
          'ultimaActualizacion': DateTime.now().toIso8601String(),
        });
        transaction.update(productoRef, {'cantidadDisponible': nuevoStockFisico});
      }

      final datosMovimiento = {
        'productoId': productoId,
        'clienteId': clienteId,
        'proveedorId': proveedorId,
        'tipo': tipo.name,
        'cantidad': cantidad,
        'motivo': motivo,
        'referencia': referencia,
        'facturaNumero': facturaNumero,
        'facturaFecha': facturaFecha?.toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
        'productoNombre': productoNombre,
        'clienteNombre': clienteNombre,
      };

      transaction.set(movimientoRef, datosMovimiento);
    });
  }

  Future<List<Map<String, dynamic>>> obtenerFacturasUnicas() async => [];
  Future<void> filtrarPorFactura(String f) async {}
}