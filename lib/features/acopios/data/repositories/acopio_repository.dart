import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/acopio_model.dart';
import '../models/movimiento_acopio_model.dart';

class AcopioRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _colAcopios = 'acopios';
  static const String _colMovimientos = 'movimientos_acopio';
  static const String _colProductos = 'productos';
  static const String _colStock = 'stock'; // Colección espejo de stock

  // --- LECTURA ---

  Future<List<AcopioDetalle>> obtenerTodosConDetalle({bool soloActivos = true}) async {
    try {
      Query query = _firestore.collection(_colAcopios);
      if (soloActivos) {
        // Solo traemos acopios que tengan saldo positivo (> 0)
        query = query.where('cantidadDisponible', isGreaterThan: 0);
      }
      // Ordenar por cliente para agrupar visualmente
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

  // --- ESCRITURA (TRANSACCIONES REALES) ---

  Future<void> registrarMovimiento({
    required String productoId,
    required String clienteId,
    required String proveedorId, // Dónde está guardado (ej: Depósito S&G)
    required TipoMovimientoAcopio tipo,
    required double cantidad,

    // Datos opcionales
    String? motivo,
    String? referencia,
    String? facturaNumero,
    DateTime? facturaFecha,
    bool valorizado = false,

    // Datos desnormalizados para la UI (Nombres)
    String productoNombre = '',
    String productoCodigo = '',
    String clienteNombre = '',
    String proveedorNombre = '',
    String categoriaNombre = '',
    String unidadBase = '',
  }) async {

    // Referencias a documentos
    final acopioQuery = _firestore.collection(_colAcopios)
        .where('clienteId', isEqualTo: clienteId)
        .where('productoId', isEqualTo: productoId)
        .where('proveedorId', isEqualTo: proveedorId)
        .limit(1);

    final stockRef = _firestore.collection(_colStock).doc(productoCodigo); // Usamos código como ID en stock
    final productoRef = _firestore.collection(_colProductos).doc(productoCodigo);
    final movimientoRef = _firestore.collection(_colMovimientos).doc();

    return _firestore.runTransaction((transaction) async {
      // 1. Leer estado actual del Acopio (si existe)
      final acopioSnapshot = await acopioQuery.get();
      DocumentReference? acopioDocRef;
      double saldoAcopioActual = 0;

      if (acopioSnapshot.docs.isNotEmpty) {
        acopioDocRef = acopioSnapshot.docs.first.reference;
        saldoAcopioActual = (acopioSnapshot.docs.first.data()['cantidadDisponible'] as num).toDouble();
      } else {
        // Si no existe, crearemos uno nuevo
        acopioDocRef = _firestore.collection(_colAcopios).doc();
      }

      // 2. Leer Stock Físico S&G (Solo necesario si entra o sale mercadería física)
      double stockFisicoActual = 0;
      if (tipo == TipoMovimientoAcopio.entrada || tipo == TipoMovimientoAcopio.devolucion) {
        final stockDoc = await transaction.get(stockRef);
        if (stockDoc.exists) {
          stockFisicoActual = (stockDoc.data()?['cantidadDisponible'] as num?)?.toDouble() ?? 0;
        }
      }

      // 3. Calcular Nuevos Saldos y Validar
      double nuevoSaldoAcopio = saldoAcopioActual;
      double nuevoStockFisico = stockFisicoActual;

      switch (tipo) {
        case TipoMovimientoAcopio.entrada:
        // Cliente COMPRA y deja en acopio:
        // -> Aumenta su Acopio
        // -> Disminuye nuestro Stock Físico (porque ya no es nuestro, es del cliente)
          if (stockFisicoActual < cantidad) {
            throw Exception("Stock físico insuficiente para realizar este acopio. Disponible: $stockFisicoActual");
          }
          nuevoSaldoAcopio += cantidad;
          nuevoStockFisico -= cantidad;
          break;

        case TipoMovimientoAcopio.salida:
        // Cliente RETIRA material:
        // -> Disminuye su Acopio
        // -> El Stock Físico no cambia (porque ya se descontó cuando compró)
          if (saldoAcopioActual < cantidad) {
            throw Exception("Saldo de acopio insuficiente. Disponible: $saldoAcopioActual");
          }
          nuevoSaldoAcopio -= cantidad;
          break;

        case TipoMovimientoAcopio.devolucion:
        // Cliente DEVUELVE material (cancela compra):
        // -> Disminuye su Acopio
        // -> Aumenta nuestro Stock Físico
          if (saldoAcopioActual < cantidad) {
            throw Exception("No puede devolver más de lo que tiene acopiado.");
          }
          nuevoSaldoAcopio -= cantidad;
          nuevoStockFisico += cantidad;
          break;

        default:
        // Otros tipos (traspaso, ajuste) por ahora solo afectan acopio
        // Implementar lógica específica si hace falta
          break;
      }

      // 4. Ejecutar Escrituras en la Transacción

      // A) Actualizar/Crear Acopio
      final datosAcopio = {
        'clienteId': clienteId,
        'productoId': productoId,
        'proveedorId': proveedorId,
        'cantidadDisponible': nuevoSaldoAcopio,
        'estado': nuevoSaldoAcopio > 0 ? 'activo' : 'inactivo',
        'updatedAt': DateTime.now().toIso8601String(),
        // Datos desnormalizados (se guardan siempre para mantenerlos actualizados)
        'clienteRazonSocial': clienteNombre,
        'clienteCodigo': clienteId, // Asumiendo que ID = Código
        'productoNombre': productoNombre,
        'productoCodigo': productoCodigo,
        'proveedorNombre': proveedorNombre,
        'proveedorCodigo': proveedorId,
        'unidadBase': unidadBase,
        'categoriaNombre': categoriaNombre,
      };

      transaction.set(acopioDocRef!, datosAcopio, SetOptions(merge: true));

      // B) Actualizar Stock Físico (si corresponde)
      if (tipo == TipoMovimientoAcopio.entrada || tipo == TipoMovimientoAcopio.devolucion) {
        transaction.update(stockRef, {
          'cantidadDisponible': nuevoStockFisico,
          'ultimaActualizacion': DateTime.now().toIso8601String(),
        });
        // Espejo en producto también
        transaction.update(productoRef, {'cantidadDisponible': nuevoStockFisico});
      }

      // C) Registrar el Movimiento (Historial)
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
        // Desnormalizados para reporte rápido
        'productoNombre': productoNombre,
        'clienteNombre': clienteNombre,
      };

      transaction.set(movimientoRef, datosMovimiento);
    });
  }

  // Métodos placeholders que puedes implementar a futuro
  Future<List<Map<String, dynamic>>> obtenerFacturasUnicas() async => [];
  Future<void> filtrarPorFactura(String f) async {}
}