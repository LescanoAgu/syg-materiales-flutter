import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/stock_model.dart';
import '../models/producto_model.dart';

class StockRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'stock';

  Future<StockModel?> obtenerPorProductoId(String productoId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(productoId).get();
      if (doc.exists) {
        return StockModel.fromMap(doc.data()!).copyWith(id: doc.id);
      }
      return StockModel(productoId: productoId, cantidadDisponible: 0);
    } catch (e) { return null; }
  }

  // Alias necesario
  Future<StockModel?> obtenerPorProductoCodigo(String codigo) async => obtenerPorProductoId(codigo);

  Future<List<ProductoConStock>> obtenerTodosConStock({bool soloActivos = true}) async {
    try {
      Query query = _firestore.collection('productos');
      if (soloActivos) query = query.where('estado', isEqualTo: 'activo');

      final snapshot = await query.orderBy('codigo').get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return ProductoModel.fromMap(data);
      }).toList();
    } catch (e) {
      print('Error stock: $e');
      return [];
    }
  }

  Future<void> actualizarCantidad({required String productoId, required double cantidad}) async {
    final batch = _firestore.batch();
    final stockRef = _firestore.collection(_collection).doc(productoId);

    batch.set(stockRef, {
      'productoId': productoId,
      'cantidadDisponible': cantidad,
      'ultimaActualizacion': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    final prodRef = _firestore.collection('productos').doc(productoId);
    batch.update(prodRef, {'cantidadDisponible': cantidad});

    await batch.commit();
  }

  // Método que faltaba (usado en ProductoFormPage)
  Future<void> establecer({required String productoId, required double cantidad}) async {
    await actualizarCantidad(productoId: productoId, cantidad: cantidad);
  }

  // Método que faltaba (usado en StockPage)
  Future<int> contarStockBajo() async {
    try {
      final snapshot = await _firestore.collection('productos')
          .where('estado', isEqualTo: 'activo')
          .where('cantidadDisponible', isLessThan: 10)
          .where('cantidadDisponible', isGreaterThan: 0)
          .count().get();
      return snapshot.count ?? 0;
    } catch (e) { return 0; }
  }
}