import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/acopio_model.dart';

class AcopioRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'acopios';

  // Traer solo lo que tiene saldo (activo = true)
  Future<List<AcopioModel>> obtenerActivos() async {
    try {
      final snapshot = await _firestore.collection(_collection)
          .where('activo', isEqualTo: true)
          .orderBy('fechaCompra', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AcopioModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print("Error obteniendo acopios: $e");
      return [];
    }
  }

  Future<void> crearAcopio(AcopioModel acopio) async {
    await _firestore.collection(_collection).add(acopio.toMap());
  }

  // Método transaccional para descontar stock de una factura específica
  Future<void> consumirDeAcopio(String acopioId, Map<String, double> itemsAConsumir) async {
    return _firestore.runTransaction((transaction) async {
      final docRef = _firestore.collection(_collection).doc(acopioId);
      final doc = await transaction.get(docRef);

      if (!doc.exists) throw Exception("Acopio no encontrado");

      final acopio = AcopioModel.fromMap(doc.data()!, doc.id);

      List<Map<String, dynamic>> nuevosItems = [];
      bool quedaSaldoGlobal = false;

      for (var item in acopio.items) {
        // Cuánto vamos a restar de este item específico
        double consumo = itemsAConsumir[item.productoId] ?? 0.0;
        double nuevoRestante = item.cantidadRestante - consumo;

        if (nuevoRestante < -0.001) { // Tolerancia pequeña para float
          throw Exception("Saldo insuficiente en ${item.productoNombre}. Quedan ${item.cantidadRestante}, intentaste sacar $consumo");
        }

        if (nuevoRestante > 0) quedaSaldoGlobal = true;

        nuevosItems.add({
          'productoId': item.productoId,
          'productoNombre': item.productoNombre,
          'cantidadOriginal': item.cantidadOriginal,
          'cantidadRestante': nuevoRestante,
        });
      }

      transaction.update(docRef, {
        'items': nuevosItems,
        'activo': quedaSaldoGlobal, // Se archiva si todo llega a 0
      });
    });
  }
}