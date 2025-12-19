import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/stock_model.dart';
import '../models/producto_model.dart';

class StockRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'stock';
  static const String _prodCollection = 'productos';

  Future<StockModel?> obtenerPorProductoId(String productoId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(productoId).get();
      if (doc.exists) {
        return StockModel.fromMap(doc.data()!).copyWith(id: doc.id);
      }
      return StockModel(productoId: productoId, cantidadDisponible: 0);
    } catch (e) { return null; }
  }

  // Alias
  Future<StockModel?> obtenerPorProductoCodigo(String codigo) async => obtenerPorProductoId(codigo);

  Future<List<ProductoModel>> obtenerTodosConStock({bool soloActivos = true}) async {
    try {
      Query query = _firestore.collection(_prodCollection);
      if (soloActivos) query = query.where('estado', isEqualTo: 'activo');

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // ✅ CORRECCIÓN: Se pasa el ID como segundo argumento
        return ProductoModel.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Método atómico para actualizar stock sin movimiento
  Future<void> actualizarStock(String productoId, double cantidadDelta) async {
    final refStock = _firestore.collection(_collection).doc(productoId);
    final refProd = _firestore.collection(_prodCollection).doc(productoId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(refStock);
      double actual = 0;
      if (snapshot.exists) {
        actual = (snapshot.data()?['cantidadDisponible'] as num?)?.toDouble() ?? 0;
      }

      double nueva = actual + cantidadDelta;

      transaction.set(refStock, {
        'productoId': productoId,
        'cantidadDisponible': nueva,
        'ultimaActualizacion': FieldValue.serverTimestamp()
      }, SetOptions(merge: true));

      transaction.update(refProd, {'cantidadDisponible': nueva});
    });
  }
}