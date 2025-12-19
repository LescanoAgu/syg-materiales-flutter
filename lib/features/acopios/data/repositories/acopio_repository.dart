import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/acopio_model.dart';

class AcopioRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'acopios';

  Future<List<AcopioModel>> obtenerAcopios() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      return snapshot.docs
          .map((doc) => AcopioModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception("Error obteniendo acopios: $e");
    }
  }

  Future<AcopioModel?> obtenerPorId(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) return null;
      return AcopioModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      return null;
    }
  }

  Future<void> actualizar(AcopioModel acopio) async {
    if (acopio.id == null) throw Exception("ID nulo");
    await _firestore.collection(_collection).doc(acopio.id).update(acopio.toMap());
  }

  Future<void> guardarAcopio(AcopioModel acopio) async {
    // Buscamos si ya existe una billetera para este cliente en este proveedor
    final query = await _firestore.collection(_collection)
        .where('clienteId', isEqualTo: acopio.clienteId)
        .where('proveedorId', isEqualTo: acopio.proveedorId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      // Si existe, actualizamos fusionando items
      final docId = query.docs.first.id;
      final existente = AcopioModel.fromMap(query.docs.first.data(), docId);

      // Lógica de fusión simple: Agregamos lo nuevo
      // (En una app real haríamos un merge más complejo de listas)
      // Por ahora, asumimos que 'acopio' trae la lista final deseada o usamos una lógica de suma
      // Para simplificar: sobreescribimos con lo que manda el provider que ya hizo la lógica

      await _firestore.collection(_collection).doc(docId).update(acopio.toMap());
    } else {
      await _firestore.collection(_collection).add(acopio.toMap());
    }
  }
}