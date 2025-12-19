import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/categoria_model.dart';

class CategoriaRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'categorias';

  Future<List<CategoriaModel>> obtenerTodas() async {
    try {
      final snapshot = await _firestore.collection(_collection)
          .orderBy('orden')
          .get();

      return snapshot.docs.map((doc) {
        return CategoriaModel.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      // Si falla el ordenamiento (falta de índice), intentamos sin orden
      try {
        final snapshot = await _firestore.collection(_collection).get();
        return snapshot.docs.map((doc) => CategoriaModel.fromMap(doc.data(), doc.id)).toList();
      } catch (e2) {
        return [];
      }
    }
  }

  Future<CategoriaModel?> obtenerPorId(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return CategoriaModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> crear(CategoriaModel categoria) async {
    await _firestore.collection(_collection).add(categoria.toMap());
  }
}