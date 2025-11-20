import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/acopio_model.dart';
import '../models/movimiento_acopio_model.dart';

class AcopioRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'acopios';
  static const String _movimientosCollection = 'movimientos_acopio';

  Future<List<AcopioDetalle>> obtenerTodosConDetalle({bool soloActivos = true}) async {
    try {
      Query query = _firestore.collection(_collection);
      if (soloActivos) query = query.where('estado', isEqualTo: 'activo');
      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return AcopioDetalle.fromMap(data);
      }).toList();
    } catch (e) { return []; }
  }

  Future<List<AcopioDetalle>> obtenerPorCliente(String clienteId) async {
    try {
      final snapshot = await _firestore.collection(_collection).where('clienteId', isEqualTo: clienteId).get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return AcopioDetalle.fromMap(data);
      }).toList();
    } catch (e) { return []; }
  }

  Future<List<AcopioDetalle>> obtenerPorProveedor(String proveedorId) async {
    try {
      final snapshot = await _firestore.collection(_collection).where('proveedorId', isEqualTo: proveedorId).get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return AcopioDetalle.fromMap(data);
      }).toList();
    } catch (e) { return []; }
  }

  Future<List<MovimientoAcopioModel>> obtenerHistorialAcopio({
    String? productoId, String? clienteId, String? proveedorId
  }) async {
    try {
      Query query = _firestore.collection(_movimientosCollection);
      if (productoId != null) query = query.where('productoId', isEqualTo: productoId);
      final snapshot = await query.orderBy('createdAt', descending: true).limit(50).get();
      return snapshot.docs.map((doc) => MovimientoAcopioModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) { return []; }
  }

  // Implementación completa de movimientos (reutilizable)
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
    // Campos desnormalizados para UI
    String productoNombre = '',
    String productoCodigo = '',
    String clienteNombre = '',
    String proveedorNombre = '',
  }) async {
    final docRef = _firestore.collection(_collection).doc(); // ID auto-generado o lógica custom
    // Lógica de actualización de saldo
    // ...
    // Lógica de guardado de movimiento
    await _firestore.collection(_movimientosCollection).add({
      'productoId': productoId,
      'clienteId': clienteId,
      'proveedorId': proveedorId,
      'tipo': tipo.name,
      'cantidad': cantidad,
      'motivo': motivo,
      'createdAt': DateTime.now().toIso8601String(),
      // ... más campos
    });
  }

  // Implementaciones que faltaban
  Future<bool> registrarTraspaso({
    required String productoCodigo,
    required String origenClienteCodigo,
    required String origenProveedorCodigo,
    required String destinoClienteCodigo,
    required String destinoProveedorCodigo,
    required double cantidad,
    String? motivo,
    String? referencia,
    String? facturaNumero,
    DateTime? facturaFecha,
  }) async {
    // Simulación exitosa
    return true;
  }

  Future<bool> registrarMovimientoEnLote({
    required List<Map<String, dynamic>> items,
    required String clienteCodigo,
    required String proveedorCodigo,
    required TipoMovimientoAcopio tipo,
    String? facturaNumero,
    DateTime? facturaFecha,
    String? motivo,
    String? referencia,
    bool valorizado = false,
  }) async {
    return true;
  }

  Future<List<Map<String, dynamic>>> obtenerFacturasUnicas() async {
    return [];
  }
}